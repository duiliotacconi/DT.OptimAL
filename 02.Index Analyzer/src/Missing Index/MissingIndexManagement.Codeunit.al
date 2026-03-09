namespace DefaultNamespace;

using System.IO;
using System.Reflection;

codeunit 50925 "Missing Index Management"
{
    /// <summary>
    /// Imports missing index data from Excel file.
    /// </summary>
    procedure ImportFromExcel(): Integer
    var
        TempExcelBuffer: Record "Excel Buffer" temporary;
        MissingIndex: Record "Missing Index";
        ColumnMap: Dictionary of [Text, Integer];
        InStr: InStream;
        FileName: Text;
        SheetName: Text;
        RowNo: Integer;
        TotalRows: Integer;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Importing Missing Indexes...\Row: #1#### of #2####';
        NoDataErr: Label 'No data found in the Excel file.';
        SelectFileLbl: Label 'Select Missing Indexes Excel file';
        SelectionChoice: Integer;
        DeleteAllLbl: Label 'Delete all and start fresh';
        ContinueLbl: Label 'Continue (keep existing data)';
        CancelLbl: Label 'Cancel';
    begin
        // Step 1: Ask user what to do with existing data
        MissingIndex.Reset();
        if not MissingIndex.IsEmpty() then begin
            SelectionChoice := StrMenu(
                DeleteAllLbl + ',' + ContinueLbl + ',' + CancelLbl,
                1,
                'Existing data found. How would you like to proceed?');

            case SelectionChoice of
                1: // Delete all and start fresh
                    begin
                        if not Confirm('This will delete ALL existing missing index entries. Continue?') then
                            exit(0);
                        MissingIndex.Truncate();
                        Commit();
                    end;
                2: // Continue with existing data
                    ; // Do nothing, just proceed
                else // Cancel or closed
                    exit(0);
            end;
        end;

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

            CreateMissingIndexFromExcelRow(TempExcelBuffer, MissingIndex, RowNo, ColumnMap);
        end;
        ProgressDialog.Close();

        Message('%1 missing index entries imported.', TotalRows);
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
                // Normalize header names - remove spaces
                HeaderName := DelChr(HeaderName, '=', ' ');
                if HeaderName <> '' then
                    ColumnMap.Add(HeaderName, ColNo);
            until TempExcelBuffer.Next() = 0;
    end;

    local procedure CreateMissingIndexFromExcelRow(var TempExcelBuffer: Record "Excel Buffer" temporary; var MissingIndex: Record "Missing Index"; RowNo: Integer; var ColumnMap: Dictionary of [Text, Integer])
    var
        SQLTableName: Text[250];
        ExtensionIdText: Text;
        EqualityFieldsRaw: Text;
        InequalityFieldsRaw: Text;
        IncludeFieldsRaw: Text;
        SeeksValue: Integer;
        ScansValue: Integer;
        AvgTotalCost: Decimal;
        AvgImpact: Decimal;
        EstimatedBenefit: Decimal;
    begin
        // Read values from Excel columns using dynamic column mapping
        SQLTableName := CopyStr(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'tablename'), 1, 250);
        ExtensionIdText := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'extensionid');
        EqualityFieldsRaw := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'indexequalitycolumns');
        InequalityFieldsRaw := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'indexinequalitycolumns');
        IncludeFieldsRaw := GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'indexincludecolumns');
        Evaluate(SeeksValue, GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'seeks'));
        Evaluate(ScansValue, GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'scans'));
        Evaluate(AvgTotalCost, ParseDecimalValue(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'averagetotalcost')));
        Evaluate(AvgImpact, ParseDecimalValue(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'averageimpact')));
        Evaluate(EstimatedBenefit, ParseDecimalValue(GetCellValueByHeader(TempExcelBuffer, RowNo, ColumnMap, 'estimatedbenefit')));

        // Create the Missing Index entry
        Clear(MissingIndex);
        MissingIndex.Init();
        MissingIndex."SQL Table Name" := SQLTableName;

        // Parse Extension Id
        if ExtensionIdText <> '' then
            Evaluate(MissingIndex."Extension Id", ExtensionIdText);

        MissingIndex.Seeks := SeeksValue;
        MissingIndex.Scans := ScansValue;
        MissingIndex."Average Total Cost" := AvgTotalCost;
        MissingIndex."Average Impact" := AvgImpact;
        MissingIndex."Estimated Benefit" := EstimatedBenefit;

        // Match SQL table name to AL table
        MatchTableName(MissingIndex, SQLTableName);

        // Transform field names from SQL to AL format
        if MissingIndex."Table ID" > 0 then begin
            MissingIndex."Equality Fields" := CopyStr(CleanupFieldList(TransformFieldNames(MissingIndex."Table ID", EqualityFieldsRaw)), 1, 1000);
            MissingIndex."Inequality Fields" := CopyStr(CleanupFieldList(TransformFieldNames(MissingIndex."Table ID", InequalityFieldsRaw)), 1, 1000);
            MissingIndex."Include Fields" := CopyStr(CleanupFieldList(TransformFieldNames(MissingIndex."Table ID", IncludeFieldsRaw)), 1, 1000);
        end else begin
            MissingIndex."Equality Fields" := CopyStr(CleanupFieldList(EqualityFieldsRaw), 1, 1000);
            MissingIndex."Inequality Fields" := CopyStr(CleanupFieldList(InequalityFieldsRaw), 1, 1000);
            MissingIndex."Include Fields" := CopyStr(CleanupFieldList(IncludeFieldsRaw), 1, 1000);
        end;

        MissingIndex."No. of Equality Fields" := CountFieldsInList(MissingIndex."Equality Fields");
        MissingIndex."No. of Inequality Fields" := CountFieldsInList(MissingIndex."Inequality Fields");
        MissingIndex."No. of Include Fields" := CountFieldsInList(MissingIndex."Include Fields");

        MissingIndex.Insert(true);
    end;

    local procedure ParseDecimalValue(Value: Text): Text
    begin
        // Remove thousand separators (comma) and handle European format
        Value := DelChr(Value, '=', ',');
        exit(Value);
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
            TempExcelBuffer.CalcFields("Cell Value as Blob");
            if TempExcelBuffer."Cell Value as Blob".HasValue() then begin
                TempExcelBuffer."Cell Value as Blob".CreateInStream(InStr, TextEncoding::UTF8);
                CellValue := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
                exit(CellValue);
            end;
            exit(TempExcelBuffer."Cell Value as Text");
        end;
        exit('');
    end;

    local procedure MatchTableName(var MissingIndex: Record "Missing Index"; SQLTableName: Text)
    var
        AllObj: Record AllObjWithCaption;
        NormalizedSQLName: Text;
        NormalizedALName: Text;
        ExtractedTableName: Text;
        VSIFTKey: Integer;
        IsVSIFT: Boolean;
    begin
        // Check if this is a VSIFT table and extract the real table name
        ExtractedTableName := ExtractTableNameFromVSIFT(SQLTableName, IsVSIFT, VSIFTKey);
        MissingIndex."Is VSIFT" := IsVSIFT;
        MissingIndex."VSIFT Key" := VSIFTKey;

        // Normalize SQL table name for comparison
        NormalizedSQLName := NormalizeNameForComparison(ExtractedTableName);

        // Loop through all tables and find matching one
        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        if AllObj.FindSet() then
            repeat
                NormalizedALName := NormalizeNameForComparison(AllObj."Object Name");
                if NormalizedSQLName = NormalizedALName then begin
                    MissingIndex."Table ID" := AllObj."Object ID";
                    MissingIndex."AL Table Name" := AllObj."Object Name";
                    exit;
                end;
            until AllObj.Next() = 0;
    end;

    local procedure ExtractTableNameFromVSIFT(SQLTableName: Text; var IsVSIFT: Boolean; var VSIFTKey: Integer): Text
    var
        VSIFTPos: Integer;
        KeyPos: Integer;
        TableName: Text;
        KeyText: Text;
        Parts: List of [Text];
        PartText: Text;
        i: Integer;
    begin
        IsVSIFT := false;
        VSIFTKey := 0;

        // Check if this contains $VSIFT$Key pattern
        VSIFTPos := StrPos(UpperCase(SQLTableName), '$VSIFT$KEY');
        if VSIFTPos = 0 then
            exit(SQLTableName); // Not a VSIFT, return original name

        IsVSIFT := true;

        // Extract the key number from the end (e.g., "Key5" -> 5)
        KeyText := CopyStr(SQLTableName, VSIFTPos + 10); // After "$VSIFT$Key"
        if Evaluate(VSIFTKey, DelChr(KeyText, '=', 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')) then;

        // Get the part before $VSIFT
        TableName := CopyStr(SQLTableName, 1, VSIFTPos - 1);

        // Now extract the actual table name from the remaining string
        // Pattern can be: CompanyPrefix$TableName$ExtensionId or TableName$ExtensionId or CompanyPrefix$TableName or just TableName
        // Split by $ and analyze
        SplitString(TableName, '$', Parts);

        // If we have multiple parts, we need to identify which is the table name
        // The table name is typically not a GUID (extension ID) and not a company prefix
        // Strategy: Find the part that looks like a table name (not GUID, not company prefix)
        if Parts.Count() = 1 then
            exit(Parts.Get(1))
        else if Parts.Count() = 2 then begin
            // Could be: CompanyPrefix$TableName or TableName$ExtensionId
            // Check if second part is a GUID (extension ID)
            if IsGuid(Parts.Get(2)) then
                exit(Parts.Get(1)) // First part is table name
            else
                exit(Parts.Get(2)); // Second part is table name (first was company prefix)
        end else if Parts.Count() >= 3 then begin
            // CompanyPrefix$TableName$ExtensionId - table name is the second part
            // But we need to check if second is GUID, then first is table name
            if IsGuid(Parts.Get(2)) then
                exit(Parts.Get(1))
            else
                exit(Parts.Get(2));
        end;

        exit(TableName);
    end;

    local procedure SplitString(InputString: Text; Delimiter: Char; var Parts: List of [Text])
    var
        Part: Text;
        DelimPos: Integer;
    begin
        Clear(Parts);
        while InputString <> '' do begin
            DelimPos := StrPos(InputString, Format(Delimiter));
            if DelimPos > 0 then begin
                Part := CopyStr(InputString, 1, DelimPos - 1);
                InputString := CopyStr(InputString, DelimPos + 1);
            end else begin
                Part := InputString;
                InputString := '';
            end;
            if Part <> '' then
                Parts.Add(Part);
        end;
    end;

    local procedure IsGuid(Value: Text): Boolean
    var
        GuidValue: Guid;
    begin
        // Check if the value looks like a GUID (with or without braces)
        if StrLen(Value) < 32 then
            exit(false);

        // Try to evaluate as GUID
        exit(Evaluate(GuidValue, Value));
    end;

    local procedure NormalizeNameForComparison(Name: Text): Text
    var
        NormalizedName: Text;
    begin
        // Remove company prefix if present (e.g., "CRONUS_International_Ltd_$")
        if StrPos(Name, '$') > 0 then
            Name := CopyStr(Name, StrPos(Name, '$') + 1);

        // Remove trailing $xxx extensions
        if StrPos(Name, '$') > 0 then
            Name := CopyStr(Name, 1, StrPos(Name, '$') - 1);

        // Convert to uppercase and remove special characters
        NormalizedName := UpperCase(Name);
        NormalizedName := DelChr(NormalizedName, '=', '."\/''"%][ _');

        exit(NormalizedName);
    end;

    local procedure TransformFieldNames(TableID: Integer; SQLFieldList: Text): Text
    var
        RecRef: RecordRef;
        FieldList: List of [Text];
        ALFieldList: Text;
        SQLFieldName: Text;
        ALFieldName: Text;
    begin
        if (TableID = 0) or (SQLFieldList = '') then
            exit(SQLFieldList);

        ParseFieldList(SQLFieldList, FieldList);

        if not TryOpenRecRef(TableID, RecRef) then
            exit(SQLFieldList);

        ALFieldList := '';
        foreach SQLFieldName in FieldList do begin
            ALFieldName := FindALFieldName(RecRef, SQLFieldName);

            if ALFieldList <> '' then
                ALFieldList += ', ';

            if ALFieldName <> '' then
                ALFieldList += ALFieldName
            else
                ALFieldList += SQLFieldName;
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
        SQLFieldName := DelChr(SQLFieldName, '=', '[]"');
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

        FieldList := DelChr(FieldList, '=', '[]"');
        FieldList := FieldList.Replace(';', ',');

        while FieldList <> '' do begin
            CommaPos := StrPos(FieldList, ',');
            if CommaPos > 0 then begin
                FieldName := CopyStr(FieldList, 1, CommaPos - 1);
                FieldList := CopyStr(FieldList, CommaPos + 1);
            end else begin
                FieldName := FieldList;
                FieldList := '';
            end;

            FieldName := DelChr(FieldName, '<>', ' ');
            FieldName := DelChr(FieldName, '=', '"''');

            // Strip extension GUID from field name (e.g., "Field Name$guid-here" -> "Field Name")
            FieldName := StripExtensionGuidFromFieldName(FieldName);

            if FieldName <> '' then
                FieldNames.Add(FieldName);
        end;
    end;

    /// <summary>
    /// Strips extension GUID from field names that come from table extensions.
    /// Example: "EOS Document Class Code$4e2a89a2-9049-496c-8b3a-f4eee6399b0e" -> "EOS Document Class Code"
    /// </summary>
    local procedure StripExtensionGuidFromFieldName(FieldName: Text): Text
    var
        DollarPos: Integer;
        PotentialGuid: Text;
        GuidValue: Guid;
    begin
        if FieldName = '' then
            exit('');

        // Find the last $ in the field name
        DollarPos := GetLastDollarPosition(FieldName);
        if DollarPos = 0 then
            exit(FieldName); // No $, return as is

        // Check if what follows $ looks like a GUID
        PotentialGuid := CopyStr(FieldName, DollarPos + 1);

        // If it's a valid GUID, strip it
        if Evaluate(GuidValue, PotentialGuid) then
            exit(CopyStr(FieldName, 1, DollarPos - 1));

        // Also try with braces around it (some GUIDs might not have braces)
        if Evaluate(GuidValue, '{' + PotentialGuid + '}') then
            exit(CopyStr(FieldName, 1, DollarPos - 1));

        // Not a GUID, return original
        exit(FieldName);
    end;

    local procedure GetLastDollarPosition(Text: Text): Integer
    var
        i: Integer;
        LastPos: Integer;
    begin
        LastPos := 0;
        for i := 1 to StrLen(Text) do
            if Text[i] = '$' then
                LastPos := i;
        exit(LastPos);
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
        CleanedList := DelChr(FieldList, '=', '[]"''');
        CleanedList := DelChr(CleanedList, '<>', ' ');

        if CleanedList = '' then
            exit('');

        if DelChr(CleanedList, '=', ',') = '' then
            exit('');

        exit(DelChr(FieldList, '=', '[]"'''));
    end;

    /// <summary>
    /// Calculates selectivity for a single Missing Index entry.
    /// </summary>
    procedure CalculateSelectivity(var MissingIndex: Record "Missing Index")
    var
        IndexSelectivity: Record "Index Selectivity";
        IndexDetail: Record "Index Detail";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        EqualityFieldList: List of [Text];
        InequalityFieldList: List of [Text];
        AllFieldNumbers: List of [Integer];
        FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]];
        TempFieldDict: Dictionary of [Text, Integer];
        FieldSelectivityList: List of [Decimal];
        FieldNoBySelectivity: Dictionary of [Decimal, Integer];
        FieldNameByNo: Dictionary of [Integer, Text];
        FieldValue: Text;
        FieldName: Text;
        FieldNo: Integer;
        TotalRows: Integer;
        CurrentRow: Integer;
        DistinctCount: Integer;
        FieldPosition: Integer;
        SelectivityValue: Decimal;
        SuggestedIndex: Text;
        SortedSelectivities: List of [Decimal];
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating Selectivity...\Phase: #1##############################\Progress: #2#### / #3####';
    begin
        if MissingIndex."Table ID" = 0 then
            exit;

        // Delete existing selectivity records for this missing index
        IndexSelectivity.SetRange("Source Type", "Index Source Type"::"Missing Index");
        IndexSelectivity.SetRange("Missing Index Entry No.", MissingIndex."Entry No.");
        if IndexSelectivity.FindSet() then
            repeat
                IndexDetail.Reset();
                IndexDetail.SetRange("Index Entry No.", IndexSelectivity."Entry No.");
                IndexDetail.DeleteAll();
            until IndexSelectivity.Next() = 0;
        IndexSelectivity.DeleteAll();

        // Parse equality and inequality fields
        ParseFieldList(MissingIndex."Equality Fields", EqualityFieldList);
        ParseFieldList(MissingIndex."Inequality Fields", InequalityFieldList);

        if (EqualityFieldList.Count = 0) and (InequalityFieldList.Count = 0) then
            exit;

        ProgressDialog.Open(ProgressMsg);

        // Open the table
        if not TryOpenRecRef(MissingIndex."Table ID", RecRef) then begin
            ProgressDialog.Close();
            exit;
        end;

        TotalRows := RecRef.Count();
        if TotalRows = 0 then begin
            RecRef.Close();
            ProgressDialog.Close();
            exit;
        end;

        // Get field numbers and initialize dictionaries
        GetFieldNumbersAndInit(RecRef, EqualityFieldList, AllFieldNumbers, FieldNameByNo, FieldDistinctValues);
        GetFieldNumbersAndInit(RecRef, InequalityFieldList, AllFieldNumbers, FieldNameByNo, FieldDistinctValues);

        // Single pass: Collect all field values
        ProgressDialog.Update(1, 'Processing records...');
        ProgressDialog.Update(3, TotalRows);
        CurrentRow := 0;

        if RecRef.FindSet() then
            repeat
                CurrentRow += 1;
                if (CurrentRow mod 1000) = 0 then
                    ProgressDialog.Update(2, CurrentRow);

                foreach FieldNo in AllFieldNumbers do begin
                    if RecRef.FieldExist(FieldNo) then begin
                        FieldRef := RecRef.Field(FieldNo);
                        FieldValue := Format(FieldRef.Value);

                        TempFieldDict := FieldDistinctValues.Get(FieldNo);
                        if not TempFieldDict.ContainsKey(FieldValue) then
                            TempFieldDict.Add(FieldValue, 1)
                        else
                            TempFieldDict.Set(FieldValue, TempFieldDict.Get(FieldValue) + 1);
                        FieldDistinctValues.Set(FieldNo, TempFieldDict);
                    end;
                end;
            until RecRef.Next() = 0;

        ProgressDialog.Update(2, TotalRows);
        RecRef.Close();

        // Create selectivity records and build suggested index
        ProgressDialog.Update(1, 'Creating selectivity records...');

        // Process equality fields and collect selectivity values
        FieldPosition := 0;
        foreach FieldName in EqualityFieldList do begin
            FieldNo := GetFieldNoByName(FieldNameByNo, FieldName);
            if FieldNo = 0 then
                continue;

            FieldPosition += 1;

            if FieldDistinctValues.ContainsKey(FieldNo) then begin
                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                DistinctCount := TempFieldDict.Count;

                if TotalRows > 0 then
                    SelectivityValue := DistinctCount / TotalRows
                else
                    SelectivityValue := 0;

                // Store selectivity for sorting (use negative to handle duplicates)
                if not FieldNoBySelectivity.ContainsKey(SelectivityValue) then begin
                    FieldNoBySelectivity.Add(SelectivityValue, FieldNo);
                    FieldSelectivityList.Add(SelectivityValue);
                end;

                // Create field selectivity record
                CreateMissingIndexSelectivityRecord(
                    IndexSelectivity,
                    MissingIndex,
                    "Selectivity Type"::Field,
                    FieldNo,
                    FieldName,
                    FieldPosition,
                    DistinctCount,
                    TotalRows,
                    true // IsEquality
                );

                // Create bucket histogram
                CreateBucketHistogramForMissingIndex(
                    MissingIndex."Entry No.",
                    "Selectivity Type"::Field,
                    FieldNo,
                    FieldName,
                    TempFieldDict
                );
            end;
        end;

        // Process inequality fields
        foreach FieldName in InequalityFieldList do begin
            FieldNo := GetFieldNoByName(FieldNameByNo, FieldName);
            if FieldNo = 0 then
                continue;

            FieldPosition += 1;

            if FieldDistinctValues.ContainsKey(FieldNo) then begin
                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                DistinctCount := TempFieldDict.Count;

                if TotalRows > 0 then
                    SelectivityValue := DistinctCount / TotalRows
                else
                    SelectivityValue := 0;

                // Create field selectivity record
                CreateMissingIndexSelectivityRecord(
                    IndexSelectivity,
                    MissingIndex,
                    "Selectivity Type"::Field,
                    FieldNo,
                    FieldName,
                    FieldPosition,
                    DistinctCount,
                    TotalRows,
                    false // IsEquality
                );

                // Create bucket histogram
                CreateBucketHistogramForMissingIndex(
                    MissingIndex."Entry No.",
                    "Selectivity Type"::Field,
                    FieldNo,
                    FieldName,
                    TempFieldDict
                );
            end;
        end;

        // Build suggested index: sort equality fields by selectivity (descending)
        SuggestedIndex := BuildSuggestedIndex(EqualityFieldList, InequalityFieldList, FieldDistinctValues, FieldNameByNo, TotalRows);

        // Create index-level selectivity record with suggested key
        CreateMissingIndexSelectivityRecord(
            IndexSelectivity,
            MissingIndex,
            "Selectivity Type"::Index,
            0,
            'Suggested Index: ' + CopyStr(SuggestedIndex, 1, 220),
            0,
            0,
            TotalRows,
            true
        );

        // Update the Missing Index with suggested index
        MissingIndex."Suggested Index" := CopyStr(SuggestedIndex, 1, 1000);
        MissingIndex."Selectivity Calculated" := true;
        MissingIndex.Modify(true);

        ProgressDialog.Close();
        Commit();
    end;

    /// <summary>
    /// Calculates selectivity for all Missing Indexes for a specific table.
    /// OPTIMIZED: Uses single pass through table records for all missing indexes.
    /// </summary>
    procedure CalculateSelectivityForTable(TableID: Integer): Integer
    var
        MissingIndex: Record "Missing Index";
        IndexSelectivity: Record "Index Selectivity";
        IndexDetail: Record "Index Detail";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        // Data structures for single-pass processing
        AllFieldNumbers: List of [Integer];                                                     // Unique field numbers across all missing indexes
        AllFieldNames: Dictionary of [Integer, Text];                                           // Field No -> Field Name
        FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]];            // Field No -> (Value -> Count)
        MissingIndexFields: Dictionary of [Integer, List of [Integer]];                         // Missing Index Entry No -> List of field numbers
        MissingIndexEqualityFields: Dictionary of [Integer, List of [Text]];                    // Missing Index Entry No -> Equality field names
        MissingIndexInequalityFields: Dictionary of [Integer, List of [Text]];                  // Missing Index Entry No -> Inequality field names
        TempFieldDict: Dictionary of [Text, Integer];
        TempFieldNoList: List of [Integer];
        TempEqualityList: List of [Text];
        TempInequalityList: List of [Text];
        EntryNoList: List of [Integer];
        FieldValue: Text;
        FieldName: Text;
        FieldNo: Integer;
        EntryNo: Integer;
        TotalRows: Integer;
        CurrentRow: Integer;
        DistinctCount: Integer;
        FieldPosition: Integer;
        ProcessedCount: Integer;
        SuggestedIndex: Text;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating Selectivity for Table...\Phase: #1##############################\Progress: #2#### / #3####';
    begin
        MissingIndex.SetRange("Table ID", TableID);
        if MissingIndex.IsEmpty() then
            exit(0);

        ProgressDialog.Open(ProgressMsg);
        ProgressDialog.Update(1, 'Collecting field definitions...');

        // ============================================
        // PHASE 1: Collect all fields from all missing indexes for this table
        // ============================================
        if MissingIndex.FindSet() then
            repeat
                // Delete existing selectivity and detail records
                IndexSelectivity.SetRange("Source Type", "Index Source Type"::"Missing Index");
                IndexSelectivity.SetRange("Missing Index Entry No.", MissingIndex."Entry No.");
                if IndexSelectivity.FindSet() then
                    repeat
                        IndexDetail.Reset();
                        IndexDetail.SetRange("Index Entry No.", IndexSelectivity."Entry No.");
                        IndexDetail.DeleteAll();
                    until IndexSelectivity.Next() = 0;
                IndexSelectivity.DeleteAll();

                // Parse equality and inequality fields
                Clear(TempEqualityList);
                Clear(TempInequalityList);
                Clear(TempFieldNoList);
                ParseFieldList(MissingIndex."Equality Fields", TempEqualityList);
                ParseFieldList(MissingIndex."Inequality Fields", TempInequalityList);

                // Store field lists for this missing index
                MissingIndexEqualityFields.Add(MissingIndex."Entry No.", TempEqualityList);
                MissingIndexInequalityFields.Add(MissingIndex."Entry No.", TempInequalityList);
                EntryNoList.Add(MissingIndex."Entry No.");
            until MissingIndex.Next() = 0;

        // Open table and get field numbers
        if not TryOpenRecRef(TableID, RecRef) then begin
            ProgressDialog.Close();
            exit(0);
        end;

        TotalRows := RecRef.Count();
        if TotalRows = 0 then begin
            RecRef.Close();
            ProgressDialog.Close();
            exit(0);
        end;

        // Build master list of all fields and initialize dictionaries
        foreach EntryNo in EntryNoList do begin
            TempEqualityList := MissingIndexEqualityFields.Get(EntryNo);
            TempInequalityList := MissingIndexInequalityFields.Get(EntryNo);

            CollectFieldNumbers(RecRef, TempEqualityList, AllFieldNumbers, AllFieldNames, FieldDistinctValues);
            CollectFieldNumbers(RecRef, TempInequalityList, AllFieldNumbers, AllFieldNames, FieldDistinctValues);
        end;

        if AllFieldNumbers.Count = 0 then begin
            RecRef.Close();
            ProgressDialog.Close();
            exit(0);
        end;

        // ============================================
        // PHASE 2: Single pass through all records - collect ALL field values
        // ============================================
        ProgressDialog.Update(1, 'Processing records (single pass)...');
        ProgressDialog.Update(3, TotalRows);
        CurrentRow := 0;

        if RecRef.FindSet() then
            repeat
                CurrentRow += 1;
                if (CurrentRow mod 1000) = 0 then
                    ProgressDialog.Update(2, CurrentRow);

                // Collect values for ALL fields in a single record read
                foreach FieldNo in AllFieldNumbers do begin
                    if RecRef.FieldExist(FieldNo) then begin
                        FieldRef := RecRef.Field(FieldNo);
                        FieldValue := Format(FieldRef.Value);

                        TempFieldDict := FieldDistinctValues.Get(FieldNo);
                        if not TempFieldDict.ContainsKey(FieldValue) then
                            TempFieldDict.Add(FieldValue, 1)
                        else
                            TempFieldDict.Set(FieldValue, TempFieldDict.Get(FieldValue) + 1);
                        FieldDistinctValues.Set(FieldNo, TempFieldDict);
                    end;
                end;
            until RecRef.Next() = 0;

        ProgressDialog.Update(2, TotalRows);
        RecRef.Close();

        // ============================================
        // PHASE 3: Create selectivity records for each missing index
        // ============================================
        ProgressDialog.Update(1, 'Creating selectivity records...');

        MissingIndex.SetRange("Table ID", TableID);
        if MissingIndex.FindSet() then
            repeat
                ProcessedCount += 1;

                TempEqualityList := MissingIndexEqualityFields.Get(MissingIndex."Entry No.");
                TempInequalityList := MissingIndexInequalityFields.Get(MissingIndex."Entry No.");

                // Create field selectivity records for equality fields
                FieldPosition := 0;
                foreach FieldName in TempEqualityList do begin
                    FieldNo := GetFieldNoByNameFromDict(AllFieldNames, FieldName);
                    if FieldNo = 0 then
                        continue;

                    FieldPosition += 1;

                    if FieldDistinctValues.ContainsKey(FieldNo) then begin
                        TempFieldDict := FieldDistinctValues.Get(FieldNo);
                        DistinctCount := TempFieldDict.Count;

                        CreateMissingIndexSelectivityRecord(
                            IndexSelectivity,
                            MissingIndex,
                            "Selectivity Type"::Field,
                            FieldNo,
                            FieldName,
                            FieldPosition,
                            DistinctCount,
                            TotalRows,
                            true // IsEquality
                        );

                        // Create bucket histogram
                        CreateBucketHistogramForMissingIndex(
                            MissingIndex."Entry No.",
                            "Selectivity Type"::Field,
                            FieldNo,
                            FieldName,
                            TempFieldDict
                        );
                    end;
                end;

                // Create field selectivity records for inequality fields
                foreach FieldName in TempInequalityList do begin
                    FieldNo := GetFieldNoByNameFromDict(AllFieldNames, FieldName);
                    if FieldNo = 0 then
                        continue;

                    FieldPosition += 1;

                    if FieldDistinctValues.ContainsKey(FieldNo) then begin
                        TempFieldDict := FieldDistinctValues.Get(FieldNo);
                        DistinctCount := TempFieldDict.Count;

                        CreateMissingIndexSelectivityRecord(
                            IndexSelectivity,
                            MissingIndex,
                            "Selectivity Type"::Field,
                            FieldNo,
                            FieldName,
                            FieldPosition,
                            DistinctCount,
                            TotalRows,
                            false // IsEquality
                        );

                        CreateBucketHistogramForMissingIndex(
                            MissingIndex."Entry No.",
                            "Selectivity Type"::Field,
                            FieldNo,
                            FieldName,
                            TempFieldDict
                        );
                    end;
                end;

                // Build suggested index
                SuggestedIndex := BuildSuggestedIndexFromDicts(TempEqualityList, TempInequalityList, FieldDistinctValues, AllFieldNames, TotalRows);

                // Create index-level selectivity record
                CreateMissingIndexSelectivityRecord(
                    IndexSelectivity,
                    MissingIndex,
                    "Selectivity Type"::Index,
                    0,
                    'Suggested Index: ' + CopyStr(SuggestedIndex, 1, 220),
                    0,
                    0,
                    TotalRows,
                    true
                );

                // Update the Missing Index
                MissingIndex."Suggested Index" := CopyStr(SuggestedIndex, 1, 1000);
                MissingIndex."Selectivity Calculated" := true;
                MissingIndex.Modify(true);
            until MissingIndex.Next() = 0;

        ProgressDialog.Close();
        Commit();
        exit(ProcessedCount);
    end;

    local procedure CollectFieldNumbers(var RecRef: RecordRef; FieldNameList: List of [Text]; var AllFieldNumbers: List of [Integer]; var AllFieldNames: Dictionary of [Integer, Text]; var FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]])
    var
        FieldRef: FieldRef;
        TempFieldDict: Dictionary of [Text, Integer];
        FieldName: Text;
        FieldNo: Integer;
        i: Integer;
    begin
        foreach FieldName in FieldNameList do begin
            // Find field number by name
            for i := 1 to RecRef.FieldCount() do begin
                FieldRef := RecRef.FieldIndex(i);
                if UpperCase(FieldRef.Name) = UpperCase(FieldName) then begin
                    FieldNo := FieldRef.Number;
                    if not AllFieldNumbers.Contains(FieldNo) then begin
                        AllFieldNumbers.Add(FieldNo);
                        AllFieldNames.Add(FieldNo, FieldRef.Name);
                        Clear(TempFieldDict);
                        FieldDistinctValues.Add(FieldNo, TempFieldDict);
                    end;
                    break;
                end;
            end;
        end;
    end;

    local procedure GetFieldNoByNameFromDict(AllFieldNames: Dictionary of [Integer, Text]; FieldName: Text): Integer
    var
        FieldNo: Integer;
        StoredName: Text;
    begin
        foreach FieldNo in AllFieldNames.Keys() do begin
            StoredName := AllFieldNames.Get(FieldNo);
            if UpperCase(StoredName) = UpperCase(FieldName) then
                exit(FieldNo);
        end;
        exit(0);
    end;

    local procedure BuildSuggestedIndexFromDicts(EqualityFieldList: List of [Text]; InequalityFieldList: List of [Text]; FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]]; FieldNameByNo: Dictionary of [Integer, Text]; TotalRows: Integer): Text
    var
        FieldSelectivities: List of [Decimal];
        FieldNoBySelectivity: Dictionary of [Decimal, Integer];
        TempFieldDict: Dictionary of [Text, Integer];
        FieldName: Text;
        FieldNo: Integer;
        SelectivityValue: Decimal;
        SuggestedIndex: Text;
        SortedSelectivities: List of [Decimal];
        UsedFieldNos: List of [Integer];
        i: Integer;
    begin
        // Calculate selectivity for each equality field
        foreach FieldName in EqualityFieldList do begin
            FieldNo := GetFieldNoByNameFromDict(FieldNameByNo, FieldName);
            if (FieldNo > 0) and FieldDistinctValues.ContainsKey(FieldNo) then begin
                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                if TotalRows > 0 then
                    SelectivityValue := TempFieldDict.Count / TotalRows
                else
                    SelectivityValue := 0;

                // Use a unique key to avoid collisions
                while FieldNoBySelectivity.ContainsKey(SelectivityValue) do
                    SelectivityValue := SelectivityValue + 0.0000001;

                FieldNoBySelectivity.Add(SelectivityValue, FieldNo);
                FieldSelectivities.Add(SelectivityValue);
            end;
        end;

        // Sort by selectivity descending (most selective first)
        SortedSelectivities := FieldSelectivities;
        SortListDescending(SortedSelectivities);

        // Build suggested index from sorted equality fields
        SuggestedIndex := '';
        foreach SelectivityValue in SortedSelectivities do begin
            if FieldNoBySelectivity.ContainsKey(SelectivityValue) then begin
                FieldNo := FieldNoBySelectivity.Get(SelectivityValue);
                if not UsedFieldNos.Contains(FieldNo) then begin
                    UsedFieldNos.Add(FieldNo);
                    if SuggestedIndex <> '' then
                        SuggestedIndex += ', ';
                    SuggestedIndex += FieldNameByNo.Get(FieldNo);
                end;
            end;
        end;

        // Add inequality fields at the end (not sorted by selectivity)
        foreach FieldName in InequalityFieldList do begin
            FieldNo := GetFieldNoByNameFromDict(FieldNameByNo, FieldName);
            if (FieldNo > 0) and not UsedFieldNos.Contains(FieldNo) then begin
                UsedFieldNos.Add(FieldNo);
                if SuggestedIndex <> '' then
                    SuggestedIndex += ', ';
                SuggestedIndex += FieldName;
            end;
        end;

        exit(SuggestedIndex);
    end;

    local procedure SortListDescending(var Values: List of [Decimal])
    var
        i, j : Integer;
        TempVal: Decimal;
        TempList: List of [Decimal];
    begin
        // Simple bubble sort descending
        TempList := Values;
        for i := 1 to TempList.Count - 1 do
            for j := i + 1 to TempList.Count do
                if TempList.Get(i) < TempList.Get(j) then begin
                    TempVal := TempList.Get(i);
                    TempList.Set(i, TempList.Get(j));
                    TempList.Set(j, TempVal);
                end;
        Values := TempList;
    end;

    /// <summary>
    /// Calculates selectivity for all Missing Indexes, grouped by table for optimal performance.
    /// Each table is processed once (single-pass through records).
    /// </summary>
    procedure CalculateSelectivityForAll(): Integer
    var
        MissingIndex: Record "Missing Index";
        TableIDList: List of [Integer];
        TableID: Integer;
        ProcessedCount: Integer;
        TableCount: Integer;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating Selectivity for All Missing Indexes...\Table: #1#### / #2#### - #3##################';
    begin
        // Collect distinct Table IDs
        MissingIndex.SetFilter("Table ID", '>0');
        if MissingIndex.FindSet() then
            repeat
                if not TableIDList.Contains(MissingIndex."Table ID") then
                    TableIDList.Add(MissingIndex."Table ID");
            until MissingIndex.Next() = 0;

        TableCount := TableIDList.Count;
        if TableCount = 0 then
            exit(0);

        ProgressDialog.Open(ProgressMsg);
        ProgressDialog.Update(2, TableCount);

        // Process each table using the optimized single-pass function
        foreach TableID in TableIDList do begin
            ProcessedCount += 1;
            ProgressDialog.Update(1, ProcessedCount);
            ProgressDialog.Update(3, GetTableName(TableID));
            CalculateSelectivityForTable(TableID);
        end;

        ProgressDialog.Close();
        Message('%1 tables processed.', ProcessedCount);
        exit(ProcessedCount);
    end;

    local procedure GetTableName(TableID: Integer): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableID) then
            exit(CopyStr(AllObjWithCaption."Object Name", 1, 250));
        exit('');
    end;

    local procedure GetFieldNumbersAndInit(
        var RecRef: RecordRef;
        var FieldNames: List of [Text];
        var AllFieldNumbers: List of [Integer];
        var FieldNameByNo: Dictionary of [Integer, Text];
        var FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]]
    )
    var
        FieldRef: FieldRef;
        FieldName: Text;
        FieldNo: Integer;
        TempFieldDict: Dictionary of [Text, Integer];
        i: Integer;
    begin
        foreach FieldName in FieldNames do begin
            // Find field by name
            for i := 1 to RecRef.FieldCount do begin
                FieldRef := RecRef.FieldIndex(i);
                if FieldRef.Name = FieldName then begin
                    FieldNo := FieldRef.Number;
                    if not AllFieldNumbers.Contains(FieldNo) then begin
                        AllFieldNumbers.Add(FieldNo);
                        FieldNameByNo.Add(FieldNo, FieldName);
                        Clear(TempFieldDict);
                        FieldDistinctValues.Add(FieldNo, TempFieldDict);
                    end;
                    break;
                end;
            end;
        end;
    end;

    local procedure GetFieldNoByName(var FieldNameByNo: Dictionary of [Integer, Text]; FieldName: Text): Integer
    var
        FieldNo: Integer;
        StoredName: Text;
        FieldNos: List of [Integer];
    begin
        FieldNos := FieldNameByNo.Keys();
        foreach FieldNo in FieldNos do begin
            StoredName := FieldNameByNo.Get(FieldNo);
            if StoredName = FieldName then
                exit(FieldNo);
        end;
        exit(0);
    end;

    local procedure BuildSuggestedIndex(
        var EqualityFields: List of [Text];
        var InequalityFields: List of [Text];
        var FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]];
        var FieldNameByNo: Dictionary of [Integer, Text];
        TotalRows: Integer
    ): Text
    var
        TempFieldDict: Dictionary of [Text, Integer];
        SelectivityList: List of [Decimal];
        FieldSelectivity: Dictionary of [Text, Decimal];
        FieldName: Text;
        FieldNo: Integer;
        DistinctCount: Integer;
        SelectivityValue: Decimal;
        SuggestedIndex: Text;
        SortedFields: List of [Text];
        i, j : Integer;
        TempSelectivity: Decimal;
        TempName: Text;
    begin
        // Calculate selectivity for each equality field
        foreach FieldName in EqualityFields do begin
            FieldNo := GetFieldNoByName(FieldNameByNo, FieldName);
            if FieldNo = 0 then
                continue;

            if FieldDistinctValues.ContainsKey(FieldNo) then begin
                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                DistinctCount := TempFieldDict.Count;
                if TotalRows > 0 then
                    SelectivityValue := DistinctCount / TotalRows
                else
                    SelectivityValue := 0;
                FieldSelectivity.Add(FieldName, SelectivityValue);
                SortedFields.Add(FieldName);
            end;
        end;

        // Sort equality fields by selectivity (descending - most selective first)
        for i := 1 to SortedFields.Count - 1 do
            for j := i + 1 to SortedFields.Count do begin
                if FieldSelectivity.Get(SortedFields.Get(j)) > FieldSelectivity.Get(SortedFields.Get(i)) then begin
                    TempName := SortedFields.Get(i);
                    SortedFields.Set(i, SortedFields.Get(j));
                    SortedFields.Set(j, TempName);
                end;
            end;

        // Build suggested index from sorted equality fields
        SuggestedIndex := '';
        foreach FieldName in SortedFields do begin
            if SuggestedIndex <> '' then
                SuggestedIndex += ', ';
            SuggestedIndex += FieldName;
        end;

        // Add inequality fields (also sorted by selectivity)
        Clear(SortedFields);
        Clear(FieldSelectivity);

        foreach FieldName in InequalityFields do begin
            FieldNo := GetFieldNoByName(FieldNameByNo, FieldName);
            if FieldNo = 0 then
                continue;

            if FieldDistinctValues.ContainsKey(FieldNo) then begin
                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                DistinctCount := TempFieldDict.Count;
                if TotalRows > 0 then
                    SelectivityValue := DistinctCount / TotalRows
                else
                    SelectivityValue := 0;
                FieldSelectivity.Add(FieldName, SelectivityValue);
                SortedFields.Add(FieldName);
            end;
        end;

        // Sort inequality fields by selectivity (descending)
        for i := 1 to SortedFields.Count - 1 do
            for j := i + 1 to SortedFields.Count do begin
                if FieldSelectivity.Get(SortedFields.Get(j)) > FieldSelectivity.Get(SortedFields.Get(i)) then begin
                    TempName := SortedFields.Get(i);
                    SortedFields.Set(i, SortedFields.Get(j));
                    SortedFields.Set(j, TempName);
                end;
            end;

        // Append inequality fields
        foreach FieldName in SortedFields do begin
            if SuggestedIndex <> '' then
                SuggestedIndex += ', ';
            SuggestedIndex += FieldName;
        end;

        exit(SuggestedIndex);
    end;

    local procedure CreateMissingIndexSelectivityRecord(
        var IndexSelectivity: Record "Index Selectivity";
        MissingIndex: Record "Missing Index";
        SelectivityType: Enum "Selectivity Type";
        FieldNo: Integer;
        FieldName: Text[250];
        FieldPosition: Integer;
        DistinctValues: Integer;
        TotalRows: Integer;
        IsEquality: Boolean
    )
    begin
        Clear(IndexSelectivity);
        IndexSelectivity.Init();
        IndexSelectivity."Source Type" := "Index Source Type"::"Missing Index";
        IndexSelectivity."Missing Index Entry No." := MissingIndex."Entry No.";
        IndexSelectivity."Index Entry No." := 0;
        IndexSelectivity."Table ID" := MissingIndex."Table ID";
        IndexSelectivity."Table Name" := MissingIndex."AL Table Name";
        IndexSelectivity."Key Index" := 0;
        IndexSelectivity."Selectivity Type" := SelectivityType;
        IndexSelectivity."Field No." := FieldNo;
        IndexSelectivity."Field Name" := FieldName;
        IndexSelectivity."Field Position" := FieldPosition;
        IndexSelectivity."Distinct Values" := DistinctValues;
        IndexSelectivity."Total Rows" := TotalRows;

        if TotalRows > 0 then
            IndexSelectivity.Selectivity := DistinctValues / TotalRows
        else
            IndexSelectivity.Selectivity := 0;

        if DistinctValues > 0 then
            IndexSelectivity.Density := 1.0 / DistinctValues
        else
            IndexSelectivity.Density := 0;

        IndexSelectivity."Last Updated" := CurrentDateTime();
        IndexSelectivity.Insert(true);
    end;

    local procedure CreateBucketHistogramForMissingIndex(
        MissingIndexEntryNo: Integer;
        SelectivityType: Enum "Selectivity Type";
        FieldNo: Integer;
        FieldName: Text[250];
        var ValuesDict: Dictionary of [Text, Integer]
    )
    var
        IndexDetail: Record "Index Detail";
        BucketDict: Dictionary of [Integer, Integer];
        ValueKey: Text;
        ValueKeys: List of [Text];
        RecordCount: Integer;
        BucketValue: Integer;
        BucketKeys: List of [Integer];
    begin
        ValueKeys := ValuesDict.Keys;
        foreach ValueKey in ValueKeys do begin
            RecordCount := ValuesDict.Get(ValueKey);

            if BucketDict.ContainsKey(RecordCount) then
                BucketDict.Set(RecordCount, BucketDict.Get(RecordCount) + 1)
            else
                BucketDict.Add(RecordCount, 1);
        end;

        BucketKeys := BucketDict.Keys;
        foreach BucketValue in BucketKeys do begin
            Clear(IndexDetail);
            IndexDetail.Init();
            IndexDetail."Index Entry No." := MissingIndexEntryNo;
            IndexDetail."Selectivity Type" := SelectivityType;
            IndexDetail."Field No." := FieldNo;
            IndexDetail."Field Name" := FieldName;
            IndexDetail.Bucket := BucketValue;
            IndexDetail."No. of Groups" := BucketDict.Get(BucketValue);
            IndexDetail.Insert(true);
        end;
    end;
}
