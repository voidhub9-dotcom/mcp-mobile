/**
 * VoidHub decompiler — stage 3: structure recovery.
 *
 * Reconstructs high-level control flow (while/for/repeat/if-else) from
 * the CFG by recognizing back edges as loops, numeric-for and generic-for
 * opcode patterns, and conditional branches as if statements. Blocks that
 * resist structuring fall back to explicit goto/label form so output is
 * always valid.
 */

import { decodeInstructions, IS_UNCONDITIONAL_JUMP, jumpTargetIndex, type DecodedInstruction } from "./opcodes.js";
import type { LuauConstant, LuauProto } from "./lbc.js";
import { buildControlFlowGraph, findLoopHeaders, type BasicBlock, type ControlFlowGraph } from "./cfg.js";

export type Statement =
    | { kind: "comment"; text: string }
    | { kind: "label"; pc: number }
    | { kind: "goto"; target: number }
    | { kind: "raw"; pc: number; text: string }
    | { kind: "if"; condition: string; body: Statement[]; elseBody?: Statement[] }
    | { kind: "while"; condition: string; body: Statement[] }
    | { kind: "repeat"; body: Statement[]; condition: string }
    | { kind: "numericFor"; register: number; from: string; to: string; step: string; body: Statement[] }
    | { kind: "genericFor"; registers: number[]; iterator: string; body: Statement[] };

export interface StructuredProto {
    protoIndex: number;
    statements: Statement[];
    /** Fraction of instructions that ended up inside structured constructs. */
    structuredRatio: number;
}

function constantText(constant: LuauConstant | undefined): string {
    if (constant === undefined)
        return "?";
    switch (constant.type) {
        case "string":
            return JSON.stringify(constant.value);
        case "number":
            return String(constant.value);
        case "boolean":
            return constant.value ? "true" : "false";
        case "nil":
            return "nil";
        default:
            return "k";
    }
}

function reg(index: number): string {
    return `r${index}`;
}

