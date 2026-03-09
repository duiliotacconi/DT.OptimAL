namespace DefaultNamespace;

page 50925 "Missing Index List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "Missing Index";
    SourceTableView = sorting("Estimated Benefit") order(descending);
    Caption = 'Missing Index List';
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the entry number.';
                }
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the AL table ID.';
                }
                field("AL Table Name"; Rec."AL Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the AL table name.';
                }
                field("Is VSIFT"; Rec."Is VSIFT")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this missing index is for a VSIFT (SumIndexField) index.';
                    Style = Attention;
                    StyleExpr = Rec."Is VSIFT";
                }
                field("VSIFT Key"; Rec."VSIFT Key")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the key index number for the VSIFT.';
                    BlankZero = true;
                }
                field("SQL Table Name"; Rec."SQL Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SQL table name as stored in SQL Server.';
                    Visible = false;
                }
                field("Equality Fields"; Rec."Equality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the equality columns for the missing index.';
                }
                field("Inequality Fields"; Rec."Inequality Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the inequality columns for the missing index.';
                }
                field("Include Fields"; Rec."Include Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the include columns for the missing index.';
                }
                field(Seeks; Rec.Seeks)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of seeks that would benefit from this index.';
                }
                field(Scans; Rec.Scans)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of scans that would benefit from this index.';
                }
                field("Average Total Cost"; Rec."Average Total Cost")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the average total cost of queries that would benefit.';
                }
                field("Average Impact"; Rec."Average Impact")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the average impact percentage improvement.';
                    Style = Favorable;
                    StyleExpr = Rec."Average Impact" > 50;
                }
                field("Estimated Benefit"; Rec."Estimated Benefit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the estimated benefit of creating this index.';
                    Style = Strong;
                }
                field("Suggested Index"; Rec."Suggested Index")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the suggested index fields ordered by selectivity (most selective first).';
                    Style = Favorable;
                    StyleExpr = Rec."Selectivity Calculated";
                }
                field("Selectivity Calculated"; Rec."Selectivity Calculated")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether selectivity has been calculated for this missing index.';
                    Visible = false;
                }
                field("Import DateTime"; Rec."Import DateTime")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the entry was imported.';
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
            action(ImportFromExcel)
            {
                ApplicationArea = All;
                Caption = 'Import from Excel';
                Image = ImportExcel;
                ToolTip = 'Import missing indexes from an Excel file.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    MissingIndexMgt: Codeunit "Missing Index Management";
                begin
                    MissingIndexMgt.ImportFromExcel();
                    CurrPage.Update(false);
                end;
            }
            action(ShowTableIndexes)
            {
                ApplicationArea = All;
                Caption = 'Show Table Indexes';
                Image = Table;
                ToolTip = 'Show the indexes for the related table.';
                Promoted = true;
                PromotedCategory = Category4;

                trigger OnAction()
                var
                    IndexEntry: Record "Index Entry";
                    IndexEntries: Page "Index Entries";
                begin
                    IndexEntry.SetRange("Table ID", Rec."Table ID");
                    IndexEntries.SetTableView(IndexEntry);
                    IndexEntries.Run();
                end;
            }
            action(CalculateSelectivity)
            {
                ApplicationArea = All;
                Caption = 'Calculate Selectivity';
                Image = CalculateCost;
                ToolTip = 'Calculate selectivity for missing index fields to determine optimal field order.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    MissingIndex: Record "Missing Index";
                    MissingIndexMgt: Codeunit "Missing Index Management";
                    SelectionChoice: Integer;
                    SelectedLbl: Label 'Calculate for selected missing index';
                    TableLbl: Label 'Calculate for all missing indexes in table %1 (%2)', Comment = '%1 = Table ID, %2 = Table Name';
                    AllLbl: Label 'Calculate for all missing indexes';
                    CancelLbl: Label 'Cancel';
                    ProcessedCount: Integer;
                begin
                    SelectionChoice := StrMenu(
                        SelectedLbl + ',' + StrSubstNo(TableLbl, Rec."Table ID", Rec."AL Table Name") + ',' + AllLbl + ',' + CancelLbl,
                        1,
                        'Calculate selectivity for:');

                    case SelectionChoice of
                        1: // Selected missing index only
                            begin
                                MissingIndex := Rec;
                                MissingIndexMgt.CalculateSelectivity(MissingIndex);
                                Rec := MissingIndex;
                                CurrPage.Update(false);
                                Message('Selectivity calculated for the selected missing index.');
                            end;
                        2: // All missing indexes in table
                            begin
                                ProcessedCount := MissingIndexMgt.CalculateSelectivityForTable(Rec."Table ID");
                                CurrPage.Update(false);
                                Message('Selectivity calculated for %1 missing indexes.', ProcessedCount);
                            end;
                        3: // All missing indexes
                            begin
                                ProcessedCount := MissingIndexMgt.CalculateSelectivityForAll();
                                CurrPage.Update(false);
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
                Image = AnalysisView;
                ToolTip = 'View selectivity details for this missing index.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    IndexSelectivity: Record "Index Selectivity";
                    IndexSelectivityList: Page "Index Selectivity List";
                begin
                    IndexSelectivity.SetRange("Source Type", "Index Source Type"::"Missing Index");
                    IndexSelectivity.SetRange("Missing Index Entry No.", Rec."Entry No.");
                    IndexSelectivityList.SetTableView(IndexSelectivity);
                    IndexSelectivityList.SetMissingIndexEntry(Rec);
                    IndexSelectivityList.Run();
                end;
            }
            action(ClearAll)
            {
                ApplicationArea = All;
                Caption = 'Clear All';
                Image = Delete;
                ToolTip = 'Delete all missing index entries.';

                trigger OnAction()
                var
                    MissingIndex: Record "Missing Index";
                begin
                    if not Confirm('Are you sure you want to delete all missing index entries?') then
                        exit;

                    MissingIndex.Truncate();
                    CurrPage.Update(false);
                    Message('All missing index entries have been deleted.');
                end;
            }
        }
    }
}
