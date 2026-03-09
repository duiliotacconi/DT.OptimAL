namespace DefaultNamespace;

table 50913 "Index Detail"
{
    DataClassification = SystemMetadata;
    Caption = 'Index Detail';

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
        field(3; "Selectivity Type"; Enum "Selectivity Type")
        {
            DataClassification = SystemMetadata;
            Caption = 'Selectivity Type';
        }
        field(4; "Field No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Field No.';
        }
        field(5; "Field Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Field Name';
        }
        field(10; Bucket; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Bucket';
        }
        field(11; "No. of Groups"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Groups';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(IndexEntry; "Index Entry No.", "Selectivity Type", "Field No.", Bucket)
        {
        }
    }
}
