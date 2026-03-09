namespace DefaultNamespace;

using System.Reflection;

table 50910 "Index Entry"
{
    DataClassification = SystemMetadata;
    Caption = 'Index Entry';

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
        field(9; "AL Key Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'AL Key Name';
        }
        field(5; "Key Fields"; Text[500])
        {
            DataClassification = SystemMetadata;
            Caption = 'Key Fields';
        }
        field(6; "Included Columns"; Text[500])
        {
            DataClassification = SystemMetadata;
            Caption = 'Included Columns (Inferred)';
        }
        field(15; "SQL Index"; Text[500])
        {
            DataClassification = SystemMetadata;
            Caption = 'SQL Index';
        }
        field(7; "No. of Key Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Key Fields';
        }
        field(8; "No. of Included Columns"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Included Columns';
        }
        field(10; Clustered; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Clustered';
        }
        field(11; "Maintain SIFT Index"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Maintain SIFT Index';
        }
        field(12; "SIFT Fields"; Text[500])
        {
            DataClassification = SystemMetadata;
            Caption = 'SIFT Fields';
        }
        field(13; Unique; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Unique';
        }
        field(14; Enabled; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Enabled';
        }
        field(20; "Total Record Count"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Total Record Count';
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
