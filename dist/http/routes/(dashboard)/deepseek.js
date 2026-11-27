import { DEEPSEEK_API_KEY, DEEPSEEK_MODEL } from "../../../config.js";
export function GET(_req, res) {
    const hasEnvKey = !!DEEPSEEK_API_KEY;
    const defaultModel = DEEPSEEK_MODEL;
    const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<title>VoidHub DeepSeek</title>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
:root {
  --bg: #000000;
  --surface: #0e0e10;
  --surface2: #141416;
  --border: #1f1f23;
  --text: #f5f5f7;
  --text-muted: #9b9ba3;
  --accent: #9d8cff;
  --accent2: #5b4be0;
  --success: #3ddc84;
  --error: #ff5a5f;
  --thinking: #c4b8ff;
  --think-bg: rgba(157, 140, 255, 0.08);
  --user-bg: #ffffff;
  --ai-bg: #0e0e10;
  --tool-bg: #08080a;
}
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  background: var(--bg);
  color: var(--text);
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
header {
  background: var(--surface);
  padding: 12px 16px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--border);
  flex-shrink: 0;
}
header h1 {
  font-size: 18px;
  font-weight: 600;
  display: flex;
  align-items: center;
  gap: 8px;
}
header .logo {
  width: 28px; height: 28px;
  background: linear-gradient(135deg, var(--accent), var(--accent2));
  border-radius: 8px;
  display: flex; align-items: center; justify-content: center;
  font-size: 14px; font-weight: 700;
}
.settings-btn {
  background: var(--surface2);
  border: 1px solid var(--border);
  color: var(--text-muted);
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 13px;
  cursor: pointer;
}
.settings-btn:active { background: var(--accent); color: white; }
#chat {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  -webkit-overflow-scrolling: touch;
}
.msg {
  max-width: 88%;
  padding: 10px 14px;
  border-radius: 16px;
  font-size: 14px;
  line-height: 1.5;
  word-wrap: break-word;
  white-space: pre-wrap;
  position: relative;
  animation: fadeIn 0.2s ease;
}
@keyframes fadeIn { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: none; } }
.msg.user {
  align-self: flex-end;
  background: var(--user-bg);
  color: white;
  border-bottom-right-radius: 4px;
}
.msg.ai {
  align-self: flex-start;
  background: var(--ai-bg);
  color: var(--text);
  border: 1px solid var(--border);
  border-bottom-left-radius: 4px;
}
.msg.tool {
  align-self: flex-start;
  background: var(--tool-bg);
  border: 1px solid var(--border);
  color: var(--text-muted);
  font-size: 12px;
  font-family: 'SF Mono', Monaco, monospace;
  border-radius: 10px;
  max-height: 200px;
  overflow-y: auto;
}
.msg.tool .tool-header {
  color: var(--success);
  font-weight: 600;
  margin-bottom: 4px;
}
.msg.error {
  align-self: center;
  background: rgba(239,68,68,0.1);
  border: 1px solid var(--error);
  color: var(--error);
  font-size: 13px;
  text-align: center;
}
.typing {
  align-self: flex-start;
  background: var(--ai-bg);
  border: 1px solid var(--border);
  padding: 12px 16px;
  border-radius: 16px;
  display: flex;
  gap: 4px;
}
.typing span {
  width: 8px; height: 8px;
  border-radius: 50%;
  background: var(--text-muted);
  animation: bounce 0.6s infinite alternate;
}
.typing span:nth-child(2) { animation-delay: 0.2s; }
.typing span:nth-child(3) { animation-delay: 0.4s; }
@keyframes bounce { to { transform: translateY(-6px); opacity: 0.5; } }
#input-area {
  background: var(--surface);
  padding: 10px 12px;
  border-top: 1px solid var(--border);
  display: flex;
  gap: 8px;
  align-items: flex-end;
  flex-shrink: 0;
  padding-bottom: max(10px, env(safe-area-inset-bottom));
}
#msg-input {
  flex: 1;
  background: var(--bg);
  border: 1px solid var(--border);
  color: var(--text);
  padding: 12px 16px;
  border-radius: 24px;
  font-size: 15px;
  resize: none;
  max-height: 120px;
  min-height: 44px;
  line-height: 1.4;
  outline: none;
  -webkit-appearance: none;
}
#msg-input:focus { border-color: var(--accent); }
#send-btn {
  width: 44px; height: 44px;
  border-radius: 50%;
  border: none;
  background: var(--accent);
  color: white;
  font-size: 18px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: background 0.15s;
}
#send-btn:disabled { background: var(--border); }
#send-btn:active { background: var(--accent2); }
.modal-overlay {
  display: none;
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.6);
  z-index: 100;
  justify-content: center;
  align-items: center;
  padding: 20px;
}
.modal-overlay.active { display: flex; }
.modal {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 16px;
  padding: 24px;
  width: 100%;
  max-width: 420px;
  max-height: 85vh;
  overflow-y: auto;
}
.modal h2 { font-size: 18px; margin-bottom: 16px; }
.modal label { font-size: 13px; color: var(--text-muted); display: block; margin-bottom: 6px; }
.modal input {
  width: 100%;
  background: var(--bg);
  border: 1px solid var(--border);
  color: var(--text);
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 14px;
  margin-bottom: 16px;
  outline: none;
}
.modal input:focus { border-color: var(--accent); }
.modal .hint { font-size: 12px; color: var(--text-muted); margin-top: -10px; margin-bottom: 16px; line-height: 1.4; }
.modal-actions { display: flex; gap: 8px; justify-content: flex-end; }
.modal button {
  padding: 8px 20px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--surface2);
  color: var(--text);
  font-size: 14px;
  cursor: pointer;
}
.modal button.primary { background: var(--accent); border-color: var(--accent); color: white; }
.modal button.danger { background: rgba(239,68,68,0.15); border-color: var(--error); color: var(--error); }
.status-badge {
  font-size: 11px;
  padding: 2px 8px;
  border-radius: 6px;
  font-weight: 500;
}
.status-badge.on { background: rgba(16,185,129,0.15); color: var(--success); }
.status-badge.off { background: rgba(239,68,68,0.15); color: var(--error); }

