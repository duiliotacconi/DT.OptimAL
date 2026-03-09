namespace DefaultNamespace;

page 50910 "Index Entries"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Index Entry";
    Caption = 'Index Entries';
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
                field("Key Index"; Rec."Key Index")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the key index number.';
                }
                field(Clustered; Rec.Clustered)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this is the clustered index.';
                    Style = Strong;
                    StyleExpr = Rec.Clustered;
                }
                field("Key Fields"; Rec."Key Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the fields that make up the key.';
                }
                field("No. of Key Fields"; Rec."No. of Key Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of fields in the key.';
                }
                field("SQL Index"; Rec."SQL Index")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SQL index fields as stored in metadata. Compare with Key Fields to identify included columns.';
                    Visible = false;
                }
                field("Included Columns"; Rec."Included Columns")
                {
                    ApplicationArea = All;
                    ToolTip = 'Included columns as defined by the IncludedFields property. Note: BC metadata does not expose this property at runtime - this field will be empty.';
                }
                field("No. of Included Columns"; Rec."No. of Included Columns")
                {
                    ApplicationArea = All;
                    ToolTip = 'Number of included columns. Note: BC metadata does not expose IncludedFields at runtime.';
                }
                field("Maintain SIFT Index"; Rec."Maintain SIFT Index")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether SIFT (SumIndexField Technology) is maintained for this index.';
                    Style = Favorable;
                    StyleExpr = Rec."Maintain SIFT Index";
                }
                field("SIFT Fields"; Rec."SIFT Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SIFT fields for this index.';
                }
                field(Unique; Rec.Unique)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the key is unique.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the key is enabled.';
                }
                field("Total Record Count"; Rec."Total Record Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of records in the table.';
                    Style = Strong;
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
        area(Processing)
        {
            action(RefreshIndexData)
            {
                ApplicationArea = All;
                Caption = 'Refresh Index Data';
                Image = Refresh;
                ToolTip = 'Refresh the index data from the database.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    IndexMgt: Codeunit "Index Management";
                    LastTableID: Integer;
                    SelectionChoice: Integer;
                    ContinueLbl: Label 'Continue from last table (ID: %1)', Comment = '%1 = Table ID';
                    StartFreshLbl: Label 'Start from scratch (delete all)';
                    CancelLbl: Label 'Cancel';
                begin
                    if IndexMgt.HasExistingData() then begin
                        LastTableID := IndexMgt.GetLastProcessedTableID();
                        SelectionChoice := StrMenu(
                            StrSubstNo(ContinueLbl, LastTableID) + ',' + StartFreshLbl + ',' + CancelLbl,
                            1,
                            'Existing data found. What would you like to do?');

                        case SelectionChoice of
                            1: // Continue from last table
                                IndexMgt.CollectIndexDataFromTable(LastTableID, false);
                            2: // Start from scratch
                                IndexMgt.CollectIndexDataFromTable(0, true);
                            else // Cancel or closed
                                exit;
                        end;
                    end else
                        IndexMgt.CollectIndexDataFromTable(0, true);

                    CurrPage.Update(false);
                    Message('Index data has been refreshed.');
                end;
            }
            action(ClearData)
            {
                ApplicationArea = All;
                Caption = 'Clear All Data';
                Image = Delete;
                ToolTip = 'Clear all Index entries.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    IndexEntry: Record "Index Entry";
                begin
                    if not Confirm('Are you sure you want to clear all Index entries?') then
                        exit;

                    IndexEntry.DeleteAll();
                    CurrPage.Update(false);
                    Message('All Index entries have been cleared.');
                end;
            }
            action(FilterClustered)
            {
                ApplicationArea = All;
                Caption = 'Show Clustered Only';
                Image = FilterLines;
                ToolTip = 'Filter to show only clustered indexes.';

                trigger OnAction()
                begin
                    Rec.SetRange(Clustered, true);
                    CurrPage.Update(false);
                end;
            }
            action(FilterNonClustered)
            {
                ApplicationArea = All;
                Caption = 'Show Only NC Indexes';
                Image = FilterLines;
                ToolTip = 'Filter to show only non-clustered indexes.';

                trigger OnAction()
                begin
                    Rec.SetRange(Clustered, false);
                    CurrPage.Update(false);
                end;
            }
            action(FilterSIFT)
            {
                ApplicationArea = All;
                Caption = 'Show SIFT Indexes Only';
                Image = FilterLines;
                ToolTip = 'Filter to show only indexes with SIFT enabled.';

                trigger OnAction()
                begin
                    Rec.SetRange("Maintain SIFT Index", true);
                    CurrPage.Update(false);
                end;
            }
            action(ClearFilters)
            {
                ApplicationArea = All;
                Caption = 'Clear Filters';
                Image = ClearFilter;
                ToolTip = 'Clear all filters.';

                trigger OnAction()
                begin
                    Rec.Reset();
                    CurrPage.Update(false);
                end;
            }
            action(CalculateSelectivity)
            {
                ApplicationArea = All;
                Caption = 'Calculate Selectivity';
                Image = Calculate;
                ToolTip = 'Calculate selectivity and density for each field in the key and for the composite key.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    IndexMgt: Codeunit "Index Management";
                    SelectionChoice: Integer;
                    CurrentIndexLbl: Label 'Current index only';
                    AllIndexesTableLbl: Label 'All indexes for this table';
                    AllIndexesAllTablesLbl: Label 'All indexes (all tables)';
                    CancelLbl: Label 'Cancel';
                    IndexCount: Integer;
                begin
                    if (SelectionChoice <> 3) and (Rec."Total Record Count" <= 1) then begin
                        Message('Cannot calculate selectivity for tables with 0 or 1 records.');
                        exit;
                    end;

                    SelectionChoice := StrMenu(
                        CurrentIndexLbl + ',' + AllIndexesTableLbl + ',' + AllIndexesAllTablesLbl + ',' + CancelLbl,
                        1,
                        'Calculate selectivity for:');

                    case SelectionChoice of
                        1: // Current index only
                            begin
                                if Rec."Total Record Count" <= 1 then begin
                                    Message('Cannot calculate selectivity for tables with 0 or 1 records.');
                                    exit;
                                end;
                                IndexMgt.CalculateSelectivity(Rec);
                                Message('Selectivity calculated for index %1.', Rec."Key Index");
                            end;
                        2: // All indexes for this table
                            begin
                                if Rec."Total Record Count" <= 1 then begin
                                    Message('Cannot calculate selectivity for tables with 0 or 1 records.');
                                    exit;
                                end;
                                IndexCount := IndexMgt.CalculateSelectivityForTable(Rec."Table ID", Rec."Table Name");
                                Message('Selectivity calculated for %1 indexes in table %2.', IndexCount, Rec."Table Name");
                            end;
                        3: // All indexes for all tables
                            begin
                                if not Confirm('This will calculate selectivity for ALL indexes across ALL tables.\This may take a significant amount of time. Continue?') then
                                    exit;
                                IndexCount := IndexMgt.CalculateSelectivityForAllTables();
                                Message('Selectivity calculated for %1 indexes across all tables.', IndexCount);
                            end;
                        else // Cancel or closed
                            exit;
                    end;
                end;
            }
            action(ViewSelectivity)
            {
                ApplicationArea = All;
                Caption = 'View Selectivity';
                Image = Statistics;
                ToolTip = 'View the calculated selectivity for this index without recalculating.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    IndexSelectivity: Record "Index Selectivity";
                    IndexSelectivityPage: Page "Index Selectivity List";
                begin
                    IndexSelectivity.SetRange("Index Entry No.", Rec."Entry No.");
                    if IndexSelectivity.IsEmpty() then begin
                        Message('No selectivity data found. Use "Calculate Selectivity" first.');
                        exit;
                    end;

                    IndexSelectivityPage.SetEntry(Rec);
                    IndexSelectivityPage.SetTableView(IndexSelectivity);
                    IndexSelectivityPage.Run();
                end;
            }
        }
    }
}
