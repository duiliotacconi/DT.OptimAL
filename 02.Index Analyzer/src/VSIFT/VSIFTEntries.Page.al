namespace DefaultNamespace;

page 50900 "VSIFT Entries"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "VSIFT Entry";
    Caption = 'VSIFT Entries';
    CardPageId = "VSIFT Entry Card";
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
                    ToolTip = 'Specifies the key index.';
                }
                field("Key Fields"; Rec."Key Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the key fields.';
                }
                field("SIFT Fields"; Rec."SIFT Fields")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the SIFT fields.';
                }
                field("Total Record Count"; Rec."Total Record Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the total number of records in the indexed view.';
                    Style = Strong;
                }
                field("Group Count"; Rec."Group Count")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of unique VSIFT groups (buckets).';
                    Style = Strong;
                }
                field("Min Group Value"; Rec."Min Group Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the minimum value of elements grouped.';
                    Style = Attention;
                }
                field("Max Group Value"; Rec."Max Group Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the maximum value of elements grouped.';
                    Style = Favorable;
                }
                field("Avg Group Value"; Rec."Avg Group Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the average group value.';
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
            part(VSIFTChartPart; "VSIFT Detail Chart")
            {
                ApplicationArea = All;
            }
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
            action(RefreshVSIFTData)
            {
                ApplicationArea = All;
                Caption = 'Refresh VSIFT Data';
                Image = Refresh;
                ToolTip = 'Refresh the VSIFT data from the database.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    VSIFTMgt: Codeunit "VSIFT Management";
                    LastTableID: Integer;
                    SelectionChoice: Integer;
                    CurrentTableLbl: Label 'Current table only (%1)', Comment = '%1 = Table Name';
                    ContinueLbl: Label 'Continue from last table (ID: %1)', Comment = '%1 = Table ID';
                    StartFreshLbl: Label 'Start from scratch (delete all)';
                    CancelLbl: Label 'Cancel';
                begin
                    if VSIFTMgt.HasExistingData() then begin
                        LastTableID := VSIFTMgt.GetLastProcessedTableID();
                        SelectionChoice := StrMenu(
                            StrSubstNo(CurrentTableLbl, Rec."Table Name") + ',' + StrSubstNo(ContinueLbl, LastTableID) + ',' + StartFreshLbl + ',' + CancelLbl,
                            1,
                            'Refresh VSIFT data for:');

                        case SelectionChoice of
                            1: // Current table only
                                VSIFTMgt.CollectVSIFTDataForTable(Rec."Table ID");
                            2: // Continue from last table
                                VSIFTMgt.CollectVSIFTDataFromTable(LastTableID, false);
                            3: // Start from scratch
                                VSIFTMgt.CollectVSIFTDataFromTable(0, true);
                            else // Cancel or closed
                                exit;
                        end;
                    end else
                        VSIFTMgt.CollectVSIFTDataFromTable(0, true);

                    CurrPage.Update(false);
                    Message('VSIFT data has been refreshed.');
                end;
            }
            action(ViewDetails)
            {
                ApplicationArea = All;
                Caption = 'View Details';
                Image = View;
                ToolTip = 'View detailed VSIFT information for the selected entry.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    VSIFTDetail: Record "VSIFT Detail";
                    VSIFTDetailsPage: Page "VSIFT Details";
                begin
                    VSIFTDetail.SetRange("VSIFT Entry No.", Rec."Entry No.");
                    VSIFTDetailsPage.SetTableView(VSIFTDetail);
                    VSIFTDetailsPage.SetEntry(Rec);
                    VSIFTDetailsPage.Run();

                end;
            }
            action(ClearData)
            {
                ApplicationArea = All;
                Caption = 'Clear All Data';
                Image = Delete;
                ToolTip = 'Clear all VSIFT entries and details.';
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    VSIFTEntry: Record "VSIFT Entry";
                    VSIFTDetail: Record "VSIFT Detail";
                begin
                    if not Confirm('Do you want to delete all VSIFT data?', false) then
                        exit;

                    VSIFTDetail.Truncate();
                    VSIFTEntry.Truncate();
                    CurrPage.Update(false);
                    Message('All VSIFT data has been cleared.');
                end;
            }
            action(CalculateSelectivity)
            {
                ApplicationArea = All;
                Caption = 'Calculate Selectivity';
                Image = Calculate;
                ToolTip = 'Calculate selectivity and density for each field in the VSIFT key.';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    VSIFTMgt: Codeunit "VSIFT Management";
                    SelectionChoice: Integer;
                    CurrentVSIFTLbl: Label 'Current VSIFT only';
                    AllVSIFTsTableLbl: Label 'All VSIFTs for this table';
                    AllVSIFTsAllTablesLbl: Label 'All VSIFTs (all tables)';
                    CancelLbl: Label 'Cancel';
                    ProcessedCount: Integer;
                begin
                    SelectionChoice := StrMenu(
                        CurrentVSIFTLbl + ',' + AllVSIFTsTableLbl + ',' + AllVSIFTsAllTablesLbl + ',' + CancelLbl,
                        1,
                        'Calculate selectivity for:');

                    case SelectionChoice of
                        1: // Current VSIFT only
                            begin
                                if Rec."Total Record Count" <= 1 then begin
                                    Message('Cannot calculate selectivity for tables with 0 or 1 records.');
                                    exit;
                                end;
                                VSIFTMgt.CalculateSelectivity(Rec);
                                Message('Selectivity calculated for VSIFT entry %1.', Rec."Entry No.");
                            end;
                        2: // All VSIFTs for this table
                            begin
                                if Rec."Total Record Count" <= 1 then begin
                                    Message('Cannot calculate selectivity for tables with 0 or 1 records.');
                                    exit;
                                end;
                                ProcessedCount := VSIFTMgt.CalculateSelectivityForTable(Rec."Table ID");
                                Message('Selectivity calculated for %1 VSIFTs in table %2.', ProcessedCount, Rec."Table Name");
                            end;
                        3: // All VSIFTs for all tables
                            begin
                                if not Confirm('This will calculate selectivity for ALL VSIFTs across ALL tables.\This may take a significant amount of time. Continue?') then
                                    exit;
                                ProcessedCount := VSIFTMgt.CalculateSelectivityForAll();
                                Message('Selectivity calculated for %1 tables.', ProcessedCount);
                            end;
                        else // Cancel or closed
                            exit;
                    end;
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.VSIFTChartPart.Page.SetVSIFTEntry(Rec."Entry No.");
    end;
}
