namespace DT.ISVTelemetrySample;

using System.Upgrade;

/// <summary>
/// Main page for demonstrating telemetry signals.
/// Opening this page triggers CL0001 (Page opened) telemetry.
/// </summary>
page 50100 "Telemetry Demo"
{
    Caption = 'Telemetry Demo - ISV Telemetry Sample';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Telemetry Demo";

    layout
    {
        area(Content)
        {
            group(Instructions)
            {
                Caption = 'Telemetry Demo Instructions';

                field(InstructionsText; InstructionsLbl)
                {
                    ApplicationArea = All;
                    Caption = 'How to Use';
                    MultiLine = true;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                }
            }
            group(TelemetrySignals)
            {
                Caption = 'Available Telemetry Signals';

                field(SignalsList; SignalsListLbl)
                {
                    ApplicationArea = All;
                    Caption = 'Signals';
                    MultiLine = true;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(RecordDetails)
            {
                Caption = 'Record Details';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
                field("Demo Type"; Rec."Demo Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the demo type.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(PerformanceSignals)
            {
                Caption = 'Performance Signals';

                action(SimulateLongRunningAL)
                {
                    Caption = 'Simulate Long Running AL (RT0018)';
                    ApplicationArea = All;
                    Image = Process;
                    ToolTip = 'Runs a procedure that takes longer than 10 seconds to trigger RT0018 telemetry signal.';

                    trigger OnAction()
                    var
                        TelemetryDemoMgt: Codeunit "Telemetry Demo Mgt.";
                    begin
                        TelemetryDemoMgt.SimulateLongRunningALMethod();
                        Message(LongRunningCompletedLbl);
                    end;
                }
                action(SimulateLongRunningSQL)
                {
                    Caption = 'Simulate Long Running SQL (RT0005)';
                    ApplicationArea = All;
                    Image = Database;
                    ToolTip = 'Runs a SQL query that takes a long time to trigger RT0005 telemetry signal.';

                    trigger OnAction()
                    var
                        TelemetryDemoMgt: Codeunit "Telemetry Demo Mgt.";
                    begin
                        TelemetryDemoMgt.SimulateLongRunningSQL();
                        Message(LongRunningSQLCompletedLbl);
                    end;
                }
            }
            group(ErrorSignals)
            {
                Caption = 'Error Signals';

                action(SimulateErrorDialog)
                {
                    Caption = 'Simulate Error Dialog (RT0030)';
                    ApplicationArea = All;
                    Image = Error;
                    ToolTip = 'Displays an error dialog to trigger RT0030 telemetry signal.';

                    trigger OnAction()
                    var
                        TelemetryDemoMgt: Codeunit "Telemetry Demo Mgt.";
                    begin
                        TelemetryDemoMgt.SimulateErrorDialog();
                    end;

                }
            }
            group(ReportSignals)
            {
                Caption = 'Report Signals';

                action(RunSuccessfulReport)
                {
                    Caption = 'Run Report Successfully (RT0006)';
                    ApplicationArea = All;
                    Image = Report;
                    ToolTip = 'Runs a report successfully to trigger RT0006 telemetry signal.';

                    trigger OnAction()
                    begin
                        Report.Run(Report::"Telemetry Demo Report");
                    end;
                }
                action(RunCancelledReport)
                {
                    Caption = 'Run Report with Cancel (RT0007)';
                    ApplicationArea = All;
                    Image = Cancel;
                    ToolTip = 'Runs a report that will be cancelled to trigger RT0007 telemetry signal. Cancel the report request page.';

                    trigger OnAction()
                    begin
                        Report.Run(Report::"Telemetry Demo Report", true, true);
                    end;
                }
                action(RunReportWithCommit)
                {
                    Caption = 'Run Report with Commit Issue (RT0011)';
                    ApplicationArea = All;
                    Image = Reject;
                    ToolTip = 'Runs a report that performs a commit and then is cancelled to trigger RT0011 telemetry signal.';

                    trigger OnAction()
                    begin
                        Report.Run(Report::"Telemetry Demo Commit Report");
                    end;
                }
            }
            group(WebServiceSignals)
            {
                Caption = 'Web Service Signals';

                action(MakeOutgoingWebServiceCall)
                {
                    Caption = 'Outgoing Web Service Call (RT0019)';
                    ApplicationArea = All;
                    Image = Web;
                    ToolTip = 'Makes an outgoing web service call to trigger RT0019 telemetry signal.';

                    trigger OnAction()
                    var
                        TelemetryDemoMgt: Codeunit "Telemetry Demo Mgt.";
                    begin
                        TelemetryDemoMgt.SimulateOutgoingWebServiceCall();
                    end;
                }
            }
            group(PageViewSignals)
            {
                Caption = 'Page View Signals';

                action(OpenListPage)
                {
                    Caption = 'Open List Page (CL0001)';
                    ApplicationArea = All;
                    Image = List;
                    ToolTip = 'Opens the Telemetry Demo List page to trigger CL0001 telemetry.';

                    trigger OnAction()
                    begin
                        Page.Run(Page::"Telemetry Demo List");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(SimulateLongRunningAL_Promoted; SimulateLongRunningAL) { }
                actionref(SimulateLongRunningSQL_Promoted; SimulateLongRunningSQL) { }
                actionref(SimulateErrorDialog_Promoted; SimulateErrorDialog) { }
                actionref(RunSuccessfulReport_Promoted; RunSuccessfulReport) { }
                actionref(MakeOutgoingWebServiceCall_Promoted; MakeOutgoingWebServiceCall) { }
            }
        }
    }

    var
        InstructionsLbl: Label 'This app demonstrates various telemetry signals that are emitted to Application Insights when configured in app.json. Use the actions below to trigger different telemetry events. Make sure your Application Insights connection string is configured in the app.json file.';
        SignalsListLbl: Label 'RT0030 - Error Dialog\RT0010 - Extension Update Failed\AL0000EJ9 - Upgrade Tag Searched\AL0000EJA - Upgrade Tag Set\RT0018 - Long Running AL Method\RT0005 - Long Running SQL Query\CL0001 - Page Opened\RT0006 - Report Generation Success/Failure\RT0007 - Report Cancelled\RT0011 - Report Cancelled with Commit\AL0000N0E/N0F/N0G/N0H/N0I - Report Layout Lifecycle\LC0025 - Table Index Disabled\RT0008 - Incoming Web Service\RT0053 - Deprecated Endpoint Called\RT0019 - Outgoing Web Service';
        LongRunningCompletedLbl: Label 'Long running AL method completed. Check Application Insights for RT0018 telemetry (if threshold was exceeded).';
        LongRunningSQLCompletedLbl: Label 'Long running SQL operation completed. Check Application Insights for RT0005 telemetry (if threshold was exceeded).';

}