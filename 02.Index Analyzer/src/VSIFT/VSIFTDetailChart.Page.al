namespace DefaultNamespace;

using System.Integration;
using System.Visualization;

page 50903 "VSIFT Detail Chart"
{
    Caption = 'VSIFT Histogram';
    PageType = CardPart;

    layout
    {
        area(Content)
        {
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = All;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    UpdateChart();
                end;

                trigger Refresh()
                begin
                    UpdateChart();
                end;
            }
        }
    }

    var
        VSIFTEntryNo: Integer;
        IsChartAddInReady: Boolean;

    procedure SetVSIFTEntry(EntryNo: Integer)
    begin
        VSIFTEntryNo := EntryNo;
        if IsChartAddInReady then
            UpdateChart();
    end;

    local procedure UpdateChart()
    var
        VSIFTDetail: Record "VSIFT Detail";
        BusinessChart: Codeunit "Business Chart";
        BucketLbl: Label 'Bucket';
        NoOfGroupsLbl: Label 'No. of Groups';
        XIndex: Integer;
    begin
        if VSIFTEntryNo = 0 then
            exit;

        BusinessChart.Initialize();
        BusinessChart.SetXDimension(BucketLbl, Enum::"Business Chart Data Type"::String);
        BusinessChart.AddMeasure(NoOfGroupsLbl, 1, Enum::"Business Chart Data Type"::Integer, Enum::"Business Chart Type"::Column);

        VSIFTDetail.SetRange("VSIFT Entry No.", VSIFTEntryNo);
        XIndex := 0;
        if VSIFTDetail.FindSet() then
            repeat
                BusinessChart.AddDataRowWithXDimension(Format(VSIFTDetail.Bucket));
                BusinessChart.SetValue(NoOfGroupsLbl, XIndex, VSIFTDetail."No. of Groups");
                XIndex += 1;
            until VSIFTDetail.Next() = 0;

        BusinessChart.Update(CurrPage.BusinessChart);
    end;
}
