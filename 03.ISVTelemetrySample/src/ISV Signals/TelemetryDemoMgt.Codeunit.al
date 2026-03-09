namespace DT.ISVTelemetrySample;

using System.Telemetry;
using System.Upgrade;

/// <summary>
/// Codeunit containing management functions for telemetry demonstrations.
/// Contains methods to trigger various telemetry signals.
/// </summary>
codeunit 50100 "Telemetry Demo Mgt."
{
    /// <summary>
    /// Simulates a long-running AL method to trigger RT0018 telemetry.
    /// RT0018 - Operation exceeded time threshold (AL method)
    /// The method runs for approximately 12 seconds to exceed the typical 10-second threshold.
    /// </summary>
    procedure SimulateLongRunningALMethod()
    var
        StartTime: DateTime;
        i: Integer;
        Result: Decimal;
    begin
        StartTime := CurrentDateTime();

        // Perform CPU-intensive calculations for ~12 seconds
        // This should trigger RT0018 if the threshold is configured
        while CurrentDateTime() - StartTime < 12000 do begin
            for i := 1 to 10000 do
                Result := Result + Power(i, 2) / (i + 1);

            // Reset to prevent overflow
            if Result > 1000000000 then
                Result := 0;
        end;

        LogTelemetryEvent('Long running AL method completed', Result);
    end;

    /// <summary>
    /// Simulates a long-running SQL operation to trigger RT0005 telemetry.
    /// RT0005 - Operation exceeded time threshold (SQL query)
    /// Creates multiple records and performs complex queries.
    /// </summary>
    procedure SimulateLongRunningSQL()
    var
        TelemetryDemo: Record "Telemetry Demo";
        i: Integer;
        RecordCount: Integer;
    begin
        // Insert many records to create a larger dataset
        for i := 1 to 1000 do begin
            TelemetryDemo.Init();
            TelemetryDemo."Entry No." := 0;
            TelemetryDemo.Description := StrSubstNo(LongRunningSQLDescLbl, i);
            TelemetryDemo."Demo Type" := TelemetryDemo."Demo Type"::"Long Running SQL";
            TelemetryDemo.Amount := Random(10000) / 100;
            TelemetryDemo.Insert(true);
        end;

        // Perform a complex query operation that may trigger RT0005
        TelemetryDemo.Reset();
        TelemetryDemo.SetRange("Demo Type", TelemetryDemo."Demo Type"::"Long Running SQL");
        TelemetryDemo.SetFilter(Amount, '>%1', 0);

        // Read through all records multiple times
        repeat
            RecordCount += 1;
        until TelemetryDemo.Next() = 0;

        // Aggregate calculation
        TelemetryDemo.CalcSums(Amount);

        Message(SQLOperationCompletedLbl, RecordCount, TelemetryDemo.Amount);
    end;

    /// <summary>
    /// Simulates an error dialog to trigger RT0030 telemetry.
    /// RT0030 - Error dialog displayed
    /// Uses a Label to ensure proper telemetry logging of the error message.
    /// </summary>
    procedure SimulateErrorDialog()
    begin
        // Using a Label constant ensures the error message is properly logged in telemetry
        // If you use a variable instead of a Label, the message won't be captured properly
        Error(DemoErrorLbl);
    end;

    /// <summary>
    /// Makes an outgoing web service call to trigger RT0019 telemetry.
    /// RT0019 - Web Service Called (Outgoing)
    /// </summary>
    procedure SimulateOutgoingWebServiceCall()
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ResponseText: Text;
        Success: Boolean;
    begin
        // Make an outgoing HTTP call to a public API
        // This triggers RT0019 telemetry
        Success := HttpClient.Get('https://httpbin.org/get', HttpResponseMessage);

        if Success and HttpResponseMessage.IsSuccessStatusCode() then begin
            HttpResponseMessage.Content().ReadAs(ResponseText);
            Message(OutgoingWebServiceSuccessLbl);
        end else
            Message(OutgoingWebServiceFailedLbl, HttpResponseMessage.HttpStatusCode());
    end;

    /// <summary>
    /// Creates sample data for demonstration purposes.
    /// </summary>
    procedure CreateSampleData()
    var
        TelemetryDemo: Record "Telemetry Demo";
        i: Integer;
        DemoTypes: array[7] of Enum "Telemetry Demo Type";
    begin
        DemoTypes[1] := DemoTypes[1] ::"Long Running AL";
        DemoTypes[2] := DemoTypes[2] ::"Long Running SQL";
        DemoTypes[3] := DemoTypes[3] ::"Error Dialog";
        DemoTypes[4] := DemoTypes[4] ::"Report Generation";
        DemoTypes[5] := DemoTypes[5] ::"Page View";
        DemoTypes[6] := DemoTypes[6] ::"Web Service";

        for i := 1 to 7 do begin
            TelemetryDemo.Init();
            TelemetryDemo."Entry No." := 0;
            TelemetryDemo.Description := StrSubstNo(SampleDataDescLbl, Format(DemoTypes[i]));
            TelemetryDemo."Demo Type" := DemoTypes[i];
            TelemetryDemo.Amount := Random(10000) / 100;
            TelemetryDemo.Insert(true);
        end;
    end;

    /// <summary>
    /// Sends daily telemetry signals based on the Telemetry Demo Setup configuration.
    /// If "Enable Telemetry To" is set to "All", telemetry is sent to both customer and ISV ingestion points.
    /// If set to "App Publisher", telemetry is sent only to the ISV's ingestion point.
    /// If set to "None", no telemetry is sent.
    /// This event subscriber is triggered once per day by the Business Central platform.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Management", OnSendDailyTelemetry, '', true, true)]
    local procedure OnSendDailyTelemetry()
    var
        TelemetryDemoSetup: Record "Telemetry Demo Setup";
        TelemetryEnableToEnum: Enum "Telemetry Enable To";
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDemoSetup.GetSetup();
        if TelemetryDemoSetup."Enable Telemetry To" = TelemetryEnableToEnum::None then
            exit; // Telemetry disabled, do not send any signals

        TelemetryCustomDimensions.Add('SignalType', 'DailyTelemetry');
        TelemetryCustomDimensions.Add('Timestamp', Format(CurrentDateTime(), 0, 9));

        // Send telemetry based on setup configuration
        // TelemetryScope::All sends to both customer AND ISV ingestion points
        // TelemetryScope::ExtensionPublisher sends only to ISV ingestion point
        case TelemetryDemoSetup."Enable Telemetry To" of
            TelemetryEnableToEnum::All:
                Session.LogMessage(
                    'TELDEMO010',
                    DailyTelemetryCustomerSignalLbl,
                    Verbosity::Normal,
                    DataClassification::SystemMetadata,
                    TelemetryScope::All,
                    TelemetryCustomDimensions);
            TelemetryEnableToEnum::"App Publisher":
                begin
                    TelemetryCustomDimensions.Set('SignalType', 'DailyTelemetryISV');
                    Session.LogMessage(
                        'TELDEMO011',
                        DailyTelemetryISVSignalLbl,
                        Verbosity::Normal,
                        DataClassification::SystemMetadata,
                        TelemetryScope::ExtensionPublisher,
                        TelemetryCustomDimensions);
                end;
        end;

    end;

    local procedure LogTelemetryEvent(EventName: Text; Value: Decimal)
    var
        TelemetryCustomDimensions: Dictionary of [Text, Text];
    begin
        TelemetryCustomDimensions.Add('EventName', EventName);
        TelemetryCustomDimensions.Add('Value', Format(Value));
        Session.LogMessage('TELDEMLRAM', 'Long Running AL Methods', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, TelemetryCustomDimensions);
    end;

    var
        DemoErrorLbl: Label 'This is a demonstration error to trigger RT0030 telemetry. The error message is logged to Application Insights when using a Label constant.';
        LongRunningSQLDescLbl: Label 'Long Running SQL Demo Record %1', Comment = '%1 = Record number';
        SQLOperationCompletedLbl: Label 'SQL operation completed. Processed %1 records with total amount: %2', Comment = '%1 = Record count, %2 = Total amount';
        OutgoingWebServiceSuccessLbl: Label 'Outgoing web service call succeeded. RT0019 telemetry was emitted.';
        OutgoingWebServiceFailedLbl: Label 'Outgoing web service call failed with status code: %1. RT0019 telemetry was still emitted.', Comment = '%1 = HTTP status code';
        SampleDataDescLbl: Label 'Sample data for %1', Comment = '%1 = Demo type name';
        DailyTelemetryCustomerSignalLbl: Label 'Daily telemetry signal sent to customer and ISV ingestion points.';
        DailyTelemetryISVSignalLbl: Label 'Daily telemetry signal sent to ISV ingestion point.';
}
