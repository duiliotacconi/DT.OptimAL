namespace DefaultNamespace;

page 50913 "DTC Index Details"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "DTC Index Detail";
    SourceTableView = sorting("Index Entry No.", "Selectivity Type", "Field No.", Bucket);
    Caption = 'Index Details - Bucket Histogram';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(HeaderInfo)
            {
                Caption = 'Field/Index Information';
                field(TableNameHeader; TableNameHeader)
                {
                    ApplicationArea = All;
                    Caption = 'Table Name';
                    Editable = false;
                    ToolTip = 'Specifies the table name.';
                }
                field(FieldNameHeader; FieldNameHeader)
                {
                    ApplicationArea = All;
                    Caption = 'Field/Key';
                    Editable = false;
                    ToolTip = 'Specifies the field name or composite key.';
                }
                field(SelectivityTypeHeader; SelectivityTypeHeader)
                {
                    ApplicationArea = All;
                    Caption = 'Type';
                    Editable = false;
                    ToolTip = 'Specifies whether this is field-level or index-level analysis.';
                }
            }
            part(Chart; "DTC Index Detail Chart")
            {
                ApplicationArea = All;
                Caption = 'Bucket Distribution';
            }
            part(GroupChart; "DTC Index Group Distr. Chart")
            {
                ApplicationArea = All;
                Caption = 'Group Distribution';
            }
            repeater(Group)
            {
                field(Bucket; Rec.Bucket)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the bucket size (number of records per group/value).';
                    Style = Strong;
                }
                field("No. of Groups"; Rec."No. of Groups")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how many distinct values/groups have this bucket size.';
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
        TableNameHeader: Text[250];
        FieldNameHeader: Text[250];
        SelectivityTypeHeader: Text[50];
        IndexEntryNoVar: Integer;
        SelectivityTypeVar: Enum "DTC Selectivity Type";
        FieldNoVar: Integer;

    trigger OnOpenPage()
    begin
        CurrPage.Chart.Page.SetIndexDetail(IndexEntryNoVar, SelectivityTypeVar, FieldNoVar);
        CurrPage.GroupChart.Page.SetIndexDetail(IndexEntryNoVar, SelectivityTypeVar, FieldNoVar);
    end;

    procedure SetEntry(IndexSelectivity: Record "DTC Index Selectivity")
    begin
        TableNameHeader := IndexSelectivity."Table Name";
        FieldNameHeader := IndexSelectivity."Field Name";
        IndexEntryNoVar := IndexSelectivity."Index Entry No.";
        SelectivityTypeVar := IndexSelectivity."Selectivity Type";
        FieldNoVar := IndexSelectivity."Field No.";
        if IndexSelectivity."Selectivity Type" = IndexSelectivity."Selectivity Type"::Field then
            SelectivityTypeHeader := 'Field'
        else
            SelectivityTypeHeader := 'Index (Composite Key)';
    end;
}
