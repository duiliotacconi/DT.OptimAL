namespace DefaultNamespace;

page 50935 "DTC API VSIFT Details"
{
    PageType = API;
    APIPublisher = 'dt';
    APIGroup = 'indexAnalyzer';
    APIVersion = 'v1.0';
    EntityCaption = 'VSIFT Detail';
    EntitySetCaption = 'VSIFT Details';
    EntityName = 'vsiftDetail';
    EntitySetName = 'vsiftDetails';
    SourceTable = "DTC VSIFT Detail";
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
                field(vsiftEntryNo; Rec."VSIFT Entry No.") { Caption = 'VSIFT Entry No.'; }
                field(bucket; Rec.Bucket) { Caption = 'Bucket'; }
                field(noOfGroups; Rec."No. of Groups") { Caption = 'No. of Groups'; }
            }
        }
    }
}