function instructionText(proto: LuauProto, instruction: DecodedInstruction): string {
    const k = proto.constants;
    const a = instruction.a;
    const b = instruction.b;
    const c = instruction.c;
    const d = instruction.d;
    const aux = instruction.aux;
    switch (instruction.opName) {
        case "LOADNIL":
            return `${reg(a)} = nil`;
        case "LOADB":
            return `${reg(a)} = ${b !== 0 ? "true" : "false"}`;
        case "LOADN":
            return `${reg(a)} = ${d}`;
        case "LOADK":
            return `${reg(a)} = ${constantText(k[d & 0xffff])}`;
        case "LOADKX":
            return `${reg(a)} = ${constantText(k[aux ?? 0])}`;
        case "MOVE":
            return `${reg(a)} = ${reg(b)}`;
        case "GETGLOBAL":
            return `${reg(a)} = _G[${constantText(k[aux ?? 0])}]`;
        case "SETGLOBAL":
            return `_G[${constantText(k[aux ?? 0])}] = ${reg(a)}`;
        case "GETUPVAL":
            return `${reg(a)} = upvalue_${b}`;
        case "SETUPVAL":
            return `upvalue_${b} = ${reg(a)}`;
        case "GETIMPORT":
            return `${reg(a)} = import(${constantText(k[d & 0xffff])})`;
        case "GETTABLE":
            return `${reg(a)} = ${reg(b)}[${reg(c)}]`;
        case "SETTABLE":
            return `${reg(b)}[${reg(c)}] = ${reg(a)}`;
        case "GETTABLEKS":
            return `${reg(a)} = ${reg(b)}[${constantText(k[aux ?? 0])}]`;
        case "SETTABLEKS":
            return `${reg(b)}[${constantText(k[aux ?? 0])}] = ${reg(a)}`;
        case "GETTABLEN":
            return `${reg(a)} = ${reg(b)}[${c + 1}]`;
        case "SETTABLEN":
            return `${reg(b)}[${c + 1}] = ${reg(a)}`;
        case "NAMECALL":
            return `${reg(a + 1)} = ${reg(b)}:${constantText(k[aux ?? 0])}(...)`;
        case "CALL": {
            const argCount = b - 1;
            const resultCount = c - 1;
            const args = argCount < 0 ? "..." : argCount === 0 ? "" : `${reg(a + 1)}..r${a + argCount}`;
            const results = resultCount < 0 ? "..." : resultCount === 0 ? "" : `${reg(a)}..r${a + resultCount - 1}`;
            return resultCount === 0
                ? `${reg(a)}(${args})`
                : `${results} = ${reg(a)}(${args})`;
        }
        case "RETURN": {
            const count = b - 1;
            if (count < 0)
                return "return ...";
            if (count === 0)
                return "return";
            return `return ${reg(a)}${count > 1 ? `, …(${count})` : ""}`;
        }
        case "ADD":
            return `${reg(a)} = ${reg(b)} + ${reg(c)}`;
        case "SUB":
            return `${reg(a)} = ${reg(b)} - ${reg(c)}`;
        case "MUL":
            return `${reg(a)} = ${reg(b)} * ${reg(c)}`;
        case "DIV":
            return `${reg(a)} = ${reg(b)} / ${reg(c)}`;
        case "MOD":
            return `${reg(a)} = ${reg(b)} % ${reg(c)}`;
        case "POW":
            return `${reg(a)} = ${reg(b)} ^ ${reg(c)}`;
        case "ADDK":
            return `${reg(a)} = ${reg(b)} + ${constantText(k[c])}`;
        case "SUBK":
            return `${reg(a)} = ${reg(b)} - ${constantText(k[c])}`;
        case "MULK":
            return `${reg(a)} = ${reg(b)} * ${constantText(k[c])}`;
        case "DIVK":
            return `${reg(a)} = ${reg(b)} / ${constantText(k[c])}`;
        case "MODK":
            return `${reg(a)} = ${reg(b)} % ${constantText(k[c])}`;
        case "POWK":
            return `${reg(a)} = ${reg(b)} ^ ${constantText(k[c])}`;
        case "AND":
            return `${reg(a)} = ${reg(a)} and ${reg(b)}`;
        case "OR":
            return `${reg(a)} = ${reg(a)} or ${reg(b)}`;
        case "ANDK":
            return `${reg(a)} = ${reg(a)} and ${constantText(k[c])}`;
        case "ORK":
            return `${reg(a)} = ${reg(a)} or ${constantText(k[c])}`;
        case "NOT":
            return `${reg(a)} = not ${reg(b)}`;
        case "MINUS":
            return `${reg(a)} = -${reg(b)}`;
        case "LENGTH":
            return `${reg(a)} = #${reg(b)}`;
        case "NEWTABLE":
            return `${reg(a)} = {}`;
        case "DUPTABLE":
            return `${reg(a)} = dup(${constantText(k[d & 0xffff])})`;
        case "SETLIST":
            return `${reg(b)}:set_list(${reg(b + 1)}, ${aux ?? 0})`;
        case "CONCAT":
            return `${reg(a)} = concat(${reg(b)} .. ${reg(c)})`;
        case "GETVARARGS":
            return `${reg(a)} = varargs(${b})`;
        case "DUPCLOSURE":
            return `${reg(a)} = closure(${constantText(k[d & 0xffff])})`;
        case "NEWCLOSURE":
            return `${reg(a)} = closure(proto ${d & 0xffff})`;
        case "CAPTURE":
            return `capture(${b === 0 ? "val" : b === 1 ? "ref" : "up"} ${reg(c)})`;
        case "IDIV":
            return `${reg(a)} = ${reg(b)} // ${reg(c)}`;
        case "IDIVK":
            return `${reg(a)} = ${reg(b)} // ${constantText(k[c])}`;
        case "SUBRK":
            return `${reg(a)} = ${constantText(k[b])} - ${reg(c)}`;
        case "DIVRK":
            return `${reg(a)} = ${constantText(k[b])} / ${reg(c)}`;
        case "CLOSEUPVALS":
            return `close_upvalues(${reg(a)})`;
        case "COVERAGE":
        case "NOP":
        case "BREAK":
            return "";
        default:
            return `${instruction.opName.toLowerCase()} a=${a} b=${b} c=${c}`;
    }
}

