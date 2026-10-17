.pragma library

// Fuzzy + acronym matching for the Cipher menu.
// Returns a score (higher is better) or -1 when `query` does not match `text`.
//   exact prefix   > word-start acronym ("vsc" -> "Visual Studio Code") > substring > subsequence
function score(query, text) {
    if (!query) return 0;
    const q = query.toLowerCase();
    const t = (text || "").toLowerCase();
    if (!t) return -1;

    if (t === q) return 1000;
    if (t.startsWith(q)) return 900 - t.length;

    const words = t.split(/[\s\-_.\/›]+/).filter(w => w.length > 0);
    const acronym = words.map(w => w[0]).join("");
    if (acronym.startsWith(q)) return 800 - words.length;
    if (words.some(w => w.startsWith(q))) return 700 - t.length;

    const idx = t.indexOf(q);
    if (idx !== -1) return 600 - idx;

    // subsequence, rewarding consecutive runs
    let ti = 0, run = 0, total = 0;
    for (let qi = 0; qi < q.length; qi++) {
        const found = t.indexOf(q[qi], ti);
        if (found === -1) return -1;
        run = (found === ti) ? run + 1 : 0;
        total += 1 + run * 2;
        ti = found + 1;
    }
    return 100 + total - Math.floor(t.length / 4);
}

// Best score across several fields of an item.
function best(query, fields) {
    let s = -1;
    for (const f of fields) {
        if (!f) continue;
        const v = score(query, f);
        if (v > s) s = v;
    }
    return s;
}
