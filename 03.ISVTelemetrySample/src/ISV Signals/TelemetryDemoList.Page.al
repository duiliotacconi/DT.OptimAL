namespace DT.ISVTelemetrySample;

/// <summary>
/// List page for Telemetry Demo records.
/// Opening this page triggers CL0001 (Page opened) telemetry.
/// </summary>
page 50101 "Telemetry Demo List"
{
    Caption = 'Telemetry Demo List';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Telemetry Demo";
    CardPageId = "Telemetry Demo";
    Editable = true;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description.';
                }
                field("Demo Type"; Rec."Demo Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the demo type.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the record was created.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the amount.';
                }
                field(Processed; Rec.Processed)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies if the record has been processed.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(CreateSampleData)
            {
                Caption = 'Create Sample Data';
                ApplicationArea = All;
                Image = CreateDocument;
                ToolTip = 'Creates sample data for demonstration purposes.';

                trigger OnAction()
                var
                    TelemetryDemoMgt: Codeunit "Telemetry Demo Mgt.";
                begin
                    TelemetryDemoMgt.CreateSampleData();
                    CurrPage.Update(false);
                    Message(SampleDataCreatedLbl);
                end;
            }
        }
        area(Promoted)
        {
            actionref(CreateSampleData_Promoted; CreateSampleData) { }
        }
    }

    var
        SampleDataCreatedLbl: Label 'Sample data has been created successfully.';
}
