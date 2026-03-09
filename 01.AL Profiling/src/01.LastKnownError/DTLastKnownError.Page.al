page 50116 DTLastKnownError
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'DT Last Known Error';

    actions
    {
        area(Processing)
        {
            action(DTLastKnownError)
            {
                ApplicationArea = All;
                Caption = 'Get Foo Customer';
                ToolTip = 'Get Foo Customer';
                Image = Customer;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction();
                var
                    TryResult: Boolean;
                    GetFooCustomerResultMsg: Label 'Get Foo Customer Result: %1', Comment = '%1 = TryFunction result (true/false)';
                begin
                    TryResult := GetFoo();
                    Message(GetFooCustomerResultMsg, TryResult);
                end;
            }
        }
    }

    [TryFunction]
    procedure GetFoo()
    var
        Customer: Record Customer;
        FooCustomerLbl: Label 'This-Will-Throw-An-Error';
    begin
        Customer.Get(FooCustomerLbl);
    end;

}