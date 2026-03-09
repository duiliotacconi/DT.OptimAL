namespace DT.ALProfilingSample;

using System.Tooling;

codeunit 50199 "DT.ALProfilerHelper"
{
    SingleInstance = true;

    procedure Start()
    var
        SamplingPerformanceProfiler: Codeunit "Sampling Performance Profiler";
        ProfilerSamplingInterval: Enum "Sampling Interval";
        ProfilingSessionRunningMsg: Label 'Profiling session is now running...';
    begin
        if Session.CurrentExecutionMode() = ExecutionMode::Debug then
            exit;

        if SamplingPerformanceProfiler.IsRecordingInProgress() then
            SamplingPerformanceProfiler.Stop();

        ProfilerSamplingInterval := "Sampling Interval"::SampleEvery50ms;
        SamplingPerformanceProfiler.Start(ProfilerSamplingInterval);

        Message(ProfilingSessionRunningMsg);
    end;

    procedure Stop()
    var
        SamplingPerformanceProfiler: Codeunit "Sampling Performance Profiler";
        ToFile: Text;
        PrivacyNoticeMsg: Label @'
            Profiling has been stopped.
            WARNING! The file might contain HARDCORE data. Do you want to continue?';
        ProfileFileNameTxt: Label 'PerformanceProfile_%1', Locked = true;
        ProfileFileExtensionTxt: Label '.alcpuprofile', Locked = true;
        NoProfilingSessionRunningMsg: Label 'No profiling session is running.';
    begin
        if SamplingPerformanceProfiler.IsRecordingInProgress() then begin
            SamplingPerformanceProfiler.Stop();

            if not Confirm(PrivacyNoticeMsg) then
                exit;

            ToFile := StrSubstNo(ProfileFileNameTxt, Format(SessionId()) + ProfileFileExtensionTxt);
            DownloadFromStream(SamplingPerformanceProfiler.GetData(), '', '', '', ToFile);
        end else
            Message(NoProfilingSessionRunningMsg);
    end;

}