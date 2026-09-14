namespace DefaultNamespace;

page 50926 "DTC LRQ FF Statement FactBox"
{
    PageType = CardPart;
    ApplicationArea = All;
    SourceTable = "DTC LRQ FlowField Entry";
    Caption = 'SQL Statement';

    layout
    {
        area(Content)
        {
            usercontrol(SqlViewer; "DTC SQL Viewer")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    IsControlReady := true;
                    PushSQL();
                end;
            }
        }
    }

    var
        SQLStatementText: Text;
        IsControlReady: Boolean;

    trigger OnAfterGetRecord()
    begin
        SQLStatementText := Rec.GetSQLStatement();
        PushSQL();
    end;

    local procedure PushSQL()
    begin
        if IsControlReady then
            CurrPage.SqlViewer.SetSQL(SQLStatementText);
    end;
}
