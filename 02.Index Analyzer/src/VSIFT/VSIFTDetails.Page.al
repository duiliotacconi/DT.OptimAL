namespace DefaultNamespace;

page 50901 "VSIFT Details"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "VSIFT Detail";
    Caption = 'VSIFT Details';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(HeaderInfo)
            {
                Caption = 'VSIFT Information';
                field(TableName; TableName)
                {
                    ApplicationArea = All;
                    Caption = 'Table Name';
                    Editable = false;
                    ToolTip = 'Specifies the table name for this VSIFT.';
                }
                field(KeyFields; KeyFields)
                {
                    ApplicationArea = All;
                    Caption = 'Key Fields';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the key fields.';
                }
                field(SIFTFields; SIFTFields)
                {
                    ApplicationArea = All;
                    Caption = 'SIFT Fields';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the SIFT fields.';
                }
            }
            part(Chart; "VSIFT Detail Chart")
            {
                ApplicationArea = All;
                Caption = 'Bucket Distribution';
            }
            part(GroupChart; "VSIFT Group Distribution Chart")
            {
                ApplicationArea = All;
                Caption = 'Group Distribution';
            }
            repeater(Group)
            {
                field(Bucket; Rec.Bucket)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bucket size (number of records per group).';
                    Style = Strong;
                }
                field("No. of Groups"; Rec."No. of Groups")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many groups have this bucket size.';
                    Style = Strong;
                }
            }
        }
        area(Factboxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = All;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        TableName: Text[250];
        KeyFields: Text[250];
        SIFTFields: Text[250];
        VSIFTEntryNo: Integer;

    trigger OnOpenPage()
    begin
        CurrPage.Chart.Page.SetVSIFTEntry(VSIFTEntryNo);
        CurrPage.GroupChart.Page.SetVSIFTEntry(VSIFTEntryNo);
    end;

    procedure SetEntry(var VSIFTEntry: Record "VSIFT Entry")
    begin
        TableName := VSIFTEntry."Table Name";
        KeyFields := VSIFTEntry."Key Fields";
        SIFTFields := VSIFTEntry."SIFT Fields";
        VSIFTEntryNo := VSIFTEntry."Entry No.";
    end;
}
