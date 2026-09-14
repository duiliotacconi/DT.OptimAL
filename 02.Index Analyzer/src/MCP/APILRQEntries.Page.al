namespace DefaultNamespace;

page 50938 "DTC API LRQ Entries"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'LRQ Entry';
    EntitySetCaption = 'LRQ Entries';
    EntityName = 'lrqEntry';
    EntitySetName = 'lrqEntries';
    SourceTable = "DTC LRQ Entry";
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
                field(sqlTableName; Rec."SQL Table Name") { Caption = 'SQL Table Name'; }
                field(tableId; Rec."Table ID") { Caption = 'Table ID'; }
                field(alTableName; Rec."AL Table Name") { Caption = 'AL Table Name'; }
                field(isolationLevel; Rec."Isolation Level") { Caption = 'Isolation Level'; }
                field(noOfFlowFields; Rec."No. of FlowFields") { Caption = 'No. of FlowFields'; }
                field(queryType; Rec."Query Type") { Caption = 'Query Type'; }
                field(noOfJoins; Rec."No. of JOINs") { Caption = 'No. of JOINs'; }
                field(subQueryAlias; Rec."Sub Query Alias") { Caption = 'Sub Query Alias'; }
                field(aggregateFunction; Rec."Aggregate Function") { Caption = 'Aggregate Function'; }
                field(occurrence; Rec.Occurrence) { Caption = 'Occurrence'; }
                field(averageDuration; Rec."Average Duration") { Caption = 'Average Duration'; }
                field(totalDuration; Rec."Total Duration") { Caption = 'Total Duration'; }
                field(percentage; Rec.Percentage) { Caption = 'Percentage'; }
                field(equalityFields; Rec."Equality Fields") { Caption = 'Equality Fields'; }
                field(inequalityFields; Rec."Inequality Fields") { Caption = 'Inequality Fields'; }
                field(noOfEqualityFields; Rec."No. of Equality Fields") { Caption = 'No. of Equality Fields'; }
                field(noOfInequalityFields; Rec."No. of Inequality Fields") { Caption = 'No. of Inequality Fields'; }
                field(importDateTime; Rec."Import DateTime") { Caption = 'Import DateTime'; }
                field(parentEntryNo; Rec."Parent Entry No.") { Caption = 'Parent Entry No.'; }
                field(flowFieldName; Rec."FlowField Name") { Caption = 'FlowField Name'; }
            }
        }
    }
}
