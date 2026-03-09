namespace DefaultNamespace;

page 50902 "VSIFT Entry Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "VSIFT Entry";
    Caption = 'VSIFT Entry Card';

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table ID.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table name.';
                }
                field("Key Index"; Rec."Key Index")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the key index.';
                }
                field("Key Fields"; Rec."Key Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the key fields.';
                    MultiLine = true;
                }
                field("SIFT Fields"; Rec."SIFT Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SIFT fields.';
                    MultiLine = true;
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';
                field("Total Record Count"; Rec."Total Record Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of records in the indexed view.';
                    Style = Strong;
                }
                field("Min Group Value"; Rec."Min Group Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum value of elements grouped.';
                }
                field("Max Group Value"; Rec."Max Group Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum value of elements grouped.';
                }
                field("Avg Group Value"; Rec."Avg Group Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the average group value.';
                }
                field("Last Updated"; Rec."Last Updated")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the entry was last updated.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ViewDetails)
            {
                ApplicationArea = All;
                Caption = 'View Details';
                Image = View;
                ToolTip = 'View detailed VSIFT information for this entry.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    VSIFTDetail: Record "VSIFT Detail";
                    VSIFTDetailsPage: Page "VSIFT Details";
                begin
                    VSIFTDetail.SetRange("VSIFT Entry No.", Rec."Entry No.");
                    VSIFTDetailsPage.SetTableView(VSIFTDetail);
                    VSIFTDetailsPage.SetEntry(Rec);
                    VSIFTDetailsPage.Run();
                end;
            }
        }
    }
}
