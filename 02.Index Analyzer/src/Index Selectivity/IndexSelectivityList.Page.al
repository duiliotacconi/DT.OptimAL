namespace DefaultNamespace;

page 50912 "Index Selectivity List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Index Selectivity";
    SourceTableView = sorting("Index Entry No.", "Selectivity Type", "Field Position");
    Caption = 'Index Selectivity';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(HeaderInfo)
            {
                Caption = 'Index Information';
                field(TableNameHeader; TableNameHeader)
                {
                    ApplicationArea = All;
                    Caption = 'Table Name';
                    Editable = false;
                    ToolTip = 'Specifies the table name for this index.';
                }
                field(KeyFieldsHeader; KeyFieldsHeader)
                {
                    ApplicationArea = All;
                    Caption = 'Key Fields';
                    Editable = false;
                    MultiLine = true;
                    ToolTip = 'Specifies the key fields.';
                }
            }
            repeater(Group)
            {
                field("Selectivity Type"; Rec."Selectivity Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this is a field-level or index-level selectivity calculation.';
                    Style = Strong;
                    StyleExpr = Rec."Selectivity Type" = Rec."Selectivity Type"::Index;
                }
                field("Field Position"; Rec."Field Position")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the position of the field in the key.';
                    Visible = false;
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the field name or "Composite Key" for index-level selectivity.';
                    Style = Strong;
                    StyleExpr = Rec."Selectivity Type" = Rec."Selectivity Type"::Index;
                }
                field("Distinct Values"; Rec."Distinct Values")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the count of distinct values for this field or composite key.';
                    Style = Favorable;
                }
                field("Total Rows"; Rec."Total Rows")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of rows in the table.';
                }
                field(Selectivity; Rec.Selectivity)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the selectivity ratio (Distinct Values / Total Rows). Higher is better for index efficiency.';
                    Style = Favorable;
                    StyleExpr = Rec.Selectivity > 0.1;
                }
                field(Density; Rec.Density)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the density (1.0 / Distinct Values). Lower is better for index efficiency.';
                    Style = Unfavorable;
                    StyleExpr = Rec.Density > 0.1;
                }
                field("Last Updated"; Rec."Last Updated")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the selectivity was last calculated.';
                    Visible = false;
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

    actions
    {
        area(Processing)
        {
            action(ViewHistogram)
            {
                ApplicationArea = All;
                Caption = 'View Histogram';
                Image = AnalysisView;
                ToolTip = 'View the bucket histogram for this field or index.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    IndexDetail: Record "Index Detail";
                    IndexDetailsPage: Page "Index Details";
                begin
                    IndexDetail.SetRange("Index Entry No.", Rec."Index Entry No.");
                    IndexDetail.SetRange("Selectivity Type", Rec."Selectivity Type");
                    if Rec."Selectivity Type" = Rec."Selectivity Type"::Field then
                        IndexDetail.SetRange("Field No.", Rec."Field No.");
                    IndexDetailsPage.SetEntry(Rec);
                    IndexDetailsPage.SetTableView(IndexDetail);
                    IndexDetailsPage.Run();
                end;
            }
            action(ShowFieldsOnly)
            {
                ApplicationArea = All;
                Caption = 'Show Fields Only';
                Image = FilterLines;
                ToolTip = 'Filter to show only field-level selectivity.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.SetRange("Selectivity Type", Rec."Selectivity Type"::Field);
                    CurrPage.Update(false);
                end;
            }
            action(ShowKeysOnly)
            {
                ApplicationArea = All;
                Caption = 'Show Keys Only';
                Image = FilterLines;
                ToolTip = 'Filter to show only index/key-level selectivity.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.SetRange("Selectivity Type", Rec."Selectivity Type"::Index);
                    CurrPage.Update(false);
                end;
            }
            action(ClearFilters)
            {
                ApplicationArea = All;
                Caption = 'Clear Filters';
                Image = ClearFilter;
                ToolTip = 'Clear all filters and show all selectivity data.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                begin
                    Rec.SetRange("Selectivity Type");
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        TableNameHeader: Text[250];
        KeyFieldsHeader: Text[500];
        IndexEntryNoVar: Integer;
        MissingIndexEntryNoVar: Integer;
        VSIFTEntryNoVar: Integer;

    procedure SetEntry(var IndexEntry: Record "Index Entry")
    begin
        TableNameHeader := IndexEntry."Table Name";
        KeyFieldsHeader := IndexEntry."Key Fields";
        IndexEntryNoVar := IndexEntry."Entry No.";
    end;

    procedure SetMissingIndexEntry(var MissingIndex: Record "Missing Index")
    begin
        TableNameHeader := MissingIndex."AL Table Name";
        KeyFieldsHeader := 'Equality: ' + MissingIndex."Equality Fields" + ' | Inequality: ' + MissingIndex."Inequality Fields";
        MissingIndexEntryNoVar := MissingIndex."Entry No.";
    end;

    procedure SetVSIFTEntry(var VSIFTEntry: Record "VSIFT Entry")
    begin
        TableNameHeader := VSIFTEntry."Table Name";
        KeyFieldsHeader := 'Key Fields: ' + VSIFTEntry."Key Fields" + ' | SIFT Fields: ' + VSIFTEntry."SIFT Fields";
        VSIFTEntryNoVar := VSIFTEntry."Entry No.";
    end;
}
