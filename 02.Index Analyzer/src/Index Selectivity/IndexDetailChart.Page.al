namespace DefaultNamespace;

using System.Integration;
using System.Visualization;

page 50914 "DTC Index Detail Chart"
{
    Caption = 'Index Histogram';
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
        SelectivityTypeFilter: Enum "DTC Selectivity Type";
        FieldNoFilter: Integer;
        IsChartAddInReady: Boolean;
        HasFilters: Boolean;

    procedure SetIndexDetail(EntryNo: Integer; SelType: Enum "DTC Selectivity Type"; FieldNo: Integer)
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
        IndexDetail: Record "DTC Index Detail";
        BusChart: Codeunit "Business Chart";
        BucketLbl: Label 'Bucket';
        NoOfGroupsLbl: Label 'No. of Groups';
        XIndex: Integer;
    begin
        if not HasFilters then
            exit;

        if IndexEntryNo = 0 then
            exit;

        BusChart.Initialize();
        BusChart.SetXDimension(BucketLbl, Enum::"Business Chart Data Type"::String);
        BusChart.AddMeasure(NoOfGroupsLbl, 1, Enum::"Business Chart Data Type"::Integer, Enum::"Business Chart Type"::Column);

        IndexDetail.SetRange("Index Entry No.", IndexEntryNo);
        IndexDetail.SetRange("Selectivity Type", SelectivityTypeFilter);
        if SelectivityTypeFilter = SelectivityTypeFilter::Field then
            IndexDetail.SetRange("Field No.", FieldNoFilter);
        IndexDetail.SetCurrentKey("Index Entry No.", "Selectivity Type", "Field No.", Bucket);

        XIndex := 0;
        if IndexDetail.FindSet() then
            repeat
                BusChart.AddDataRowWithXDimension(Format(IndexDetail.Bucket));
                BusChart.SetValue(NoOfGroupsLbl, XIndex, IndexDetail."No. of Groups");
                XIndex += 1;
            until IndexDetail.Next() = 0;

        BusChart.Update(CurrPage.BusinessChart);
    end;
}
