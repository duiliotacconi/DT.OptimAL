namespace DefaultNamespace;

page 50930 "DTC Page Scripting File Setup"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "DTC Page Scripting File Setup";
    Caption = 'Page Scripting File Setup';
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Profile ID"; Rec."Profile ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the profile to use when running page scripting files. Enter a valid Profile ID (e.g. BUSINESS MANAGER EVALUATION).';
                    Lookup = false;
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the company name to use in the generated page scripting files. If left empty, the current company is used.';
                }
                field("Template File Name"; Rec."Template File Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the uploaded template file.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportTemplate)
            {
                ApplicationArea = All;
                Caption = 'Import Template';
                Image = Import;
                ToolTip = 'Import a Page Scripting template YAML file.';

                trigger OnAction()
                var
                    InStr: InStream;
                    OutStr: OutStream;
                    FileName: Text;
                begin
                    if not UploadIntoStream('Select Page Scripting Template File', '', 'YAML Files (*.yaml)|*.yaml|All Files (*.*)|*.*', FileName, InStr) then
                        exit;

                    Rec."Page Script Template File".CreateOutStream(OutStr, TextEncoding::UTF8);
                    CopyStream(OutStr, InStr);
                    Rec."Template File Name" := CopyStr(FileName, 1, MaxStrLen(Rec."Template File Name"));
                    Rec.Modify(true);
                    Message('Template file "%1" has been imported.', FileName);
                end;
            }
            action(DownloadTemplate)
            {
                ApplicationArea = All;
                Caption = 'Download Template';
                Image = Export;
                ToolTip = 'Download the currently stored Page Scripting template YAML file.';

                trigger OnAction()
                var
                    InStr: InStream;
                    FileName: Text;
                begin
                    Rec.CalcFields("Page Script Template File");
                    if not Rec."Page Script Template File".HasValue() then
                        Error('No template file has been uploaded.');

                    Rec."Page Script Template File".CreateInStream(InStr, TextEncoding::UTF8);
                    FileName := Rec."Template File Name";
                    if FileName = '' then
                        FileName := 'Template.yaml';
                    DownloadFromStream(InStr, 'Download Template', '', 'YAML Files (*.yaml)|*.yaml|All Files (*.*)|*.*', FileName);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ImportTemplate_Promoted; ImportTemplate)
                {
                }
                actionref(DownloadTemplate_Promoted; DownloadTemplate)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}
