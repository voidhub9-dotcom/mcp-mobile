// VoidHub decompiler regression tests.
// Builds synthetic Luau bytecode chunks and verifies every pipeline profile.
import test from "node:test";
import assert from "node:assert/strict";
import { runVoidhubPipeline } from "../dist/decompiler/voidhub/pipeline.js";
import { parseLuauBytecode } from "../dist/decompiler/voidhub/lbc.js";
import { decodeInstructions, OPCODE_NAMES } from "../dist/decompiler/voidhub/opcodes.js";

function varint(value) {
    const bytes = [];
    let v = value >>> 0;
    while (v >= 128) {
        bytes.push((v & 127) | 128);
        v >>>= 7;
    }
    bytes.push(v);
    return bytes;
}

function u8v(value) {
    return [value & 255];
}

function f64v(value) {
    const buffer = Buffer.alloc(8);
    buffer.writeDoubleLE(value, 0);
    return [...buffer];
}

/** Build a single instruction word: op | A<<8 | D<<16. */
function word(op, a, d) {
    return (((d & 0xffff) << 16) | (op & 255) | ((a & 255) << 8)) >>> 0;
}

/**
 * Minimal chunk builder. The code array holds 32-bit instruction WORDS
 * (not bytes); constants and strings are assembled into a version-4
 * varint-encoded module.
 */
function buildChunk({ strings = [], code = [], constants = [], numParams = 0, vararg = 1 }) {
    const chunk = [...[0x1b, 0x4c, 0x75, 0x61, 0x75], 4, 1];
    chunk.push(...varint(strings.length));
    for (const s of strings) {
        chunk.push(...varint(s.length));
        for (const ch of s)
            chunk.push(ch.charCodeAt(0));
    }
    chunk.push(
        ...varint(1),
        ...u8v(8), ...u8v(numParams), ...u8v(0), ...u8v(vararg), ...u8v(0),
        ...varint(0),                        // no type info
        ...varint(code.length),              // word count
    );
    const wordBuffer = Buffer.alloc(4);
    for (const w of code) {
        wordBuffer.writeUInt32LE(w >>> 0, 0);
        chunk.push(...wordBuffer);
    }
    chunk.push(...varint(constants.length));
    for (const constant of constants)
        chunk.push(...constant);
    chunk.push(...varint(0), ...varint(0), ...varint(0), ...u8v(0), ...u8v(0), ...varint(0));
    return Buffer.from(chunk);
}

const numericConstant = (value) => [...u8v(2), ...f64v(value)];
const stringConstant = (stringTableIndex) => [...u8v(3), ...varint(stringTableIndex + 1)];

test("opcode table is positional and stable", () => {
    assert.equal(OPCODE_NAMES[0], "NOP");
    assert.equal(OPCODE_NAMES[4], "LOADN");
    assert.equal(OPCODE_NAMES[22], "RETURN");
    assert.equal(OPCODE_NAMES[56], "FORNPREP");
    assert.equal(OPCODE_NAMES[57], "FORNLOOP");
    assert.equal(decodeInstructions([word(4, 3, 9)])[0].opName, "LOADN");
});

test("parses a well-formed chunk and reports exact consumption", () => {
    const bytecode = buildChunk({
        strings: ["print"],
        code: [word(4, 0, 7), word(22, 0, 0)],
        constants: [numericConstant(7)],
    });
    const chunk = parseLuauBytecode(bytecode);
    assert.equal(chunk.bytecodeVersion, 4);
    assert.equal(chunk.strings.length, 1);
    assert.equal(chunk.protos.length, 1);
    assert.equal(chunk.consumedBytes, bytecode.length);
    assert.equal(chunk.protos[0].code.length, 2);
    assert.deepEqual(chunk.protos[0].constants[0], { type: "number", value: 7 });
});

test("rejects truncated bytecode without crashing", () => {
    assert.throws(() => parseLuauBytecode(Buffer.from([0x1b, 0x4c, 0x75])), /too small|Could not parse/);
});

