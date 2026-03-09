namespace DT.ISVTelemetrySample;

using DT.ISVTelemetrySample;

permissionset 50100 ISVTelemetrySample
{
    Assignable = true;
    Permissions = tabledata "Telemetry Demo Setup"=RIMD,
        table "Telemetry Demo Setup"=X,
        codeunit "Telemetry Demo Logger"=X,
        page "Telemetry Demo Setup"=X,
        tabledata "Telemetry Demo"=RIMD,
        table "Telemetry Demo"=X,
        report "Telemetry Demo Commit Report"=X,
        report "Telemetry Demo Report"=X,
        codeunit "Telemetry Demo Install"=X,
        codeunit "Telemetry Demo Mgt."=X,
        page "Telemetry Demo"=X,
        page "Telemetry Demo List"=X;
}