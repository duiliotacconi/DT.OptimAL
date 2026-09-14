namespace DefaultNamespace;

page 50933 "DTC API Table Indexes"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'Table Index';
    EntitySetCaption = 'Table Indexes';
    EntityName = 'tableIndex';
    EntitySetName = 'tableIndexes';
    SourceTable = "DTC Table Index";
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
                field(tableId; Rec."Table ID") { Caption = 'Table ID'; }
                field(tableName; Rec."Table Name") { Caption = 'Table Name'; }
                field(noOfIndexes; Rec."No. of Indexes") { Caption = 'No. of Indexes'; }
                field(noOfVSIFTIndexes; Rec."No. of VSIFT Indexes") { Caption = 'No. of VSIFT Indexes'; }
                field(noOfIndexesWithIncluded; Rec."No. of Indexes with Included") { Caption = 'No. of Indexes with Included'; }
                field(noOfIndexesWithSIFT; Rec."No. of Indexes with SIFT") { Caption = 'No. of Indexes with SIFT'; }
                field(totalRecordCount; Rec."Total Record Count") { Caption = 'Total Record Count'; }
                field(noOfLRQ; Rec."No. of LRQ") { Caption = 'No. of LRQ'; }
                field(totalDurationOfLRQ; Rec."Total Duration of LRQ") { Caption = 'Total Duration of LRQ'; }
                field(noOfFF; Rec."No. of FF") { Caption = 'No. of FF'; }
                field(noOfMissingIndexes; Rec."No. of Missing Indexes") { Caption = 'No. of Missing Indexes'; }
                field(lastUpdated; Rec."Last Updated") { Caption = 'Last Updated'; }
            }
        }
    }
}
