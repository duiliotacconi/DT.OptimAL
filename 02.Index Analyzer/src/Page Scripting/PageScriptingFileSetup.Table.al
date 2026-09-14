namespace DefaultNamespace;

table 50930 "DTC Page Scripting File Setup"
{
    DataClassification = SystemMetadata;
    Caption = 'Page Scripting File Setup';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            DataClassification = SystemMetadata;
            Caption = 'Primary Key';
        }
        field(2; "Page Script Template File"; Blob)
        {
            DataClassification = SystemMetadata;
            Caption = 'Page Script Template File';
        }
        field(3; "Template File Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Template File Name';
            Editable = false;
        }
        field(4; "Profile ID"; Code[30])
        {
            DataClassification = SystemMetadata;
            Caption = 'Profile';
        }
        field(5; "Company Name"; Text[100])
        {
            DataClassification = SystemMetadata;
            Caption = 'Company Name';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
