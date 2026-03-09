namespace DT.ISVTelemetrySample;

/// <summary>
/// Enum defining the telemetry sending options.
/// Controls where telemetry data is sent based on user configuration.
/// </summary>
enum 50101 "Telemetry Enable To"
{
    Caption = 'Telemetry Enable To';
    Extensible = false;

    value(0; "None")
    {
        Caption = 'None';
    }
    value(1; "App Publisher")
    {
        Caption = 'App Publisher';
    }
    value(2; "All")
    {
        Caption = 'All';
    }
}
