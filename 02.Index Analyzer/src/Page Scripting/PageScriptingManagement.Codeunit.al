namespace DefaultNamespace;

using System.IO;
using System.Utilities;

codeunit 50930 "DTC Page Scripting Management"
{
    procedure GenerateForSelectedTable(TableID: Integer)
    var
        Setup: Record "DTC Page Scripting File Setup";
        TempBlob: Codeunit "Temp Blob";
        TemplateContent: Text;
        ModifiedContent: Text;
        SourceTableID: Text;
        TargetTableID: Text;
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        GetSetup(Setup, true);
        TemplateContent := ReadBlobAsText(Setup);
        SourceTableID := ExtractSourceTableID(TemplateContent);
        if SourceTableID = '' then
            Error(CannotExtractIDErr);

        TargetTableID := Format(TableID);
        ModifiedContent := ReplaceTemplateContent(TemplateContent, SourceTableID, TargetTableID, Setup."Profile ID", Setup."Company Name");

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(ModifiedContent);
        TempBlob.CreateInStream(InStr);
        FileName := StrSubstNo(TableFileNameLbl, TargetTableID);
        DownloadFromStream(InStr, DownloadTitleLbl, '', YamlFilterLbl, FileName);
    end;

    procedure GenerateForAllTables()
    var
        Setup: Record "DTC Page Scripting File Setup";
        TableIndexRec: Record "DTC Table Index";
        DataCompression: Codeunit "Data Compression";
        ZipTempBlob: Codeunit "Temp Blob";
        TemplateContent: Text;
        ModifiedContent: Text;
        SuiteContent: TextBuilder;
        SourceTableID: Text;
        TargetTableID: Text;
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        GetSetup(Setup, true);
        TemplateContent := ReadBlobAsText(Setup);
        SourceTableID := ExtractSourceTableID(TemplateContent);
        if SourceTableID = '' then
            Error(CannotExtractIDErr);

        TableIndexRec.Reset();
        if not TableIndexRec.FindSet() then
            Error(NoTablesErr);

        DataCompression.CreateZipArchive();

        // Build suite YAML header
        SuiteContent.AppendLine('name: Table Index Suite');
        SuiteContent.AppendLine('description: Table Index Suite to generate details');
        SuiteContent.AppendLine('start:');
        SuiteContent.AppendLine('  profile: ' + Setup."Profile ID");
        SuiteContent.AppendLine('steps:');

        repeat
            TargetTableID := Format(TableIndexRec."Table ID");
            ModifiedContent := ReplaceTemplateContent(TemplateContent, SourceTableID, TargetTableID, Setup."Profile ID", Setup."Company Name");

            // Add table YAML to ZIP
            AddTextEntryToZip(DataCompression, ModifiedContent, StrSubstNo(TableFileNameLbl, TargetTableID));

            // Add step to suite
            SuiteContent.AppendLine('  - type: include');
            SuiteContent.AppendLine('    name: Table' + TargetTableID);
            SuiteContent.AppendLine('    description: Run <file>Table' + TargetTableID + '</file>');
            SuiteContent.AppendLine('    file: .\Table' + TargetTableID + '.yaml');
        until TableIndexRec.Next() = 0;

        // Add suite YAML to ZIP
        AddTextEntryToZip(DataCompression, SuiteContent.ToText(), SuiteFileNameLbl);

        // Save and download ZIP
        ZipTempBlob.CreateOutStream(OutStr);
        DataCompression.SaveZipArchive(OutStr);
        DataCompression.CloseZipArchive();
        ZipTempBlob.CreateInStream(InStr);
        FileName := SuiteZipFileNameLbl;
        DownloadFromStream(InStr, DownloadTitleLbl, '', ZipFilterLbl, FileName);
    end;

    local procedure GetSetup(var Setup: Record "DTC Page Scripting File Setup"; RequireProfile: Boolean)
    begin
        if not Setup.Get() then
            Error(NoSetupErr);
        Setup.CalcFields("Page Script Template File");
        if not Setup."Page Script Template File".HasValue() then
            Error(NoTemplateErr);
        if RequireProfile and (Setup."Profile ID" = '') then
            Error(NoProfileErr);
    end;

    local procedure ReadBlobAsText(var Setup: Record "DTC Page Scripting File Setup"): Text
    var
        InStr: InStream;
        Content: TextBuilder;
        Line: Text;
    begin
        Setup."Page Script Template File".CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS do begin
            InStr.ReadText(Line);
            Content.AppendLine(Line);
        end;
        exit(Content.ToText());
    end;

    local procedure ExtractSourceTableID(TemplateContent: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
    begin
        StartPos := TemplateContent.IndexOf(NamePrefixLbl);
        if StartPos = 0 then
            exit('');

        StartPos += StrLen(NamePrefixLbl);
        EndPos := StartPos;
        while (EndPos <= StrLen(TemplateContent)) and
              (TemplateContent[EndPos] >= '0') and (TemplateContent[EndPos] <= '9') do
            EndPos += 1;

        if EndPos = StartPos then
            exit('');

        exit(CopyStr(TemplateContent, StartPos, EndPos - StartPos));
    end;

    local procedure ReplaceTemplateContent(TemplateContent: Text; SourceID: Text; TargetID: Text; ProfileID: Code[30]; CompanyNameToUse: Text): Text
    var
        Result: Text;
    begin
        Result := TemplateContent;
        // Replace name: TableXXX
        Result := Result.Replace('Table' + SourceID, 'Table' + TargetID);
        // Replace value: "XXX"
        Result := Result.Replace('"' + SourceID + '"', '"' + TargetID + '"');
        // Replace <value>XXX</value>
        Result := Result.Replace('<value>' + SourceID + '</value>', '<value>' + TargetID + '</value>');
        // Replace profile: XXXXX with Setup profile
        Result := ReplaceProfile(Result, ProfileID);
        // Replace Company Name value with the configured company (fallback to current company)
        Result := ReplaceCompanyName(Result, CompanyNameToUse);
        exit(Result);
    end;

    local procedure ReplaceProfile(Content: Text; ProfileID: Code[30]): Text
    var
        ProfilePrefix: Text;
        StartPos: Integer;
        EndPos: Integer;
        OldProfile: Text;
    begin
        ProfilePrefix := 'profile: ';
        StartPos := Content.IndexOf(ProfilePrefix);
        if StartPos = 0 then
            exit(Content);

        StartPos += StrLen(ProfilePrefix);
        EndPos := StartPos;
        while (EndPos <= StrLen(Content)) and (Content[EndPos] <> 10) and (Content[EndPos] <> 13) do
            EndPos += 1;

        OldProfile := CopyStr(Content, StartPos, EndPos - StartPos);
        exit(Content.Replace(ProfilePrefix + OldProfile, ProfilePrefix + ProfileID));
    end;

    local procedure ReplaceCompanyName(Content: Text; CompanyNameToUse: Text): Text
    var
        CompanyFieldMarker: Text;
        ValuePrefix: Text;
        CurrentCompany: Text;
        MarkerPos: Integer;
        ValuePos: Integer;
        StartPos: Integer;
        EndPos: Integer;
        OldCompanyName: Text;
        Result: Text;
    begin
        CompanyFieldMarker := 'field: Company Name';
        ValuePrefix := 'value: ';
        if CompanyNameToUse <> '' then
            CurrentCompany := CompanyNameToUse
        else
            CurrentCompany := CompanyName();
        Result := Content;

        MarkerPos := Result.IndexOf(CompanyFieldMarker);
        if MarkerPos = 0 then
            exit(Result);

        // Find the next "value: " after "field: Company Name"
        ValuePos := CopyStr(Result, MarkerPos).IndexOf(ValuePrefix);
        if ValuePos = 0 then
            exit(Result);

        // Absolute position of value content
        StartPos := MarkerPos + ValuePos - 1 + StrLen(ValuePrefix);
        EndPos := StartPos;
        while (EndPos <= StrLen(Result)) and (Result[EndPos] <> 10) and (Result[EndPos] <> 13) do
            EndPos += 1;

        OldCompanyName := CopyStr(Result, StartPos, EndPos - StartPos);
        if OldCompanyName = '' then
            exit(Result);

        // Replace old company name with current company in the value and description lines
        Result := Result.Replace(ValuePrefix + OldCompanyName, ValuePrefix + CurrentCompany);
        Result := Result.Replace('<value>' + OldCompanyName + '</value>', '<value>' + CurrentCompany + '</value>');
        exit(Result);
    end;

    local procedure AddTextEntryToZip(var DataCompression: Codeunit "Data Compression"; Content: Text; EntryName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        EntryOutStr: OutStream;
        EntryInStr: InStream;
    begin
        TempBlob.CreateOutStream(EntryOutStr, TextEncoding::UTF8);
        EntryOutStr.WriteText(Content);
        TempBlob.CreateInStream(EntryInStr);
        DataCompression.AddEntry(EntryInStr, EntryName);
    end;

    var
        NoSetupErr: Label 'Page Scripting File Setup has not been configured. Please set it up first.';
        NoTemplateErr: Label 'No template file has been uploaded in the Page Scripting File Setup.';
        NoProfileErr: Label 'No profile has been selected in the Page Scripting File Setup.';
        NoTablesErr: Label 'No tables found in Table Index. Please import data first.';
        CannotExtractIDErr: Label 'Cannot extract the source table ID from the template. The template must have a "name: TableXXX" entry.';
        NamePrefixLbl: Label 'name: Table', Locked = true;
        TableFileNameLbl: Label 'Table%1.yaml', Locked = true, Comment = '%1 = Table ID';
        SuiteFileNameLbl: Label 'TableIndexSuite.yaml', Locked = true;
        SuiteZipFileNameLbl: Label 'TableIndexSuite.zip', Locked = true;
        DownloadTitleLbl: Label 'Download Page Scripting Files';
        YamlFilterLbl: Label 'YAML Files (*.yaml)|*.yaml', Locked = true;
        ZipFilterLbl: Label 'ZIP Files (*.zip)|*.zip', Locked = true;
}
