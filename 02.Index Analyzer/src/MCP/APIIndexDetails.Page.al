namespace DefaultNamespace;

page 50937 "DTC API Index Details"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'Index Detail';
    EntitySetCaption = 'Index Details';
    EntityName = 'indexDetail';
    EntitySetName = 'indexDetails';
    SourceTable = "DTC Index Detail";
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
                field(selectivityType; Rec."Selectivity Type") { Caption = 'Selectivity Type'; }
                field(fieldNo; Rec."Field No.") { Caption = 'Field No.'; }
                field(fieldName; Rec."Field Name") { Caption = 'Field Name'; }
                field(bucket; Rec.Bucket) { Caption = 'Bucket'; }
                field(noOfGroups; Rec."No. of Groups") { Caption = 'No. of Groups'; }
            }
        }
    }
}
