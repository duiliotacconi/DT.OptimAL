codeunit 50112 DTALProfilerSampleHelper
{
    procedure GetGLSetupCurrencyDescription(): Text
    var
        GLSetup: Record "General Ledger Setup";
    begin
        SelectLatestVersion();
        GLSetup.Get();
        exit(GLSetup."Local Currency Description");
    end;

}