#!/usr/bin/env node
/**
 * Quita emoticones/emojis "decorativos" de los archivos .md en docs/.
 *
 * MANTIENE (whitelist) los emojis con valor semantico en tablas/listas:
 *   🟢 (U+1F7E2)  verde - estado OK
 *   🟡 (U+1F7E1)  amarillo - advertencia
 *   🔴 (U+1F534)  rojo - critico
 *   ⚪ (U+26AA)   blanco - cargando/sin datos
 *   ❌ (U+274C)   cruz - "no se borra" / lista negativa
 *
 * El resto (🔑 🔌 📋 ✅ ⚠ etc.) se elimina.
 */
const fs = require("fs");
const path = require("path");

const DOCS_DIR = path.resolve(__dirname, "..", "docs");

// Emojis que se DEBEN MANTENER (codepoints).
const KEEP = new Set([
    0x1F7E2, // 🟢
    0x1F7E1, // 🟡
    0x1F534, // 🔴
    0x26AA,  // ⚪
    0x274C,  // ❌
]);

// Rangos de emojis a eliminar (excepto los del whitelist KEEP).
// Cubre BMP + planos suplementarios. Procesamos por codepoints, no por code-units.
const RANGES = [
    [0x1F300, 0x1F5FF], // simbolos & pictogramas
    [0x1F600, 0x1F64F], // emoticonos
    [0x1F680, 0x1F6FF], // transporte & mapas
    [0x1F700, 0x1F77F], // alquimicos
    [0x1F780, 0x1F7FF], // geometricos extendidos (incluye 🟢 🟡 🔴 -> protegidos por KEEP)
    [0x1F800, 0x1F8FF], // flechas C suplementarias
    [0x1F900, 0x1F9FF], // simbolos suplementarios
    [0x1FA00, 0x1FA6F], // ajedrez
    [0x1FA70, 0x1FAFF], // pictogramas extendidos
    [0x2600,  0x26FF],  // simbolos varios (☀ ⚠ ⚡ etc.) -> ⚪ protegido por KEEP
    [0x2700,  0x27BF],  // dingbats (✓ ✂ ❌ etc.) -> ❌ protegido por KEEP
    [0x2B00,  0x2BFF],  // flechas varias
    [0x2300,  0x23FF],  // tecnicos varios (⌚ ⏰ ⏳)
    [0x1F000, 0x1F02F], // mahjong
    [0x1F0A0, 0x1F0FF], // cartas
    [0x1F100, 0x1F1FF], // alfanumerico cerrado / banderas regionales
    [0x1F200, 0x1F2FF], // CJK cerrado
];

// Caracteres "invisibles" asociados a emojis que tambien borramos:
//  - U+FE0F variation selector-16 (forma emoji)
//  - U+FE0E variation selector-15 (forma texto)
//  - U+200D zero-width joiner
//  - U+20E3 combining enclosing keycap
const INVISIBLE = new Set([0xFE0F, 0xFE0E, 0x200D, 0x20E3]);

function isEmojiCodepoint(cp) {
    if (KEEP.has(cp)) return false;
    for (const [lo, hi] of RANGES) {
        if (cp >= lo && cp <= hi) return true;
    }
    return false;
}

function stripEmojis(text) {
    let out = "";
    let i = 0;
    const len = text.length;
    while (i < len) {
        const cp = text.codePointAt(i);
        const charLen = cp > 0xFFFF ? 2 : 1;

        if (isEmojiCodepoint(cp)) {
            // descartar el emoji; tambien comerse selectores/ZWJ/keycap inmediatos
            i += charLen;
            while (i < len) {
                const next = text.codePointAt(i);
                if (INVISIBLE.has(next)) {
                    i += next > 0xFFFF ? 2 : 1;
                } else if (isEmojiCodepoint(next)) {
                    i += next > 0xFFFF ? 2 : 1;
                } else {
                    break;
                }
            }
            continue;
        }

        // Si encontramos un selector/keycap "huerfano" (sin emoji previo conservado), lo eliminamos
        if (INVISIBLE.has(cp)) {
            // Verificar el ultimo caracter copiado: si es uno de los emojis KEEP,
            // conservamos el selector (no rompemos su forma). Caso contrario, lo borramos.
            const lastCp = out.length > 0 ? out.codePointAt(out.length - (out.charCodeAt(out.length - 1) >= 0xD800 ? 2 : 1)) : -1;
            if (KEEP.has(lastCp)) {
                out += String.fromCodePoint(cp);
            }
            i += charLen;
            continue;
        }

        out += String.fromCodePoint(cp);
        i += charLen;
    }

    // Limpieza minima y segura:
    //  - quitar espacios al final de cada linea
    //  - normalizar EOL a \n
    //  - colapsar doble espacio que quedo tras quitar un emoji de bullet
    //    ("- 🔑 Texto" -> "-  Texto" -> "- Texto") y en items de tabla
    //    al inicio de celda ("| 🔑 X |" -> "|  X |" -> "| X |").
    //  - NO se toca el contenido dentro de fences de codigo ``` ``` para no
    //    romper la alineacion de scripts.
    const lines = out.split(/\r?\n/);
    let inCode = false;
    for (let idx = 0; idx < lines.length; idx++) {
        let l = lines[idx].replace(/[ \t]+$/g, "");
        // detectar fence
        if (/^\s*```/.test(l)) {
            inCode = !inCode;
            lines[idx] = l;
            continue;
        }
        if (inCode) {
            lines[idx] = l;
            continue;
        }
        // bullet markdown: "- ", "* ", "+ " seguido de doble espacio
        l = l.replace(/^(\s*[-*+])\s{2,}(?=\S)/, "$1 ");
        // numeracion: "1. " o "1) " seguido de doble espacio
        l = l.replace(/^(\s*\d+[.)])\s{2,}(?=\S)/, "$1 ");
        // blockquote bullet: "> - 🔑 Texto" -> "> - Texto"
        l = l.replace(/^(\s*>\s*[-*+])\s{2,}(?=\S)/, "$1 ");
        // celdas de tabla: "| " seguido de doble espacio dentro de la celda
        l = l.replace(/\|\s{2,}(?=\S)/g, "| ");
        lines[idx] = l;
    }
    out = lines.join("\n");

    return out;
}

function processFile(filePath) {
    const original = fs.readFileSync(filePath, "utf8");
    const cleaned = stripEmojis(original);
    if (cleaned !== original) {
        fs.writeFileSync(filePath, cleaned, { encoding: "utf8" });
        const diff = original.length - cleaned.length;
        console.log(`[OK] ${path.basename(filePath)}: -${diff} caracteres`);
        return diff;
    }
    console.log(`[--] ${path.basename(filePath)}: sin cambios`);
    return 0;
}

function main() {
    if (!fs.existsSync(DOCS_DIR)) {
        console.error(`ERROR: no existe ${DOCS_DIR}`);
        process.exit(1);
    }
    let total = 0;
    const files = fs.readdirSync(DOCS_DIR).sort();
    for (const name of files) {
        if (name.toLowerCase().endsWith(".md")) {
            total += processFile(path.join(DOCS_DIR, name));
        }
    }
    console.log(`\nTotal: ${total} caracteres eliminados`);
}

main();