/** JUMPXEQK* opcodes carry a NOT flag in the high bit of the AUX word. */
function auxNot(aux: number | undefined): boolean {
    return ((aux ?? 0) >>> 31) !== 0;
}

function conditionText(proto: LuauProto, instruction: DecodedInstruction, negate: boolean): string {
    const k = proto.constants;
    const a = instruction.a;
    const aux = instruction.aux;
    let condition: string;
    switch (instruction.opName) {
        case "JUMPIF":
            condition = reg(a);
            break;
        case "JUMPIFNOT":
            condition = reg(a);
            negate = !negate;
            break;
        // Comparison jumps keep the second register in AUX; D is the offset.
        case "JUMPIFEQ":
            condition = `${reg(a)} == ${reg(aux ?? 0)}`;
            break;
        case "JUMPIFLE":
            condition = `${reg(a)} <= ${reg(aux ?? 0)}`;
            break;
        case "JUMPIFLT":
            condition = `${reg(a)} < ${reg(aux ?? 0)}`;
            break;
        case "JUMPIFNOTEQ":
            condition = `${reg(a)} ~= ${reg(aux ?? 0)}`;
            break;
        case "JUMPIFNOTLE":
            condition = `${reg(a)} > ${reg(aux ?? 0)}`;
            break;
        case "JUMPIFNOTLT":
            condition = `${reg(a)} >= ${reg(aux ?? 0)}`;
            break;
        case "JUMPXEQKNIL":
            condition = `${reg(a)} == nil`;
            if (auxNot(aux))
                negate = !negate;
            break;
        case "JUMPXEQKB":
            condition = `${reg(a)} == ${(aux ?? 0) & 1 ? "true" : "false"}`;
            if (auxNot(aux))
                negate = !negate;
            break;
        case "JUMPXEQKN":
        case "JUMPXEQKS":
            condition = `${reg(a)} == ${constantText(k[(aux ?? 0) & 0xffffff])}`;
            if (auxNot(aux))
                negate = !negate;
            break;
        default:
            condition = `${reg(a)} ?`;
    }
    if (negate)
        return `not (${condition})`;
    return condition;
}

/** Strip a redundant double negation, e.g. `not (not (x))` -> `x`. */
function invertCondition(condition: string): string {
    if (condition.startsWith("not (") && condition.endsWith(")"))
        return condition.slice(5, -1);
    return `not (${condition})`;
}

function rawStatements(proto: LuauProto, block: BasicBlock, skipJump: boolean): Statement[] {
    const out: Statement[] = [];
    for (const instruction of block.instructions) {
        if (skipJump && IS_UNCONDITIONAL_JUMP.has(instruction.opName) && instruction === block.instructions.at(-1))
            continue;
        // Loop step instructions are mechanics, not body code.
        if (instruction.opName === "FORNLOOP" || instruction.opName === "FORGLOOP")
            continue;
        const text = instructionText(proto, instruction);
        if (text !== "")
            out.push({ kind: "raw", pc: instruction.index, text });
    }
    return out;
}

