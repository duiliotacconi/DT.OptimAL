namespace DefaultNamespace;

using System.IO;
using System.Reflection;
using System.Utilities;

codeunit 50920 "LRQ Management"
{
    /// <summary>
    /// Main entry point for importing LRQ data and populating all related tables.
    /// Asks user whether to delete all data or continue from where left off.
    /// </summary>
    procedure ImportLRQAndPopulateAll()
    var
        LRQEntry: Record "LRQ Entry";
        LRQFlowFieldEntry: Record "LRQ FlowField Entry";
        TableIndex: Record "Table Index";
        IndexEntry: Record "Index Entry";
        VSIFTEntry: Record "VSIFT Entry";
        VSIFTDetail: Record "VSIFT Detail";
        SelectionChoice: Integer;
        DeleteAllLbl: Label 'Delete all and start fresh';
        ContinueLbl: Label 'Continue (keep existing data)';
        CancelLbl: Label 'Cancel';
        TotalImported: Integer;
        TotalTablesProcessed: Integer;
        TotalVSIFTProcessed: Integer;
        SuccessMsg: Label 'Import completed:\- %1 LRQ entries imported\- %2 tables processed for indexes\- %3 tables processed for VSIFT', Comment = '%1 = LRQ count, %2 = Table count, %3 = VSIFT count';
    begin
        // Step 1: Ask user what to do with existing data
        SelectionChoice := StrMenu(
            DeleteAllLbl + ',' + ContinueLbl + ',' + CancelLbl,
            1,
            'How would you like to proceed?');

        case SelectionChoice of
            1: // Delete all and start fresh
                begin
                    if not Confirm('This will delete ALL existing data in LRQ Entry, Table Index, Index Entry, VSIFT Entry, and VSIFT Detail tables. Continue?') then
                        exit;

                    // Truncate all related tables
                    LRQFlowFieldEntry.Truncate();
                    LRQEntry.Truncate();
                    TableIndex.Truncate();
                    IndexEntry.Truncate();
                    VSIFTDetail.Truncate();
                    VSIFTEntry.Truncate();
                    Commit();
                end;
            2: // Continue with existing data
                ; // Do nothing, just proceed
            else // Cancel or closed
                exit;
        end;

        // Step 2: Import Excel file to LRQ Entry table
        TotalImported := ImportFromExcel();
        if TotalImported = 0 then
            exit; // No data imported or user cancelled

        Commit();

        // Step 3: Populate Table Index and Index Entry for tables found in LRQ
        TotalTablesProcessed := PopulateIndexDataFromLRQ();
        Commit();

        // Step 4: Populate VSIFT data for tables found in LRQ
        TotalVSIFTProcessed := PopulateVSIFTDataFromLRQ();
        Commit();

        // Show success message
        Message(SuccessMsg, TotalImported, TotalTablesProcessed, TotalVSIFTProcessed);
    end;

    /// <summary>
    /// Imports LRQ data from Excel file. Returns the number of entries imported.
    /// </summary>
    procedure ImportFromExcel(): Integer
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        LRQEntry: Record "LRQ Entry";
        ColumnMap: Dictionary of [Text, Integer];
        InStr: InStream;
        FileName: Text;
        SheetName: Text;
        RowNo: Integer;
        TotalRows: Integer;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Importing Long Running Queries...\Row: #1#### of #2####';
        NoDataErr: Label 'No data found in the Excel file.';
        SelectFileLbl: Label 'Select Long Running Queries Excel file';
    begin
        // Upload Excel file
        if not UploadIntoStream(SelectFileLbl, '', 'Excel Files (*.xlsx)|*.xlsx', FileName, InStr) then
            exit(0);

        // Read Excel file into buffer
        TempExcelBuffer.Reset();
        TempExcelBuffer.DeleteAll();
        SheetName := TempExcelBuffer.SelectSheetsNameStream(InStr);
        if SheetName = '' then
            exit(0);

        TempExcelBuffer.OpenBookStream(InStr, SheetName);
        TempExcelBuffer.ReadSheet();

        // Get total rows (excluding header)
        TempExcelBuffer.Reset();
        if TempExcelBuffer.FindLast() then
            TotalRows := TempExcelBuffer."Row No." - 1 // Exclude header row
        else
            Error(NoDataErr);

        if TotalRows <= 0 then
            Error(NoDataErr);

        // Read header row and build column mapping
        BuildColumnMap(TempExcelBuffer, ColumnMap);

        // Process each row (starting from row 2 to skip header)
        ProgressDialog.Open(ProgressMsg);
        for RowNo := 2 to TotalRows + 1 do begin
            ProgressDialog.Update(1, RowNo - 1);
            ProgressDialog.Update(2, TotalRows);

            CreateLRQEntryFromExcelRow(TempExcelBuffer, LRQEntry, RowNo, ColumnMap);
        end;
        ProgressDialog.Close();

        exit(TotalRows);
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

    /// <summary>
    /// Populates Table Index and Index Entry tables based on unique tables found in LRQ Entry.
    /// Skips tables that already exist in Table Index.
    /// </summary>
    local procedure PopulateIndexDataFromLRQ(): Integer
    var
        LRQEntry: Record "LRQ Entry";
        TableIndex: Record "Table Index";
        IndexEntry: Record "Index Entry";
        TableMetadata: Record "Table Metadata";
        KeyMetadata: Record "Key";
        AllObj: Record AllObjWithCaption;
        ProcessedTables: List of [Integer];
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Processing Index Data from LRQ...\Table: #1######## #2##############################';
        RecordCount: Integer;
        IndexCount: Integer;
        VSIFTCount: Integer;
        IncludedCount: Integer;
        SIFTFieldsCount: Integer;
        TableID: Integer;
        TablesProcessed: Integer;
    begin
        TablesProcessed := 0;

        // Get distinct Table IDs from LRQ Entry
        LRQEntry.Reset();
        LRQEntry.SetFilter("Table ID", '>0'); // Only valid table IDs
        LRQEntry.SetCurrentKey("Table ID");
        if not LRQEntry.FindSet() then
            exit(0);

        ProgressDialog.Open(ProgressMsg);

        repeat
            TableID := LRQEntry."Table ID";

            // Skip if already processed in this run
            if ProcessedTables.Contains(TableID) then begin
                LRQEntry.SetFilter("Table ID", '>%1', TableID);
                if not LRQEntry.FindFirst() then
                    break;
            end else begin
                // Skip if table already exists in Table Index
                if not TableIndex.Get(TableID) then begin
                    // Process this table
                    TableMetadata.Reset();
                    TableMetadata.SetRange(ID, TableID);
                    if TableMetadata.FindFirst() then begin
                        AllObj.Reset();
                        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
                        AllObj.SetRange("Object ID", TableID);
                        if AllObj.FindFirst() then begin
                            ProgressDialog.Update(1, TableID);
                            ProgressDialog.Update(2, AllObj."Object Name");

                            RecordCount := GetTableRecordCount(TableID);
                            if RecordCount < 0 then
                                RecordCount := 0;

                            // Reset counters
                            IndexCount := 0;
                            VSIFTCount := 0;
                            IncludedCount := 0;
                            SIFTFieldsCount := 0;

                            // Find all keys for the table
                            KeyMetadata.Reset();
                            KeyMetadata.SetRange(TableNo, TableID);
                            if KeyMetadata.FindSet() then
                                repeat
                                    CreateIndexEntry(IndexEntry, KeyMetadata, AllObj."Object Name", RecordCount);

                                    // Count for Table Index (only enabled indexes)
                                    if KeyMetadata.Enabled then begin
                                        IndexCount += 1;
                                        if KeyMetadata.MaintainSIFTIndex and (KeyMetadata.SumIndexFields <> '') then
                                            VSIFTCount += 1;
                                        if KeyMetadata.SumIndexFields <> '' then
                                            SIFTFieldsCount += 1;
                                        if GetIncludedColumns(KeyMetadata) <> '' then
                                            IncludedCount += 1;
                                    end;
                                until KeyMetadata.Next() = 0;

                            // Create Table Index entry
                            CreateTableIndex(TableIndex, TableID, AllObj."Object Name", IndexCount, VSIFTCount, IncludedCount, SIFTFieldsCount, RecordCount);
                            TablesProcessed += 1;
                        end;
                    end;
                end;

                ProcessedTables.Add(TableID);

                // Move to next distinct Table ID
                LRQEntry.SetFilter("Table ID", '>%1', TableID);
                if not LRQEntry.FindFirst() then
                    break;
            end;
        until false;

        ProgressDialog.Close();
        exit(TablesProcessed);
    end;

    /// <summary>
    /// Populates VSIFT Entry and VSIFT Detail tables based on unique tables found in LRQ Entry.
    /// Skips tables that already have VSIFT entries.
    /// </summary>
    local procedure PopulateVSIFTDataFromLRQ(): Integer
    var
        LRQEntry: Record "LRQ Entry";
        VSIFTEntry: Record "VSIFT Entry";
        VSIFTMgt: Codeunit "VSIFT Management";
        ProcessedTables: List of [Integer];
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Processing VSIFT Data from LRQ...\Table: #1########';
        TableID: Integer;
        TablesProcessed: Integer;
    begin
        TablesProcessed := 0;

        // Get distinct Table IDs from LRQ Entry
        LRQEntry.Reset();
        LRQEntry.SetFilter("Table ID", '>0'); // Only valid table IDs
        LRQEntry.SetCurrentKey("Table ID");
        if not LRQEntry.FindSet() then
            exit(0);

        ProgressDialog.Open(ProgressMsg);

        repeat
            TableID := LRQEntry."Table ID";

            // Skip if already processed in this run
            if ProcessedTables.Contains(TableID) then begin
                LRQEntry.SetFilter("Table ID", '>%1', TableID);
                if not LRQEntry.FindFirst() then
                    break;
            end else begin
                // Skip if table already has VSIFT entries
                VSIFTEntry.Reset();
                VSIFTEntry.SetRange("Table ID", TableID);
                if VSIFTEntry.IsEmpty() then begin
                    ProgressDialog.Update(1, TableID);
                    VSIFTMgt.CollectVSIFTDataForTable(TableID);
                    TablesProcessed += 1;
                end;

                ProcessedTables.Add(TableID);

                // Move to next distinct Table ID
                LRQEntry.SetFilter("Table ID", '>%1', TableID);
                if not LRQEntry.FindFirst() then
                    break;
            end;
        until false;

        ProgressDialog.Close();
        exit(TablesProcessed);
    end;

    local procedure GetTableRecordCount(TableID: Integer): Integer
    var
        RecordCount: Integer;
    begin
        if not TryGetRecordCount(TableID, RecordCount) then
            exit(-1);
        exit(RecordCount);
    end;

    [TryFunction]
    local procedure TryGetRecordCount(TableID: Integer; var RecordCount: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableID);
        RecordCount := RecRef.Count();
        RecRef.Close();
    end;

    local procedure CreateTableIndex(var TableIndex: Record "Table Index"; TableID: Integer; TableName: Text[250]; IndexCount: Integer; VSIFTCount: Integer; IncludedCount: Integer; SIFTFieldsCount: Integer; RecordCount: Integer)
    begin
        Clear(TableIndex);
        TableIndex.Init();
        TableIndex."Table ID" := TableID;
        TableIndex."Table Name" := TableName;
        TableIndex."No. of Indexes" := IndexCount;
        TableIndex."No. of VSIFT Indexes" := VSIFTCount;
        TableIndex."No. of Indexes with Included" := IncludedCount;
        TableIndex."No. of Indexes with SIFT" := SIFTFieldsCount;
        TableIndex."Total Record Count" := RecordCount;
        TableIndex.Insert(true);
    end;

    local procedure CreateIndexEntry(var IndexEntry: Record "Index Entry"; KeyMetadata: Record "Key"; TableName: Text[250]; RecordCount: Integer)
    var
        IncludedColumns: Text;
    begin
        Clear(IndexEntry);
        IndexEntry.Init();
        IndexEntry."Table ID" := KeyMetadata.TableNo;
        IndexEntry."Table Name" := TableName;
        IndexEntry."Key Index" := KeyMetadata."No.";

        // Key Fields
        IndexEntry."Key Fields" := CopyStr(KeyMetadata."Key", 1, 500);
        IndexEntry."No. of Key Fields" := CountFieldsInList(KeyMetadata."Key");

        // SQL Index
        IndexEntry."SQL Index" := CopyStr(KeyMetadata.SQLIndex, 1, 500);

        // Included Columns
        IncludedColumns := GetIncludedColumns(KeyMetadata);
        IndexEntry."Included Columns" := CopyStr(IncludedColumns, 1, 500);
        IndexEntry."No. of Included Columns" := CountFieldsInList(IncludedColumns);

        // Clustered property
        IndexEntry.Clustered := KeyMetadata.Clustered;

        // SIFT properties
        IndexEntry."Maintain SIFT Index" := KeyMetadata.MaintainSIFTIndex;
        if KeyMetadata.SumIndexFields <> '' then begin
            IndexEntry."SIFT Fields" := CopyStr(GetFieldNamesFromNumbers(KeyMetadata.TableNo, KeyMetadata.SumIndexFields), 1, 500);
            if IndexEntry."SIFT Fields" = '' then
                IndexEntry."SIFT Fields" := CopyStr(KeyMetadata.SumIndexFields, 1, 500);
        end;

        // Other properties
        IndexEntry.Unique := KeyMetadata.Unique;
        IndexEntry.Enabled := KeyMetadata.Enabled;

        // Record count
        IndexEntry."Total Record Count" := RecordCount;

        IndexEntry.Insert(true);
    end;

    local procedure GetIncludedColumns(KeyMetadata: Record "Key"): Text
    var
        KeyFields: List of [Text];
        SQLFields: List of [Text];
        IncludedColumns: Text;
        SQLField: Text;
    begin
        if KeyMetadata.SQLIndex = '' then
            exit('');

        // Parse key fields and SQL index fields
        ParseFieldListToList(KeyMetadata."Key", KeyFields);
        ParseFieldListToList(KeyMetadata.SQLIndex, SQLFields);

        // Find fields in SQLIndex that are not in Key
        foreach SQLField in SQLFields do begin
            if not KeyFields.Contains(SQLField) then begin
                if IncludedColumns <> '' then
                    IncludedColumns += ', ';
                IncludedColumns += SQLField;
            end;
        end;

        exit(IncludedColumns);
    end;

    local procedure ParseFieldListToList(FieldListText: Text; var FieldList: List of [Text])
    var
        FieldName: Text;
        CommaPos: Integer;
    begin
        Clear(FieldList);
        if FieldListText = '' then
            exit;

        while FieldListText <> '' do begin
            CommaPos := StrPos(FieldListText, ',');
            if CommaPos > 0 then begin
                FieldName := CopyStr(FieldListText, 1, CommaPos - 1);
                FieldListText := CopyStr(FieldListText, CommaPos + 1);
            end else begin
                FieldName := FieldListText;
                FieldListText := '';
            end;
            FieldName := DelChr(FieldName, '<>', ' ');
            if FieldName <> '' then
                FieldList.Add(FieldName);
        end;
    end;

    local procedure GetFieldNamesFromNumbers(TableNo: Integer; FieldNumbers: Text): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        FieldNums: List of [Text];
        FieldNames: Text;
        FieldNumText: Text;
        FieldNum: Integer;
    begin
        if not TryOpenRecRef(TableNo, RecRef) then
            exit('');

        ParseFieldListToList(FieldNumbers, FieldNums);
        foreach FieldNumText in FieldNums do begin
            if Evaluate(FieldNum, FieldNumText) then begin
                if TryGetFieldRef(RecRef, FieldNum, FldRef) then begin
                    if FieldNames <> '' then
                        FieldNames += ', ';
                    FieldNames += FldRef.Name;
                end;
            end;
        end;

        RecRef.Close();
        exit(FieldNames);
    end;

    [TryFunction]
    local procedure TryGetFieldRef(var RecRef: RecordRef; FieldNo: Integer; var FldRef: FieldRef)
    begin
        FldRef := RecRef.Field(FieldNo);
    end;

    local procedure CreateLRQEntryFromExcelRow(var TempExcelBuffer: Record "Excel Buffer" temporary; var LRQEntry: Record "LRQ Entry"; RowNo: Integer; var ColumnMap: Dictionary of [Text, Integer])
    var
        LRQSQLParser: Codeunit "LRQ SQL Parser";
        SQLStatement: Text;
        IsolationLevelText: Text;
        EqualityFieldsJson: Text;
        InequalityFieldsJson: Text;
        OccurrenceCount: Integer;
        AvgDurationMs: Decimal;
        TotalDurationMs: Decimal;
        PercentageValue: Decimal;
    begin
        // Read values from Excel - KQL has already processed these
        SQLStatement := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'sqlstatement');

        // Read isolation level from Excel (calculated in KQL)
        IsolationLevelText := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'isolationlevel');

        // Read equality/inequality fields from Excel (calculated in KQL as JSON arrays)
        EqualityFieldsJson := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'equalityfields');
        InequalityFieldsJson := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'inequalityfields');

        // Read statistics that are calculated in KQL (keep these from Excel)
        Evaluate(OccurrenceCount, GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'occurrence'));
        Evaluate(AvgDurationMs, GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'avgduration'));
        Evaluate(TotalDurationMs, GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'totalduration'));
        Evaluate(PercentageValue, GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'percentage'));

        // Create the LRQ Entry
        Clear(LRQEntry);
        LRQEntry.Init();

        // Store original SQL statement (as-is from import)
        LRQEntry.SetOriginalSQLStatement(SQLStatement);

        // Use parser to extract table name, flowfield count, join count from SQL
        LRQSQLParser.ParseSQLStatement(LRQEntry, SQLStatement);

        // Override with values from Excel (more reliable - calculated in KQL)
        LRQEntry."Isolation Level" := ParseIsolationLevel(IsolationLevelText);

        // Parse JSON array format ["field1","field2"] to comma-separated list
        LRQEntry."Equality Fields" := CopyStr(ParseJsonArrayToFieldList(EqualityFieldsJson), 1, 1000);
        LRQEntry."Inequality Fields" := CopyStr(ParseJsonArrayToFieldList(InequalityFieldsJson), 1, 1000);
        LRQEntry."No. of Equality Fields" := CountFieldsInList(LRQEntry."Equality Fields");
        LRQEntry."No. of Inequality Fields" := CountFieldsInList(LRQEntry."Inequality Fields");

        // Match SQL table name to AL table
        MatchTableName(LRQEntry, LRQEntry."SQL Table Name");

        // Transform field names from SQL format to AL format
        if LRQEntry."Table ID" > 0 then begin
            LRQEntry."Equality Fields" := CopyStr(CleanupFieldList(TransformFieldNames(LRQEntry."Table ID", LRQEntry."Equality Fields")), 1, 1000);
            LRQEntry."Inequality Fields" := CopyStr(CleanupFieldList(TransformFieldNames(LRQEntry."Table ID", LRQEntry."Inequality Fields")), 1, 1000);
            LRQEntry."No. of Equality Fields" := CountFieldsInList(LRQEntry."Equality Fields");
            LRQEntry."No. of Inequality Fields" := CountFieldsInList(LRQEntry."Inequality Fields");
        end;

        // Set statistics from Excel (these are aggregated values)
        LRQEntry.Occurrence := OccurrenceCount;
        LRQEntry."Average Duration" := Round(AvgDurationMs, 1);
        LRQEntry."Total Duration" := Round(TotalDurationMs, 1);
        LRQEntry.Percentage := Round(PercentageValue / 100, 0.01);

        // Set Query Type based on FlowFields count
        if LRQEntry."No. of FlowFields" > 0 then
            LRQEntry."Query Type" := 'Query with FF'
        else
            LRQEntry."Query Type" := 'Query';

        // Generate prettified SQL
        LRQEntry.SetPrettifiedSQL(LRQSQLParser.PrettifySQL(SQLStatement));

        // Store working SQL statement (same as original for main query)
        LRQEntry.SetSQLStatement(SQLStatement);

        LRQEntry.Insert(true);

        // Create FlowField subquery entries if there are OUTER APPLY clauses
        if LRQEntry."No. of FlowFields" > 0 then
            LRQSQLParser.CreateFlowFieldEntries(LRQEntry, SQLStatement);
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
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
        CellValue: Text;
    begin
        TempExcelBuffer.Reset();
        TempExcelBuffer.SetRange("Row No.", RowNo);
        TempExcelBuffer.SetRange("Column No.", ColNo);
        if TempExcelBuffer.FindFirst() then begin
            // First check if there's a Blob value (for large text that exceeds 250 chars)
            TempExcelBuffer.CalcFields("Cell Value as Blob");
            if TempExcelBuffer."Cell Value as Blob".HasValue() then begin
                TempExcelBuffer."Cell Value as Blob".CreateInStream(InStr, TextEncoding::UTF8);
                CellValue := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
                exit(CellValue);
            end;
            // Fall back to the standard text field
            exit(TempExcelBuffer."Cell Value as Text");
        end;
        exit('');
    end;

    local procedure ParseIsolationLevel(IsolationLevelText: Text): Enum "Isolation Level"
    begin
        case UpperCase(DelChr(IsolationLevelText, '=', ' ')) of
            'UPDLOCK':
                exit("Isolation Level"::UpdLock);
            'READCOMMITTED':
                exit("Isolation Level"::ReadCommitted);
            'READUNCOMMITTED':
                exit("Isolation Level"::ReadUncommitted);
            'REPEATABLEREAD':
                exit("Isolation Level"::RepeatableRead);
            else
                exit("Isolation Level"::Default);
        end;
    end;

    /// <summary>
    /// Parses JSON array format ["field1","field2"] to comma-separated list "field1,field2"
    /// </summary>
    local procedure ParseJsonArrayToFieldList(JsonArray: Text): Text
    var
        FieldList: Text;
        FieldName: Text;
        i: Integer;
        InQuote: Boolean;
        c: Char;
    begin
        // Handle empty or [] case
        if (JsonArray = '') or (JsonArray = '[]') then
            exit('');

        // Remove brackets
        JsonArray := DelChr(JsonArray, '=', '[]');

        // Parse quoted strings separated by commas
        InQuote := false;
        FieldName := '';

        for i := 1 to StrLen(JsonArray) do begin
            c := JsonArray[i];

            if c = '"' then begin
                if InQuote then begin
                    // End of field name
                    if FieldName <> '' then begin
                        if FieldList <> '' then
                            FieldList += ',';
                        FieldList += FieldName;
                    end;
                    FieldName := '';
                    InQuote := false;
                end else
                    InQuote := true;
            end else if InQuote then
                    FieldName += Format(c);
        end;

        exit(FieldList);
    end;

    local procedure MatchTableName(var LRQEntry: Record "LRQ Entry"; SQLTableName: Text)
    var
        AllObj: Record AllObjWithCaption;
        NormalizedSQLName: Text;
        NormalizedALName: Text;
    begin
        // Normalize SQL table name for comparison
        // SQL uses _ for special characters: ."\'/%][
        NormalizedSQLName := NormalizeNameForComparison(SQLTableName);

        // Loop through all tables and find matching one by normalized name comparison
        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        if AllObj.FindSet() then
            repeat
                NormalizedALName := NormalizeNameForComparison(AllObj."Object Name");
                if NormalizedSQLName = NormalizedALName then begin
                    LRQEntry."Table ID" := AllObj."Object ID";
                    LRQEntry."AL Table Name" := AllObj."Object Name";
                    exit;
                end;
            until AllObj.Next() = 0;
    end;

    local procedure NormalizeNameForComparison(Name: Text): Text
    var
        NormalizedName: Text;
    begin
        // Remove company prefix if present (e.g., "CRONUS_International_Ltd_$")
        if StrPos(Name, '$') > 0 then
            Name := CopyStr(Name, StrPos(Name, '$') + 1);

        // Remove trailing $xxx extensions (like $437f4ee7-bb19-4cb6-bf1b-1bafffe1cf67)
        if StrPos(Name, '$') > 0 then
            Name := CopyStr(Name, 1, StrPos(Name, '$') - 1);

        // Convert to uppercase and remove all special characters that underscore can represent
        // Special characters: . " \ / ' % ] [
        // Also remove underscores and spaces for normalized comparison
        NormalizedName := UpperCase(Name);
        NormalizedName := DelChr(NormalizedName, '=', '."\/''"%][ _');

        exit(NormalizedName);
    end;



    local procedure TransformFieldNames(TableID: Integer; SQLFieldList: Text): Text
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        FieldList: List of [Text];
        ALFieldList: Text;
        SQLFieldName: Text;
        ALFieldName: Text;
        i: Integer;
    begin
        if (TableID = 0) or (SQLFieldList = '') then
            exit(SQLFieldList);

        // Parse the comma-separated list of SQL field names
        ParseFieldList(SQLFieldList, FieldList);

        if not TryOpenRecRef(TableID, RecRef) then
            exit(SQLFieldList);

        ALFieldList := '';
        foreach SQLFieldName in FieldList do begin
            // Try to match the SQL field name to an AL field
            ALFieldName := FindALFieldName(RecRef, SQLFieldName);

            if ALFieldList <> '' then
                ALFieldList += ', ';

            if ALFieldName <> '' then
                ALFieldList += ALFieldName
            else
                ALFieldList += SQLFieldName; // Keep original if no match found
        end;

        RecRef.Close();
        exit(ALFieldList);
    end;

    [TryFunction]
    local procedure TryOpenRecRef(TableID: Integer; var RecRef: RecordRef)
    begin
        RecRef.Open(TableID);
    end;

    local procedure FindALFieldName(var RecRef: RecordRef; SQLFieldName: Text): Text
    var
        FldRef: FieldRef;
        i: Integer;
        FieldCount: Integer;
        NormalizedSQLName: Text;
        NormalizedALName: Text;
    begin
        // Remove square brackets and quotes if present
        SQLFieldName := DelChr(SQLFieldName, '=', '[]"');

        // Normalize SQL field name for comparison
        // SQL uses _ for special characters: ."\'/%][
        NormalizedSQLName := NormalizeNameForComparison(SQLFieldName);

        FieldCount := RecRef.FieldCount();
        for i := 1 to FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            NormalizedALName := NormalizeNameForComparison(FldRef.Name);

            if NormalizedSQLName = NormalizedALName then
                exit(FldRef.Name);
        end;

        exit('');
    end;



    local procedure ParseFieldList(FieldList: Text; var FieldNames: List of [Text])
    var
        FieldName: Text;
        CommaPos: Integer;
    begin
        Clear(FieldNames);
        if FieldList = '' then
            exit;

        // Remove square brackets from the field list (e.g., ["Field1","Field2"] -> Field1,Field2)
        FieldList := DelChr(FieldList, '=', '[]"');

        // Handle different separators (comma, semicolon, newline)
        FieldList := FieldList.Replace(';', ',');
        FieldList := FieldList.Replace('\n', ',');

        while FieldList <> '' do begin
            CommaPos := StrPos(FieldList, ',');
            if CommaPos > 0 then begin
                FieldName := CopyStr(FieldList, 1, CommaPos - 1);
                FieldList := CopyStr(FieldList, CommaPos + 1);
            end else begin
                FieldName := FieldList;
                FieldList := '';
            end;

            // Trim spaces and remove any remaining quotes
            FieldName := DelChr(FieldName, '<>', ' ');
            FieldName := DelChr(FieldName, '=', '"''');
            if FieldName <> '' then
                FieldNames.Add(FieldName);
        end;
    end;

    local procedure CountFieldsInList(FieldList: Text): Integer
    var
        FieldCount: Integer;
        i: Integer;
    begin
        if FieldList = '' then
            exit(0);

        FieldCount := 1;
        for i := 1 to StrLen(FieldList) do begin
            if FieldList[i] = ',' then
                FieldCount += 1;
        end;
        exit(FieldCount);
    end;

    local procedure CleanupFieldList(FieldList: Text): Text
    var
        CleanedList: Text;
    begin
        // Remove square brackets, quotes, and trim
        CleanedList := DelChr(FieldList, '=', '[]"''');
        CleanedList := DelChr(CleanedList, '<>', ' ');

        // If the result is empty or just whitespace/commas, return empty
        CleanedList := DelChr(CleanedList, '=', ' ');
        if CleanedList = '' then
            exit('');

        // Check if it's just commas (no actual field names)
        if DelChr(CleanedList, '=', ',') = '' then
            exit('');

        exit(DelChr(FieldList, '=', '[]"'''));
    end;
}
