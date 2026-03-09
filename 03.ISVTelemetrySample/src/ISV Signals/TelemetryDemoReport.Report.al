namespace DT.ISVTelemetrySample;

/// <summary>
/// Demo report for triggering report telemetry signals.
/// 
/// TELEMETRY SIGNALS:
/// - RT0006: Success report generation (when report runs successfully)
/// - RT0006: Report rendering failed (when report fails)
/// - RT0007: Cancellation report generation (when user cancels the report)
/// </summary>
report 50100 "Telemetry Demo Report"
{
    Caption = 'Telemetry Demo Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = RDLCLayout;

    dataset
    {
        dataitem(TelemetryDemo; "Telemetry Demo")
        {
            RequestFilterFields = "Demo Type", "Created DateTime";

            column(EntryNo; "Entry No.") { }
            column(Description; Description) { }
            column(DemoType; "Demo Type") { }
            column(CreatedDateTime; "Created DateTime") { }
            column(Amount; Amount) { }
            column(Processed; Processed) { }
            column(CompanyName; CompanyName) { }
            column(ReportTitle; ReportTitleLbl) { }
            column(GeneratedAt; Format(CurrentDateTime())) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';

                    field(SimulateReportErrorField; SimulateReportError)
                    {
                        Caption = 'Simulate Error (RT0006 Failure)';
                        ApplicationArea = All;
                        ToolTip = 'Enable this option to simulate a report error, which will trigger RT0006 failure telemetry.';
                    }
                }
            }
        }
    }

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = 'src/ISV Signals/TelemetryDemoReport.rdl';
            Caption = 'RDLC Layout';
        }
        layout(WordLayout)
        {
            Type = Word;
            LayoutFile = 'src/ISV Signals/TelemetryDemoReport.docx';
            Caption = 'Word Layout';
        }
        layout(ExcelLayout)
        {
            Type = Excel;
            LayoutFile = 'src/ISV Signals/TelemetryDemoReport.xlsx';
            Caption = 'Excel Layout';
        }
    }

    trigger OnPreReport()
    begin
        if SimulateReportError then
            Error(SimulatedReportErrorLbl);
    end;

    var
        SimulateReportError: Boolean;
        ReportTitleLbl: Label 'Telemetry Demo Report';
        SimulatedReportErrorLbl: Label 'This is a simulated report error to trigger RT0006 failure telemetry. The report generation was intentionally failed for demonstration purposes.';
}
