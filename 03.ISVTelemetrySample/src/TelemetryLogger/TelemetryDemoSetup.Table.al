namespace DT.ISVTelemetrySample;

/// <summary>
/// Table for storing Telemetry Demo Setup configuration.
/// This is a singleton table that stores the telemetry settings.
/// </summary>
table 50101 "Telemetry Demo Setup"
{
    Caption = 'Telemetry Demo Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Enable Telemetry To"; Enum "Telemetry Enable To")
        {
            Caption = 'Enable OnSendDailyTelemetry To';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                // Log telemetry setting change
                if "Enable Telemetry To" <> xRec."Enable Telemetry To" then begin
                    Session.LogMessage(
                        'DT-0001',
                        StrSubstNo(TelemetrySettingChangedLbl, xRec."Enable Telemetry To", "Enable Telemetry To"),
                        Verbosity::Normal,
                        DataClassification::SystemMetadata,
                        TelemetryScope::ExtensionPublisher,
                        'OldValue', Format(xRec."Enable Telemetry To"),
                        'NewValue', Format("Enable Telemetry To")
                    );

                    // Warn user about potential higher costs when enabling telemetry to All
                    if "Enable Telemetry To" = "Enable Telemetry To"::All then
                        Message(TelemetryAllWarningMsg);
                end;
            end;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        TelemetrySettingChangedLbl: Label 'Telemetry setting changed from %1 to %2', Locked = true;
        TelemetryAllWarningMsg: Label 'Warning: Setting telemetry to "All" will send telemetry data to both the customer and ISV ingestion points. This may result in higher data ingestion volumes and potentially increased Azure Application Insights costs. Please ensure you understand the implications before proceeding.';

    /// <summary>
    /// Gets the current setup record, creating it if it doesn't exist.
    /// </summary>
    procedure GetSetup()
    begin
        Reset();
        if not Get() then begin
            Init();
            "Primary Key" := '';
            "Enable Telemetry To" := "Enable Telemetry To"::"App Publisher";
            Insert();
        end;
    end;

    /// <summary>
    /// Checks if telemetry should be sent to the app publisher.
    /// </summary>
    /// <returns>True if telemetry should be sent to app publisher.</returns>
    procedure IsTelemetryEnabledForPublisher(): Boolean
    begin
        GetSetup();
        exit("Enable Telemetry To" in ["Enable Telemetry To"::"App Publisher", "Enable Telemetry To"::All]);
    end;

    /// <summary>
    /// Checks if telemetry should be sent to all (including environment).
    /// </summary>
    /// <returns>True if telemetry should be sent to all.</returns>
    procedure IsTelemetryEnabledForAll(): Boolean
    begin
        GetSetup();
        exit("Enable Telemetry To" = "Enable Telemetry To"::All);
    end;

    /// <summary>
    /// Gets the appropriate TelemetryScope based on the current setup.
    /// </summary>
    /// <returns>The TelemetryScope to use for logging.</returns>
    procedure GetTelemetryScope(): TelemetryScope
    begin
        GetSetup();
        case "Enable Telemetry To" of
            "Enable Telemetry To"::All:
                exit(TelemetryScope::All);
            else
                exit(TelemetryScope::ExtensionPublisher);
        end;
    end;
}
