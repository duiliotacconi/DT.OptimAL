namespace DefaultNamespace;

permissionset 50901 "Index Analyzer"
{
    Caption = 'Index Analyzer';
    Assignable = true;

    Permissions =
        table "LRQ FlowField Entry" = X,
        table "VSIFT Entry" = X,
        table "VSIFT Detail" = X,
        table "Index Entry" = X,
        table "Table Index" = X,
        table "Index Selectivity" = X,
        table "Index Detail" = X,
        table "LRQ Entry" = X,
        table "Missing Index" = X,
        tabledata "LRQ FlowField Entry" = RIMD,
        tabledata "VSIFT Entry" = RIMD,
        tabledata "VSIFT Detail" = RIMD,
        tabledata "Index Entry" = RIMD,
        tabledata "Table Index" = RIMD,
        tabledata "Index Selectivity" = RIMD,
        tabledata "Index Detail" = RIMD,
        tabledata "LRQ Entry" = RIMD,
        tabledata "Missing Index" = RIMD,
        codeunit "VSIFT Management" = X,
        codeunit "Index Management" = X,
        codeunit "LRQ Management" = X,
        codeunit "Missing Index Management" = X,
        page "VSIFT Entries" = X,
        page "VSIFT Details" = X,
        page "VSIFT Detail Chart" = X,
        page "VSIFT Group Distribution Chart" = X,
        page "VSIFT Entry Card" = X,
        page "Index Entries" = X,
        page "Table Index List" = X,
        page "Index Selectivity List" = X,
        page "Index Details" = X,
        page "Index Detail Chart" = X,
        page "Index Group Distribution Chart" = X,
        page "LRQ Entries" = X,
        page "LRQ Entry Card" = X,
        page "LRQ Statement FactBox" = X,
        page "Missing Index List" = X;
}
