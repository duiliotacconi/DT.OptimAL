namespace DefaultNamespace;

using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 50931 "DTC Index Data Import"
{
    procedure ImportFromZip()
    var
        DataCompression: Codeunit "Data Compression";
        InStr: InStream;
        FileName: Text;
        EntryList: List of [Text];
        TableInfoFiles: List of [Text];
        IndexFiles: List of [Text];
        PairCount: Integer;
        UpdatedCount: Integer;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Importing Index Data...\Pair: #1#### of #2####', Comment = '#1 = Current pair, #2 = Total pairs';
        SelectFileLbl: Label 'Select ZIP file with Table Information and Indexes XLSX files';
        NoDataErr: Label 'No valid Table Information / Indexes file pairs found in the ZIP file.';
        SuccessMsg: Label 'Import completed. %1 index entries updated from %2 file pair(s).', Comment = '%1 = Updated count, %2 = Pair count';
    begin
        // Upload ZIP file
        if not UploadIntoStream(SelectFileLbl, '', 'ZIP Files (*.zip)|*.zip', FileName, InStr) then
            exit;

        // Open the ZIP archive
        DataCompression.OpenZipArchive(InStr, false);
        DataCompression.GetEntryList(EntryList);

        // Classify files into Table Information and Indexes
        ClassifyZipEntries(EntryList, TableInfoFiles, IndexFiles);

        // Pair them up
        PairCount := PairFiles(TableInfoFiles, IndexFiles);
        if PairCount = 0 then
            Error(NoDataErr);

        // Process each pair
        ProgressDialog.Open(ProgressMsg);
        UpdatedCount := 0;

        ProcessFilePairs(DataCompression, TableInfoFiles, IndexFiles, PairCount, UpdatedCount, ProgressDialog);

        ProgressDialog.Close();
        DataCompression.CloseZipArchive();

        Message(SuccessMsg, UpdatedCount, PairCount);
    end;

    local procedure ClassifyZipEntries(EntryList: List of [Text]; var TableInfoFiles: List of [Text]; var IndexFiles: List of [Text])
    var
        EntryName: Text;
        LowerName: Text;
    begin
        Clear(TableInfoFiles);
        Clear(IndexFiles);

        foreach EntryName in EntryList do begin
            LowerName := LowerCase(EntryName);
            if LowerName.EndsWith('.xlsx') and LowerName.Contains('table information') then
                TableInfoFiles.Add(EntryName)
            else
                if LowerName.EndsWith('.xlsx') and LowerName.Contains('indexes') then
                    IndexFiles.Add(EntryName);
        end;
    end;

    local procedure PairFiles(var TableInfoFiles: List of [Text]; var IndexFiles: List of [Text]): Integer
    begin
        // Sort each list by numeric suffix to preserve generation order.
        // Page Scripting generates files sequentially: Table Information then Indexes for each table.
        // The browser appends auto-incremented numbers (2), (3)... per file type.
        // Within each type, numeric suffix order == generation timestamp order.
        SortByNumericSuffix(TableInfoFiles);
        SortByNumericSuffix(IndexFiles);

        // The number of pairs is the minimum of the two lists
        if TableInfoFiles.Count() < IndexFiles.Count() then
            exit(TableInfoFiles.Count())
        else
            exit(IndexFiles.Count());
    end;

    local procedure SortByNumericSuffix(var TextList: List of [Text])
    var
        i: Integer;
        j: Integer;
        MinIdx: Integer;
        MinNum: Integer;
        Count: Integer;
        FileNames: array[1000] of Text;
        FileSuffixes: array[1000] of Integer;
        TempName: Text;
        TempNum: Integer;
    begin
        Count := TextList.Count();
        if Count <= 1 then
            exit;

        // Copy to arrays and extract numeric suffixes
        for i := 1 to Count do begin
            FileNames[i] := TextList.Get(i);
            FileSuffixes[i] := ExtractNumericSuffix(FileNames[i]);
        end;

        // Selection sort by numeric suffix (ascending)
        for i := 1 to Count - 1 do begin
            MinIdx := i;
            MinNum := FileSuffixes[i];
            for j := i + 1 to Count do
                if FileSuffixes[j] < MinNum then begin
                    MinIdx := j;
                    MinNum := FileSuffixes[j];
                end;
            if MinIdx <> i then begin
                TempName := FileNames[i];
                TempNum := FileSuffixes[i];
                FileNames[i] := FileNames[MinIdx];
                FileSuffixes[i] := FileSuffixes[MinIdx];
                FileNames[MinIdx] := TempName;
                FileSuffixes[MinIdx] := TempNum;
            end;
        end;

        // Rebuild list
        Clear(TextList);
        for i := 1 to Count do
            TextList.Add(FileNames[i]);
    end;

    local procedure ExtractNumericSuffix(FileName: Text): Integer
    var
        OpenParen: Integer;
        CloseParen: Integer;
        NumText: Text;
        NumValue: Integer;
    begin
        // Extract numeric value from parentheses, e.g. "Table Information (35).xlsx" → 35
        // Files without a suffix (first pair) get 0 so they sort first
        OpenParen := FileName.LastIndexOf('(');
        CloseParen := FileName.LastIndexOf(')');
        if (OpenParen > 0) and (CloseParen > OpenParen) then begin
            NumText := CopyStr(FileName, OpenParen + 1, CloseParen - OpenParen - 1);
            NumText := DelChr(NumText, '=', ' ');
            if Evaluate(NumValue, NumText) then
                exit(NumValue);
        end;
        exit(0);
    end;

    local procedure ProcessFilePairs(var DataCompression: Codeunit "Data Compression"; TableInfoFiles: List of [Text]; IndexFiles: List of [Text]; PairCount: Integer; var UpdatedCount: Integer; var ProgressDialog: Dialog)
    var
        i: Integer;
        TableNo: Integer;
        PairUpdated: Integer;
    begin
        for i := 1 to PairCount do begin
            ProgressDialog.Update(1, i);
            ProgressDialog.Update(2, PairCount);

            // Step 1: Parse Table Information file to get Table No.
            TableNo := ParseTableInformationFile(DataCompression, TableInfoFiles.Get(i));
            if TableNo <= 0 then
                Message('Warning: Could not extract Table No. from file "%1". Skipping this pair.', TableInfoFiles.Get(i))
            else begin
                // Step 2: Parse Indexes file and update Index Entry records
                PairUpdated := ParseIndexesFile(DataCompression, IndexFiles.Get(i), TableNo);
                UpdatedCount += PairUpdated;
            end;
        end;
    end;

    local procedure ParseTableInformationFile(var DataCompression: Codeunit "Data Compression"; EntryName: Text): Integer
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        SheetName: Text;
        TableNoColIdx: Integer;
        TableNoText: Text;
        TableNo: Integer;
    begin
        // Extract the file from ZIP into a blob
        TempBlob.CreateOutStream(OutStr);
        DataCompression.ExtractEntry(EntryName, OutStr);
        TempBlob.CreateInStream(InStr);

        // Read Excel file
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        SheetName := TempExcelBuffer.SelectSheetsNameStream(InStr);
        if SheetName = '' then
            exit(0);

        TempBlob.CreateInStream(InStr);
        TempExcelBuffer.OpenBookStream(InStr, SheetName);
        TempExcelBuffer.ReadSheet();

        // Find "Table No." column in header row (row 1)
        TableNoColIdx := 0;
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", 1);
        if TempExcelBuffer.FindSet() then
            repeat
                if LowerCase(TempExcelBuffer."Cell Value as Text") = 'table no.' then begin
                    TableNoColIdx := TempExcelBuffer."Column No.";
                    break;
                end;
            until TempExcelBuffer.Next() = 0;

        if TableNoColIdx = 0 then
            exit(0);

        // Get value from row 2, same column
        TableNoText := GetCellValueAsText(TempExcelBuffer, 2, TableNoColIdx);
        if Evaluate(TableNo, TableNoText) then
            exit(TableNo);

        exit(0);
    end;

    local procedure ParseIndexesFile(var DataCompression: Codeunit "Data Compression"; EntryName: Text; TableNo: Integer): Integer
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        SheetName: Text;
        ColumnMap: Dictionary of [Text, Integer];
        TotalRows: Integer;
        UpdatedCount: Integer;
    begin
        // Extract the file from ZIP
        TempBlob.CreateOutStream(OutStr);
        DataCompression.ExtractEntry(EntryName, OutStr);
        TempBlob.CreateInStream(InStr);

        // Read Excel file
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        SheetName := TempExcelBuffer.SelectSheetsNameStream(InStr);
        if SheetName = '' then
            exit(0);

        TempBlob.CreateInStream(InStr);
        TempExcelBuffer.OpenBookStream(InStr, SheetName);
        TempExcelBuffer.ReadSheet();

        // Get total rows
        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast() then
            TotalRows := TempExcelBuffer."Row No."
        else
            exit(0);

        if TotalRows <= 1 then
            exit(0);

        // Build column mapping from header row
        BuildColumnMap(TempExcelBuffer, ColumnMap);

        // Process each data row using positional matching
        // Build ordered list of Index Entries for this table
        UpdatedCount := 0;
        UpdatedCount := MatchAndUpdateIndexEntries(TempExcelBuffer, ColumnMap, TotalRows, TableNo);

        exit(UpdatedCount);
    end;

    local procedure BuildColumnMap(var TempExcelBuffer: Record "Excel Buffer" temporary; var ColumnMap: Dictionary of [Text, Integer])
    var
        ColNo: Integer;
        HeaderName: Text;
    begin
        Clear(ColumnMap);
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", 1);
        if TempExcelBuffer.FindSet() then
            repeat
                ColNo := TempExcelBuffer."Column No.";
                HeaderName := LowerCase(TempExcelBuffer."Cell Value as Text");
                if HeaderName <> '' then
                    ColumnMap.Add(HeaderName, ColNo);
            until TempExcelBuffer.Next() = 0;
    end;

    local procedure MatchAndUpdateIndexEntries(var TempExcelBuffer: Record "Excel Buffer" temporary; var ColumnMap: Dictionary of [Text, Integer]; TotalRows: Integer; TableNo: Integer): Integer
    var
        IndexEntry: Record "DTC Index Entry";
        IndexName: Text;
        RowNo: Integer;
        UpdatedCount: Integer;
    begin
        UpdatedCount := 0;

        // For each XLSX data row, try to find the matching Index Entry by AL Key Name
        for RowNo := 2 to TotalRows do begin
            IndexName := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'index name');
            if IndexName <> '' then begin
                IndexEntry.Reset();
                IndexEntry.SetRange("Table ID", TableNo);
                IndexEntry.SetRange("AL Key Name", IndexName);
                if IndexEntry.FindFirst() then begin
                    // Match found: update existing entry
                    IndexEntry.Paired := true;
                    IndexEntry."Created From Pairings" := false;
                    ApplyXlsxDataToIndexEntry(IndexEntry, TempExcelBuffer, ColumnMap, RowNo, IndexName);
                    UpdatedCount += 1;
                end else begin
                    // No match: create a new entry (e.g. non-AL keys like $systemId)
                    CreateIndexEntryFromXlsx(TempExcelBuffer, ColumnMap, RowNo, TableNo, IndexName);
                    UpdatedCount += 1;
                end;
            end;
        end;

        exit(UpdatedCount);
    end;

    local procedure ApplyXlsxDataToIndexEntry(var IndexEntry: Record "DTC Index Entry"; var TempExcelBuffer: Record "Excel Buffer" temporary; var ColumnMap: Dictionary of [Text, Integer]; RowNo: Integer; IndexName: Text)
    var
        CellValue: Text;
        DecValue: Decimal;
        BigIntValue: BigInteger;
        BoolValue: Boolean;
    begin
        // Always populate AL Key Name from XLSX
        IndexEntry."AL Key Name" := CopyStr(IndexName, 1, 250);

        // Update Enabled in Database
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'enabled in database');
        if CellValue <> '' then
            if Evaluate(BoolValue, CellValue) then
                IndexEntry."Enabled in Database" := BoolValue;

        // Update AL Defined
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'al defined');
        if CellValue <> '' then
            if Evaluate(BoolValue, CellValue) then
                IndexEntry."AL Defined" := BoolValue;

        // Update Fragmentation (%)
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'fragmentation (%)');
        if CellValue <> '' then
            if Evaluate(DecValue, CellValue, 9) then
                IndexEntry."Fragmentation %" := DecValue;

        // Update Index Size (kB)
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'index size (kb)');
        if CellValue <> '' then
            if Evaluate(DecValue, CellValue, 9) then
                IndexEntry."Index Size (kB)" := DecValue;

        // Update Seeks
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'seeks');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Seeks" := BigIntValue;

        // Update Scans
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'scans');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Scans" := BigIntValue;

        // Update Lookups
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'lookups');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Lookups" := BigIntValue;

        // Update Updates
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'updates');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Updates" := BigIntValue;

        // Update Last Seek
        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last seek'));
        if CellValue <> '' then
            IndexEntry."Last Seek" := CopyStr(CellValue, 1, 50);

        // Update Last Scan
        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last scan'));
        if CellValue <> '' then
            IndexEntry."Last Scan" := CopyStr(CellValue, 1, 50);

        // Update Last Lookup
        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last lookup'));
        if CellValue <> '' then
            IndexEntry."Last Lookup" := CopyStr(CellValue, 1, 50);

        // Update Last Update
        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last update'));
        if CellValue <> '' then
            IndexEntry."Last Update" := CopyStr(CellValue, 1, 50);

        // Update Statistics Updated At
        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'statistics updated at'));
        if CellValue <> '' then
            IndexEntry."Statistics Updated At" := CopyStr(CellValue, 1, 50);

        IndexEntry.Modify(true);
    end;

    local procedure CreateIndexEntryFromXlsx(var TempExcelBuffer: Record "Excel Buffer" temporary; var ColumnMap: Dictionary of [Text, Integer]; RowNo: Integer; TableNo: Integer; IndexName: Text)
    var
        IndexEntry: Record "DTC Index Entry";
        AllObj: Record AllObjWithCaption;
        TableName: Text[250];
    begin
        // Get table name
        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableNo);
        if AllObj.FindFirst() then
            TableName := AllObj."Object Name"
        else
            TableName := '';

        Clear(IndexEntry);
        IndexEntry.Init();
        IndexEntry."Table ID" := TableNo;
        IndexEntry."Table Name" := TableName;
        IndexEntry."AL Key Name" := CopyStr(IndexName, 1, 250);
        IndexEntry."Created From Pairings" := true;
        IndexEntry.Paired := false;

        // Apply all XLSX data fields
        ApplyXlsxDataToNewEntry(IndexEntry, TempExcelBuffer, ColumnMap, RowNo);

        IndexEntry.Insert(true);
    end;

    local procedure ApplyXlsxDataToNewEntry(var IndexEntry: Record "DTC Index Entry"; var TempExcelBuffer: Record "Excel Buffer" temporary; var ColumnMap: Dictionary of [Text, Integer]; RowNo: Integer)
    var
        CellValue: Text;
        DecValue: Decimal;
        BigIntValue: BigInteger;
        BoolValue: Boolean;
    begin
        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'enabled in database');
        if CellValue <> '' then
            if Evaluate(BoolValue, CellValue) then
                IndexEntry."Enabled in Database" := BoolValue;

        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'al defined');
        if CellValue <> '' then
            if Evaluate(BoolValue, CellValue) then
                IndexEntry."AL Defined" := BoolValue;

        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'fragmentation (%)');
        if CellValue <> '' then
            if Evaluate(DecValue, CellValue, 9) then
                IndexEntry."Fragmentation %" := DecValue;

        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'index size (kb)');
        if CellValue <> '' then
            if Evaluate(DecValue, CellValue, 9) then
                IndexEntry."Index Size (kB)" := DecValue;

        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'seeks');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Seeks" := BigIntValue;

        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'scans');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Scans" := BigIntValue;

        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'lookups');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Lookups" := BigIntValue;

        CellValue := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'updates');
        if CellValue <> '' then
            if Evaluate(BigIntValue, CellValue, 9) then
                IndexEntry."User Updates" := BigIntValue;

        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last seek'));
        if CellValue <> '' then
            IndexEntry."Last Seek" := CopyStr(CellValue, 1, 50);

        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last scan'));
        if CellValue <> '' then
            IndexEntry."Last Scan" := CopyStr(CellValue, 1, 50);

        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last lookup'));
        if CellValue <> '' then
            IndexEntry."Last Lookup" := CopyStr(CellValue, 1, 50);

        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'last update'));
        if CellValue <> '' then
            IndexEntry."Last Update" := CopyStr(CellValue, 1, 50);

        CellValue := CleanDateTimeText(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'statistics updated at'));
        if CellValue <> '' then
            IndexEntry."Statistics Updated At" := CopyStr(CellValue, 1, 50);
    end;

    local procedure CleanDateTimeText(InputValue: Text): Text
    begin
        if InputValue in [
            '0000-01-01T00:00:00Z', '0001-01-01T00:00:00Z', '1753-01-01T00:00:00Z',
            '0000-01-01T00:00:00.000Z', '0001-01-01T00:00:00.000Z', '1753-01-01T00:00:00.000Z',
            '01/01/0001 00:00:00', '01/01/1753 00:00:00',
            '1/1/0001 12:00:00 AM', '1/1/1753 12:00:00 AM'] then
            exit('');
        exit(InputValue);
    end;

    local procedure GetCellValueByHeader(var TempExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; var ColumnMap: Dictionary of [Text, Integer]; HeaderName: Text): Text
    var
        ColNo: Integer;
    begin
        if ColumnMap.ContainsKey(HeaderName) then begin
            ColNo := ColumnMap.Get(HeaderName);
            exit(GetCellValueAsText(TempExcelBuffer, RowNo, ColNo));
        end;
        exit('');
    end;

    local procedure GetCellValueAsText(var TempExcelBuffer: Record "Excel Buffer" temporary; RowNo: Integer; ColNo: Integer): Text
    var
        InStr: InStream;
        CellValue: Text;
        Line: Text;
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", RowNo);
        TempExcelBuffer.SetRange("Column No.", ColNo);
        if TempExcelBuffer.FindFirst() then begin
            TempExcelBuffer.CalcFields("Cell Value as Blob");
            if TempExcelBuffer."Cell Value as Blob".HasValue() then begin
                TempExcelBuffer."Cell Value as Blob".CreateInStream(InStr, TextEncoding::UTF8);
                CellValue := '';
                while not InStr.EOS do begin
                    InStr.ReadText(Line);
                    if CellValue <> '' then
                        CellValue += ' ';
                    CellValue += Line;
                end;
                exit(CellValue);
            end;
            exit(TempExcelBuffer."Cell Value as Text");
        end;
        exit('');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Excel Buffer", OnBeforeParseCellValue, '', false, false)]
    local procedure HandleBeforeParseCellValue(var ExcelBuffer: Record "Excel Buffer"; var Value: Text; var FormatString: Text; var IsHandled: Boolean)
    var
        LowerFormat: Text;
        OADate: Decimal;
        DaysFromBase: Integer;
        TimeFraction: Decimal;
        DatePart: Date;
        TimePart: Time;
        TimeMs: Integer;
    begin
        LowerFormat := LowerCase(FormatString);
        // Only handle formats that contain date indicators (year)
        if not LowerFormat.Contains('y') then
            exit;

        // Value is the raw OLE serial date number (e.g. "45714.604")
        if not Evaluate(OADate, Value, 9) then
            exit;

        // Skip zero/near-zero values (null dates)
        if OADate < 1 then
            exit;

        // Convert OLE Automation date to AL DateTime
        DaysFromBase := Round(OADate, 1, '<');
        TimeFraction := OADate - DaysFromBase;
        DatePart := DMY2Date(30, 12, 1899) + DaysFromBase;
        TimeMs := Round(TimeFraction * 86400000, 1);
        TimePart := 000000T + TimeMs;

        ExcelBuffer."Cell Value as Text" := CopyStr(Format(CreateDateTime(DatePart, TimePart)), 1, 250);
        ExcelBuffer."Cell Type" := ExcelBuffer."Cell Type"::Date;
        IsHandled := true;
    end;
}
