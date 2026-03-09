namespace DT.ISVTelemetrySample;

using System.Telemetry;

/// <summary>
/// Codeunit implementing the Telemetry Logger interface.
/// Provides functionality to send telemetry based on the setup configuration.
/// </summary>
codeunit 50103 "Telemetry Demo Logger" implements "Telemetry Logger"
{
    Access = Internal;

    /// <summary>
    /// Logs a telemetry message based on the setup configuration.
    /// This method is called by the system when telemetry is sent via the Telemetry or Feature Telemetry codeunits.
    /// </summary>
    /// <param name="EventId">The event identifier.</param>
    /// <param name="Message">The telemetry message.</param>
    /// <param name="Verbosity">The verbosity level of the message.</param>
    /// <param name="DataClassification">The data classification of the message.</param>
    /// <param name="TelemetryScope">The requested telemetry scope.</param>
    /// <param name="CustomDimensions">Additional custom dimensions for the telemetry.</param>
    procedure LogMessage(EventId: Text; Message: Text; Verbosity: Verbosity; DataClassification: DataClassification; TelemetryScope: TelemetryScope; CustomDimensions: Dictionary of [Text, Text])
    var
        TelemetryDemoSetup: Record "Telemetry Demo Setup";
        EffectiveTelemetryScope: TelemetryScope;
    begin
        TelemetryDemoSetup.GetSetup();

        // Check if telemetry is disabled
        if TelemetryDemoSetup."Enable Telemetry To" = TelemetryDemoSetup."Enable Telemetry To"::None then
            exit;

        // Determine the effective telemetry scope based on setup
        case TelemetryDemoSetup."Enable Telemetry To" of
            TelemetryDemoSetup."Enable Telemetry To"::"App Publisher":
                // Only send to app publisher, regardless of requested scope
                EffectiveTelemetryScope := TelemetryScope::ExtensionPublisher;
            TelemetryDemoSetup."Enable Telemetry To"::All:
                // Honor the requested scope or use All
                if TelemetryScope = TelemetryScope::All then
                    EffectiveTelemetryScope := TelemetryScope::All
                else
                    EffectiveTelemetryScope := TelemetryScope;
        end;

        Session.LogMessage(EventId, Message, Verbosity, DataClassification, EffectiveTelemetryScope, CustomDimensions);
    end;

    /// <summary>
    /// Subscribes to the OnRegisterTelemetryLogger event to register this telemetry logger.
    /// For the functionality to behave as expected, there must be exactly one implementation 
    /// of the "Telemetry Logger" interface registered per app publisher.
    /// </summary>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Telemetry Loggers", OnRegisterTelemetryLogger, '', true, true)]
    local procedure OnRegisterTelemetryLogger(var Sender: Codeunit "Telemetry Loggers")
    var
        TelemetryDemoLogger: Codeunit "Telemetry Demo Logger";
    begin
        Sender.Register(TelemetryDemoLogger);
    end;
}
