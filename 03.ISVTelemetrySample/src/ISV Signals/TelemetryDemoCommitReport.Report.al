namespace DT.ISVTelemetrySample;

/// <summary>
/// Demo report for triggering RT0011 telemetry signal.
/// 
/// TELEMETRY SIGNALS:
/// - RT0011: Report cancelled but a commit occurred
/// 
/// This report demonstrates the scenario where a commit happens during report execution
/// but the report is subsequently cancelled. This is an important scenario to monitor
/// as it can lead to data inconsistencies.
/// </summary>
report 50101 "Telemetry Demo Commit Report"
{
    Caption = 'Telemetry Demo - Commit Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(TelemetryDemo; "Telemetry Demo")
        {
            RequestFilterFields = "Demo Type";

            trigger OnPreDataItem()
            begin
                // Create a record and commit it
                // This simulates a scenario where data is committed during report processing
                CreateAndCommitRecord();
            end;

            trigger OnAfterGetRecord()
            begin
                RecordsProcessed += 1;

                // After processing some records, allow user to see the issue
                if RecordsProcessed >= MaxRecordsBeforePrompt then
                    if Confirm(CancelReportPromptLbl) then
                        Error(ReportCancelledLbl);
            end;

            trigger OnPostDataItem()
            begin
                Message(ReportCompletedLbl, RecordsProcessed);
            end;
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

                    field(MaxRecordsField; MaxRecordsBeforePrompt)
                    {
                        Caption = 'Records Before Cancel Prompt';
                        ApplicationArea = All;
                        ToolTip = 'Number of records to process before showing the cancel prompt.';
                        MinValue = 1;
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            MaxRecordsBeforePrompt := 3;
        end;
    }

    trigger OnPreReport()
    begin
        RecordsProcessed := 0;
    end;

    local procedure CreateAndCommitRecord()
    var
        TelemetryDemo: Record "Telemetry Demo";
    begin
        // Create a new record
        TelemetryDemo.Init();
        TelemetryDemo."Entry No." := 0;
        TelemetryDemo.Description := CommitDemoDescLbl;
        TelemetryDemo."Demo Type" := TelemetryDemo."Demo Type"::"Report Generation";
        TelemetryDemo.Amount := Random(1000) / 100;
        TelemetryDemo.Insert(true);

        // IMPORTANT: This commit is what causes RT0011 telemetry
        // If the report is cancelled after this commit, the data remains
        // but the report shows as cancelled, creating an inconsistent state
        Commit();
    end;

    var
        RecordsProcessed: Integer;
        MaxRecordsBeforePrompt: Integer;
        CommitDemoDescLbl: Label 'Record created during RT0011 demo (commit before cancel)';
        CancelReportPromptLbl: Label 'A commit has already occurred. Do you want to cancel the report now?\This will trigger RT0011 telemetry (Report cancelled but a commit occurred).';
        ReportCancelledLbl: Label 'Report cancelled after commit. This triggers RT0011 telemetry. Note: The committed data will remain in the database.';
        ReportCompletedLbl: Label 'Report completed successfully. Processed %1 records.', Comment = '%1 = Number of records processed';
}