test("all profiles decompile a numeric for loop", () => {
    // sum = 0; for i = 1, 10 do sum = sum + 1 end; print(sum)
    const code = [
        word(4, 0, 0),        // 0: LOADN r0, 0
        word(56, 1, 2),       // 1: FORNPREP r1 -> 4
        word(39, 0, 0),      // 2: ADDK r0, r0, K0
        word(57, 1, -2),      // 3: FORNLOOP r1 -> 2
        word(7, 4, 0),       // 4: GETGLOBAL r4 (aux word follows)
        0,                    //    aux = K0
        word(6, 5, 0),       // 5: MOVE r5, r0
        word(21, 4, 1),      // 6: CALL r4, 1, 0
        word(22, 0, 0),       // 7: RETURN
    ];
    const bytecode = buildChunk({
        strings: ["print"],
        code,
        constants: [numericConstant(1)],
    });

    for (const profile of ["disasm", "balanced", "structured"]) {
        const result = runVoidhubPipeline(bytecode, profile);
        assert.equal(result.ok, true, `${profile} should succeed: ${result.error}`);
        assert.ok(result.source && result.source.length > 0, `${profile} should produce source`);
        assert.equal(result.protoCount, 1);
        assert.equal(result.instructionCount, 8);
    }

    const disasm = runVoidhubPipeline(bytecode, "disasm");
    assert.match(disasm.source, /for r1 = r2, r3, r4 do/);
    assert.match(disasm.source, /r0 = r0 \+ 1/);

    const structured = runVoidhubPipeline(bytecode, "structured");
    assert.match(structured.source, /for r1 = r2, r3, r4 do/);
    assert.match(structured.source, /r0 = r0 \+ 1/);
    // The loop body must not be duplicated after the loop.
    const bodyMatches = structured.source.match(/r0 = r0 \+ 1/g) ?? [];
    assert.equal(bodyMatches.length, 1, "loop body should appear exactly once");
    assert.ok(structured.structuredRatio > 0, "structured ratio should be positive");
});

test("string constants resolve through the string table", () => {
    const bytecode = buildChunk({
        strings: ["game", "Workspace"],
        code: [word(7, 0, 0), 0], // GETGLOBAL r0, aux -> K0
        constants: [stringConstant(1)],
    });
    const result = runVoidhubPipeline(bytecode, "disasm");
    assert.match(result.source, /Workspace/);
});

test("paste-void text export helper rejects empty content", async () => {
    const { exportTextToPasteVoid } = await import("../dist/shared/paste-void.js");
    const result = await exportTextToPasteVoid("", "test");
    assert.equal(result.ok, false);
});

test("structured profile reports a clean failure on garbage input", () => {
    const garbage = Buffer.from([0x1b, 0x4c, 0x75, 0x61, 0x75, 4, 1, 0xff, 0xff, 0xff, 0xff, 0xff]);
    const result = runVoidhubPipeline(garbage, "structured");
    assert.equal(result.ok, false);
    assert.ok(result.error);
});

test("structured profile recovers while loops and keeps trailing code outside the body", () => {
    // while r0 do r0 = false end; r1 = 1; return
    const code = [
        word(2, 0, 0),    // 0: LOADNIL r0
        word(26, 0, 2),   // 1: JUMPIFNOT r0 -> 4 (offset in D)
        word(3, 0, 0),    // 2: LOADB r0, false
        word(24, 0, -3),  // 3: JUMPBACK -> 1
        word(4, 1, 1),    // 4: LOADN r1, 1
        word(22, 0, 0),   // 5: RETURN
    ];
    const bytecode = buildChunk({ code });

    const disasm = runVoidhubPipeline(bytecode, "disasm");
    assert.match(disasm.source, /if not r0 then goto 4/);

    const structured = runVoidhubPipeline(bytecode, "structured");
    assert.equal(structured.ok, true);
    const src = structured.source;
    const whileIdx = src.indexOf("while r0 do");
    assert.ok(whileIdx !== -1, "while loop should be recovered");
    const endIdx = src.indexOf("end", whileIdx);
    const bodyIdx = src.indexOf("r0 = false");
    assert.ok(bodyIdx > whileIdx && bodyIdx < endIdx, "loop body must sit inside the while");
    const afterIdx = src.indexOf("r1 = 1");
    assert.ok(afterIdx > endIdx, "code after the loop must not be swallowed into the loop body");
    assert.equal(src.match(/r0 = false/g)?.length, 1, "loop body should appear exactly once");
});

