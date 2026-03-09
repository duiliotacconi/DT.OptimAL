namespace DT.ISVTelemetrySample;

/// <summary>
/// Page for configuring Telemetry Demo Setup.
/// Allows users to configure where telemetry data is sent.
/// </summary>
page 50102 "Telemetry Demo Setup"
{
    Caption = 'Telemetry Demo Setup';
    PageType = Card;
    SourceTable = "Telemetry Demo Setup";
    ApplicationArea = All;
    UsageCategory = Administration;
    DeleteAllowed = false;
    InsertAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Enable Telemetry To"; Rec."Enable Telemetry To")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies where telemetry data should be sent. None: No telemetry is sent. App Publisher: Telemetry is sent only to the app publisher''s Application Insights. All: Telemetry is sent to both the app publisher and the environment''s Application Insights.';
                }
            }
            group(Information)
            {
                Caption = 'Information';

                field(TelemetryInfo; TelemetryInfoTxt)
                {
                    ApplicationArea = All;
                    Caption = 'About Telemetry';
                    Editable = false;
                    MultiLine = true;
                    ShowCaption = false;
                    Style = Subordinate;
                }
            }
        }
    }

    var
        TelemetryInfoTxt: Label 'Telemetry helps monitor the health and usage of the application. When enabled, telemetry data is sent to Azure Application Insights for analysis.\\\None: No telemetry data is collected.\App Publisher: Telemetry is sent only to the extension publisher''s Application Insights resource.\All: Telemetry is sent to both the extension publisher and the environment''s Application Insights resource.';

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
