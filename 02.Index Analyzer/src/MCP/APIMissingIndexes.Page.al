namespace DefaultNamespace;

page 50940 "DTC API Missing Indexes"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'Missing Index';
    EntitySetCaption = 'Missing Indexes';
    EntityName = 'missingIndex';
    EntitySetName = 'missingIndexes';
    SourceTable = "DTC Missing Index";
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
                field(extensionId; Rec."Extension Id") { Caption = 'Extension Id'; }
                field(equalityFields; Rec."Equality Fields") { Caption = 'Equality Fields'; }
                field(inequalityFields; Rec."Inequality Fields") { Caption = 'Inequality Fields'; }
                field(includeFields; Rec."Include Fields") { Caption = 'Include Fields'; }
                field(noOfEqualityFields; Rec."No. of Equality Fields") { Caption = 'No. of Equality Fields'; }
                field(noOfInequalityFields; Rec."No. of Inequality Fields") { Caption = 'No. of Inequality Fields'; }
                field(noOfIncludeFields; Rec."No. of Include Fields") { Caption = 'No. of Include Fields'; }
                field(seeks; Rec.Seeks) { Caption = 'Seeks'; }
                field(scans; Rec.Scans) { Caption = 'Scans'; }
                field(averageTotalCost; Rec."Average Total Cost") { Caption = 'Average Total Cost'; }
                field(averageImpact; Rec."Average Impact") { Caption = 'Average Impact'; }
                field(estimatedBenefit; Rec."Estimated Benefit") { Caption = 'Estimated Benefit'; }
                field(isVSIFT; Rec."Is VSIFT") { Caption = 'Is VSIFT'; }
                field(vsiftKey; Rec."VSIFT Key") { Caption = 'VSIFT Key'; }
                field(suggestedIndex; Rec."Suggested Index") { Caption = 'Suggested Index'; }
                field(selectivityCalculated; Rec."Selectivity Calculated") { Caption = 'Selectivity Calculated'; }
                field(importDateTime; Rec."Import DateTime") { Caption = 'Import DateTime'; }
            }
        }
    }
}
