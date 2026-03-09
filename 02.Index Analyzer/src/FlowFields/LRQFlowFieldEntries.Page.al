namespace DefaultNamespace;

page 50924 "LRQ FlowField Entries"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "LRQ FlowField Entry";
    Caption = 'LRQ FlowField Entries';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                    Visible = false;
                }
                field("LRQ Entry No."; Rec."LRQ Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the parent LRQ entry number.';
                }
                field("FlowField Name"; Rec."FlowField Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the FlowField name extracted from the subquery alias.';
                    Style = Strong;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the AL table name.';
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        TableIndex: Record "Table Index";
                        TableIndexList: Page "Table Index List";
                    begin
                        if Rec."Table ID" > 0 then begin
                            TableIndex.SetRange("Table ID", Rec."Table ID");
                            TableIndexList.SetTableView(TableIndex);
                            TableIndexList.Run();
                        end;
                    end;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table ID.';
                }
                field("Isolation Level"; Rec."Isolation Level")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SQL isolation level used for the subquery.';
                }
                field("Aggregate Function"; Rec."Aggregate Function")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the aggregate function used (SUM, COUNT, etc.).';
                }
                field("Equality Fields"; Rec."Equality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the equality columns in the WHERE clause.';
                }
                field("No. of Equality Fields"; Rec."No. of Equality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of equality fields.';
                }
                field("Inequality Fields"; Rec."Inequality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the inequality columns in the WHERE clause.';
                }
                field("No. of Inequality Fields"; Rec."No. of Inequality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of inequality fields.';
                }
                field("Sub Query Alias"; Rec."Sub Query Alias")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the subquery alias from the SQL.';
                    Visible = false;
                }
                field(Occurrence; Rec.Occurrence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the occurrence count inherited from parent query.';
                }
            }
        }
        area(Factboxes)
        {
            part(SQLStatementPart; "LRQ FF Statement FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowParentEntry)
            {
                ApplicationArea = All;
                Caption = 'Show Parent LRQ Entry';
                ToolTip = 'Navigate to the parent LRQ entry.';
                Image = Hierarchy;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LRQEntry: Record "LRQ Entry";
                    LRQEntryCard: Page "LRQ Entry Card";
                begin
                    if LRQEntry.Get(Rec."LRQ Entry No.") then begin
                        LRQEntryCard.SetRecord(LRQEntry);
                        LRQEntryCard.Run();
                    end;
                end;
            }
            action(ShowTableIndexes)
            {
                ApplicationArea = All;
                Caption = 'Show Table Indexes';
                ToolTip = 'View indexes for the FlowField source table.';
                Image = Table;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    TableIndex: Record "Table Index";
                    TableIndexList: Page "Table Index List";
                begin
                    if Rec."Table ID" > 0 then begin
                        TableIndex.SetRange("Table ID", Rec."Table ID");
                        TableIndexList.SetTableView(TableIndex);
                        TableIndexList.Run();
                    end;
                end;
            }
        }
    }
}
