namespace DefaultNamespace;

page 50932 "DTC API Index Entries"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'Index Entry';
    EntitySetCaption = 'Index Entries';
    EntityName = 'indexEntry';
    EntitySetName = 'indexEntries';
    SourceTable = "DTC Index Entry";
    ODataKeyFields = SystemId;
    Extensible = false;
    DelayedInsert = true;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(entryNo; Rec."Entry No.") { Caption = 'Entry No.'; }
                field(tableId; Rec."Table ID") { Caption = 'Table ID'; }
                field(tableName; Rec."Table Name") { Caption = 'Table Name'; }
                field(keyIndex; Rec."Key Index") { Caption = 'Key Index'; }
                field(alKeyName; Rec."AL Key Name") { Caption = 'AL Key Name'; }
                field(keyFields; Rec."Key Fields") { Caption = 'Key Fields'; }
                field(includedColumns; Rec."Included Columns") { Caption = 'Included Columns'; }
                field(sqlIndex; Rec."SQL Index") { Caption = 'SQL Index'; }
                field(noOfKeyFields; Rec."No. of Key Fields") { Caption = 'No. of Key Fields'; }
                field(noOfIncludedColumns; Rec."No. of Included Columns") { Caption = 'No. of Included Columns'; }
                field(clustered; Rec.Clustered) { Caption = 'Clustered'; }
                field(maintainSIFTIndex; Rec."Maintain SIFT Index") { Caption = 'Maintain SIFT Index'; }
                field(siftFields; Rec."SIFT Fields") { Caption = 'SIFT Fields'; }
                field(unique; Rec.Unique) { Caption = 'Unique'; }
                field(enabled; Rec.Enabled) { Caption = 'Enabled'; }
                field(totalRecordCount; Rec."Total Record Count") { Caption = 'Total Record Count'; }
                field(databaseStartTime; Rec."Database Start Time") { Caption = 'Database Start Time'; }
                field(lastUpdated; Rec."Last Updated") { Caption = 'Last Updated'; }
                field(fragmentationPercent; Rec."Fragmentation %") { Caption = 'Fragmentation %'; }
                field(userSeeks; Rec."User Seeks") { Caption = 'User Seeks'; }
                field(userScans; Rec."User Scans") { Caption = 'User Scans'; }
                field(userLookups; Rec."User Lookups") { Caption = 'User Lookups'; }
                field(userUpdates; Rec."User Updates") { Caption = 'User Updates'; }
                field(lastSeek; Rec."Last Seek") { Caption = 'Last Seek'; }
                field(lastScan; Rec."Last Scan") { Caption = 'Last Scan'; }
                field(lastLookup; Rec."Last Lookup") { Caption = 'Last Lookup'; }
                field(lastUpdate; Rec."Last Update") { Caption = 'Last Update'; }
                field(enabledInDatabase; Rec."Enabled in Database") { Caption = 'Enabled in Database'; }
                field(alDefined; Rec."AL Defined") { Caption = 'AL Defined'; }
                field(indexSizeKB; Rec."Index Size (kB)") { Caption = 'Index Size (kB)'; }
                field(statisticsUpdatedAt; Rec."Statistics Updated At") { Caption = 'Statistics Updated At'; }
                field(paired; Rec.Paired) { Caption = 'Paired'; }
                field(createdFromPairings; Rec."Created From Pairings") { Caption = 'Created From Pairings'; }
            }
        }
    }
}
