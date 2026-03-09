namespace DefaultNamespace;

page 50920 "LRQ Entries"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "LRQ Entry";
    Caption = 'Long Running Query Entries';
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
                    StyleExpr = RowStyle;
                }
                field("SQL Table Name"; Rec."SQL Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SQL table name as stored in SQL Server.';
                    StyleExpr = RowStyle;
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the AL table ID.';
                    StyleExpr = RowStyle;
                }
                field("AL Table Name"; Rec."AL Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the AL table name.';
                    StyleExpr = RowStyle;
                }
                field("Isolation Level"; Rec."Isolation Level")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SQL isolation level used for the query.';
                    StyleExpr = RowStyle;
                }
                field("Query Type"; Rec."Query Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of query (Query, FlowField, etc.).';
                    StyleExpr = RowStyle;
                }
                field("No. of FlowFields"; Rec."No. of FlowFields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of FlowFields in the query.';
                    StyleExpr = RowStyle;
                    DrillDown = true;

                    trigger OnDrillDown()
                    var
                        LRQFlowFieldEntry: Record "LRQ FlowField Entry";
                        LRQFlowFieldEntries: Page "LRQ FlowField Entries";
                    begin
                        LRQFlowFieldEntry.SetRange("LRQ Entry No.", Rec."Entry No.");
                        LRQFlowFieldEntries.SetTableView(LRQFlowFieldEntry);
                        LRQFlowFieldEntries.Run();
                    end;
                }
                field("No. of JOINs"; Rec."No. of JOINs")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of JOINs in the query.';
                    StyleExpr = RowStyle;
                }
                field(Occurrence; Rec.Occurrence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of times the query was found in telemetry.';
                    Style = Strong;
                    StyleExpr = RowStyle;
                }
                field("Average Duration"; Rec."Average Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the average duration of the query.';
                    StyleExpr = RowStyle;
                }
                field("Total Duration"; Rec."Total Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total duration of the query in the period.';
                    Style = Strong;
                    StyleExpr = RowStyle;
                }
                field(Percentage; Rec.Percentage)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of total duration.';
                    StyleExpr = RowStyle;
                }
                field("Equality Fields"; Rec."Equality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the equality columns in the WHERE clause.';
                    StyleExpr = RowStyle;
                }
                field("No. of Equality Fields"; Rec."No. of Equality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of equality fields.';
                    StyleExpr = RowStyle;
                }
                field("Inequality Fields"; Rec."Inequality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the inequality columns in the WHERE clause.';
                    StyleExpr = RowStyle;
                }
                field("No. of Inequality Fields"; Rec."No. of Inequality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of inequality fields.';
                    StyleExpr = RowStyle;
                }
                field("Sub Query Alias"; Rec."Sub Query Alias")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sub query alias.';
                    StyleExpr = RowStyle;
                }
                field("Aggregate Function"; Rec."Aggregate Function")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the aggregate function used (SUM, COUNT, MIN, etc.).';
                    StyleExpr = RowStyle;
                }
                field("Import DateTime"; Rec."Import DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the entry was imported.';
                    StyleExpr = RowStyle;
                }
            }
        }
        area(Factboxes)
        {
            part(SQLStatementPart; "LRQ Statement FactBox")
            {
                ApplicationArea = All;
                SubPageLink = "Entry No." = field("Entry No.");
            }
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
            action(ViewSQLStatement)
            {
                ApplicationArea = All;
                Caption = 'View SQL Statement';
                Image = ViewDetails;
                ToolTip = 'View the full SQL statement for this entry.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    LRQEntryCard: Page "LRQ Entry Card";
                begin
                    LRQEntryCard.SetRecord(Rec);
                    LRQEntryCard.RunModal();
                end;
            }
            action(ShowFlowFieldEntries)
            {
                ApplicationArea = All;
                Caption = 'FlowField SubQueries';
                Image = List;
                ToolTip = 'View the FlowField subqueries for this entry.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LRQFlowFieldEntry: Record "LRQ FlowField Entry";
                    LRQFlowFieldEntries: Page "LRQ FlowField Entries";
                begin
                    LRQFlowFieldEntry.SetRange("LRQ Entry No.", Rec."Entry No.");
                    LRQFlowFieldEntries.SetTableView(LRQFlowFieldEntry);
                    LRQFlowFieldEntries.Run();
                end;
            }
            action(ShowAllFlowFields)
            {
                ApplicationArea = All;
                Caption = 'All FlowField SubQueries';
                Image = AllLines;
                ToolTip = 'View all FlowField subqueries.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    LRQFlowFieldEntries: Page "LRQ FlowField Entries";
                begin
                    LRQFlowFieldEntries.Run();
                end;
            }
        }
        area(Navigation)
        {
            action(ShowIndexes)
            {
                ApplicationArea = All;
                Caption = 'Show Table Indexes';
                Image = Table;
                ToolTip = 'Show the indexes for the related table.';
                Promoted = true;
                PromotedCategory = Category4;

                trigger OnAction()
                var
                    IndexEntry: Record "Index Entry";
                    IndexEntries: Page "Index Entries";
                begin
                    IndexEntry.SetRange("Table ID", Rec."Table ID");
                    IndexEntries.SetTableView(IndexEntry);
                    IndexEntries.Run();
                end;
            }
        }
    }

    var
        RowStyle: Text;
        HasFlowFields: Boolean;

    trigger OnAfterGetRecord()
    begin
        HasFlowFields := Rec."No. of FlowFields" > 0;

        case Rec."Isolation Level" of
            Rec."Isolation Level"::UpdLock:
                RowStyle := 'Unfavorable'; // Red
            Rec."Isolation Level"::ReadCommitted:
                RowStyle := 'Ambiguous'; // Blue
            else
                RowStyle := 'None';
        end;
    end;
}
