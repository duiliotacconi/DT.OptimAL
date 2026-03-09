namespace DefaultNamespace;

using System.Reflection;

table 50911 "Table Index"
{
    DataClassification = SystemMetadata;
    Caption = 'Table Index';
    LookupPageId = "Table Index List";
    DrillDownPageId = "Table Index List";

    fields
    {
        field(1; "Table ID"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Table ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Table Name"; Text[250])
        {
            DataClassification = SystemMetadata;
            Caption = 'Table Name';
            Editable = false;
        }
        field(10; "No. of Indexes"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Indexes';
            Editable = false;
        }
        field(11; "No. of VSIFT Indexes"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of VSIFT Indexes';
            Editable = false;
        }
        field(12; "No. of Indexes with Included"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Indexes with Included Columns';
            Editable = false;
        }
        field(13; "No. of Indexes with SIFT"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'No. of Indexes with SIFT Fields';
            Editable = false;
        }
        field(20; "Total Record Count"; Integer)
        {
            DataClassification = SystemMetadata;
            Caption = 'Total Record Count';
            Editable = false;
        }
        field(21; "No. of LRQ"; Integer)
        {
            Caption = 'No. of LRQ';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("LRQ Entry" where("Table ID" = field("Table ID"), "Query Type" = filter('Query|Query with FF')));
        }
        field(22; "Total Duration of LRQ"; Duration)
        {
            Caption = 'Total Duration of LRQ';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("LRQ Entry"."Total Duration" where("Table ID" = field("Table ID"), "Query Type" = filter('Query|Query with FF')));
        }
        field(23; "No. of FF"; Integer)
        {
            Caption = 'No. of FlowFields';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("LRQ FlowField Entry" where("Table ID" = field("Table ID")));
        }
        field(24; "No. of Missing Indexes"; Integer)
        {
            Caption = 'No. of Missing Indexes';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = count("Missing Index" where("Table ID" = field("Table ID")));
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
        key(PK; "Table ID")
        {
            Clustered = true;
        }
        key(TableName; "Table Name")
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