test("comparison jumps use the D operand for the offset and AUX for the second register", () => {
    // if r0 == r1 then r2 = 5 end; return
    // compilers emit JUMPIFNOTEQ r0, r1 -> 5 to skip the then-branch
    const code = [
        word(2, 0, 0),    // 0: LOADNIL r0
        word(2, 1, 0),    // 1: LOADNIL r1
        word(30, 0, 2),   // 2: JUMPIFNOTEQ r0, r1 -> 5
        1,                //    aux: second register is r1
        word(4, 2, 5),    // 4: LOADN r2, 5
        word(22, 0, 0),   // 5: RETURN
    ];
    const bytecode = buildChunk({ code });

    const disasm = runVoidhubPipeline(bytecode, "disasm");
    assert.match(disasm.source, /if r0 ~= r1 then goto 5/);

    const structured = runVoidhubPipeline(bytecode, "structured");
    assert.equal(structured.ok, true);
    assert.match(structured.source, /if r0 ~= r1 then/);
    assert.match(structured.source, /r2 = 5/);
});

test("JUMPXEQK conditions decode the constant index and NOT flag from AUX", () => {
    // if r0 ~= 1 then r1 = 1 end; return
    const code = [
        word(79, 0, 2),       // 0: JUMPXEQKN r0, K0 (NOT) -> 3
        0x80000000,           //    aux: constant index 0 | NOT flag in the high bit
        word(4, 1, 1),        // 2: LOADN r1, 1
        word(22, 0, 0),       // 3: RETURN
    ];
    const bytecode = buildChunk({
        code,
        constants: [numericConstant(1)],
    });

    const disasm = runVoidhubPipeline(bytecode, "disasm");
    assert.match(disasm.source, /if r0 ~= 1 then goto 3/);

    const structured = runVoidhubPipeline(bytecode, "structured");
    assert.equal(structured.ok, true);
    assert.match(structured.source, /if not \(r0 == 1\) then/);
    assert.match(structured.source, /r1 = 1/);
});

test("generic for loops structure nested conditionals", () => {
    // for a, b, c in r0 do if r3 then r4 = 2 end end; return
    const code = [
        word(2, 0, 0),    // 0: LOADNIL r0
        word(76, 0, 3),   // 1: FORGPREP r0 -> 5
        word(4, 3, 1),    // 2: LOADN r3, 1
        word(26, 3, 1),   // 3: JUMPIFNOT r3 -> 5
        word(4, 4, 2),    // 4: LOADN r4, 2
        word(58, 0, -4),  // 5: FORGLOOP r0 -> 2
        1,                //    aux: 1 loop variable
        word(22, 0, 0),   // 7: RETURN
    ];
    const bytecode = buildChunk({ code });

    const structured = runVoidhubPipeline(bytecode, "structured");
    assert.equal(structured.ok, true);
    assert.match(structured.source, /for r3, r4, r5 in r0 do/);
    assert.match(structured.source, /if r3 then/);
    const forIdx = structured.source.indexOf("for r3");
    const ifIdx = structured.source.indexOf("if r3 then");
    const endIdx = structured.source.indexOf("end", ifIdx);
    const bodyIdx = structured.source.indexOf("r4 = 2");
    assert.ok(bodyIdx > forIdx && bodyIdx < endIdx, "nested if body must stay inside the for loop");
});

test("JUMPX uses the E operand and dead code after a forward jump is skipped", () => {
    const code = [
        word(4, 0, 1),   // 0: LOADN r0, 1
        67 | (2 << 8),   // 1: JUMPX -> 4 (offset lives in bits 8-31)
        word(4, 1, 2),   // 2: LOADN r1, 2 (dead)
        word(4, 2, 3),   // 3: LOADN r2, 3 (dead)
        word(22, 0, 0),  // 4: RETURN
    ];
    const bytecode = buildChunk({ code });

    const structured = runVoidhubPipeline(bytecode, "structured");
    assert.equal(structured.ok, true);
    assert.match(structured.source, /r0 = 1/);
    assert.doesNotMatch(structured.source, /r1 = 2/, "dead code must not be emitted");
    assert.match(structured.source, /return/);
});

test("LOADN reads its signed 16-bit value from the D operand", () => {
    const code = [
        word(4, 0, -1),   // 0: LOADN r0, -1
        word(4, 1, 300),  // 1: LOADN r1, 300
        word(22, 0, 0),   // 2: RETURN
    ];
    const bytecode = buildChunk({ code });

    const disasm = runVoidhubPipeline(bytecode, "disasm");
    assert.match(disasm.source, /r0 = -1/);
    assert.match(disasm.source, /r1 = 300/);
});
