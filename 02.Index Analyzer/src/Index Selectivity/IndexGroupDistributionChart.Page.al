namespace DefaultNamespace;

using System.Integration;
using System.Visualization;

page 50915 "Index Group Distribution Chart"
{
    Caption = 'Index Group Distribution';
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
        IndexEntryNo: Integer;
        SelectivityTypeFilter: Enum "Selectivity Type";
        FieldNoFilter: Integer;
        IsChartAddInReady: Boolean;
        HasFilters: Boolean;

    procedure SetIndexDetail(EntryNo: Integer; SelType: Enum "Selectivity Type"; FieldNo: Integer)
    begin
        IndexEntryNo := EntryNo;
        SelectivityTypeFilter := SelType;
        FieldNoFilter := FieldNo;
        HasFilters := true;
        if IsChartAddInReady then
            UpdateChart();
    end;

    local procedure UpdateChart()
    var
        IndexDetail: Record "Index Detail";
        BusChart: Codeunit "Business Chart";
        NoOfGroupsLbl: Label 'No. of Groups';
        BucketLbl: Label 'Bucket';
        XIndex: Integer;
    begin
        if not HasFilters then
            exit;

        if IndexEntryNo = 0 then
            exit;

        BusChart.Initialize();
        BusChart.SetXDimension(NoOfGroupsLbl, Enum::"Business Chart Data Type"::String);
        BusChart.AddMeasure(BucketLbl, 1, Enum::"Business Chart Data Type"::Integer, Enum::"Business Chart Type"::Column);

        IndexDetail.SetRange("Index Entry No.", IndexEntryNo);
        IndexDetail.SetRange("Selectivity Type", SelectivityTypeFilter);
        if SelectivityTypeFilter = SelectivityTypeFilter::Field then
            IndexDetail.SetRange("Field No.", FieldNoFilter);
        IndexDetail.SetCurrentKey("Index Entry No.", "Selectivity Type", "Field No.", "No. of Groups");
        IndexDetail.SetAscending("No. of Groups", true);

        XIndex := 0;
        if IndexDetail.FindSet() then
            repeat
                BusChart.AddDataRowWithXDimension(Format(IndexDetail."No. of Groups"));
                BusChart.SetValue(BucketLbl, XIndex, IndexDetail.Bucket);
                XIndex += 1;
            until IndexDetail.Next() = 0;

        BusChart.Update(CurrPage.BusinessChart);
    end;
}
