namespace DT.ISVTelemetrySample;

/// <summary>
/// Install codeunit for the Telemetry Demo extension.
/// This codeunit runs when the extension is installed and can trigger
/// extension lifecycle telemetry signals.
/// </summary>
codeunit 50101 "Telemetry Demo Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        // Initialize data when the extension is installed
        InitializeDefaultData();

        // Log a custom telemetry event for the installation
        LogInstallationTelemetry();
    end;

    trigger OnInstallAppPerDatabase()
    begin
        // Database-level initialization
        // This trigger runs once for the entire database
    end;

    local procedure InitializeDefaultData()
    var
        TelemetryDemo: Record "Telemetry Demo";
    begin
        if not TelemetryDemo.IsEmpty() then
            exit;

        // Create initial demo record
        TelemetryDemo.Init();
        TelemetryDemo."Entry No." := 0;
        TelemetryDemo.Description := InstallRecordDescLbl;
        TelemetryDemo."Demo Type" := TelemetryDemo."Demo Type"::" ";
        TelemetryDemo.Insert(true);
    end;

    local procedure LogInstallationTelemetry()
    var
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        TelemetryCustomDimensions.Add('EventType', 'Installation');
        TelemetryCustomDimensions.Add('ExtensionName', 'ISV Telemetry Sample');
        Session.LogMessage(
            'TELDEMO-INSTALL',
            'ISV Telemetry Sample extension installed',
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            TelemetryCustomDimensions);
    end;

    var
        InstallRecordDescLbl: Label 'Initial record created during extension installation';
}
