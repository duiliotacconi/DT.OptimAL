"use strict";

// Runs after all scripts and stylesheets are loaded. Builds the container and
// signals AL that the control is ready to receive SQL.
(function () {
    var controlAddIn = document.getElementById("controlAddIn");
    var pre = document.createElement("pre");
    pre.id = "dtc-sql-viewer";
    pre.className = "dtc-sql-viewer";
    (controlAddIn || document.body).appendChild(pre);

    if (typeof Microsoft !== "undefined" &&
        Microsoft.Dynamics &&
        Microsoft.Dynamics.NAV &&
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("ControlReady", []);
    }
})();