function structureBlock(
    proto: LuauProto,
    cfg: ControlFlowGraph,
    block: BasicBlock,
    loopHeaders: Set<number>,
    visited: Set<number>,
    enclosingWhile?: number,
): Statement[] {
    const out: Statement[] = [];
    if (visited.has(block.id))
        return out;
    visited.add(block.id);

    const last = block.instructions.at(-1);
    const lastIndex = last ? last.index + (last.aux !== undefined ? 2 : 1) : block.end;
    const fallthroughId = cfg.blockAt.get(lastIndex);
    const emitThenAdvance = (statements: Statement[]): void => {
        out.push(...statements);
    };

    // Numeric for loop: FORNPREP jumps to a FORNLOOP.
    if (last && last.opName === "FORNPREP") {
        const bodyStart = last.index + 1;
        const loopEnd = last.index + 1 + last.d;
        const body = statementsBetween(proto, cfg, bodyStart, loopEnd, loopHeaders, visited);
        emitThenAdvance([
            {
                kind: "numericFor",
                register: last.a,
                from: reg(last.a + 1),
                to: reg(last.a + 2),
                step: reg(last.a + 3),
                body,
            },
        ]);
        // Consume every block inside the loop range so the outer walker
        // does not re-emit them.
        for (let pc = bodyStart; pc < loopEnd; pc++) {
            const id = cfg.blockAt.get(pc);
            if (id !== undefined)
                visited.add(id);
        }
        return out;
    }

    // Generic for loop: FORGPREP* + FORGLOOP back edge.
    if (last && (last.opName === "FORGPREP" || last.opName === "FORGPREP_NEXT" || last.opName === "FORGPREP_INEXT")) {
        const base = last.a;
        const bodyStart = last.index + 1;
        const loopEnd = last.index + 1 + last.d;
        const body = statementsBetween(proto, cfg, bodyStart, loopEnd, loopHeaders, visited);
        for (let pc = bodyStart; pc < loopEnd; pc++) {
            const id = cfg.blockAt.get(pc);
            if (id !== undefined)
                visited.add(id);
        }
        emitThenAdvance([
            {
                kind: "genericFor",
                registers: [base + 3, base + 4, base + 5],
                iterator: reg(base),
                body,
            },
        ]);
        return out;
    }

    // Loop header with a back edge. When the header's conditional jump is a
    // clean forward exit past the loop body, recover a while loop; otherwise
    // emit a label so body gotos stay valid and keep structuring below.
    let emittedLabel = false;
    if (loopHeaders.has(block.id) && block.predecessors.some((p) => p >= block.id)) {
        const loopLast = block.instructions.at(-1);
        const loopEnd = loopExtent(cfg, block);
        if (loopLast && loopLast.opName.startsWith("JUMPIF")) {
            const exitTarget = jumpTargetIndex(loopLast);
            if (exitTarget !== undefined && exitTarget >= loopEnd) {
                const condition = conditionText(proto, loopLast, true);
                const bodyBlocks = statementsBetween(proto, cfg, block.end, loopEnd, loopHeaders, visited, block.start);
                emitThenAdvance([
                    { kind: "while", condition, body: bodyBlocks },
                ]);
                return out;
            }
        }
        emitThenAdvance([{ kind: "label", pc: block.start }]);
        emittedLabel = true;
    }

    // Conditional branch -> if statement with structured bodies.
    if (last && (last.opName.startsWith("JUMPIF") || last.opName.startsWith("JUMPXEQK"))) {
        const condition = conditionText(proto, last, false);
        const targetId = cfg.blockAt.get(jumpTargetIndex(last) ?? -1);
        if (targetId !== undefined) {
            const thenBlock = cfg.blocks[targetId];
            const thenBody = structureBlock(proto, cfg, thenBlock, loopHeaders, visited, enclosingWhile);
            const elseBody = fallthroughId !== undefined
                ? structureBlock(proto, cfg, cfg.blocks[fallthroughId]!, loopHeaders, visited, enclosingWhile)
                : undefined;
            if (thenBody.length === 0 && elseBody && elseBody.length > 0) {
                // The jump target was consumed elsewhere (e.g. a loop latch);
                // invert the condition and keep the fallthrough as the body.
                emitThenAdvance([
                    { kind: "if", condition: invertCondition(condition), body: elseBody },
                ]);
            }
            else {
                emitThenAdvance([
                    {
                        kind: "if",
                        condition,
                        body: thenBody,
                        ...(elseBody && elseBody.length > 0 ? { elseBody } : {}),
                    },
                ]);
            }
            return out;
        }
    }

    // Unconditional jump: keep the goto when it points backwards (loop back
    // edge or retry); forward jumps are consumed by the outer walker.
    if (last && IS_UNCONDITIONAL_JUMP.has(last.opName)) {
        emitThenAdvance(rawStatements(proto, block, true));
        const target = jumpTargetIndex(last) ?? block.start;
        if ((target < block.start || emittedLabel) && target !== enclosingWhile)
            emitThenAdvance([{ kind: "goto", target }]);
        else if (target > block.start) {
            // Forward jump: blocks strictly between the jump and its target
            // with no predecessors are unreachable — skip them.
            for (let pc = lastIndex; pc < target; pc++) {
                const deadId = cfg.blockAt.get(pc);
                if (deadId === undefined)
                    continue;
                if (cfg.blocks[deadId]!.predecessors.length === 0)
                    visited.add(deadId);
            }
        }
        return out;
    }

    // Plain fallthrough block.
    emitThenAdvance(rawStatements(proto, block, false));
    return out;
}

