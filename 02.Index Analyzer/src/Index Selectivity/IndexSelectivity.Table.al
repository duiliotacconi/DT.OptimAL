namespace DefaultNamespace;

table 50912 "Index Selectivity"
{
    DataClassification = SystemMetadata;
    Caption = 'Index Selectivity';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Index Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Index Entry No.';
            TableRelation = "Index Entry"."Entry No.";
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
        }
        field(4; "Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Table Name';
        }
        field(5; "Key Index"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Key Index';
        }
        field(6; "Source Type"; Enum "Index Source Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Source Type';
        }
        field(7; "Missing Index Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Missing Index Entry No.';
            TableRelation = "Missing Index"."Entry No.";
        }
        field(8; "Suggested Key Fields"; Text[1000])
        {
            DataClassification = SystemMetadata;
            Caption = 'Suggested Key Fields';
            Description = 'Fields ordered by selectivity (most selective first)';
        }
        field(10; "Selectivity Type"; Enum "Selectivity Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Selectivity Type';
        }
        field(11; "Field No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field No.';
        }
        field(12; "Field Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Field Name';
        }
        field(13; "Field Position"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field Position';
        }
        field(20; "Distinct Values"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Distinct Values';
        }
        field(21; "Total Rows"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Total Rows';
        }
        field(22; Selectivity; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Selectivity';
            DecimalPlaces = 4 : 6;
        }
        field(23; Density; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Density';
            DecimalPlaces = 4 : 6;
        }
        field(30; "Last Updated"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Updated';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(IndexEntry; "Source Type", "Index Entry No.", "Selectivity Type", "Field Position")
        {
        }
        key(MissingIndexEntry; "Source Type", "Missing Index Entry No.", "Selectivity Type", "Field Position")
        {
        }
    }

    trigger OnInsert()
    begin
        "Last Updated" := CurrentDateTime();
    end;

    trigger OnModify()
    begin
        "Last Updated" := CurrentDateTime();
    end;
}
