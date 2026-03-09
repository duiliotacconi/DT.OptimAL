namespace DefaultNamespace;

using System.Integration;
using System.Visualization;

page 50904 "VSIFT Group Distribution Chart"
{
    Caption = 'VSIFT Group Distribution';
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
        BusChart: Codeunit "Business Chart";
        NoOfGroupsLbl: Label 'No. of Groups';
        BucketLbl: Label 'Bucket';
        XIndex: Integer;
    begin
        if VSIFTEntryNo = 0 then
            exit;

        BusChart.Initialize();
        BusChart.SetXDimension(NoOfGroupsLbl, Enum::"Business Chart Data Type"::String);
        BusChart.AddMeasure(BucketLbl, 1, Enum::"Business Chart Data Type"::Integer, Enum::"Business Chart Type"::Column);

        VSIFTDetail.SetRange("VSIFT Entry No.", VSIFTEntryNo);
        VSIFTDetail.SetCurrentKey("VSIFT Entry No.", "No. of Groups");
        VSIFTDetail.SetAscending("No. of Groups", true);
        XIndex := 0;
        if VSIFTDetail.FindSet() then
            repeat
                BusChart.AddDataRowWithXDimension(Format(VSIFTDetail."No. of Groups"));
                BusChart.SetValue(BucketLbl, XIndex, VSIFTDetail.Bucket);
                XIndex += 1;
            until VSIFTDetail.Next() = 0;

        BusChart.Update(CurrPage.BusinessChart);
    end;
}
