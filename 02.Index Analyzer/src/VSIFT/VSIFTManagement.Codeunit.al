namespace DefaultNamespace;

using System.Reflection;

codeunit 50900 "VSIFT Management"
{
    procedure CollectVSIFTData()
    begin
        CollectVSIFTDataFromTable(0, true);
    end;

    procedure CollectVSIFTDataFromTable(StartFromTableID: Integer; ClearExisting: Boolean)
    var
        VSIFTEntry: Record "VSIFT Entry";
        VSIFTDetail: Record "VSIFT Detail";
        TableMetadata: Record "Table Metadata";
        KeyMetadata: Record "Key";
        AllObj: Record AllObjWithCaption;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Processing VSIFT Data...\Table: #1######## #2##############################\Key Index: #3#### Fields: #4##############################';
        LastTableID: Integer;
    begin
        // Clear existing data if requested
        if ClearExisting then begin
            VSIFTEntry.Truncate();
            VSIFTDetail.Truncate();
        end else
            if StartFromTableID > 0 then begin
                // Delete existing records for the starting table and onwards (including details)
                VSIFTEntry.SetFilter("Table ID", '>=%1', StartFromTableID);
                if VSIFTEntry.FindSet() then
                    repeat
                        VSIFTDetail.SetRange("VSIFT Entry No.", VSIFTEntry."Entry No.");
                        VSIFTDetail.DeleteAll();
                    until VSIFTEntry.Next() = 0;
                VSIFTEntry.Reset();
                VSIFTEntry.SetFilter("Table ID", '>=%1', StartFromTableID);
                VSIFTEntry.DeleteAll();
                VSIFTEntry.Reset();
            end;

        ProgressDialog.Open(ProgressMsg);
        LastTableID := 0;

        // Loop through all tables (excluding system, virtual, and internal/private tables)
        TableMetadata.SetFilter(ID, '<%1', 2000000000); // Exclude system tables
        if StartFromTableID > 0 then
            TableMetadata.SetFilter(ID, '>=%1&<%2', StartFromTableID, 2000000000); // Start from specified table (inclusive)
        TableMetadata.SetRange(TableType, TableMetadata.TableType::Normal); // Exclude virtual tables
        TableMetadata.SetRange(Access, TableMetadata.Access::Public); // Only public tables (exclude internal/private)
        if TableMetadata.FindSet() then
            repeat
                // Get table name
                AllObj.Reset();
                AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
                AllObj.SetRange("Object ID", TableMetadata.ID);
                if AllObj.FindFirst() then begin
                    // Check if we can access the table before processing
                    if CanAccessTable(TableMetadata.ID) then begin
                        // Find keys with SIFT
                        KeyMetadata.Reset();
                        KeyMetadata.SetRange(TableNo, TableMetadata.ID);
                        KeyMetadata.SetFilter(SumIndexFields, '<>%1', '');
                        if KeyMetadata.FindSet() then
                            repeat
                                // Update progress dialog BEFORE processing the key
                                ProgressDialog.Update(1, TableMetadata.ID);
                                ProgressDialog.Update(2, AllObj."Object Name");
                                ProgressDialog.Update(3, KeyMetadata."No.");
                                ProgressDialog.Update(4, KeyMetadata."Key");

                                CreateVSIFTEntry(VSIFTEntry, KeyMetadata, AllObj."Object Name");
                                CreateVSIFTDetails(VSIFTEntry, KeyMetadata);
                            until KeyMetadata.Next() = 0;

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

    procedure GetLastProcessedTableID(): Integer
    var
        VSIFTEntry: Record "VSIFT Entry";
    begin
        VSIFTEntry.Reset();
        if VSIFTEntry.FindLast() then
            exit(VSIFTEntry."Table ID");
        exit(0);
    end;

    procedure HasExistingData(): Boolean
    var
        VSIFTEntry: Record "VSIFT Entry";
    begin
        exit(not VSIFTEntry.IsEmpty());
    end;

    procedure CollectVSIFTDataForTable(TableID: Integer)
    var
        VSIFTEntry: Record "VSIFT Entry";
        VSIFTDetail: Record "VSIFT Detail";
        KeyMetadata: Record "Key";
        AllObj: Record AllObjWithCaption;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Processing VSIFT Data for Table #1########...\Key Index: #2#### Fields: #3##############################';
    begin
        if TableID = 0 then
            exit;

        // Delete existing records for this table
        VSIFTEntry.SetRange("Table ID", TableID);
        if VSIFTEntry.FindSet() then
            repeat
                VSIFTDetail.SetRange("VSIFT Entry No.", VSIFTEntry."Entry No.");
                VSIFTDetail.DeleteAll();
            until VSIFTEntry.Next() = 0;
        VSIFTEntry.Reset();
        VSIFTEntry.SetRange("Table ID", TableID);
        VSIFTEntry.DeleteAll();
        VSIFTEntry.Reset();

        // Get table name
        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", TableID);
        if not AllObj.FindFirst() then
            exit;

        // Check if we can access the table before processing
        if not CanAccessTable(TableID) then
            exit;

        ProgressDialog.Open(ProgressMsg);
        ProgressDialog.Update(1, TableID);

        // Find keys with SIFT for this table
        KeyMetadata.Reset();
        KeyMetadata.SetRange(TableNo, TableID);
        KeyMetadata.SetFilter(SumIndexFields, '<>%1', '');
        if KeyMetadata.FindSet() then
            repeat
                // Update progress dialog
                ProgressDialog.Update(2, KeyMetadata."No.");
                ProgressDialog.Update(3, KeyMetadata."Key");

                CreateVSIFTEntry(VSIFTEntry, KeyMetadata, AllObj."Object Name");
                CreateVSIFTDetails(VSIFTEntry, KeyMetadata);
            until KeyMetadata.Next() = 0;

        ProgressDialog.Close();
    end;

    local procedure CanAccessTable(TableID: Integer): Boolean
    var
        RecRef: RecordRef;
        RecordCount: Integer;
    begin
        // Try to open the table and get record count to verify access
        if not TryGetRecordCount(TableID, RecordCount) then
            exit(false);
        exit(true);
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

    local procedure CreateVSIFTEntry(var VSIFTEntry: Record "VSIFT Entry"; KeyMetadata: Record "Key"; TableName: Text[250])
    begin
        Clear(VSIFTEntry);
        VSIFTEntry.Init();
        VSIFTEntry."Table ID" := KeyMetadata.TableNo;
        VSIFTEntry."Table Name" := TableName;
        VSIFTEntry."Key Index" := KeyMetadata."No.";
        // Key field contains field names, SumIndexFields contains field numbers
        VSIFTEntry."Key Fields" := CopyStr(KeyMetadata."Key", 1, 250);
        VSIFTEntry."SIFT Fields" := CopyStr(KeyMetadata.SumIndexFields, 1, 250);
        VSIFTEntry."No. of Fields" := CountFieldsInKey(KeyMetadata."Key");

        // Calculate statistics
        CalculateVSIFTStatistics(VSIFTEntry, KeyMetadata);

        VSIFTEntry.Insert(true);
    end;

    local procedure CreateVSIFTDetails(var VSIFTEntry: Record "VSIFT Entry"; KeyMetadata: Record "Key")
    var
        VSIFTDetail: Record "VSIFT Detail";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyFieldList: List of [Integer];
        GroupDict: Dictionary of [Text, Integer];
        BucketDict: Dictionary of [Integer, Integer];
        GroupKey: Text;
        GroupKeys: List of [Text];
        BucketKeys: List of [Integer];
        RecordCount: Integer;
        BucketValue: Integer;
    begin
        // Group records by unique key field combinations and count records per group
        GetFieldNumbersFromNames(KeyMetadata.TableNo, KeyMetadata."Key", KeyFieldList);

        RecRef.Open(KeyMetadata.TableNo);
        if RecRef.FindSet() then begin
            repeat
                // Build the group key from key fields
                GroupKey := BuildGroupKey(RecRef, KeyFieldList);

                // Update the count dictionary
                if GroupDict.ContainsKey(GroupKey) then
                    GroupDict.Set(GroupKey, GroupDict.Get(GroupKey) + 1)
                else
                    GroupDict.Add(GroupKey, 1);
            until RecRef.Next() = 0;
        end;
        RecRef.Close();

        // Now create bucket distribution - how many groups have each record count
        GroupKeys := GroupDict.Keys;
        foreach GroupKey in GroupKeys do begin
            RecordCount := GroupDict.Get(GroupKey);

            if BucketDict.ContainsKey(RecordCount) then
                BucketDict.Set(RecordCount, BucketDict.Get(RecordCount) + 1)
            else
                BucketDict.Add(RecordCount, 1);
        end;

        // Create VSIFT Detail records for each bucket
        BucketKeys := BucketDict.Keys;
        foreach BucketValue in BucketKeys do begin
            Clear(VSIFTDetail);
            VSIFTDetail.Init();
            VSIFTDetail."VSIFT Entry No." := VSIFTEntry."Entry No.";
            VSIFTDetail.Bucket := BucketValue;
            VSIFTDetail."No. of Groups" := BucketDict.Get(BucketValue);
            VSIFTDetail.Insert();
        end;
    end;

    local procedure CalculateVSIFTStatistics(var VSIFTEntry: Record "VSIFT Entry"; KeyMetadata: Record "Key")
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyFieldList: List of [Integer];
        SIFTFieldList: List of [Integer];
        GroupDict: Dictionary of [Text, Decimal];
        CountDict: Dictionary of [Text, Integer];
        GroupKey: Text;
        SumAmount: Decimal;
        MinValue, MaxValue : Integer;
        TotalSum: Decimal;
        TotalGroups, TotalRecordCount : Integer;
        IsFirstGroup: Boolean;
        GroupKeys: List of [Text];
        GroupValue: Decimal;
        GroupCount: Integer;
    begin
        RecRef.Open(KeyMetadata.TableNo);
        VSIFTEntry."Total Record Count" := RecRef.Count();

        GetFieldNumbersFromNames(KeyMetadata.TableNo, KeyMetadata."Key", KeyFieldList);
        ParseFieldList(KeyMetadata.SumIndexFields, SIFTFieldList);

        // Group records and calculate per-group statistics
        if RecRef.FindSet() then begin
            repeat
                // Build the group key from key fields
                GroupKey := BuildGroupKey(RecRef, KeyFieldList);

                // Accumulate SIFT field values for this group
                SumAmount := 0;
                if SIFTFieldList.Count > 0 then begin
                    if RecRef.FieldExist(SIFTFieldList.Get(1)) then begin
                        FieldRef := RecRef.Field(SIFTFieldList.Get(1));
                        SumAmount := GetDecimalValue(FieldRef);
                    end;
                end;

                // Update the dictionary with accumulated values
                if GroupDict.ContainsKey(GroupKey) then begin
                    GroupDict.Set(GroupKey, GroupDict.Get(GroupKey) + SumAmount);
                    CountDict.Set(GroupKey, CountDict.Get(GroupKey) + 1);
                end else begin
                    GroupDict.Add(GroupKey, SumAmount);
                    CountDict.Add(GroupKey, 1);
                end;
            until RecRef.Next() = 0;
        end;
        RecRef.Close();

        // Calculate statistics based on the VSIFT group values (bucket counts)
        IsFirstGroup := true;
        MinValue := 0;
        MaxValue := 0;
        TotalSum := 0;
        TotalGroups := CountDict.Count;
        VSIFTEntry."Group Count" := TotalGroups;

        GroupKeys := CountDict.Keys;
        foreach GroupKey in GroupKeys do begin
            GroupCount := CountDict.Get(GroupKey); // This is the VSIFT value - count of records in the bucket

            if IsFirstGroup then begin
                MinValue := GroupCount;
                MaxValue := GroupCount;
                IsFirstGroup := false;
            end else begin
                if GroupCount < MinValue then
                    MinValue := GroupCount;
                if GroupCount > MaxValue then
                    MaxValue := GroupCount;
            end;

            TotalSum += GroupCount;
        end;

        VSIFTEntry."Min Group Value" := MinValue;
        VSIFTEntry."Max Group Value" := MaxValue;
        if TotalGroups > 0 then
            VSIFTEntry."Avg Group Value" := TotalSum / TotalGroups;
    end;

    local procedure GetFieldNamesFromNumbers(TableNo: Integer; FieldList: Text): Text[250]
    var
        FieldRef: FieldRef;
        RecRef: RecordRef;
        FieldNoList: List of [Integer];
        FieldNames: Text;
        FieldNo: Integer;
    begin
        // Both Key and SumIndexFields contain field numbers that need to be converted to names
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
        exit(CopyStr(FieldNames, 1, 250));
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

    local procedure GetFieldNumbersFromNames(TableNo: Integer; FieldNames: Text; var FieldNoList: List of [Integer])
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

    local procedure GetDecimalValue(FieldRef: FieldRef): Decimal
    var
        DecValue: Decimal;
    begin
        case FieldRef.Type of
            FieldType::Decimal,
            FieldType::Integer,
            FieldType::BigInteger:
                DecValue := FieldRef.Value;
            else
                DecValue := 0;
        end;
        exit(DecValue);
    end;

    local procedure BuildGroupKey(RecRef: RecordRef; KeyFieldList: List of [Integer]): Text
    var
        FieldRef: FieldRef;
        FieldNo: Integer;
        GroupKey: Text;
    begin
        GroupKey := '';
        foreach FieldNo in KeyFieldList do begin
            if RecRef.FieldExist(FieldNo) then begin
                FieldRef := RecRef.Field(FieldNo);
                if GroupKey <> '' then
                    GroupKey += '|';
                GroupKey += Format(FieldRef.Value);
            end;
        end;
        exit(GroupKey);
    end;

    local procedure CountFieldsInKey(KeyFields: Text): Integer
    var
        FieldCount: Integer;
        i: Integer;
    begin
        if KeyFields = '' then
            exit(0);

        FieldCount := 1;
        for i := 1 to StrLen(KeyFields) do begin
            if KeyFields[i] = ',' then
                FieldCount += 1;
        end;
        exit(FieldCount);
    end;

    /// <summary>
    /// Calculates selectivity for a single VSIFT entry.
    /// </summary>
    procedure CalculateSelectivity(var VSIFTEntry: Record "VSIFT Entry")
    var
        IndexSelectivity: Record "Index Selectivity";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        KeyFieldList: List of [Integer];
        FieldNo: Integer;
        FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]];
        AllFieldNames: Dictionary of [Integer, Text];
        TempFieldDict: Dictionary of [Text, Integer];
        FieldValue: Text;
        CompositeKeyValue: Text;
        CompositeKeyDict: Dictionary of [Text, Integer];
        TotalRows: Integer;
        ProcessedRows: Integer;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating VSIFT Selectivity...\Phase: #1##############################\Progress: #2#### / #3####';
    begin
        // Delete existing selectivity records for this VSIFT entry only
        IndexSelectivity.SetRange("Source Type", IndexSelectivity."Source Type"::VSIFT);
        IndexSelectivity.SetRange("Index Entry No.", VSIFTEntry."Entry No.");
        IndexSelectivity.DeleteAll();

        // Get field numbers from key fields (field names)
        GetFieldNumbersFromNames(VSIFTEntry."Table ID", VSIFTEntry."Key Fields", KeyFieldList);

        if KeyFieldList.Count = 0 then
            exit;

        ProgressDialog.Open(ProgressMsg);

        // Open the table and prepare field name mapping
        RecRef.Open(VSIFTEntry."Table ID");
        TotalRows := RecRef.Count();

        if TotalRows = 0 then begin
            RecRef.Close();
            ProgressDialog.Close();
            exit;
        end;

        // Initialize dictionaries for all fields
        foreach FieldNo in KeyFieldList do begin
            if RecRef.FieldExist(FieldNo) then begin
                FieldRef := RecRef.Field(FieldNo);
                AllFieldNames.Add(FieldNo, FieldRef.Name);
                Clear(TempFieldDict);
                FieldDistinctValues.Add(FieldNo, TempFieldDict);
            end;
        end;

        // SINGLE PASS: Collect ALL field values and composite key at once
        ProgressDialog.Update(1, 'Collecting field values...');
        ProgressDialog.Update(3, TotalRows);

        if RecRef.FindSet() then
            repeat
                ProcessedRows += 1;
                if ProcessedRows mod 1000 = 0 then
                    ProgressDialog.Update(2, ProcessedRows);

                // Build composite key
                CompositeKeyValue := '';
                foreach FieldNo in KeyFieldList do begin
                    if RecRef.FieldExist(FieldNo) then begin
                        FieldRef := RecRef.Field(FieldNo);
                        FieldValue := Format(FieldRef.Value);

                        // Add to individual field dictionary
                        TempFieldDict := FieldDistinctValues.Get(FieldNo);
                        if not TempFieldDict.ContainsKey(FieldValue) then
                            TempFieldDict.Add(FieldValue, 1)
                        else
                            TempFieldDict.Set(FieldValue, TempFieldDict.Get(FieldValue) + 1);
                        FieldDistinctValues.Set(FieldNo, TempFieldDict);

                        // Build composite key
                        if CompositeKeyValue <> '' then
                            CompositeKeyValue += '|';
                        CompositeKeyValue += FieldValue;
                    end;
                end;

                // Track composite key
                if not CompositeKeyDict.ContainsKey(CompositeKeyValue) then
                    CompositeKeyDict.Add(CompositeKeyValue, 1)
                else
                    CompositeKeyDict.Set(CompositeKeyValue, CompositeKeyDict.Get(CompositeKeyValue) + 1);
            until RecRef.Next() = 0;

        RecRef.Close();

        // Now create selectivity records for individual fields
        ProgressDialog.Update(1, 'Creating selectivity records...');
        CreateSelectivityRecordsForVSIFT(
            VSIFTEntry,
            KeyFieldList,
            AllFieldNames,
            FieldDistinctValues,
            CompositeKeyDict,
            TotalRows);

        ProgressDialog.Close();
    end;

    local procedure CreateSelectivityRecordsForVSIFT(
        VSIFTEntry: Record "VSIFT Entry";
        KeyFieldList: List of [Integer];
        AllFieldNames: Dictionary of [Integer, Text];
        FieldDistinctValues: Dictionary of [Integer, Dictionary of [Text, Integer]];
        CompositeKeyDict: Dictionary of [Text, Integer];
        TotalRows: Integer)
    var
        IndexSelectivity: Record "Index Selectivity";
        TempFieldDict: Dictionary of [Text, Integer];
        FieldNo: Integer;
        FieldPosition: Integer;
        DistinctCount: Integer;
        SelectivityValue: Decimal;
        DensityValue: Decimal;
    begin
        // Create Individual Field records
        foreach FieldNo in KeyFieldList do begin
            if FieldDistinctValues.ContainsKey(FieldNo) then begin
                FieldPosition += 1;
                TempFieldDict := FieldDistinctValues.Get(FieldNo);
                DistinctCount := TempFieldDict.Count;

                if TotalRows > 0 then begin
                    SelectivityValue := DistinctCount / TotalRows;
                    if DistinctCount > 0 then
                        DensityValue := 1 / DistinctCount
                    else
                        DensityValue := 1;
                end else begin
                    SelectivityValue := 0;
                    DensityValue := 1;
                end;

                Clear(IndexSelectivity);
                IndexSelectivity.Init();
                IndexSelectivity."Source Type" := IndexSelectivity."Source Type"::VSIFT;
                IndexSelectivity."Index Entry No." := VSIFTEntry."Entry No.";
                IndexSelectivity."Table ID" := VSIFTEntry."Table ID";
                IndexSelectivity."Table Name" := VSIFTEntry."Table Name";
                IndexSelectivity."Key Index" := VSIFTEntry."Key Index";
                IndexSelectivity."Selectivity Type" := IndexSelectivity."Selectivity Type"::Field;
                IndexSelectivity."Field No." := FieldNo;
                if AllFieldNames.ContainsKey(FieldNo) then
                    IndexSelectivity."Field Name" := CopyStr(AllFieldNames.Get(FieldNo), 1, 250);
                IndexSelectivity."Field Position" := FieldPosition;
                IndexSelectivity."Distinct Values" := DistinctCount;
                IndexSelectivity."Total Rows" := TotalRows;
                IndexSelectivity.Selectivity := SelectivityValue;
                IndexSelectivity.Density := DensityValue;
                IndexSelectivity.Insert(true);
            end;
        end;

        // Create Composite Key record
        DistinctCount := CompositeKeyDict.Count;
        if TotalRows > 0 then begin
            SelectivityValue := DistinctCount / TotalRows;
            if DistinctCount > 0 then
                DensityValue := 1 / DistinctCount
            else
                DensityValue := 1;
        end else begin
            SelectivityValue := 0;
            DensityValue := 1;
        end;

        Clear(IndexSelectivity);
        IndexSelectivity.Init();
        IndexSelectivity."Source Type" := IndexSelectivity."Source Type"::VSIFT;
        IndexSelectivity."Index Entry No." := VSIFTEntry."Entry No.";
        IndexSelectivity."Table ID" := VSIFTEntry."Table ID";
        IndexSelectivity."Table Name" := VSIFTEntry."Table Name";
        IndexSelectivity."Key Index" := VSIFTEntry."Key Index";
        IndexSelectivity."Selectivity Type" := IndexSelectivity."Selectivity Type"::Index;
        IndexSelectivity."Field Position" := KeyFieldList.Count + 1;
        IndexSelectivity."Distinct Values" := DistinctCount;
        IndexSelectivity."Total Rows" := TotalRows;
        IndexSelectivity.Selectivity := SelectivityValue;
        IndexSelectivity.Density := DensityValue;
        IndexSelectivity.Insert(true);
    end;

    /// <summary>
    /// Calculates selectivity for all VSIFT entries in a specific table.
    /// </summary>
    procedure CalculateSelectivityForTable(TableID: Integer): Integer
    var
        VSIFTEntry: Record "VSIFT Entry";
        ProcessedCount: Integer;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating VSIFT Selectivity for Table...\Progress: #1#### / #2####';
        TotalCount: Integer;
    begin
        VSIFTEntry.SetRange("Table ID", TableID);
        TotalCount := VSIFTEntry.Count();
        if TotalCount = 0 then
            exit(0);

        ProgressDialog.Open(ProgressMsg);
        ProgressDialog.Update(2, TotalCount);

        if VSIFTEntry.FindSet() then
            repeat
                ProcessedCount += 1;
                ProgressDialog.Update(1, ProcessedCount);
                CalculateSelectivity(VSIFTEntry);
            until VSIFTEntry.Next() = 0;

        ProgressDialog.Close();
        exit(ProcessedCount);
    end;

    /// <summary>
    /// Calculates selectivity for all VSIFT entries across all tables.
    /// </summary>
    procedure CalculateSelectivityForAll(): Integer
    var
        VSIFTEntry: Record "VSIFT Entry";
        TableIDList: List of [Integer];
        TableID: Integer;
        ProcessedTableCount: Integer;
        TableCount: Integer;
        ProgressDialog: Dialog;
        ProgressMsg: Label 'Calculating VSIFT Selectivity for All Tables...\Table: #1#### / #2#### - #3##################';
    begin
        // Collect distinct Table IDs
        VSIFTEntry.SetFilter("Total Record Count", '>1');
        if VSIFTEntry.FindSet() then
            repeat
                if not TableIDList.Contains(VSIFTEntry."Table ID") then
                    TableIDList.Add(VSIFTEntry."Table ID");
            until VSIFTEntry.Next() = 0;

        TableCount := TableIDList.Count;
        if TableCount = 0 then
            exit(0);

        ProgressDialog.Open(ProgressMsg);
        ProgressDialog.Update(2, TableCount);

        // Process each table
        foreach TableID in TableIDList do begin
            ProcessedTableCount += 1;
            ProgressDialog.Update(1, ProcessedTableCount);
            ProgressDialog.Update(3, GetTableNameById(TableID));
            CalculateSelectivityForTable(TableID);
        end;

        ProgressDialog.Close();
        exit(ProcessedTableCount);
    end;

    local procedure GetTableNameById(TableID: Integer): Text[250]
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, TableID) then
            exit(CopyStr(AllObjWithCaption."Object Name", 1, 250));
        exit('');
    end;
}
