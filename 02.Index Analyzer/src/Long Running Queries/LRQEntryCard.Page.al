namespace DefaultNamespace;

page 50921 "LRQ Entry Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "LRQ Entry";
    Caption = 'Long Running Query Entry';
    Editable = false;

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
                field("SQL Table Name"; Rec."SQL Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SQL table name as stored in SQL Server.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the AL table ID.';
                }
                field("AL Table Name"; Rec."AL Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the AL table name.';
                }
                field("Isolation Level"; Rec."Isolation Level")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SQL isolation level used for the query.';
                }
                field("Query Type"; Rec."Query Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the type of query (Query, FlowField, etc.).';
                }
            }
            group(Statistics)
            {
                Caption = 'Statistics';

                field("No. of FlowFields"; Rec."No. of FlowFields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of FlowFields in the query.';
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
                }
                field(Occurrence; Rec.Occurrence)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of times the query was found in telemetry.';
                }
                field("Average Duration"; Rec."Average Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the average duration of the query.';
                }
                field("Total Duration"; Rec."Total Duration")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total duration of the query in the period.';
                }
                field(Percentage; Rec.Percentage)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the percentage of total duration.';
                }
            }
            group(Fields)
            {
                Caption = 'Query Fields';

                field("Equality Fields"; Rec."Equality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the equality columns in the WHERE clause.';
                    MultiLine = true;
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
                    MultiLine = true;
                }
                field("No. of Inequality Fields"; Rec."No. of Inequality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of inequality fields.';
                }
                field("Sub Query Alias"; Rec."Sub Query Alias")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the sub query alias.';
                }
                field("Aggregate Function"; Rec."Aggregate Function")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the aggregate function used (SUM, COUNT, MIN, etc.).';
                }
            }
            group(SQLStatement)
            {
                Caption = 'SQL Statement';

                field(PrettifiedSQLText; PrettifiedSQLText)
                {
                    ApplicationArea = All;
                    Caption = 'Formatted SQL';
                    ToolTip = 'Specifies the prettified SQL statement for better readability.';
                    MultiLine = true;
                    Editable = false;
                    ExtendedDatatype = RichContent;
                }
                field(OriginalSQLText; OriginalSQLText)
                {
                    ApplicationArea = All;
                    Caption = 'Original SQL';
                    ToolTip = 'Specifies the original SQL statement as imported.';
                    MultiLine = true;
                    Editable = false;
                    Visible = false;
                }
            }
            group(FlowFields)
            {
                Caption = 'FlowField SubQueries';
                Visible = HasFlowFields;

                field("No. of FlowFields2"; Rec."No. of FlowFields")
                {
                    ApplicationArea = All;
                    Caption = 'Number of FlowFields';
                    ToolTip = 'Specifies the number of FlowField subqueries in this query.';
                }
            }
            group(Import)
            {
                Caption = 'Import';

                field("Import DateTime"; Rec."Import DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the entry was imported.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(ShowFlowFieldEntries)
            {
                ApplicationArea = All;
                Caption = 'FlowField SubQueries';
                ToolTip = 'View the FlowField subqueries associated with this entry.';
                Image = List;
                Promoted = true;
                PromotedCategory = Process;
                Visible = HasFlowFields;

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
        }
    }

    var
        PrettifiedSQLText: Text;
        OriginalSQLText: Text;
        HasFlowFields: Boolean;

    trigger OnAfterGetRecord()
    begin
        PrettifiedSQLText := Rec.GetPrettifiedSQL();
        if PrettifiedSQLText = '' then
            PrettifiedSQLText := Rec.GetSQLStatement();

        OriginalSQLText := Rec.GetOriginalSQLStatement();
        if OriginalSQLText = '' then
            OriginalSQLText := Rec.GetSQLStatement();

        HasFlowFields := Rec."No. of FlowFields" > 0;
    end;
}
