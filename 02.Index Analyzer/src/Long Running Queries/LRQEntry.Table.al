namespace DefaultNamespace;

using System.Reflection;
using System.Utilities;

table 50920 "LRQ Entry"
{
    DataClassification = SystemMetadata;
    Caption = 'Long Running Query Entry';

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Entry No.';
            AutoIncrement = true;
        }
        field(2; "SQL Statement"; Blob)
        {
            DataClassification = SystemMetadata;
            Caption = 'SQL Statement';
        }
        field(3; "SQL Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'SQL Table Name';
        }
        field(4; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(5; "AL Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'AL Table Name';
            Editable = false;
        }
        field(6; "Isolation Level"; Enum "Isolation Level")
        {
            DataClassification = SystemMetadata;
            Caption = 'Isolation Level';
        }
        field(7; "No. of FlowFields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of FlowFields';
        }
        field(16; "Query Type"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Query Type';
        }
        field(17; "No. of JOINs"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of JOINs';
        }
        field(18; "Sub Query Alias"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Sub Query Alias';
        }
        field(19; "Aggregate Function"; Text[50])
        {
            DataClassification = SystemMetadata;
            Caption = 'Aggregate Function';
        }
        field(8; Occurrence; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Count';
        }
        field(9; "Average Duration"; Duration)
        {
            DataClassification = SystemMetadata;
            Caption = 'Average Duration';
        }
        field(10; "Total Duration"; Duration)
        {
            DataClassification = SystemMetadata;
            Caption = 'Total Duration';
        }
        field(11; Percentage; Decimal)
        {
            DataClassification = SystemMetadata;
            Caption = 'Percentage';
            DecimalPlaces = 2 : 4;
        }
        field(12; "Equality Fields"; Text[1000])
        {
            DataClassification = SystemMetadata;
            Caption = 'Equality Fields';
        }
        field(13; "Inequality Fields"; Text[1000])
        {
            DataClassification = SystemMetadata;
            Caption = 'Inequality Fields';
        }
        field(14; "No. of Equality Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Equality Fields';
        }
        field(15; "No. of Inequality Fields"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Inequality Fields';
        }
        field(20; "Import DateTime"; DateTime)
        {
            DataClassification = SystemMetadata;
            Caption = 'Import DateTime';
            Editable = false;
        }
        field(21; "Original SQL Statement"; Blob)
        {
            DataClassification = SystemMetadata;
            Caption = 'Original SQL Statement';
        }
        field(22; "Prettified SQL"; Blob)
        {
            DataClassification = SystemMetadata;
            Caption = 'Prettified SQL';
        }
        field(23; "Parent Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Parent Entry No.';
            TableRelation = "LRQ Entry"."Entry No.";
        }
        field(25; "FlowField Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'FlowField Name';
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
        key(DurationKey; "Total Duration")
        {
        }
        key(OccurrenceKey; Occurrence)
        {
        }
        key(ParentKey; "Parent Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Import DateTime" := CurrentDateTime();
    end;

    procedure GetSQLStatement(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
        SQLText: Text;
    begin
        CalcFields("SQL Statement");
        if "SQL Statement".HasValue() then begin
            "SQL Statement".CreateInStream(InStr, TextEncoding::UTF8);
            SQLText := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
        end;
        exit(SQLText);
    end;

    procedure SetSQLStatement(SQLText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("SQL Statement");
        "SQL Statement".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(SQLText);
    end;

    procedure GetOriginalSQLStatement(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
        SQLText: Text;
    begin
        CalcFields("Original SQL Statement");
        if "Original SQL Statement".HasValue() then begin
            "Original SQL Statement".CreateInStream(InStr, TextEncoding::UTF8);
            SQLText := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
        end;
        exit(SQLText);
    end;

    procedure SetOriginalSQLStatement(SQLText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Original SQL Statement");
        "Original SQL Statement".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(SQLText);
    end;

    procedure GetPrettifiedSQL(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
        SQLText: Text;
    begin
        CalcFields("Prettified SQL");
        if "Prettified SQL".HasValue() then begin
            "Prettified SQL".CreateInStream(InStr, TextEncoding::UTF8);
            SQLText := TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator());
        end;
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
}
