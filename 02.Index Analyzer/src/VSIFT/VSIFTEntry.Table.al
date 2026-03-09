namespace DefaultNamespace;

using System.Reflection;

table 50900 "VSIFT Entry"
{
    DataClassification = SystemMetadata;
    Caption = 'VSIFT Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(3; "Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Table Name';
            Editable = false;
        }
        field(4; "Key Index"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Key Index';
        }
        field(8; "AL Key Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'AL Key Name';
        }
        field(5; "Key Fields"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Key Fields';
        }
        field(6; "SIFT Fields"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'SIFT Fields';
        }
        field(7; "No. of Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Fields';
        }
        field(10; "Total Record Count"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Total Record Count';
        }
        field(14; "Group Count"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Group Count';
        }
        field(11; "Min Group Value"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Min Group Value';
        }
        field(12; "Max Group Value"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Max Group Value';
        }
        field(13; "Avg Group Value"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Avg Group Value';
        }
        field(20; "Last Updated"; DateTime)
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
        key(TableKey; "Table ID", "Key Index")
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