/* ── VoidHub look ── */
body { font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; -webkit-font-smoothing: antialiased;
  background: radial-gradient(70% 380px at 50% -80px, rgba(60,60,72,.55), rgba(0,0,0,0) 70%), #000; }
header { background: rgba(0,0,0,.72); -webkit-backdrop-filter: blur(14px); backdrop-filter: blur(14px); border-bottom: 1px solid var(--border); padding: 12px 16px; }
header h1 { font-size: 16px; font-weight: 700; letter-spacing: -.02em; gap: 10px; }
header .logo { width: 30px; height: 30px; border-radius: 9px; font-size: 0; color: transparent; background: #141416 url('https://pastevoid.lovable.app/img/Ru7BnfAV0N.png') center/cover no-repeat; box-shadow: 0 0 0 1px #2a2a2f; }
.vh-back { color: var(--text-muted); text-decoration: none; font-size: 13px; margin-right: 6px; }
.settings-btn { border-radius: 999px; padding: 8px 14px; background: var(--surface2); border: 1px solid #2a2a2f; color: var(--text); font-weight: 600; font-family: inherit; }
.status-badge { font-family: inherit; font-weight: 600; border-radius: 999px; }
.status-badge.on { background: rgba(61,220,132,.12); color: var(--success); }
.status-badge.off { background: rgba(255,90,95,.12); color: var(--error); }
#chat { width: 100%; max-width: 760px; margin: 0 auto; padding: 18px 16px; gap: 12px; }
.msg { font-size: 15px; border-radius: 18px; padding: 12px 16px; }
.msg.user { background: var(--user-bg); color: #0a0a0a; font-weight: 500; }
.msg.ai { background: var(--ai-bg); border-color: var(--border); }
.msg.tool { background: var(--tool-bg); border-color: var(--border); }
#input-area { width: 100%; max-width: 760px; margin: 0 auto; padding: 12px 16px calc(14px + env(safe-area-inset-bottom, 0px)); background: transparent; border-top: 0; gap: 10px; align-items: flex-end; }
#msg-input { font-family: inherit !important; font-size: 16px; background: var(--surface); border: 1px solid #2a2a2f; border-radius: 16px; color: var(--text); padding: 13px 16px; }
#msg-input:focus { border-color: #5a5a64; box-shadow: 0 0 0 4px rgba(255,255,255,.06); outline: none; }
#msg-input::placeholder { color: #6b6b73; }
#send-btn { width: 48px; height: 48px; flex: none; border-radius: 14px; background: linear-gradient(180deg,#fff,#e6e6ea); color: #0a0a0a; border: 1px solid #fff; display: flex; align-items: center; justify-content: center; font-size: 0; }
#send-btn svg { display: block; }
#send-btn:disabled { opacity: .45; }
.modal { background: var(--surface); border: 1px solid #2a2a2f; border-radius: 20px; font-family: inherit; }
.modal h2 { font-size: 22px; font-weight: 700; letter-spacing: -.03em; }
.modal input, .modal select { background: #000; border: 1px solid #2a2a2f; border-radius: 12px; color: var(--text); font-family: inherit; font-size: 15px; }
.modal button { font-family: inherit; font-weight: 600; border-radius: 12px; }
.modal button.primary { background: linear-gradient(180deg,#fff,#e6e6ea); color: #0a0a0a; border: 1px solid #fff; }
</style>
</head>
<body>
<header>
  <h1>
    <a class="vh-back" href="/" aria-label="Back to dashboard">&larr;</a><span class="logo">DS</span>
    VoidHub DeepSeek
    <span class="status-badge ${hasEnvKey ? 'on' : 'off'}" id="key-status">${hasEnvKey ? 'API Key Set' : 'No Key'}</span>
  </h1>
  <button class="settings-btn" onclick="toggleSettings()">Settings</button>
</header>

<div id="chat">
  <div class="msg ai">Welcome to VoidHub DeepSeek! I can help you inspect games, execute Luau code, search scripts, interact with GUI, and more. What would you like to do?</div>
</div>

<div id="input-area">
  <textarea id="msg-input" placeholder="Ask me anything about your Roblox game..." rows="1" oninput="autoResize(this)" onkeydown="onKeyDown(event)"></textarea>
  <button id="send-btn" aria-label="Send" onclick="sendMessage()"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 19V5"/><path d="m5 12 7-7 7 7"/></svg></button>
</div>

<div class="modal-overlay" id="settings-overlay" onclick="if(event.target===this)toggleSettings()">
  <div class="modal">
    <h2>Settings</h2>

    <label for="api-key-input">DeepSeek API Key ${hasEnvKey ? '(env key active)' : ''}</label>
    <input type="password" id="api-key-input" placeholder="sk-..." value="">
    <div class="hint">Get your key from <a href="https://platform.deepseek.com/api_keys" target="_blank" style="color:var(--accent2)">platform.deepseek.com</a>. ${hasEnvKey ? 'Leave blank to use the env key.' : 'Stored only in your browser localStorage.'}</div>

    <label for="auth-token-input">Bridge Auth Token</label>
    <input type="password" id="auth-token-input" placeholder="Bearer token (if auth is enabled)" value="">
    <div class="hint">Only needed if the server has MCP_AUTH_TOKEN set. Stored in localStorage.</div>

    <label for="model-input">Model</label>
    <input type="text" id="model-input" placeholder="${defaultModel}" value="${defaultModel}">
    <div class="hint">e.g. deepseek-chat, deepseek-reasoner</div>

    <div class="modal-actions">
      <button class="danger" onclick="forgetKeys()">Forget Keys</button>
      <button onclick="toggleSettings()">Cancel</button>
      <button class="primary" onclick="saveSettings()">Save</button>
    </div>
  </div>
</div>

<script>
var hasEnvKey = ${hasEnvKey};
var chatHistory = [];
var sending = false;

function getAuthHeaders() {
  var headers = { 'Content-Type': 'application/json' };
  var token = localStorage.getItem('mcp_auth_token') || '';
  if (token) headers['Authorization'] = 'Bearer ' + token;
  return headers;
}

function autoResize(el) {
  el.style.height = 'auto';
  el.style.height = Math.min(el.scrollHeight, 120) + 'px';
}

function onKeyDown(e) {
  if (e.key === 'Enter' && !e.shiftKey) {
    e.preventDefault();
    sendMessage();
  }
}

function toggleSettings() {
  var overlay = document.getElementById('settings-overlay');
  overlay.classList.toggle('active');
  if (overlay.classList.contains('active')) {
    document.getElementById('api-key-input').value = localStorage.getItem('deepseek_api_key') || '';
    document.getElementById('auth-token-input').value = localStorage.getItem('mcp_auth_token') || '';
  }
}

function saveSettings() {
  var key = document.getElementById('api-key-input').value.trim();
  if (key) localStorage.setItem('deepseek_api_key', key);
  else localStorage.removeItem('deepseek_api_key');

  var token = document.getElementById('auth-token-input').value.trim();
  if (token) localStorage.setItem('mcp_auth_token', token);
  else localStorage.removeItem('mcp_auth_token');

  toggleSettings();
}

function forgetKeys() {
  localStorage.removeItem('deepseek_api_key');
  localStorage.removeItem('mcp_auth_token');
  document.getElementById('api-key-input').value = '';
  document.getElementById('auth-token-input').value = '';
}

function getApiKey() {
  return localStorage.getItem('deepseek_api_key') || '';
}

function getModel() {
  return document.getElementById('model-input').value || '${defaultModel}';
}

function scrollToBottom() {
  var chat = document.getElementById('chat');
  chat.scrollTop = chat.scrollHeight;
}

function addMsg(role, text) {
  var div = document.createElement('div');
  div.className = 'msg ' + role;
  div.textContent = text;
  document.getElementById('chat').appendChild(div);
  scrollToBottom();
  return div;
}

function addTyping() {
  var div = document.createElement('div');
  div.className = 'typing';
  div.id = 'typing-indicator';
  div.innerHTML = '<span></span><span></span><span></span>';
  document.getElementById('chat').appendChild(div);
  scrollToBottom();
}

function removeTyping() {
  var t = document.getElementById('typing-indicator');
  if (t) t.remove();
}

async function sendMessage() {
  if (sending) return;
  var input = document.getElementById('msg-input');
  var text = input.value.trim();
  if (!text) return;

  sending = true;
  document.getElementById('send-btn').disabled = true;
  input.value = '';
  input.style.height = 'auto';

  addMsg('user', text);

  var userHistory = chatHistory.slice();
  chatHistory.push({ role: 'user', content: text });

  addTyping();

  try {
    var resp = await fetch('/api/deepseek', {
      method: 'POST',
      headers: getAuthHeaders(),
      body: JSON.stringify({
        message: text,
        history: userHistory,
        apiKey: getApiKey() || undefined,
        model: getModel()
      })
    });

    removeTyping();

    if (!resp.ok) {
      var errText = await resp.text();
      addMsg('error', 'Server error (' + resp.status + '): ' + errText.slice(0, 200));
      return;
    }

    var data = await resp.json();

    if (data.error && !data.response) {
      addMsg('error', data.error);
      return;
    }

    if (data.toolCalls && data.toolCalls.length > 0) {
      for (var i = 0; i < data.toolCalls.length; i++) {
        var tc = data.toolCalls[i];
        var toolDiv = document.createElement('div');
        toolDiv.className = 'msg tool';
        var header = document.createElement('div');
        header.className = 'tool-header';
        header.textContent = '\\u2699 ' + tc.name;
        var args = document.createElement('div');
        args.textContent = 'Args: ' + tc.args;
        var result = document.createElement('div');
        result.textContent = 'Result: ' + tc.result.slice(0, 500);
        result.style.marginTop = '4px';
        result.style.color = 'var(--text)';
        toolDiv.appendChild(header);
        toolDiv.appendChild(args);
        toolDiv.appendChild(result);
        document.getElementById('chat').appendChild(toolDiv);
      }
      scrollToBottom();
    }

    if (data.response) {
      addMsg('ai', data.response);
      chatHistory.push({ role: 'assistant', content: data.response });
    } else if (data.error) {
      addMsg('error', data.error);
    }
  } catch (err) {
    removeTyping();
    addMsg('error', 'Network error: ' + err.message);
  } finally {
    sending = false;
    document.getElementById('send-btn').disabled = false;
    document.getElementById('msg-input').focus();
  }
}

document.getElementById('msg-input').focus();
</script>
</body>
</html>`;
    res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    res.end(html);
}
