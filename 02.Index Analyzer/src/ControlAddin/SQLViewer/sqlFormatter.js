"use strict";

// Self-contained SQL prettifier + syntax highlighter for Business Central control add-in.
// Exposes window.DTCSql.toHtml(sqlText) -> HTML string with indentation and colored spans.
var DTCSql = (function () {

    // Keywords recognized for coloring (uppercase).
    var KEYWORDS = {
        "SELECT": 1, "FROM": 1, "WHERE": 1, "AND": 1, "OR": 1, "NOT": 1, "IN": 1,
        "EXISTS": 1, "BETWEEN": 1, "LIKE": 1, "IS": 1, "NULL": 1, "AS": 1, "ON": 1,
        "JOIN": 1, "INNER": 1, "LEFT": 1, "RIGHT": 1, "FULL": 1, "OUTER": 1, "CROSS": 1,
        "APPLY": 1, "GROUP": 1, "BY": 1, "ORDER": 1, "HAVING": 1, "UNION": 1, "ALL": 1,
        "INSERT": 1, "INTO": 1, "VALUES": 1, "UPDATE": 1, "SET": 1, "DELETE": 1, "TOP": 1,
        "DISTINCT": 1, "WITH": 1, "CASE": 1, "WHEN": 1, "THEN": 1, "ELSE": 1, "END": 1,
        "ASC": 1, "DESC": 1, "OVER": 1, "PARTITION": 1, "OPTION": 1, "FETCH": 1, "NEXT": 1,
        "OFFSET": 1, "ROWS": 1, "ONLY": 1, "READUNCOMMITTED": 1, "READCOMMITTED": 1,
        "UPDLOCK": 1, "ROWLOCK": 1, "HOLDLOCK": 1, "NOLOCK": 1, "TABLOCK": 1, "XLOCK": 1,
        "PIVOT": 1, "UNPIVOT": 1, "EXCEPT": 1, "INTERSECT": 1, "USING": 1, "MERGE": 1,
        "DECLARE": 1, "EXEC": 1, "RETURN": 1, "BEGIN": 1, "TRANSACTION": 1, "COMMIT": 1
    };

    // Built-in functions colored differently from keywords.
    var FUNCTIONS = {
        "COUNT": 1, "SUM": 1, "MIN": 1, "MAX": 1, "AVG": 1, "ISNULL": 1, "COALESCE": 1,
        "CAST": 1, "CONVERT": 1, "GETDATE": 1, "ROW_NUMBER": 1, "RANK": 1, "DENSE_RANK": 1,
        "SUBSTRING": 1, "LEN": 1, "UPPER": 1, "LOWER": 1, "ABS": 1, "ROUND": 1, "DATEPART": 1
    };

    function escapeHtml(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Split raw SQL into typed tokens.
    function tokenize(sql) {
        var tokens = [];
        var i = 0;
        var n = sql.length;
        while (i < n) {
            var c = sql[i];

            // Whitespace -> collapse to single space, ignored for layout.
            if (/\s/.test(c)) {
                i++;
                while (i < n && /\s/.test(sql[i])) i++;
                tokens.push({ t: "ws", v: " " });
                continue;
            }

            // Line comment
            if (c === "-" && sql[i + 1] === "-") {
                var start = i;
                while (i < n && sql[i] !== "\n") i++;
                tokens.push({ t: "comment", v: sql.substring(start, i) });
                continue;
            }

            // Block comment
            if (c === "/" && sql[i + 1] === "*") {
                var s2 = i; i += 2;
                while (i < n && !(sql[i] === "*" && sql[i + 1] === "/")) i++;
                i += 2;
                tokens.push({ t: "comment", v: sql.substring(s2, Math.min(i, n)) });
                continue;
            }

            // String literal 'text' (handles doubled quotes)
            if (c === "'") {
                var sp = i; i++;
                while (i < n) {
                    if (sql[i] === "'" && sql[i + 1] === "'") { i += 2; continue; }
                    if (sql[i] === "'") { i++; break; }
                    i++;
                }
                tokens.push({ t: "str", v: sql.substring(sp, i) });
                continue;
            }

            // Quoted identifier "..."  (BC uses these for table/column names)
            if (c === "\"") {
                var qp = i; i++;
                while (i < n) {
                    if (sql[i] === "\"" && sql[i + 1] === "\"") { i += 2; continue; }
                    if (sql[i] === "\"") { i++; break; }
                    i++;
                }
                tokens.push({ t: "id", v: sql.substring(qp, i) });
                continue;
            }

            // Bracketed identifier [...]
            if (c === "[") {
                var bp = i; i++;
                while (i < n && sql[i] !== "]") i++;
                i++;
                tokens.push({ t: "id", v: sql.substring(bp, Math.min(i, n)) });
                continue;
            }

            // Parameters @p / @@SPID
            if (c === "@") {
                var pp = i; i++;
                if (sql[i] === "@") i++;
                while (i < n && /[A-Za-z0-9_]/.test(sql[i])) i++;
                tokens.push({ t: "param", v: sql.substring(pp, i) });
                continue;
            }

            // Number
            if (/[0-9]/.test(c) || (c === "." && /[0-9]/.test(sql[i + 1]))) {
                var np = i;
                while (i < n && /[0-9.eExXA-Fa-f]/.test(sql[i])) i++;
                tokens.push({ t: "num", v: sql.substring(np, i) });
                continue;
            }

            // Word / identifier / keyword
            if (/[A-Za-z_#]/.test(c)) {
                var wp = i;
                while (i < n && /[A-Za-z0-9_#$]/.test(sql[i])) i++;
                var w = sql.substring(wp, i);
                var up = w.toUpperCase();
                var type = KEYWORDS[up] ? "kw" : (FUNCTIONS[up] ? "fn" : "word");
                tokens.push({ t: type, v: w, up: up });
                continue;
            }

            // Punctuation / operators
            if (c === "(" || c === ")") {
                tokens.push({ t: "paren", v: c });
                i++;
                continue;
            }
            if (c === ",") {
                tokens.push({ t: "comma", v: c });
                i++;
                continue;
            }
            // Multi-char operators
            var two = sql.substr(i, 2);
            if (two === ">=" || two === "<=" || two === "<>" || two === "!=") {
                tokens.push({ t: "op", v: two });
                i += 2;
                continue;
            }
            tokens.push({ t: "op", v: c });
            i++;
        }
        return tokens;
    }

    // Keywords that start a new line at the current indent level.
    var LINE_BREAK_BEFORE = {
        "SELECT": 1, "FROM": 1, "WHERE": 1, "GROUP": 1, "ORDER": 1, "HAVING": 1,
        "UNION": 1, "EXCEPT": 1, "INTERSECT": 1, "VALUES": 1, "SET": 1, "OPTION": 1,
        "INSERT": 1, "UPDATE": 1, "DELETE": 1, "JOIN": 1, "APPLY": 1
    };
    // Keywords that indent one extra level (predicate continuation).
    var SOFT_BREAK = { "AND": 1, "OR": 1, "ON": 1 };
    // Join-prefix words that should stay on the same produced line as JOIN/APPLY.
    var JOIN_PREFIX = { "INNER": 1, "LEFT": 1, "RIGHT": 1, "FULL": 1, "OUTER": 1, "CROSS": 1 };

    function span(cls, text) {
        return '<span class="dtc-sql-' + cls + '">' + escapeHtml(text) + "</span>";
    }

    function render(tok) {
        switch (tok.t) {
            case "kw": return span("kw", tok.v);
            case "fn": return span("fn", tok.v);
            case "str": return span("str", tok.v);
            case "id": return span("id", tok.v);
            case "num": return span("num", tok.v);
            case "param": return span("param", tok.v);
            case "comment": return span("cmt", tok.v);
            case "op": return span("op", tok.v);
            case "comma": return span("op", tok.v);
            default: return escapeHtml(tok.v);
        }
    }

    function indent(level) {
        var s = "";
        for (var k = 0; k < level; k++) s += "    ";
        return s;
    }

    // Produce formatted, highlighted HTML.
    function toHtml(sql) {
        if (sql === null || sql === undefined) return "";
        sql = String(sql).trim();
        if (sql === "") return "";

        var tokens = tokenize(sql).filter(function (t) { return t.t !== "ws"; });
        var out = [];
        var level = 0;
        var lineStart = true;
        var parenStack = [];

        function newline(lvl) {
            out.push("\n" + indent(lvl));
            lineStart = true;
        }
        function pushSep() {
            if (!lineStart) out.push(" ");
        }

        for (var i = 0; i < tokens.length; i++) {
            var tk = tokens[i];
            var up = tk.up;

            if (tk.t === "kw" && LINE_BREAK_BEFORE[up]) {
                // Keep JOIN prefixes attached to the JOIN that follows.
                if (JOIN_PREFIX[up]) {
                    // look ahead: is there a JOIN / APPLY soon?
                    var j = i + 1;
                    var joins = false;
                    while (j < tokens.length && tokens[j].t === "kw" &&
                        (JOIN_PREFIX[tokens[j].up] || tokens[j].up === "JOIN" || tokens[j].up === "APPLY")) {
                        if (tokens[j].up === "JOIN" || tokens[j].up === "APPLY") { joins = true; break; }
                        j++;
                    }
                    if (joins) { newline(level); out.push(render(tk)); continue; }
                }
                newline(level);
                out.push(render(tk));
                continue;
            }

            if (tk.t === "kw" && SOFT_BREAK[up]) {
                newline(level + 1);
                out.push(render(tk));
                continue;
            }

            if (tk.t === "paren" && tk.v === "(") {
                // Subquery / apply block if the next meaningful token is SELECT.
                var next = tokens[i + 1];
                var isBlock = next && next.t === "kw" && next.up === "SELECT";
                pushSep();
                out.push(render({ t: "op", v: "(" }));
                parenStack.push(isBlock);
                if (isBlock) { level++; newline(level); }
                continue;
            }

            if (tk.t === "paren" && tk.v === ")") {
                var wasBlock = parenStack.pop();
                if (wasBlock) { level = Math.max(0, level - 1); newline(level); }
                out.push(render({ t: "op", v: ")" }));
                lineStart = false;
                continue;
            }

            if (tk.t === "comma") {
                out.push(render(tk));
                // Break after commas only inside block (SELECT list / VALUES).
                if (parenStack.length === 0 || parenStack[parenStack.length - 1]) {
                    newline(level);
                } 
                continue;
            }

            // Default token: separate with a space unless at line start.
            pushSep();
            out.push(render(tk));
            lineStart = false;
        }

        return out.join("").replace(/^\n+/, "");
    }

    return { toHtml: toHtml };
})();