function statementsBetween(
    proto: LuauProto,
    cfg: ControlFlowGraph,
    startPc: number,
    endPc: number,
    loopHeaders: Set<number>,
    visited: Set<number>,
    enclosingWhile?: number,
): Statement[] {
    const out: Statement[] = [];
    let pc = startPc;
    while (pc < endPc) {
        const blockId = cfg.blockAt.get(pc);
        if (blockId === undefined)
            break;
        const block = cfg.blocks[blockId]!;
        const wasVisited = visited.has(blockId);
        if (!wasVisited)
            out.push(...structureBlock(proto, cfg, block, loopHeaders, visited, enclosingWhile));
        const last = block.instructions.at(-1);
        pc = last ? last.index + (last.aux !== undefined ? 2 : 1) : block.end;
        // A block we just structured ends the linear walk; blocks that were
        // already consumed by nested structuring are simply skipped.
        if (!wasVisited && last && IS_UNCONDITIONAL_JUMP.has(last.opName))
            break;
    }
    return out;
}

/** Exclusive end (instruction index) of a loop: the furthest back-edge source. */
function loopExtent(cfg: ControlFlowGraph, header: BasicBlock): number {
    let end = header.end;
    for (const predecessor of header.predecessors) {
        if (predecessor >= header.id)
            end = Math.max(end, cfg.blocks[predecessor]!.end);
    }
    return end;
}

/** Structure a single proto. Always produces output; ratio flags quality. */
export function structureProto(proto: LuauProto): StructuredProto {
    const cfg = buildControlFlowGraph(proto);
    const loopHeaders = findLoopHeaders(cfg);
    const visited = new Set<number>();
    const statements: Statement[] = [];

    let pc = 0;
    while (pc < proto.code.length) {
        const blockId = cfg.blockAt.get(pc);
        if (blockId === undefined)
            break;
        if (visited.has(blockId)) {
            const block = cfg.blocks[blockId]!;
            const last = block.instructions.at(-1);
            pc = last ? last.index + (last.aux !== undefined ? 2 : 1) : block.end;
            if (last && IS_UNCONDITIONAL_JUMP.has(last.opName)) {
                const target = jumpTargetIndex(last);
                if (target !== undefined)
                    pc = Math.max(pc, target);
            }
            continue;
        }
        statements.push(...structureBlock(proto, cfg, cfg.blocks[blockId]!, loopHeaders, visited));
        const block = cfg.blocks[blockId]!;
        const last = block.instructions.at(-1);
        const nextPc = last ? last.index + (last.aux !== undefined ? 2 : 1) : block.end;
        if (nextPc <= pc) {
            // Safety: always advance.
            pc = nextPc === pc ? Math.min(proto.code.length, pc + 1) : nextPc;
        }
        else {
            pc = nextPc;
        }
    }

    const structuredCount = countStructured(statements);
    const total = decodeInstructions(proto.code).length;
    return {
        protoIndex: proto.index,
        statements,
        structuredRatio: total === 0 ? 1 : Math.min(1, structuredCount / total),
    };
}

function countStructured(statements: Statement[]): number {
    let count = 0;
    for (const statement of statements) {
        if (statement.kind === "if" || statement.kind === "while" || statement.kind === "repeat"
            || statement.kind === "numericFor" || statement.kind === "genericFor") {
            count += statement.kind === "if"
                ? countStructured(statement.body) + countStructured(statement.elseBody ?? [])
                : countStructured(statement.body);
            count += 4; // the construct itself
        }
        else if (statement.kind === "raw") {
            count += 1;
        }
    }
    return count;
}
