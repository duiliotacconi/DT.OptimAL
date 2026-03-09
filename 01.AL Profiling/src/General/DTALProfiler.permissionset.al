permissionset 50100 "DT.ALProfiler"
{
    Assignable = true;
    Permissions = codeunit "DT.ALProfilerHelper"=X,
        codeunit DTALProfilerSampleHelper=X,
        page DTALProfileStartAndStop=X;
}