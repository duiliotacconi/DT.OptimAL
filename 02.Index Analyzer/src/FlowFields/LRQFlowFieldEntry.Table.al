namespace DefaultNamespace;

using System.Reflection;
using System.Utilities;

table 50926 "LRQ FlowField Entry"
{
    DataClassification = SystemMetadata;
    Caption = 'LRQ FlowField Entry';
    LookupPageId = "LRQ FlowField Entries";
    DrillDownPageId = "LRQ FlowField Entries";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "LRQ Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'LRQ Entry No.';
            TableRelation = "LRQ Entry"."Entry No.";
        }
        field(3; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(4; "Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Table Name';
            Editable = false;
        }
        field(5; "SQL Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'SQL Table Name';
        }
        field(6; "FlowField Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'FlowField Name';
        }
        field(7; "Sub Query Alias"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Sub Query Alias';
        }
        field(8; "Isolation Level"; Enum "Isolation Level")
        {
            DataClassification = SystemMetadata;
            Caption = 'Isolation Level';
        }
        field(9; "Aggregate Function"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Aggregate Function';
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
        field(12; "No. of Equality Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Equality Fields';
        }
        field(13; "No. of Inequality Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Inequality Fields';
        }
        field(14; Occurrence; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Occurrence';
        }
        field(15; "SQL Statement"; Blob)
        {
            DataClassification = SystemMetadata;
            Caption = 'SQL Statement';
        }
        field(16; "Prettified SQL"; Blob)
        {
            DataClassification = SystemMetadata;
            Caption = 'Prettified SQL';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(LRQEntry; "LRQ Entry No.")
        {
        }
        key(TableID; "Table ID")
        {
        }
    }

    procedure SetSQLStatement(SQLText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("SQL Statement");
        "SQL Statement".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(SQLText);
    end;

    procedure GetSQLStatement(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
        SQLText: Text;
    begin
        CalcFields("SQL Statement");
        if not "SQL Statement".HasValue() then
            exit('');

        "SQL Statement".CreateInStream(InStr, TextEncoding::UTF8);
        SQLText := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
        exit(SQLText);
    end;

    procedure SetPrettifiedSQL(SQLText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Prettified SQL");
        "Prettified SQL".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(SQLText);
    end;

    procedure GetPrettifiedSQL(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
        SQLText: Text;
    begin
        CalcFields("Prettified SQL");
        if not "Prettified SQL".HasValue() then
            exit('');

        "Prettified SQL".CreateInStream(InStr, TextEncoding::UTF8);
        SQLText := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
        exit(SQLText);
    end;
}
