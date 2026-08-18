/* ────────────────────────────────────────────────────────────
   Connection health
   Turns /api/status samples into a rolling picture of whether the
   connector is actually holding its session: a freshness strip, a
   link verdict, and a ledger of up/down/server-move transitions.
   The server only ever reports "connected right now", so the history
   is accumulated here on the client.
   ──────────────────────────────────────────────────────────── */
(() => {
    'use strict';

    const MAX_SAMPLES = 90;      // ~3 min at the dashboard's 2s poll
    const MAX_EVENTS = 60;

    // Mirrors the server's own thresholds closely enough to classify a sample.
    // A poll cycle is ~6s, so anything inside ~2 cycles is healthy.
    const FRESH_MS = 14_000;
    const LATE_MS = 45_000;

    const state = {
        samples: [],   // { at, idleMs, connected, quality }
        events: [],    // { at, kind, text }
        clientId: null,
        wasConnected: null,
        lastJobId: null,
    };

    const pad = (n) => String(n).padStart(2, '0');

    function clockOf(ts) {
        const d = new Date(ts);
        return `${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
    }

    function humanDuration(ms) {
        if (!Number.isFinite(ms) || ms < 0) return '—';
        const s = Math.floor(ms / 1000);
        if (s < 60) return `${s}s`;
        const m = Math.floor(s / 60);
        if (m < 60) return `${m}m ${pad(s % 60)}s`;
        const h = Math.floor(m / 60);
        return `${h}h ${pad(m % 60)}m`;
    }

    function classify(idleMs, connected) {
        if (!connected) return 'missing';
        if (idleMs <= FRESH_MS) return 'fresh';
        if (idleMs <= LATE_MS) return 'late';
        return 'missing';
    }

    function pushEvent(kind, text) {
        state.events.unshift({ at: Date.now(), kind, text });
        if (state.events.length > MAX_EVENTS) state.events.length = MAX_EVENTS;
    }

    function reset(clientId) {
        state.clientId = clientId;
        state.samples = [];
        state.events = [];
        state.wasConnected = null;
        state.lastJobId = null;
    }

    /**
     * Feed one /api/status result for the selected client.
     * @param {object|null} client the selected client entry, or null when absent
     */
    function record(client) {
        const now = Date.now();
        const clientId = client ? client.clientId : null;

        if (clientId !== state.clientId) reset(clientId);
        if (!clientId) return;

        const health = client.health || {};
        const idleMs = Number.isFinite(health.idleMs) ? health.idleMs : 0;
        const connected = health.currentSessionActive !== false;
        const quality = classify(idleMs, connected);

        state.samples.push({ at: now, idleMs, connected, quality });
        if (state.samples.length > MAX_SAMPLES) state.samples.shift();

        if (state.wasConnected === null) {
            pushEvent('up', `Session picked up — <strong>${client.username || 'client'}</strong>`);
        } else if (connected && !state.wasConnected) {
            pushEvent('up', 'Link recovered');
        } else if (!connected && state.wasConnected) {
            pushEvent('down', 'Link went quiet past the grace window');
        }
        state.wasConnected = connected;

        if (state.lastJobId && client.jobId && client.jobId !== state.lastJobId) {
            pushEvent('move', `Moved server — <strong>${client.placeName || client.placeId}</strong>`);
        }
        state.lastJobId = client.jobId || state.lastJobId;
    }

    function verdict() {
        if (!state.samples.length) return { key: 'idle', label: 'Awaiting client' };
        const recent = state.samples.slice(-20);
        const bad = recent.filter((s) => s.quality === 'missing').length;
        const late = recent.filter((s) => s.quality === 'late').length;
        const last = recent[recent.length - 1];
        if (!last.connected) return { key: 'dropped', label: 'Disconnected' };
        if (bad > 0 || late > recent.length / 3) return { key: 'wobbly', label: 'Unstable' };
        return { key: 'solid', label: 'Holding steady' };
    }

    function el(id) { return document.getElementById(id); }

    function renderStrip() {
        const strip = el('linkHealthStrip');
        if (!strip) return;
        const samples = state.samples;
        const pads = Math.max(0, MAX_SAMPLES - samples.length);
        const parts = [];
        for (let i = 0; i < pads; i += 1) {
            parts.push('<div class="linkhealth-bar linkhealth-bar--gap" style="height:14%"></div>');
        }
        for (const s of samples) {
            // Taller bar = fresher. Missing samples still show a stub so gaps read as gaps.
            const ratio = s.quality === 'missing'
                ? 1
                : Math.max(0.18, 1 - Math.min(s.idleMs, LATE_MS) / LATE_MS);
            const height = Math.round(ratio * 100);
            parts.push(`<div class="linkhealth-bar linkhealth-bar--${s.quality}" style="height:${height}%" title="${clockOf(s.at)} · idle ${humanDuration(s.idleMs)}"></div>`);
        }
        strip.innerHTML = parts.join('');
    }

    function renderStats(client) {
        const health = (client && client.health) || {};
        const samples = state.samples;
        const observed = samples.length;
        const healthy = samples.filter((s) => s.quality === 'fresh').length;
        const holdRate = observed ? Math.round((healthy / observed) * 100) : null;
        const drops = state.events.filter((e) => e.kind === 'down').length;

        const set = (id, value, tone) => {
            const node = el(id);
            if (!node) return;
            node.innerHTML = value;
            const wrap = node.closest('.linkhealth-stat');
            if (wrap) {
                wrap.classList.toggle('linkhealth-stat--warn', tone === 'warn');
                wrap.classList.toggle('linkhealth-stat--bad', tone === 'bad');
            }
        };

        set('linkHealthUptime', humanDuration(health.sessionUptimeMs) +
            '<small>since first registration</small>');
        set('linkHealthIdle', humanDuration(health.idleMs) +
            '<small>since last poll</small>',
            health.idleMs > LATE_MS ? 'bad' : health.idleMs > FRESH_MS ? 'warn' : null);
        set('linkHealthHold',
            (holdRate === null ? '—' : `${holdRate}%`) +
            `<small>over ${observed} sample${observed === 1 ? '' : 's'}</small>`,
            holdRate !== null && holdRate < 80 ? 'bad' : holdRate !== null && holdRate < 95 ? 'warn' : null);
        set('linkHealthDrops', String(drops) +
            '<small>observed this session</small>',
            drops > 2 ? 'bad' : drops > 0 ? 'warn' : null);
        set('linkHealthReconnects', String(health.reconnectCount ?? 0) +
            '<small>reported by the bridge</small>',
            (health.reconnectCount ?? 0) > 4 ? 'warn' : null);
        set('linkHealthMoves', String(health.sessionChangeCount ?? 0) +
            '<small>roblox server hops</small>');
    }

    function renderVerdict() {
        const node = el('linkHealthVerdict');
        if (!node) return;
        const v = verdict();
        node.className = `linkhealth-verdict linkhealth-verdict--${v.key}`;
        node.textContent = v.label;
    }

    function renderLedger() {
        const node = el('linkHealthLedger');
        if (!node) return;
        if (!state.events.length) {
            node.innerHTML = '<div class="linkhealth-empty">No connection transitions recorded yet.</div>';
            return;
        }
        node.innerHTML = state.events.map((e) => `
            <div class="linkhealth-event linkhealth-event--${e.kind}">
                <span class="linkhealth-event-dot"></span>
                <span class="linkhealth-event-text">${e.text}</span>
                <span class="linkhealth-event-time">${clockOf(e.at)}</span>
            </div>`).join('');
    }

    function renderScale() {
        const node = el('linkHealthScale');
        if (!node) return;
        const span = state.samples.length
            ? humanDuration(Date.now() - state.samples[0].at)
            : '—';
        node.innerHTML = `<span>${span} ago</span><span>now</span>`;
    }

    /**
     * Public entry point: called from dashboard.js on every status poll.
     */
    function update(client) {
        record(client || null);
        renderStrip();
        renderScale();
        renderVerdict();
        renderStats(client);
        renderLedger();
    }

    window.connectionHealth = { update, reset, humanDuration };
})();
