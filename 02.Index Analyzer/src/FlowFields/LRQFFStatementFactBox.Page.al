namespace DefaultNamespace;

page 50926 "LRQ FF Statement FactBox"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "LRQ FlowField Entry";
    Caption = 'SQL Statement';

    layout
    {
        area(Content)
        {
            field(SQLStatementText; SQLStatementText)
            {
                ApplicationArea = All;
                Caption = 'SQL Statement';
                ToolTip = 'Specifies the SQL statement.';
                MultiLine = true;
                Editable = false;
            }
        }
    }

    var
        SQLStatementText: Text;

    trigger OnAfterGetRecord()
    begin
        SQLStatementText := Rec.GetSQLStatement();
        // Truncate for FactBox display - full statement available in Card view
        if StrLen(SQLStatementText) > 2000 then
            SQLStatementText := CopyStr(SQLStatementText, 1, 2000) + '...';
    end;
}
