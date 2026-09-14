namespace DefaultNamespace;

codeunit 50941 "DTC Telemetry Management"
{
    procedure SendAllSignals()
    var
        IndexEntryCount: Integer;
        IndexDetailCount: Integer;
        IndexSelectivityCount: Integer;
        MissingIndexCount: Integer;
        VSIFTEntryCount: Integer;
        VSIFTDetailCount: Integer;
        TableIndexCount: Integer;
        SummaryMsg: Label 'Telemetry signals sent.\Table Index: %1\Index Entry: %2\Index Detail: %3\Index Selectivity: %4\Missing Index: %5\VSIFT Entry: %6\VSIFT Detail: %7', Comment = '%1 = Table Index count, %2 = Index Entry count, %3 = Index Detail count, %4 = Index Selectivity count, %5 = Missing Index count, %6 = VSIFT Entry count, %7 = VSIFT Detail count';
    begin
        TableIndexCount := SendTableIndexSignals();
        IndexEntryCount := SendIndexEntrySignals();
        IndexDetailCount := SendIndexDetailSignals();
        IndexSelectivityCount := SendIndexSelectivitySignals();
        MissingIndexCount := SendMissingIndexSignals();
        VSIFTEntryCount := SendVSIFTEntrySignals();
        VSIFTDetailCount := SendVSIFTDetailSignals();

        Message(
            SummaryMsg,
            TableIndexCount,
            IndexEntryCount,
            IndexDetailCount,
            IndexSelectivityCount,
            MissingIndexCount,
            VSIFTEntryCount,
            VSIFTDetailCount);
    end;

    procedure SendTableIndexSignals(): Integer
    var
        TableIndex: Record "DTC Table Index";
        Dimensions: Dictionary of [Text, Text];
        Count: Integer;
    begin
        if TableIndex.FindSet() then
            repeat
                TableIndex.CalcFields("No. of LRQ", "Total Duration of LRQ", "No. of FF", "No. of Missing Indexes");
                Clear(Dimensions);
                Dimensions.Add('TableID', Format(TableIndex."Table ID"));
                Dimensions.Add('TableName', TableIndex."Table Name");
                Dimensions.Add('NoOfIndexes', Format(TableIndex."No. of Indexes"));
                Dimensions.Add('NoOfVSIFTIndexes', Format(TableIndex."No. of VSIFT Indexes"));
                Dimensions.Add('NoOfIndexesWithIncluded', Format(TableIndex."No. of Indexes with Included"));
                Dimensions.Add('NoOfIndexesWithSIFT', Format(TableIndex."No. of Indexes with SIFT"));
                Dimensions.Add('TotalRecordCount', Format(TableIndex."Total Record Count"));
                Dimensions.Add('NoOfLRQ', Format(TableIndex."No. of LRQ"));
                Dimensions.Add('TotalDurationOfLRQ', Format(TableIndex."Total Duration of LRQ"));
                Dimensions.Add('NoOfFF', Format(TableIndex."No. of FF"));
                Dimensions.Add('NoOfMissingIndexes', Format(TableIndex."No. of Missing Indexes"));
                Dimensions.Add('LastUpdated', Format(TableIndex."Last Updated", 0, 9));
                LogSignal('DTC0011', 'Table Index', Dimensions);
                Count += 1;
            until TableIndex.Next() = 0;
        exit(Count);
    end;

    procedure SendIndexEntrySignals(): Integer
    var
        IndexEntry: Record "DTC Index Entry";
        Dimensions: Dictionary of [Text, Text];
        Count: Integer;
    begin
        if IndexEntry.FindSet() then
            repeat
                Clear(Dimensions);
                Dimensions.Add('EntryNo', Format(IndexEntry."Entry No."));
                Dimensions.Add('TableID', Format(IndexEntry."Table ID"));
                Dimensions.Add('TableName', IndexEntry."Table Name");
                Dimensions.Add('KeyIndex', Format(IndexEntry."Key Index"));
                Dimensions.Add('ALKeyName', IndexEntry."AL Key Name");
                Dimensions.Add('KeyFields', IndexEntry."Key Fields");
                Dimensions.Add('IncludedColumns', IndexEntry."Included Columns");
                Dimensions.Add('SQLIndex', IndexEntry."SQL Index");
                Dimensions.Add('NoOfKeyFields', Format(IndexEntry."No. of Key Fields"));
                Dimensions.Add('NoOfIncludedColumns', Format(IndexEntry."No. of Included Columns"));
                Dimensions.Add('Clustered', Format(IndexEntry.Clustered));
                Dimensions.Add('MaintainSIFTIndex', Format(IndexEntry."Maintain SIFT Index"));
                Dimensions.Add('SIFTFields', IndexEntry."SIFT Fields");
                Dimensions.Add('Unique', Format(IndexEntry.Unique));
                Dimensions.Add('Enabled', Format(IndexEntry.Enabled));
                Dimensions.Add('TotalRecordCount', Format(IndexEntry."Total Record Count"));
                Dimensions.Add('DatabaseStartTime', IndexEntry."Database Start Time");
                Dimensions.Add('LastUpdated', IndexEntry."Last Updated");
                Dimensions.Add('FragmentationPct', Format(IndexEntry."Fragmentation %"));
                Dimensions.Add('UserSeeks', Format(IndexEntry."User Seeks"));
                Dimensions.Add('UserScans', Format(IndexEntry."User Scans"));
                Dimensions.Add('UserLookups', Format(IndexEntry."User Lookups"));
                Dimensions.Add('UserUpdates', Format(IndexEntry."User Updates"));
                Dimensions.Add('LastSeek', IndexEntry."Last Seek");
                Dimensions.Add('LastScan', IndexEntry."Last Scan");
                Dimensions.Add('LastLookup', IndexEntry."Last Lookup");
                Dimensions.Add('LastUpdate', IndexEntry."Last Update");
                Dimensions.Add('EnabledInDatabase', Format(IndexEntry."Enabled in Database"));
                Dimensions.Add('ALDefined', Format(IndexEntry."AL Defined"));
                Dimensions.Add('IndexSizeKB', Format(IndexEntry."Index Size (kB)"));
                Dimensions.Add('StatisticsUpdatedAt', IndexEntry."Statistics Updated At");
                Dimensions.Add('Paired', Format(IndexEntry.Paired));
                Dimensions.Add('CreatedFromPairings', Format(IndexEntry."Created From Pairings"));
                LogSignal('DTC0010', 'Index Entry', Dimensions);
                Count += 1;
            until IndexEntry.Next() = 0;
        exit(Count);
    end;

    procedure SendIndexDetailSignals(): Integer
    var
        IndexDetail: Record "DTC Index Detail";
        Dimensions: Dictionary of [Text, Text];
        Count: Integer;
    begin
        if IndexDetail.FindSet() then
            repeat
                Clear(Dimensions);
                Dimensions.Add('EntryNo', Format(IndexDetail."Entry No."));
                Dimensions.Add('IndexEntryNo', Format(IndexDetail."Index Entry No."));
                Dimensions.Add('SelectivityType', Format(IndexDetail."Selectivity Type"));
                Dimensions.Add('FieldNo', Format(IndexDetail."Field No."));
                Dimensions.Add('FieldName', IndexDetail."Field Name");
                Dimensions.Add('Bucket', Format(IndexDetail.Bucket));
                Dimensions.Add('NoOfGroups', Format(IndexDetail."No. of Groups"));
                LogSignal('DTC0013', 'Index Detail', Dimensions);
                Count += 1;
            until IndexDetail.Next() = 0;
        exit(Count);
    end;

    procedure SendIndexSelectivitySignals(): Integer
    var
        IndexSelectivity: Record "DTC Index Selectivity";
        Dimensions: Dictionary of [Text, Text];
        Count: Integer;
    begin
        if IndexSelectivity.FindSet() then
            repeat
                Clear(Dimensions);
                Dimensions.Add('EntryNo', Format(IndexSelectivity."Entry No."));
                Dimensions.Add('IndexEntryNo', Format(IndexSelectivity."Index Entry No."));
                Dimensions.Add('TableID', Format(IndexSelectivity."Table ID"));
                Dimensions.Add('TableName', IndexSelectivity."Table Name");
                Dimensions.Add('KeyIndex', Format(IndexSelectivity."Key Index"));
                Dimensions.Add('SourceType', Format(IndexSelectivity."Source Type"));
                Dimensions.Add('MissingIndexEntryNo', Format(IndexSelectivity."Missing Index Entry No."));
                Dimensions.Add('SuggestedKeyFields', IndexSelectivity."Suggested Key Fields");
                Dimensions.Add('SelectivityType', Format(IndexSelectivity."Selectivity Type"));
                Dimensions.Add('FieldNo', Format(IndexSelectivity."Field No."));
                Dimensions.Add('FieldName', IndexSelectivity."Field Name");
                Dimensions.Add('FieldPosition', Format(IndexSelectivity."Field Position"));
                Dimensions.Add('DistinctValues', Format(IndexSelectivity."Distinct Values"));
                Dimensions.Add('TotalRows', Format(IndexSelectivity."Total Rows"));
                Dimensions.Add('Selectivity', Format(IndexSelectivity.Selectivity, 0, 9));
                Dimensions.Add('Density', Format(IndexSelectivity.Density, 0, 9));
                Dimensions.Add('LastUpdated', Format(IndexSelectivity."Last Updated", 0, 9));
                LogSignal('DTC0012', 'Index Selectivity', Dimensions);
                Count += 1;
            until IndexSelectivity.Next() = 0;
        exit(Count);
    end;

    procedure SendMissingIndexSignals(): Integer
    var
        MissingIndex: Record "DTC Missing Index";
        Dimensions: Dictionary of [Text, Text];
        Count: Integer;
    begin
        if MissingIndex.FindSet() then
            repeat
                Clear(Dimensions);
                Dimensions.Add('EntryNo', Format(MissingIndex."Entry No."));
                Dimensions.Add('SQLTableName', MissingIndex."SQL Table Name");
                Dimensions.Add('TableID', Format(MissingIndex."Table ID"));
                Dimensions.Add('ALTableName', MissingIndex."AL Table Name");
                Dimensions.Add('ExtensionId', Format(MissingIndex."Extension Id"));
                Dimensions.Add('EqualityFields', MissingIndex."Equality Fields");
                Dimensions.Add('InequalityFields', MissingIndex."Inequality Fields");
                Dimensions.Add('IncludeFields', MissingIndex."Include Fields");
                Dimensions.Add('NoOfEqualityFields', Format(MissingIndex."No. of Equality Fields"));
                Dimensions.Add('NoOfInequalityFields', Format(MissingIndex."No. of Inequality Fields"));
                Dimensions.Add('NoOfIncludeFields', Format(MissingIndex."No. of Include Fields"));
                Dimensions.Add('Seeks', Format(MissingIndex.Seeks));
                Dimensions.Add('Scans', Format(MissingIndex.Scans));
                Dimensions.Add('AverageTotalCost', Format(MissingIndex."Average Total Cost", 0, 9));
                Dimensions.Add('AverageImpact', Format(MissingIndex."Average Impact", 0, 9));
                Dimensions.Add('EstimatedBenefit', Format(MissingIndex."Estimated Benefit", 0, 9));
                Dimensions.Add('IsVSIFT', Format(MissingIndex."Is VSIFT"));
                Dimensions.Add('VSIFTKey', Format(MissingIndex."VSIFT Key"));
                Dimensions.Add('SuggestedIndex', MissingIndex."Suggested Index");
                Dimensions.Add('SelectivityCalculated', Format(MissingIndex."Selectivity Calculated"));
                Dimensions.Add('ImportDateTime', Format(MissingIndex."Import DateTime", 0, 9));
                LogSignal('DTC0025', 'Missing Index', Dimensions);
                Count += 1;
            until MissingIndex.Next() = 0;
        exit(Count);
    end;

    procedure SendVSIFTEntrySignals(): Integer
    var
        VSIFTEntry: Record "DTC VSIFT Entry";
        Dimensions: Dictionary of [Text, Text];
        Count: Integer;
    begin
        if VSIFTEntry.FindSet() then
            repeat
                Clear(Dimensions);
                Dimensions.Add('EntryNo', Format(VSIFTEntry."Entry No."));
                Dimensions.Add('TableID', Format(VSIFTEntry."Table ID"));
                Dimensions.Add('TableName', VSIFTEntry."Table Name");
                Dimensions.Add('KeyIndex', Format(VSIFTEntry."Key Index"));
                Dimensions.Add('ALKeyName', VSIFTEntry."AL Key Name");
                Dimensions.Add('KeyFields', VSIFTEntry."Key Fields");
                Dimensions.Add('SIFTFields', VSIFTEntry."SIFT Fields");
                Dimensions.Add('NoOfFields', Format(VSIFTEntry."No. of Fields"));
                Dimensions.Add('TotalRecordCount', Format(VSIFTEntry."Total Record Count"));
                Dimensions.Add('GroupCount', Format(VSIFTEntry."Group Count"));
                Dimensions.Add('MinGroupValue', Format(VSIFTEntry."Min Group Value"));
                Dimensions.Add('MaxGroupValue', Format(VSIFTEntry."Max Group Value"));
                Dimensions.Add('AvgGroupValue', Format(VSIFTEntry."Avg Group Value", 0, 9));
                Dimensions.Add('LastUpdated', Format(VSIFTEntry."Last Updated", 0, 9));
                LogSignal('DTC0001', 'VSIFT Entry', Dimensions);
                Count += 1;
            until VSIFTEntry.Next() = 0;
        exit(Count);
    end;

    procedure SendVSIFTDetailSignals(): Integer
    var
        VSIFTDetail: Record "DTC VSIFT Detail";
        Dimensions: Dictionary of [Text, Text];
        Count: Integer;
    begin
        if VSIFTDetail.FindSet() then
            repeat
                Clear(Dimensions);
                Dimensions.Add('VSIFTEntryNo', Format(VSIFTDetail."VSIFT Entry No."));
                Dimensions.Add('Bucket', Format(VSIFTDetail.Bucket));
                Dimensions.Add('NoOfGroups', Format(VSIFTDetail."No. of Groups"));
                LogSignal('DTC0002', 'VSIFT Detail', Dimensions);
                Count += 1;
            until VSIFTDetail.Next() = 0;
        exit(Count);
    end;

    local procedure LogSignal(EventId: Text; MessageText: Text; Dimensions: Dictionary of [Text, Text])
    begin
        Session.LogMessage(
            EventId,
            MessageText,
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::All,
            Dimensions);
    end;
}
