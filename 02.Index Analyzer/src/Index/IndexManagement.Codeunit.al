namespace DefaultNamespace;

using System.Reflection;

codeunit 50910 "Index Management"
{
    procedure CollectIndexData()
    begin
        CollectIndexDataFromTable(0, true);
    end;

    procedure CollectIndexDataFromTable(StartFromTableID: Integer; ClearExisting: Boolean)
    var
        IndexEntry: Record "Index Entry";
        TableIndex: Record "Table Index";
        TableMetadata: Record "Table Metadata";
        KeyMetadata: Record "Key";
        AllObj: Record AllObjWithCaption;
        RecRef: RecordRef;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Processing Index Data...\Table: #1######## #2##############################\Key Index: #3####';
        RecordCount: Integer;
        LastTableID: Integer;
        IndexCount: Integer;
        VSIFTCount: Integer;
        IncludedCount: Integer;
        SIFTFieldsCount: Integer;
    begin
        // Clear existing data if requested
        if ClearExisting then begin
            IndexEntry.Truncate();
            TableIndex.Truncate();
        end else
            if StartFromTableID > 0 then begin
                // Delete existing records for the starting table and onwards
                IndexEntry.SetFilter("Table ID", '>=%1', StartFromTableID);
                IndexEntry.DeleteAll();
                IndexEntry.Reset();
                TableIndex.SetFilter("Table ID", '>=%1', StartFromTableID);
                TableIndex.DeleteAll();
                TableIndex.Reset();
            end;

        ProgressDialog.Open(ProgressMsg);
        LastTableID := 0;

        // Loop through all tables (excluding system, virtual, internal/private tables, and our own analyzer tables)
        TableMetadata.SetFilter(ID, '<%1&<>%2&<>%3', 2000000000, Database::"Index Entry", Database::"Table Index"); // Exclude system tables and our own tables
        if StartFromTableID > 0 then
            TableMetadata.SetFilter(ID, '>=%1&<%2&<>%3&<>%4', StartFromTableID, 2000000000, Database::"Index Entry", Database::"Table Index"); // Start from specified table (inclusive)
        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal); // Exclude virtual tables
        TableMetadata.SetRange(Access, TableMetadata.Access::Public); // Only public tables (exclude internal/private)
        if TableMetadata.FindSet() then
            repeat
                // Get table name
                AllObj.Reset();
                AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
                AllObj.SetRange("Object ID", TableMetadata.ID);
                if AllObj.FindFirst() then begin
                    // Get record count for the table (with error handling for permission issues)
                    RecordCount := GetTableRecordCount(TableMetadata.ID);

                    // Skip tables where we couldn't get record count (permission denied)
                    if RecordCount < 0 then
                        RecordCount := 0;

                    // Only process tables with record count greater than 1
                    if RecordCount > 1 then begin
                        // Reset counters for Table Index
                        IndexCount := 0;
                        VSIFTCount := 0;
                        IncludedCount := 0;
                        SIFTFieldsCount := 0;

                        // Find all keys for the table
                        KeyMetadata.Reset();
                        KeyMetadata.SetRange(TableNo, TableMetadata.ID);
                        if KeyMetadata.FindSet() then
                            repeat
                                // Update progress dialog
                                ProgressDialog.Update(1, TableMetadata.ID);
                                ProgressDialog.Update(2, AllObj."Object Name");
                                ProgressDialog.Update(3, KeyMetadata."No.");

                                CreateIndexEntry(IndexEntry, KeyMetadata, AllObj."Object Name", RecordCount);

                                // Count for Table Index (only enabled indexes)
                                if KeyMetadata.Enabled then begin
                                    IndexCount += 1;
                                    if KeyMetadata.MaintainSIFTIndex and (KeyMetadata.SumIndexFields <> '') then
                                        VSIFTCount += 1;
                                    // Count indexes with SIFT fields defined (regardless of MaintainSIFTIndex)
                                    if KeyMetadata.SumIndexFields <> '' then
                                        SIFTFieldsCount += 1;
                                    // Check if this index has included columns (SQLIndex contains more fields than Key)
                                    if GetIncludedColumns(KeyMetadata) <> '' then
                                        IncludedCount += 1;
                                end;
                            until KeyMetadata.Next() = 0;

                        // Create Table Index entry
                        CreateTableIndex(TableIndex, TableMetadata.ID, AllObj."Object Name", IndexCount, VSIFTCount, IncludedCount, SIFTFieldsCount, RecordCount);

                        // Commit after processing each table to save progress
                        if LastTableID <> TableMetadata.ID then begin
                            Commit();
                            LastTableID := TableMetadata.ID;
                        end;
                    end;
                end;
            until TableMetadata.Next() = 0;

        ProgressDialog.Close();
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
        TableIndex."Last Updated" := CurrentDateTime();
        TableIndex.Insert(true);
    end;

    procedure GetLastProcessedTableID(): Integer
    var
        IndexEntry: Record "Index Entry";
    begin
        IndexEntry.Reset();
        if IndexEntry.FindLast() then
            exit(IndexEntry."Table ID");
        exit(0);
    end;

    procedure HasExistingData(): Boolean
    var
        IndexEntry: Record "Index Entry";
    begin
        exit(not IndexEntry.IsEmpty());
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

        // SQL Index - the actual SQL index fields
        IndexEntry."SQL Index" := CopyStr(KeyMetadata.SQLIndex, 1, 500);

        // Included Columns - derived from SQLIndex if different from Key fields
        IncludedColumns := GetIncludedColumns(KeyMetadata);
        IndexEntry."Included Columns" := CopyStr(IncludedColumns, 1, 500);
        IndexEntry."No. of Included Columns" := CountFieldsInList(IncludedColumns);

        // Clustered property
        IndexEntry.Clustered := KeyMetadata.Clustered;

        // SIFT properties
        IndexEntry."Maintain SIFT Index" := KeyMetadata.MaintainSIFTIndex;
        if KeyMetadata.SumIndexFields <> '' then begin
            // Try to get field names, fall back to field numbers if conversion fails
            IndexEntry."SIFT Fields" := CopyStr(GetFieldNamesFromNumbers(KeyMetadata.TableNo, KeyMetadata.SumIndexFields), 1, 500);
            if IndexEntry."SIFT Fields" = '' then
                IndexEntry."SIFT Fields" := CopyStr(KeyMetadata.SumIndexFields, 1, 500); // Use raw field numbers as fallback
        end;

        // Other properties
        IndexEntry.Unique := KeyMetadata.Unique;
        IndexEntry.Enabled := KeyMetadata.Enabled;

        // Record count
        IndexEntry."Total Record Count" := RecordCount;

        IndexEntry.Insert(true);
    end;

    local procedure GetTableRecordCount(TableID: Integer): Integer
    var
        RecRef: RecordRef;
        RecordCount: Integer;
    begin
        // Use TryFunction pattern to handle permission errors
        if not TryGetRecordCount(TableID, RecordCount) then
            exit(-1); // Return -1 to indicate error

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

    local procedure GetIncludedColumns(KeyMetadata: Record "Key"): Text
    var
        SQLIndexFields: Text;
        KeyFields: Text;
        IncludedFields: Text;
        SQLFieldList: List of [Text];
        KeyFieldList: List of [Text];
        SQLField: Text;
        IsKeyField: Boolean;
        KeyField: Text;
    begin
        // SQLIndex contains all fields in the SQL index (key fields + included columns)
        // We need to extract included columns by comparing SQLIndex with Key fields
        SQLIndexFields := KeyMetadata.SQLIndex;
        KeyFields := KeyMetadata."Key";

        if SQLIndexFields = '' then
            exit('');

        // Parse SQLIndex and Key fields into lists
        ParseFieldNames(SQLIndexFields, SQLFieldList);
        ParseFieldNames(KeyFields, KeyFieldList);

        // Find fields in SQLIndex that are not in Key (these are included columns)
        IncludedFields := '';
        foreach SQLField in SQLFieldList do begin
            IsKeyField := false;
            foreach KeyField in KeyFieldList do begin
                if SQLField = KeyField then begin
                    IsKeyField := true;
                    break;
                end;
            end;

            if not IsKeyField then begin
                if IncludedFields <> '' then
                    IncludedFields += ', ';
                IncludedFields += SQLField;
            end;
        end;

        exit(IncludedFields);
    end;

    local procedure ParseFieldNames(FieldNames: Text; var FieldList: List of [Text])
    var
        FieldName: Text;
        CommaPos: Integer;
    begin
        Clear(FieldList);
        if FieldNames = '' then
            exit;

        while FieldNames <> '' do begin
            CommaPos := StrPos(FieldNames, ',');
            if CommaPos > 0 then begin
                FieldName := CopyStr(FieldNames, 1, CommaPos - 1);
                FieldNames := CopyStr(FieldNames, CommaPos + 1);
            end else begin
                FieldName := FieldNames;
                FieldNames := '';
            end;

            // Trim spaces
            FieldName := DelChr(FieldName, '<>', ' ');
            if FieldName <> '' then
                FieldList.Add(FieldName);
        end;
    end;

    local procedure GetFieldNamesFromNumbers(TableNo: Integer; FieldList: Text): Text
    var
        FieldRef: FieldRef;
        RecRef: RecordRef;
        FieldNoList: List of [Integer];
        FieldNames: Text;
        FieldNo: Integer;
    begin
        if FieldList = '' then
            exit('');

        RecRef.Open(TableNo);
        ParseFieldList(FieldList, FieldNoList);

        foreach FieldNo in FieldNoList do begin
            if RecRef.FieldExist(FieldNo) then begin
                FieldRef := RecRef.Field(FieldNo);
                if FieldNames <> '' then
                    FieldNames += ', ';
                FieldNames += FieldRef.Name;
            end;
        end;

        RecRef.Close();
        exit(FieldNames);
    end;

    local procedure ParseFieldList(FieldList: Text; var FieldNoList: List of [Integer])
    var
        FieldNo: Integer;
        CommaPos: Integer;
        FieldText: Text;
    begin
        Clear(FieldNoList);
        FieldList := DelChr(FieldList, '=', ' ');

        while FieldList <> '' do begin
            CommaPos := StrPos(FieldList, ',');
            if CommaPos > 0 then begin
                FieldText := CopyStr(FieldList, 1, CommaPos - 1);
                FieldList := CopyStr(FieldList, CommaPos + 1);
            end else begin
                FieldText := FieldList;
                FieldList := '';
            end;

            if Evaluate(FieldNo, FieldText) then
                FieldNoList.Add(FieldNo);
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

    procedure CalculateSelectivity(IndexEntry: Record "Index Entry")
    var
        IndexSelectivity: Record "Index Selectivity";
        IndexDetail: Record "Index Detail";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyFieldList: List of [Integer];
        FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]]; // Field No -> (Value -> Count)
        IndexDistinctDict: Dictionary of [Text, Integer];
        TempFieldDict: Dictionary of [Text, Integer];
        FieldValue: Text;
        CompositeKey: Text;
        TotalRows: Integer;
        CurrentRow: Integer;
        DistinctCount: Integer;
        FieldPosition: Integer;
        FieldNo: Integer;
        FieldName: Text;
        AllFieldNames: Dictionary of [Integer, Text];
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating Selectivity...\Phase: #1##############################\Progress: #2#### / #3####';
    begin
        // Delete existing selectivity and detail records for this index entry only
        IndexSelectivity.SetRange("Index Entry No.", IndexEntry."Entry No.");
        if IndexSelectivity.FindSet() then
            repeat
                IndexDetail.Reset();
                IndexDetail.SetRange("Index Entry No.", IndexSelectivity."Index Entry No.");
                IndexDetail.DeleteAll();
            until IndexSelectivity.Next() = 0;
        IndexSelectivity.DeleteAll();

        // Get field numbers from key fields
        GetFieldNumbersFromKeyFields(IndexEntry."Table ID", IndexEntry."Key Fields", KeyFieldList);

        if KeyFieldList.Count = 0 then
            exit;

        ProgressDialog.Open(ProgressMsg);

        // Open the table and prepare field name mapping
        RecRef.Open(IndexEntry."Table ID");
        TotalRows := RecRef.Count();

        if TotalRows = 0 then begin
            RecRef.Close();
            ProgressDialog.Close();
            exit;
        end;

        // Note: We now calculate selectivity for ALL keys including primary keys and system keys
        // Previously we skipped single-field primary keys, but now we calculate everything to ensure consistency


        // Initialize dictionaries for all fields (composite key or non-PK indexes)
        foreach FieldNo in KeyFieldList do begin
            if RecRef.FieldExist(FieldNo) then begin
                FieldRef := RecRef.Field(FieldNo);
                AllFieldNames.Add(FieldNo, FieldRef.Name);
                Clear(TempFieldDict);
                FieldDistinctValues.Add(FieldNo, TempFieldDict);
            end;
        end;

        // ============================================
        // SINGLE PASS: Collect ALL field values and composite key at once
        // ============================================
        ProgressDialog.Update(1, 'Processing records (single pass)...');
        ProgressDialog.Update(3, TotalRows);
        CurrentRow := 0;

        if RecRef.FindSet() then
            repeat
                CurrentRow += 1;
                if (CurrentRow mod 1000) = 0 then
                    ProgressDialog.Update(2, CurrentRow);

                // Collect values for ALL individual fields in this single record read
                foreach FieldNo in KeyFieldList do begin
                    if RecRef.FieldExist(FieldNo) then begin
                        FieldRef := RecRef.Field(FieldNo);
                        FieldValue := Format(FieldRef.Value);

                        // Update field's distinct values dictionary
                        TempFieldDict := FieldDistinctValues.Get(FieldNo);
                        if not TempFieldDict.ContainsKey(FieldValue) then
                            TempFieldDict.Add(FieldValue, 1)
                        else
                            TempFieldDict.Set(FieldValue, TempFieldDict.Get(FieldValue) + 1);
                        FieldDistinctValues.Set(FieldNo, TempFieldDict);
                    end;
                end;

                // Build composite key from the same record
                CompositeKey := BuildCompositeKeyFromRecord(RecRef, KeyFieldList);
                if not IndexDistinctDict.ContainsKey(CompositeKey) then
                    IndexDistinctDict.Add(CompositeKey, 1)
                else
                    IndexDistinctDict.Set(CompositeKey, IndexDistinctDict.Get(CompositeKey) + 1);
            until RecRef.Next() = 0;

        ProgressDialog.Update(2, TotalRows);
        RecRef.Close();

        // ============================================
        // Create selectivity records from collected data
        // ============================================
        ProgressDialog.Update(1, 'Creating selectivity records...');

        // Create field-level selectivity records
        FieldPosition := 0;
        foreach FieldNo in KeyFieldList do begin
            FieldPosition += 1;

            if not AllFieldNames.ContainsKey(FieldNo) then
                continue;

            FieldName := AllFieldNames.Get(FieldNo);

            if FieldDistinctValues.ContainsKey(FieldNo) then begin
                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                DistinctCount := TempFieldDict.Count;

                // Create field selectivity record
                CreateSelectivityRecord(
                    IndexSelectivity,
                    IndexEntry,
                    "Selectivity Type"::Field,
                    FieldNo,
                    FieldName,
                    FieldPosition,
                    DistinctCount,
                    TotalRows
                );

                // Create bucket histogram for this field
                CreateBucketHistogram(
                    IndexEntry."Entry No.",
                    "Selectivity Type"::Field,
                    FieldNo,
                    FieldName,
                    TempFieldDict
                );
            end;
        end;

        // Create index-level selectivity record (composite key)
        DistinctCount := IndexDistinctDict.Count;
        CreateSelectivityRecord(
            IndexSelectivity,
            IndexEntry,
            "Selectivity Type"::Index,
            0,
            'Composite Key (' + CopyStr(IndexEntry."Key Fields", 1, 200) + ')',
            0,
            DistinctCount,
            TotalRows
        );

        // Create bucket histogram for the composite key
        CreateBucketHistogram(IndexEntry."Entry No.", "Selectivity Type"::Index, 0, 'Composite Key', IndexDistinctDict);

        ProgressDialog.Close();
        Commit();
    end;

    local procedure CreateSelectivityRecord(
        var IndexSelectivity: Record "Index Selectivity";
        IndexEntry: Record "Index Entry";
        SelectivityType: Enum "Selectivity Type";
                             FieldNo: Integer;
                             FieldName: Text[250];
                             FieldPosition: Integer;
                             DistinctValues: Integer;
                             TotalRows: Integer
    )
    begin
        Clear(IndexSelectivity);
        IndexSelectivity.Init();
        IndexSelectivity."Index Entry No." := IndexEntry."Entry No.";
        IndexSelectivity."Table ID" := IndexEntry."Table ID";
        IndexSelectivity."Table Name" := IndexEntry."Table Name";
        IndexSelectivity."Key Index" := IndexEntry."Key Index";
        IndexSelectivity."Selectivity Type" := SelectivityType;
        IndexSelectivity."Field No." := FieldNo;
        IndexSelectivity."Field Name" := FieldName;
        IndexSelectivity."Field Position" := FieldPosition;
        IndexSelectivity."Distinct Values" := DistinctValues;
        IndexSelectivity."Total Rows" := TotalRows;

        // Calculate Selectivity = Distinct Values / Total Rows
        if TotalRows > 0 then
            IndexSelectivity.Selectivity := DistinctValues / TotalRows
        else
            IndexSelectivity.Selectivity := 0;

        // Calculate Density = 1.0 / Distinct Values
        if DistinctValues > 0 then
            IndexSelectivity.Density := 1.0 / DistinctValues
        else
            IndexSelectivity.Density := 0;

        IndexSelectivity."Last Updated" := CurrentDateTime();
        IndexSelectivity.Insert(true);
    end;

    local procedure CreateBucketHistogram(
        IndexEntryNo: Integer;
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
        // Create bucket distribution - how many distinct values have each record count
        ValueKeys := ValuesDict.Keys;
        foreach ValueKey in ValueKeys do begin
            RecordCount := ValuesDict.Get(ValueKey);

            if BucketDict.ContainsKey(RecordCount) then
                BucketDict.Set(RecordCount, BucketDict.Get(RecordCount) + 1)
            else
                BucketDict.Add(RecordCount, 1);
        end;

        // Create Index Detail records for each bucket
        BucketKeys := BucketDict.Keys;
        foreach BucketValue in BucketKeys do begin
            Clear(IndexDetail);
            IndexDetail.Init();
            IndexDetail."Index Entry No." := IndexEntryNo;
            IndexDetail."Selectivity Type" := SelectivityType;
            IndexDetail."Field No." := FieldNo;
            IndexDetail."Field Name" := FieldName;
            IndexDetail.Bucket := BucketValue;
            IndexDetail."No. of Groups" := BucketDict.Get(BucketValue);
            IndexDetail.Insert(true);
        end;
    end;

    local procedure GetFieldNumbersFromKeyFields(TableNo: Integer; FieldNames: Text; var FieldNoList: List of [Integer])
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        FieldName: Text;
        TrimmedFieldName: Text;
        CommaPos: Integer;
        i: Integer;
    begin
        Clear(FieldNoList);
        if FieldNames = '' then
            exit;

        RecRef.Open(TableNo);

        while FieldNames <> '' do begin
            CommaPos := StrPos(FieldNames, ',');
            if CommaPos > 0 then begin
                FieldName := CopyStr(FieldNames, 1, CommaPos - 1);
                FieldNames := CopyStr(FieldNames, CommaPos + 1);
            end else begin
                FieldName := FieldNames;
                FieldNames := '';
            end;

            // Trim only leading and trailing spaces, preserve internal spaces
            TrimmedFieldName := DelChr(FieldName, '<>', ' ');

            // Find field by name
            for i := 1 to RecRef.FieldCount do begin
                FieldRef := RecRef.FieldIndex(i);
                if FieldRef.Name = TrimmedFieldName then begin
                    FieldNoList.Add(FieldRef.Number);
                    break;
                end;
            end;
        end;

        RecRef.Close();
    end;

    procedure CalculateSelectivityForTable(TableID: Integer; TableName: Text[250]): Integer
    var
        IndexEntry: Record "Index Entry";
        IndexSelectivity: Record "Index Selectivity";
        IndexDetail: Record "Index Detail";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating Selectivity for Table...\Table: #1##############################\Phase: #2##############################\Progress: #3#### / #4####';
        // Data structures for single-pass processing
        AllFieldNumbers: List of [Integer];                           // Unique field numbers across all indexes
        AllFieldNames: Dictionary of [Integer, Text];                  // Field No -> Field Name mapping
        FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]]; // Field No -> (Value -> Count)
        // Composite key structures: we use index entry no as key
        IndexKeyFieldLists: Dictionary of [Integer, List of [Integer]]; // Entry No -> List of field numbers
        IndexDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]]; // Entry No -> (CompositeKey -> Count)
        TempFieldDict: Dictionary of [Text, Integer];
        TempKeyFieldList: List of [Integer];
        CompositeKey: Text;
        FieldValue: Text;
        FieldNo: Integer;
        TotalRows: Integer;
        CurrentRow: Integer;
        IndexCount: Integer;
        FieldPosition: Integer;
        DistinctCount: Integer;
        EntryNo: Integer;
        EntryNoList: List of [Integer];
    begin
        IndexEntry.SetRange("Table ID", TableID);
        IndexCount := IndexEntry.Count();

        if IndexCount = 0 then
            exit(0);

        ProgressDialog.Open(ProgressMsg);
        ProgressDialog.Update(1, TableName);

        // ============================================
        // PHASE 1: Collect all fields and composite key definitions from all indexes
        // ============================================
        ProgressDialog.Update(2, 'Collecting field definitions...');

        if IndexEntry.FindSet() then
            repeat
                // Delete existing selectivity and detail records for this index entry
                IndexSelectivity.SetRange("Index Entry No.", IndexEntry."Entry No.");
                if IndexSelectivity.FindSet() then
                    repeat
                        IndexDetail.Reset();
                        IndexDetail.SetRange("Index Entry No.", IndexSelectivity."Index Entry No.");
                        IndexDetail.DeleteAll();
                    until IndexSelectivity.Next() = 0;
                IndexSelectivity.DeleteAll();

                // Get field numbers for this index's key
                Clear(TempKeyFieldList);
                GetFieldNumbersFromKeyFields(IndexEntry."Table ID", IndexEntry."Key Fields", TempKeyFieldList);

                if TempKeyFieldList.Count > 0 then begin
                    // Store the key field list for this index (for composite key calculation)
                    IndexKeyFieldLists.Add(IndexEntry."Entry No.", TempKeyFieldList);
                    EntryNoList.Add(IndexEntry."Entry No.");

                    // Initialize empty dictionary for composite key values
                    Clear(TempFieldDict);
                    IndexDistinctValues.Add(IndexEntry."Entry No.", TempFieldDict);

                    // Add all fields to our master list (avoid duplicates)
                    foreach FieldNo in TempKeyFieldList do
                        if not AllFieldNumbers.Contains(FieldNo) then
                            AllFieldNumbers.Add(FieldNo);
                end;
            until IndexEntry.Next() = 0;

        if AllFieldNumbers.Count = 0 then begin
            ProgressDialog.Close();
            exit(0);
        end;

        // Open table and get field names
        RecRef.Open(TableID);

        foreach FieldNo in AllFieldNumbers do begin
            if RecRef.FieldExist(FieldNo) then begin
                FieldRef := RecRef.Field(FieldNo);
                AllFieldNames.Add(FieldNo, FieldRef.Name);
                // Initialize empty dictionary for field values (skip primary key field 1)
                if FieldNo <> 1 then begin
                    Clear(TempFieldDict);
                    FieldDistinctValues.Add(FieldNo, TempFieldDict);
                end;
            end;
        end;

        TotalRows := RecRef.Count();
        if TotalRows = 0 then begin
            RecRef.Close();
            ProgressDialog.Close();
            exit(0);
        end;

        // ============================================
        // PHASE 2: Single pass through all records - collect ALL data at once
        // ============================================
        ProgressDialog.Update(2, 'Processing records (single pass)...');
        ProgressDialog.Update(4, TotalRows);
        CurrentRow := 0;

        if RecRef.FindSet() then
            repeat
                CurrentRow += 1;
                if (CurrentRow mod 1000) = 0 then
                    ProgressDialog.Update(3, CurrentRow);

                // Collect values for ALL individual fields in a single record read
                foreach FieldNo in AllFieldNumbers do begin
                    if (FieldNo <> 1) and RecRef.FieldExist(FieldNo) then begin
                        FieldRef := RecRef.Field(FieldNo);
                        FieldValue := Format(FieldRef.Value);

                        // Update field's distinct values dictionary
                        TempFieldDict := FieldDistinctValues.Get(FieldNo);
                        if not TempFieldDict.ContainsKey(FieldValue) then
                            TempFieldDict.Add(FieldValue, 1)
                        else
                            TempFieldDict.Set(FieldValue, TempFieldDict.Get(FieldValue) + 1);
                        FieldDistinctValues.Set(FieldNo, TempFieldDict);
                    end;
                end;

                // Build ALL composite keys for ALL indexes from this single record
                foreach EntryNo in EntryNoList do begin
                    TempKeyFieldList := IndexKeyFieldLists.Get(EntryNo);
                    CompositeKey := BuildCompositeKeyFromRecord(RecRef, TempKeyFieldList);

                    TempFieldDict := IndexDistinctValues.Get(EntryNo);
                    if not TempFieldDict.ContainsKey(CompositeKey) then
                        TempFieldDict.Add(CompositeKey, 1)
                    else
                        TempFieldDict.Set(CompositeKey, TempFieldDict.Get(CompositeKey) + 1);
                    IndexDistinctValues.Set(EntryNo, TempFieldDict);
                end;
            until RecRef.Next() = 0;

        ProgressDialog.Update(3, TotalRows);
        RecRef.Close();

        // ============================================
        // PHASE 3: Create selectivity records from collected data
        // ============================================
        ProgressDialog.Update(2, 'Creating selectivity records...');

        // Process each index and create selectivity records
        IndexEntry.SetRange("Table ID", TableID);
        if IndexEntry.FindSet() then
            repeat
                if IndexKeyFieldLists.ContainsKey(IndexEntry."Entry No.") then begin
                    TempKeyFieldList := IndexKeyFieldLists.Get(IndexEntry."Entry No.");

                    // Create field-level selectivity records for this index
                    FieldPosition := 0;
                    foreach FieldNo in TempKeyFieldList do begin
                        FieldPosition += 1;

                        if FieldNo = 1 then begin
                            // Primary key field - skip calculation, just create record
                            if AllFieldNames.ContainsKey(FieldNo) then
                                CreateSelectivityRecord(
                                    IndexSelectivity,
                                    IndexEntry,
                                    "Selectivity Type"::Field,
                                    FieldNo,
                                    AllFieldNames.Get(FieldNo) + ' (Primary Key - Skipped)',
                                    FieldPosition,
                                    TotalRows,
                                    TotalRows
                                );
                        end else begin
                            if FieldDistinctValues.ContainsKey(FieldNo) then begin
                                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                                DistinctCount := TempFieldDict.Count;

                                // Create field selectivity record
                                CreateSelectivityRecord(
                                    IndexSelectivity,
                                    IndexEntry,
                                    "Selectivity Type"::Field,
                                    FieldNo,
                                    AllFieldNames.Get(FieldNo),
                                    FieldPosition,
                                    DistinctCount,
                                    TotalRows
                                );

                                // Create bucket histogram for this field (only for first index that uses this field)
                                IndexDetail.Reset();
                                IndexDetail.SetRange("Index Entry No.", IndexEntry."Entry No.");
                                IndexDetail.SetRange("Selectivity Type", "Selectivity Type"::Field);
                                IndexDetail.SetRange("Field No.", FieldNo);
                                if IndexDetail.IsEmpty then
                                    CreateBucketHistogram(
                                        IndexEntry."Entry No.",
                                        "Selectivity Type"::Field,
                                        FieldNo,
                                        AllFieldNames.Get(FieldNo),
                                        TempFieldDict
                                    );
                            end;
                        end;
                    end;

                    // Create composite key selectivity record for this index
                    if IndexDistinctValues.ContainsKey(IndexEntry."Entry No.") then begin
                        TempFieldDict := IndexDistinctValues.Get(IndexEntry."Entry No.");
                        DistinctCount := TempFieldDict.Count;

                        CreateSelectivityRecord(
                            IndexSelectivity,
                            IndexEntry,
                            "Selectivity Type"::Index,
                            0,
                            'Composite Key (' + CopyStr(IndexEntry."Key Fields", 1, 200) + ')',
                            0,
                            DistinctCount,
                            TotalRows
                        );

                        // Create bucket histogram for the composite key
                        CreateBucketHistogram(
                            IndexEntry."Entry No.",
                            "Selectivity Type"::Index,
                            0,
                            'Composite Key',
                            TempFieldDict
                        );
                    end;
                end;
            until IndexEntry.Next() = 0;

        ProgressDialog.Close();
        Commit();
        exit(IndexCount);
    end;

    local procedure BuildCompositeKeyFromRecord(RecRef: RecordRef; KeyFieldList: List of [Integer]): Text
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        CompositeKey: Text;
    begin
        CompositeKey := '';
        foreach FieldNo in KeyFieldList do begin
            if RecRef.FieldExist(FieldNo) then begin
                FieldRef := RecRef.Field(FieldNo);
                if CompositeKey <> '' then
                    CompositeKey += '|';
                CompositeKey += Format(FieldRef.Value);
            end;
        end;
        exit(CompositeKey);
    end;

    procedure CalculateSelectivityForAllTables(): Integer
    var
        TableIndex: Record "Table Index";
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating Selectivity for All Tables...\Table: #1######## #2##############################\Progress: #3#### / #4####';
        TotalTables: Integer;
        CurrentTable: Integer;
        TotalIndexes: Integer;
        TableIndexCount: Integer;
    begin
        TableIndex.Reset();
        TableIndex.SetFilter("Total Record Count", '>1'); // Only tables with more than 1 record
        TotalTables := TableIndex.Count();

        if TotalTables = 0 then
            exit(0);

        ProgressDialog.Open(ProgressMsg);
        CurrentTable := 0;
        TotalIndexes := 0;

        if TableIndex.FindSet() then
            repeat
                CurrentTable += 1;
                ProgressDialog.Update(1, TableIndex."Table ID");
                ProgressDialog.Update(2, TableIndex."Table Name");
                ProgressDialog.Update(3, CurrentTable);
                ProgressDialog.Update(4, TotalTables);

                TableIndexCount := CalculateSelectivityForTable(TableIndex."Table ID", TableIndex."Table Name");
                TotalIndexes += TableIndexCount;
                Commit();
            until TableIndex.Next() = 0;

        ProgressDialog.Close();
        exit(TotalIndexes);
    end;

}
