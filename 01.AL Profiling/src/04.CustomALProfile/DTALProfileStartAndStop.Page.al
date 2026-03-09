page 50115 DTALProfileStartAndStop
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'AL Profiler Start/Stop';

    actions
    {
        area(Processing)
        {
            action(DTCustomALProfilStart)
            {
                ApplicationArea = All;
                Caption = 'Start';
                ToolTip = 'Start the AL profiling session';
                Image = Start;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction();
                var
                    AlProfilerHelper: Codeunit "DT.ALProfilerHelper";
                begin
                    AlProfilerHelper.Start();
                end;
            }

            action(DTCustomALProfilStop)
            {
                ApplicationArea = All;
                Caption = 'Stop';
                ToolTip = 'Stop the AL profiling session';
                Image = Stop;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;

                trigger OnAction();
                var
                    AlProfilerHelper: Codeunit "DT.ALProfilerHelper";
                begin
                    AlProfilerHelper.Stop();
                end;
            }
        }
    }

}