namespace DT.ALProfilingSample;

using Microsoft.Sales.Customer;

pageextension 50112 DTCustomerCardExt extends "Customer Card"
{
    actions
    {
        addlast(Documents)
        {
            action(DTDemoALProfilingAction)
            {
                ApplicationArea = All;
                Caption = 'Demo AL Profiling';
                ToolTip = 'Demo AL Profiling';
                Image = Start;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = New;

                trigger OnAction();
                var
                    Helper: Codeunit "DTALProfilerSampleHelper";
                    SelectedOption: Integer;
                    loopCount: Integer;
                    GLSetupCurrencyDescription: Text;
                    i: Integer;
                    SelectALoopCountMsg: Label 'Please select a loop count option:';
                    SelectALoopCountOptionMsg: Label 'Select a loop count option!';
                    CurrencyDescriptionMsg: Label 'Currency Description: %1', Comment = '%1 = Currency description from GL Setup';
                begin
                    GLSetupCurrencyDescription := '';

                    SelectedOption := Dialog.StrMenu('5000,10', 1, SelectALoopCountMsg);
                    case SelectedOption of
                        1:
                            loopCount := 5000;
                        2:
                            loopCount := 10;
                        else
                            Error(SelectALoopCountOptionMsg);
                    end;

                    for i := 1 to loopCount do
                        GLSetupCurrencyDescription := Helper.GetGLSetupCurrencyDescription();

                    Message(CurrencyDescriptionMsg, GLSetupCurrencyDescription);
                end;
            }
        }
    }
}