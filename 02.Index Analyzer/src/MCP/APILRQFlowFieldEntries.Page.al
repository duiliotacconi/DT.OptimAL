namespace DefaultNamespace;

page 50939 "DTC API LRQ FlowField Entries"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'LRQ FlowField Entry';
    EntitySetCaption = 'LRQ FlowField Entries';
    EntityName = 'lrqFlowFieldEntry';
    EntitySetName = 'lrqFlowFieldEntries';
    SourceTable = "DTC LRQ FlowField Entry";
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
                field(lrqEntryNo; Rec."LRQ Entry No.") { Caption = 'LRQ Entry No.'; }
                field(tableId; Rec."Table ID") { Caption = 'Table ID'; }
                field(tableName; Rec."Table Name") { Caption = 'Table Name'; }
                field(sqlTableName; Rec."SQL Table Name") { Caption = 'SQL Table Name'; }
                field(flowFieldName; Rec."FlowField Name") { Caption = 'FlowField Name'; }
                field(subQueryAlias; Rec."Sub Query Alias") { Caption = 'Sub Query Alias'; }
                field(isolationLevel; Rec."Isolation Level") { Caption = 'Isolation Level'; }
                field(aggregateFunction; Rec."Aggregate Function") { Caption = 'Aggregate Function'; }
                field(equalityFields; Rec."Equality Fields") { Caption = 'Equality Fields'; }
                field(inequalityFields; Rec."Inequality Fields") { Caption = 'Inequality Fields'; }
                field(noOfEqualityFields; Rec."No. of Equality Fields") { Caption = 'No. of Equality Fields'; }
                field(noOfInequalityFields; Rec."No. of Inequality Fields") { Caption = 'No. of Inequality Fields'; }
                field(occurrence; Rec.Occurrence) { Caption = 'Occurrence'; }
            }
        }
    }
}
