namespace DefaultNamespace;

using System.Reflection;

table 50925 "Missing Index"
{
    DataClassification = SystemMetadata;
    Caption = 'Missing Index';
    LookupPageId = "Missing Index List";
    DrillDownPageId = "Missing Index List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "SQL Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'SQL Table Name';
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "AL Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'AL Table Name';
            Editable = false;
        }
        field(5; "Extension Id"; Guid)
        {
            DataClassification = SystemMetadata;
            Caption = 'Extension Id';
        }
        field(10; "Equality Fields"; Text[1000])
        {
            DataClassification = SystemMetadata;
            Caption = 'Equality Fields';
        }
        field(11; "Inequality Fields"; Text[1000])
        {
            DataClassification = SystemMetadata;
            Caption = 'Inequality Fields';
        }
        field(12; "Include Fields"; Text[1000])
        {
            DataClassification = SystemMetadata;
            Caption = 'Include Fields';
        }
        field(13; "No. of Equality Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Equality Fields';
        }
        field(14; "No. of Inequality Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Inequality Fields';
        }
        field(15; "No. of Include Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Include Fields';
        }
        field(20; Seeks; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Seeks';
        }
        field(21; Scans; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Scans';
        }
        field(22; "Average Total Cost"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Average Total Cost';
            DecimalPlaces = 2 : 2;
        }
        field(23; "Average Impact"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Average Impact';
            DecimalPlaces = 2 : 2;
        }
        field(24; "Estimated Benefit"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Estimated Benefit';
            DecimalPlaces = 2 : 2;
        }
        field(25; "Is VSIFT"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Is VSIFT';
            Editable = false;
        }
        field(26; "VSIFT Key"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'VSIFT Key';
            Editable = false;
        }
        field(27; "Suggested Index"; Text[1000])
        {
            DataClassification = SystemMetadata;
            Caption = 'Suggested Index';
            Description = 'Fields ordered by selectivity (most selective first)';
            Editable = false;
        }
        field(28; "Selectivity Calculated"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Selectivity Calculated';
            Editable = false;
        }
        field(30; "Import DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Import DateTime';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(TableKey; "Table ID")
        {
        }
        key(BenefitKey; "Estimated Benefit")
        {
        }
    }

    trigger OnInsert()
    begin
        "Import DateTime" := CurrentDateTime();
    end;
}
