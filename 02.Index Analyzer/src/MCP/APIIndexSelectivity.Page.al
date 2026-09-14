namespace DefaultNamespace;

page 50936 "DTC API Index Selectivity"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'Index Selectivity';
    EntitySetCaption = 'Index Selectivities';
    EntityName = 'indexSelectivity';
    EntitySetName = 'indexSelectivities';
    SourceTable = "DTC Index Selectivity";
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
                field(indexEntryNo; Rec."Index Entry No.") { Caption = 'Index Entry No.'; }
                field(tableId; Rec."Table ID") { Caption = 'Table ID'; }
                field(tableName; Rec."Table Name") { Caption = 'Table Name'; }
                field(keyIndex; Rec."Key Index") { Caption = 'Key Index'; }
                field(sourceType; Rec."Source Type") { Caption = 'Source Type'; }
                field(missingIndexEntryNo; Rec."Missing Index Entry No.") { Caption = 'Missing Index Entry No.'; }
                field(suggestedKeyFields; Rec."Suggested Key Fields") { Caption = 'Suggested Key Fields'; }
                field(selectivityType; Rec."Selectivity Type") { Caption = 'Selectivity Type'; }
                field(fieldNo; Rec."Field No.") { Caption = 'Field No.'; }
                field(fieldName; Rec."Field Name") { Caption = 'Field Name'; }
                field(fieldPosition; Rec."Field Position") { Caption = 'Field Position'; }
                field(distinctValues; Rec."Distinct Values") { Caption = 'Distinct Values'; }
                field(totalRows; Rec."Total Rows") { Caption = 'Total Rows'; }
                field(selectivity; Rec.Selectivity) { Caption = 'Selectivity'; }
                field(density; Rec.Density) { Caption = 'Density'; }
                field(lastUpdated; Rec."Last Updated") { Caption = 'Last Updated'; }
            }
        }
    }
}
