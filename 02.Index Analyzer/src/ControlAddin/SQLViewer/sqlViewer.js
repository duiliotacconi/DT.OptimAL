"use strict";

// Implements the control add-in methods invoked from AL (SetSQL, ClearSQL).
// The container element is created by startup.js.

function DTC_getContainer() {
    var el = document.getElementById("dtc-sql-viewer");
    if (!el) {
        var controlAddIn = document.getElementById("controlAddIn");
        el = document.createElement("pre");
        el.id = "dtc-sql-viewer";
        el.className = "dtc-sql-viewer";
        (controlAddIn || document.body).appendChild(el);
    }
    return el;
}

function SetSQL(sql) {
    var el = DTC_getContainer();
    try {
        el.innerHTML = DTCSql.toHtml(sql);
    } catch (e) {
        // Fallback: show raw text if formatting fails.
        el.textContent = sql || "";
    }
}

function ClearSQL() {
    var el = DTC_getContainer();
    el.innerHTML = "";
}
