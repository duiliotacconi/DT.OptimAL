namespace DefaultNamespace;

table 50901 "VSIFT Detail"
{
    DataClassification = SystemMetadata;
    Caption = 'VSIFT Detail';

    fields
    {
        field(1; "VSIFT Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'VSIFT Entry No.';
            TableRelation = "VSIFT Entry"."Entry No.";
        }
        field(2; Bucket; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Bucket';
        }
        field(3; "No. of Groups"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Groups';
        }
    }

    keys
    {
        key(PK; "VSIFT Entry No.", Bucket)
        {
            Clustered = true;
        }
    }
}
