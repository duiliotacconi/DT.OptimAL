namespace DefaultNamespace;

using System.Reflection;

table 50910 "DTC Index Entry"
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
        field(21; "Database Start Time"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Database Start Time';
        }
        field(30; "Last Updated"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Last Updated';
            Editable = false;
        }
        field(40; "Fragmentation %"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Fragmentation %';
        }
        field(41; "User Seeks"; BigInteger)
        {
            DataClassification = SystemMetadata;
            Caption = 'Number of User Seeks';
        }
        field(42; "User Scans"; BigInteger)
        {
            DataClassification = SystemMetadata;
            Caption = 'Number of User Scans';
        }
        field(43; "User Lookups"; BigInteger)
        {
            DataClassification = SystemMetadata;
            Caption = 'Number of User Lookups';
        }
        field(44; "User Updates"; BigInteger)
        {
            DataClassification = SystemMetadata;
            Caption = 'Number of User Updates';
        }
        field(45; "Last Seek"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Last User Seek';
        }
        field(46; "Last Scan"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Last User Scan';
        }
        field(47; "Last Lookup"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Last User Lookup';
        }
        field(48; "Last Update"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Last User Update';
        }
        field(50; "Enabled in Database"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Enabled in Database';
        }
        field(51; "AL Defined"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'AL Defined';
        }
        field(52; "Index Size (kB)"; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Index Size (kB)';
        }
        field(53; "Statistics Updated At"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Statistics Updated At';
        }
        field(54; Paired; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Paired';
        }
        field(55; "Created From Pairings"; Boolean)
        {
            DataClassification = SystemMetadata;
            Caption = 'Created From Pairings';
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
        "Last Updated" := Format(CurrentDateTime());
    end;

    trigger OnModify()
    begin
        "Last Updated" := Format(CurrentDateTime());
    end;
}
