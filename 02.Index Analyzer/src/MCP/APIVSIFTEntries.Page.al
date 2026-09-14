namespace DefaultNamespace;

page 50934 "DTC API VSIFT Entries"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'VSIFT Entry';
    EntitySetCaption = 'VSIFT Entries';
    EntityName = 'vsiftEntry';
    EntitySetName = 'vsiftEntries';
    SourceTable = "DTC VSIFT Entry";
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
                field(siftFields; Rec."SIFT Fields") { Caption = 'SIFT Fields'; }
                field(noOfFields; Rec."No. of Fields") { Caption = 'No. of Fields'; }
                field(totalRecordCount; Rec."Total Record Count") { Caption = 'Total Record Count'; }
                field(groupCount; Rec."Group Count") { Caption = 'Group Count'; }
                field(minGroupValue; Rec."Min Group Value") { Caption = 'Min Group Value'; }
                field(maxGroupValue; Rec."Max Group Value") { Caption = 'Max Group Value'; }
                field(avgGroupValue; Rec."Avg Group Value") { Caption = 'Avg Group Value'; }
                field(lastUpdated; Rec."Last Updated") { Caption = 'Last Updated'; }
            }
        }
    }
}
