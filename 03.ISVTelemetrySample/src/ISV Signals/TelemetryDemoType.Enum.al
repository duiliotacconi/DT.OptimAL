namespace DT.ISVTelemetrySample;

/// <summary>
/// Enum defining the types of telemetry demonstrations available.
/// </summary>
enum 50100 "Telemetry Demo Type"
{
    Caption = 'Telemetry Demo Type';
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(1; "Long Running AL")
    {
        Caption = 'Long Running AL (RT0018)';
    }
    value(2; "Long Running SQL")
    {
        Caption = 'Long Running SQL (RT0005)';
    }
    value(3; "Error Dialog")
    {
        Caption = 'Error Dialog (RT0030)';
    }
    value(4; "Report Generation")
    {
        Caption = 'Report Generation (RT0006/RT0007/RT0011)';
    }
    value(5; "Page View")
    {
        Caption = 'Page View (CL0001)';
    }
    value(6; "Web Service")
    {
        Caption = 'Web Service (RT0008/RT0019/RT0053)';
    }

}
