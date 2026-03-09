namespace DT.ISVTelemetrySample;

/// <summary>
/// Table used for demonstrating telemetry signals.
/// This table is used to store demo data for various telemetry demonstrations.
/// </summary>
table 50100 "Telemetry Demo"
{
    Caption = 'Telemetry Demo';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Demo Type"; Enum "Telemetry Demo Type")
        {
            Caption = 'Demo Type';
        }
        field(4; "Created DateTime"; DateTime)
        {
            Caption = 'Created DateTime';
        }
        field(5; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(6; "Processed"; Boolean)
        {
            Caption = 'Processed';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(SK1; "Demo Type", "Created DateTime")
        {
            // This key can be disabled to trigger LC0025 telemetry
        }
    }

    trigger OnInsert()
    begin
        "Created DateTime" := CurrentDateTime();
    end;
}
