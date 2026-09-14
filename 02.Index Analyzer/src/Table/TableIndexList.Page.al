namespace DefaultNamespace;

page 50911 "DTC Table Index List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "DTC Table Index";
    SourceTableView = sorting("Total Duration of LRQ") order(descending);
    Caption = 'Table Index List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table ID.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the table name.';
                }
                field("No. of Indexes"; Rec."No. of Indexes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of enabled indexes for this table.';
                    Style = Strong;

                    trigger OnDrillDown()
                    begin
                        ShowIndexEntries();
                    end;
                }
                field("No. of VSIFT Indexes"; Rec."No. of VSIFT Indexes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of indexes with SIFT enabled.';
                    Style = Favorable;
                    StyleExpr = Rec."No. of VSIFT Indexes" > 0;

                    trigger OnDrillDown()
                    var
                        VSIFTEntry: Record "DTC VSIFT Entry";
                        VSIFTEntriesPage: Page "DTC VSIFT Entries";
                    begin
                        VSIFTEntry.SetRange("Table ID", Rec."Table ID");
                        VSIFTEntriesPage.SetTableView(VSIFTEntry);
                        VSIFTEntriesPage.Run();
                    end;
                }
                field("No. of Indexes with Included"; Rec."No. of Indexes with Included")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of indexes with included columns.';
                }
                field("No. of Indexes with SIFT"; Rec."No. of Indexes with SIFT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of indexes with SIFT fields defined (regardless of MaintainSIFTIndex setting).';
                    Style = Attention;
                    StyleExpr = Rec."No. of Indexes with SIFT" > Rec."No. of VSIFT Indexes";
                }
                field("Total Record Count"; Rec."Total Record Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of records in the table.';
                    Style = Strong;
                }
                field("No. of Missing Indexes"; Rec."No. of Missing Indexes")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of missing indexes suggested for this table.';
                    Style = Unfavorable;
                    StyleExpr = Rec."No. of Missing Indexes" > 0;

                    trigger OnDrillDown()
                    var
                        MissingIndex: Record "DTC Missing Index";
                        MissingIndexList: Page "DTC Missing Index List";
                    begin
                        MissingIndex.SetRange("Table ID", Rec."Table ID");
                        MissingIndexList.SetTableView(MissingIndex);
                        MissingIndexList.Run();
                    end;
                }
                field("No. of FF"; Rec."No. of FF")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of FlowField queries for this table.';

                    trigger OnDrillDown()
                    var
                        LRQFlowFieldEntry: Record "DTC LRQ FlowField Entry";
                        LRQFlowFieldEntriesPage: Page "DTC LRQ FlowField Entries";
                    begin
                        LRQFlowFieldEntry.SetRange("Table ID", Rec."Table ID");
                        LRQFlowFieldEntriesPage.SetTableView(LRQFlowFieldEntry);
                        LRQFlowFieldEntriesPage.Run();
                    end;
                }
                field("No. of LRQ"; Rec."No. of LRQ")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of Long Running Queries for this table.';

                    trigger OnDrillDown()
                    var
                        LRQEntry: Record "DTC LRQ Entry";
                        LRQEntries: Page "DTC LRQ Entries";
                    begin
                        LRQEntry.SetRange("Table ID", Rec."Table ID");
                        LRQEntry.SetFilter("Query Type", 'Query|Query with FF');
                        LRQEntries.SetTableView(LRQEntry);
                        LRQEntries.Run();
                    end;
                }
                field("Total Duration of LRQ"; Rec."Total Duration of LRQ")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total duration of all Long Running Queries for this table.';

                    trigger OnDrillDown()
                    var
                        LRQEntry: Record "DTC LRQ Entry";
                        LRQEntries: Page "DTC LRQ Entries";
                    begin
                        LRQEntry.SetRange("Table ID", Rec."Table ID");
                        LRQEntry.SetFilter("Query Type", 'Query|Query with FF');
                        LRQEntries.SetTableView(LRQEntry);
                        LRQEntries.Run();
                    end;
                }
                field("LRQ Duration %"; LRQDurationPct)
                {
                    ApplicationArea = All;
                    Caption = 'LRQ Duration %';
                    ToolTip = 'Specifies the percentage of total LRQ duration compared to all tables.';
                    DecimalPlaces = 2 : 2;
                }
                field("Last Updated"; Rec."Last Updated")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the entry was last updated.';
                }
            }
        }
        area(Factboxes)
        {
            systempart(Links; Links)
            {
                ApplicationArea = All;
            }
            systempart(Notes; Notes)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ImportLRQ_Promoted; ImportLRQ)
                {
                }
                actionref(Refresh_Promoted; Refresh)
                {
                }
            }
            group(Category_PageScripting)
            {
                Caption = 'Page Scripting';

                actionref(PageScriptingSetup_Promoted; PageScriptingSetup)
                {
                }
                actionref(ImportFromZip_Promoted; ImportFromZip)
                {
                }
                actionref(GeneratePageScriptings_Promoted; GeneratePageScriptings)
                {
                }
            }
            group(Category_Navigate)
            {
                Caption = 'Navigate';

                actionref(Indexes_Promoted; Indexes)
                {
                }
                actionref(VSIFTs_Promoted; VSIFTs)
                {
                }
                actionref(LRQ_Promoted; LRQ)
                {
                }
                actionref(FlowFields_Promoted; FlowFields)
                {
                }
                actionref(MissingIndexes_Promoted; MissingIndexes)
                {
                }
            }
            group(Category_Manage)
            {
                Caption = 'Manage';

                actionref(ClearData_Promoted; ClearData)
                {
                }
            }
            group(Category_Telemetry)
            {
                Caption = 'Telemetry';

                actionref(SendAllSignals_Promoted; SendAllSignals)
                {
                }
            }
        }
        area(Processing)
        {
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                Image = Refresh;
                ToolTip = 'Refresh the page data.';

                trigger OnAction()
                begin
                    CurrPage.Update(true);
                end;
            }
            action(Indexes)
            {
                ApplicationArea = All;
                Caption = 'Indexes';
                Image = View;
                ToolTip = 'View indexes for the selected table or all tables.';

                trigger OnAction()
                var
                    IndexEntry: Record "DTC Index Entry";
                    IndexEntriesPage: Page "DTC Index Entries";
                    SelectionChoice: Integer;
                    SelectedTableLbl: Label 'View indexes for table %1 (%2)', Comment = '%1 = Table ID, %2 = Table Name';
                    AllTablesLbl: Label 'View all indexes';
                    CancelLbl: Label 'Cancel';
                begin
                    SelectionChoice := StrMenu(
                        StrSubstNo(SelectedTableLbl, Rec."Table ID", Rec."Table Name") + ',' + AllTablesLbl + ',' + CancelLbl,
                        1,
                        'What would you like to view?');

                    case SelectionChoice of
                        1: // Selected table only
                            begin
                                IndexEntry.SetRange("Table ID", Rec."Table ID");
                                IndexEntriesPage.SetTableView(IndexEntry);
                                IndexEntriesPage.Run();
                            end;
                        2: // All indexes
                            IndexEntriesPage.Run();
                        else // Cancel or closed
                            exit;
                    end;
                end;
            }
            action(VSIFTs)
            {
                ApplicationArea = All;
                Caption = 'VSIFTs';
                Image = ListPage;
                ToolTip = 'View VSIFT entries for the selected table or all tables.';

                trigger OnAction()
                var
                    VSIFTEntry: Record "DTC VSIFT Entry";
                    VSIFTEntriesPage: Page "DTC VSIFT Entries";
                    SelectionChoice: Integer;
                    SelectedTableLbl: Label 'View VSIFTs for table %1 (%2)', Comment = '%1 = Table ID, %2 = Table Name';
                    AllTablesLbl: Label 'View all VSIFT entries';
                    CancelLbl: Label 'Cancel';
                begin
                    SelectionChoice := StrMenu(
                        StrSubstNo(SelectedTableLbl, Rec."Table ID", Rec."Table Name") + ',' + AllTablesLbl + ',' + CancelLbl,
                        1,
                        'What would you like to view?');

                    case SelectionChoice of
                        1: // Selected table only
                            begin
                                VSIFTEntry.SetRange("Table ID", Rec."Table ID");
                                VSIFTEntriesPage.SetTableView(VSIFTEntry);
                                VSIFTEntriesPage.Run();
                            end;
                        2: // All VSIFT entries
                            VSIFTEntriesPage.Run();
                        else // Cancel or closed
                            exit;
                    end;
                end;
            }
            action(LRQ)
            {
                ApplicationArea = All;
                Caption = 'LRQ';
                Image = Log;
                ToolTip = 'View Long Running Queries for the selected table or all tables.';

                trigger OnAction()
                var
                    LRQEntry: Record "DTC LRQ Entry";
                    LRQEntriesPage: Page "DTC LRQ Entries";
                    SelectionChoice: Integer;
                    SelectedTableLbl: Label 'View LRQ for table %1 (%2)', Comment = '%1 = Table ID, %2 = Table Name';
                    AllTablesLbl: Label 'View all LRQ entries';
                    CancelLbl: Label 'Cancel';
                begin
                    SelectionChoice := StrMenu(
                        StrSubstNo(SelectedTableLbl, Rec."Table ID", Rec."Table Name") + ',' + AllTablesLbl + ',' + CancelLbl,
                        1,
                        'What would you like to view?');

                    case SelectionChoice of
                        1: // Selected table only
                            begin
                                LRQEntry.SetRange("Table ID", Rec."Table ID");
                                LRQEntry.SetFilter("Query Type", '<>%1', 'FlowField');
                                LRQEntriesPage.SetTableView(LRQEntry);
                                LRQEntriesPage.Run();
                            end;
                        2: // All LRQ entries
                            begin
                                LRQEntry.SetFilter("Query Type", '<>%1', 'FlowField');
                                LRQEntriesPage.SetTableView(LRQEntry);
                                LRQEntriesPage.Run();
                            end;
                        else // Cancel or closed
                            exit;
                    end;
                end;
            }
            action(FlowFields)
            {
                ApplicationArea = All;
                Caption = 'FlowFields';
                Image = Flow;
                ToolTip = 'View FlowField queries for the selected table or all tables.';

                trigger OnAction()
                var
                    LRQFlowFieldEntry: Record "DTC LRQ FlowField Entry";
                    LRQFlowFieldEntriesPage: Page "DTC LRQ FlowField Entries";
                    SelectionChoice: Integer;
                    SelectedTableLbl: Label 'View FlowFields for table %1 (%2)', Comment = '%1 = Table ID, %2 = Table Name';
                    AllTablesLbl: Label 'View all FlowField entries';
                    CancelLbl: Label 'Cancel';
                begin
                    SelectionChoice := StrMenu(
                        StrSubstNo(SelectedTableLbl, Rec."Table ID", Rec."Table Name") + ',' + AllTablesLbl + ',' + CancelLbl,
                        1,
                        'What would you like to view?');

                    case SelectionChoice of
                        1: // Selected table only
                            begin
                                LRQFlowFieldEntry.SetRange("Table ID", Rec."Table ID");
                                LRQFlowFieldEntriesPage.SetTableView(LRQFlowFieldEntry);
                                LRQFlowFieldEntriesPage.Run();
                            end;
                        2: // All FlowField entries
                            LRQFlowFieldEntriesPage.Run();
                        else // Cancel or closed
                            exit;
                    end;
                end;
            }
            action(MissingIndexes)
            {
                ApplicationArea = All;
                Caption = 'Missing Indexes';
                Image = ErrorLog;
                ToolTip = 'View missing indexes for the selected table or all tables.';

                trigger OnAction()
                var
                    MissingIndex: Record "DTC Missing Index";
                    MissingIndexList: Page "DTC Missing Index List";
                    SelectionChoice: Integer;
                    SelectedTableLbl: Label 'View missing indexes for table %1 (%2)', Comment = '%1 = Table ID, %2 = Table Name';
                    AllTablesLbl: Label 'View all missing indexes';
                    CancelLbl: Label 'Cancel';
                begin
                    SelectionChoice := StrMenu(
                        StrSubstNo(SelectedTableLbl, Rec."Table ID", Rec."Table Name") + ',' + AllTablesLbl + ',' + CancelLbl,
                        1,
                        'What would you like to view?');

                    case SelectionChoice of
                        1: // Selected table only
                            begin
                                MissingIndex.SetRange("Table ID", Rec."Table ID");
                                MissingIndexList.SetTableView(MissingIndex);
                                MissingIndexList.Run();
                            end;
                        2: // All missing indexes
                            MissingIndexList.Run();
                        else // Cancel or closed
                            exit;
                    end;
                end;
            }
            action(ImportLRQ)
            {
                ApplicationArea = All;
                Caption = 'Import LRQ from Excel';
                Image = ImportExcel;
                ToolTip = 'Import Long Running Queries from Excel and populate Table Index and VSIFT data.';

                trigger OnAction()
                var
                    LRQMgt: Codeunit "DTC LRQ Management";
                begin
                    LRQMgt.ImportLRQAndPopulateAll();
                    CurrPage.Update(false);
                end;
            }
            action(GeneratePageScriptings)
            {
                ApplicationArea = All;
                Caption = 'Generate Page Scriptings';
                Image = Export;
                ToolTip = 'Generate Page Scripting YAML files for table index analysis.';

                trigger OnAction()
                var
                    PageScriptingMgt: Codeunit "DTC Page Scripting Management";
                    SelectionChoice: Integer;
                    SelectedTableLbl: Label 'Generate for table %1 (%2)', Comment = '%1 = Table ID, %2 = Table Name';
                    AllTablesLbl: Label 'Generate for all tables';
                    CancelLbl: Label 'Cancel';
                begin
                    SelectionChoice := StrMenu(
                        StrSubstNo(SelectedTableLbl, Rec."Table ID", Rec."Table Name") + ',' + AllTablesLbl + ',' + CancelLbl,
                        1,
                        'Generate page scripting files:');

                    case SelectionChoice of
                        1: // Selected table
                            PageScriptingMgt.GenerateForSelectedTable(Rec."Table ID");
                        2: // All tables
                            PageScriptingMgt.GenerateForAllTables();
                        else
                            exit;
                    end;
                end;
            }
            action(PageScriptingSetup)
            {
                ApplicationArea = All;
                Caption = 'Page Scripting Setup';
                Image = Setup;
                ToolTip = 'Open the Page Scripting File Setup page.';
                RunObject = page "DTC Page Scripting File Setup";
            }
            action(ImportFromZip)
            {
                ApplicationArea = All;
                Caption = 'Import from ZIP';
                Image = ImportExcel;
                ToolTip = 'Import index statistics from a ZIP file containing paired Table Information and Indexes XLSX files (Page Scripting output).';

                trigger OnAction()
                var
                    IndexDataImport: Codeunit "DTC Index Data Import";
                begin
                    IndexDataImport.ImportFromZip();
                    CurrPage.Update(false);
                end;
            }
            action(ClearData)
            {
                ApplicationArea = All;
                Caption = 'Clear All Data';
                Image = Delete;
                ToolTip = 'Clear all data from Table Index, Index Entry, LRQ Entry, VSIFT Entry, and VSIFT Detail tables.';

                trigger OnAction()
                var
                    TableIndex: Record "DTC Table Index";
                    IndexEntry: Record "DTC Index Entry";
                    LRQEntry: Record "DTC LRQ Entry";
                    VSIFTEntry: Record "DTC VSIFT Entry";
                    VSIFTDetail: Record "DTC VSIFT Detail";
                begin
                    if not Confirm('Are you sure you want to clear ALL data?\This will truncate Table Index, Index Entry, LRQ Entry, VSIFT Entry, and VSIFT Detail tables.') then
                        exit;

                    LRQEntry.Truncate();
                    VSIFTDetail.Truncate();
                    VSIFTEntry.Truncate();
                    IndexEntry.Truncate();
                    TableIndex.Truncate();
                    CurrPage.Update(false);
                    Message('All data has been cleared.');
                end;
            }
            action(SendAllSignals)
            {
                ApplicationArea = All;
                Caption = 'Send Signals for All Tables';
                Image = SendTo;
                ToolTip = 'Send telemetry signals with all fields for all analyzer tables.';

                trigger OnAction()
                var
                    TelemetryMgt: Codeunit "DTC Telemetry Management";
                begin
                    TelemetryMgt.SendAllSignals();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        CalculateTotalDuration();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Total Duration of LRQ", "No. of Missing Indexes");
        if TotalLRQDuration <> 0 then
            LRQDurationPct := Round((Rec."Total Duration of LRQ" / TotalLRQDuration) * 100, 0.01)
        else
            LRQDurationPct := 0;
    end;

    local procedure CalculateTotalDuration()
    var
        TableIndex: Record "DTC Table Index";
    begin
        TotalLRQDuration := 0;
        TableIndex.Reset();
        if TableIndex.FindSet() then
            repeat
                TableIndex.CalcFields("Total Duration of LRQ");
                TotalLRQDuration += TableIndex."Total Duration of LRQ";
            until TableIndex.Next() = 0;
    end;

    local procedure ShowIndexEntries()
    var
        IndexEntry: Record "DTC Index Entry";
        IndexEntriesPage: Page "DTC Index Entries";
    begin
        IndexEntry.SetRange("Table ID", Rec."Table ID");
        IndexEntriesPage.SetTableView(IndexEntry);
        IndexEntriesPage.Run();
    end;

    var
        TotalLRQDuration: Duration;
        LRQDurationPct: Decimal;
}
