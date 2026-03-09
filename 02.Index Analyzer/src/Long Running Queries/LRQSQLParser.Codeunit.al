namespace DefaultNamespace;

using System.Reflection;
using System.Utilities;

codeunit 50923 "LRQ SQL Parser"
{
    /// <summary>
    /// Parses SQL statement and populates the LRQ Entry fields.
    /// This is used instead of KQL pre-processing to extract:
    /// - Isolation Level
    /// - Table Name
    /// - Number of FlowFields (OUTER APPLY count)
    /// - Equality and Inequality fields from WHERE clause
    /// </summary>
    procedure ParseSQLStatement(var LRQEntry: Record "LRQ Entry"; SQLStatement: Text)
    var
        TableName: Text;
        IsolationLevel: Enum "Isolation Level";
        EqualityFields: Text;
        InequalityFields: Text;
        FlowFieldCount: Integer;
        JoinCount: Integer;
    begin
        if SQLStatement = '' then
            exit;

        // Extract main query components
        IsolationLevel := ExtractIsolationLevel(SQLStatement);
        TableName := ExtractMainTableName(SQLStatement);
        FlowFieldCount := CountOuterApply(SQLStatement);
        JoinCount := CountJoins(SQLStatement);
        ExtractWhereClauseFields(SQLStatement, TableName, EqualityFields, InequalityFields);

        // Populate LRQ Entry fields
        LRQEntry."Isolation Level" := IsolationLevel;
        LRQEntry."SQL Table Name" := CopyStr(TableName, 1, 250);
        LRQEntry."No. of FlowFields" := FlowFieldCount;
        LRQEntry."No. of JOINs" := JoinCount;
        LRQEntry."Equality Fields" := CopyStr(EqualityFields, 1, 1000);
        LRQEntry."Inequality Fields" := CopyStr(InequalityFields, 1, 1000);
        LRQEntry."No. of Equality Fields" := CountFieldsInList(EqualityFields);
        LRQEntry."No. of Inequality Fields" := CountFieldsInList(InequalityFields);
        LRQEntry."Aggregate Function" := CopyStr(ExtractAggregateFunction(SQLStatement), 1, 50);
    end;

    /// <summary>
    /// Extracts and creates FlowField subquery entries from OUTER APPLY clauses.
    /// </summary>
    procedure CreateFlowFieldEntries(ParentLRQEntry: Record "LRQ Entry"; SQLStatement: Text)
    var
        LRQFlowFieldEntry: Record "LRQ FlowField Entry";
        OuterApplyList: List of [Text];
        OuterApplySql: Text;
        SubQueryAlias: Text;
        SubQueryTable: Text;
        EqualityFields: Text;
        InequalityFields: Text;
        FlowFieldName: Text;
    begin
        ExtractOuterApplySubqueries(SQLStatement, OuterApplyList);

        foreach OuterApplySql in OuterApplyList do begin
            Clear(LRQFlowFieldEntry);
            LRQFlowFieldEntry.Init();

            // Set relationship to parent LRQ Entry
            LRQFlowFieldEntry."LRQ Entry No." := ParentLRQEntry."Entry No.";

            // Store the subquery SQL
            LRQFlowFieldEntry.SetSQLStatement(OuterApplySql);

            // Extract subquery alias (e.g., SUB$Cust_Ledger_Entry$Remaining_Amount)
            SubQueryAlias := ExtractSubQueryAlias(OuterApplySql);
            LRQFlowFieldEntry."Sub Query Alias" := CopyStr(SubQueryAlias, 1, 250);

            // Extract FlowField name from alias
            FlowFieldName := ExtractFlowFieldNameFromAlias(SubQueryAlias);
            LRQFlowFieldEntry."FlowField Name" := CopyStr(FlowFieldName, 1, 250);

            // Extract table name from subquery
            SubQueryTable := ExtractTableNameFromSubQuery(OuterApplySql);
            LRQFlowFieldEntry."SQL Table Name" := CopyStr(SubQueryTable, 1, 250);

            // Extract isolation level from subquery
            LRQFlowFieldEntry."Isolation Level" := ExtractIsolationLevel(OuterApplySql);

            // Extract WHERE clause fields from subquery
            ExtractSubQueryWhereFields(OuterApplySql, SubQueryTable, EqualityFields, InequalityFields);
            LRQFlowFieldEntry."Equality Fields" := CopyStr(EqualityFields, 1, 1000);
            LRQFlowFieldEntry."Inequality Fields" := CopyStr(InequalityFields, 1, 1000);
            LRQFlowFieldEntry."No. of Equality Fields" := CountFieldsInList(EqualityFields);
            LRQFlowFieldEntry."No. of Inequality Fields" := CountFieldsInList(InequalityFields);

            // Extract aggregate function
            LRQFlowFieldEntry."Aggregate Function" := CopyStr(ExtractAggregateFunction(OuterApplySql), 1, 50);

            // Copy parent statistics (subqueries inherit parent's occurrence)
            LRQFlowFieldEntry.Occurrence := ParentLRQEntry.Occurrence;

            // Generate prettified SQL for subquery
            LRQFlowFieldEntry.SetPrettifiedSQL(PrettifySQL(OuterApplySql));

            LRQFlowFieldEntry.Insert(true);

            // Match to AL table and transform field names
            MatchFlowFieldTableName(LRQFlowFieldEntry);
            if LRQFlowFieldEntry."Table ID" > 0 then begin
                // Transform SQL field names to AL field names
                LRQFlowFieldEntry."Equality Fields" := CopyStr(TransformFieldNames(LRQFlowFieldEntry."Table ID", LRQFlowFieldEntry."Equality Fields"), 1, 1000);
                LRQFlowFieldEntry."Inequality Fields" := CopyStr(TransformFieldNames(LRQFlowFieldEntry."Table ID", LRQFlowFieldEntry."Inequality Fields"), 1, 1000);
            end;
            LRQFlowFieldEntry.Modify();
        end;
    end;

    /// <summary>
    /// Extracts isolation level from SQL statement (e.g., WITH(READUNCOMMITTED), WITH(READCOMMITTED), WITH(UPDLOCK))
    /// </summary>
    procedure ExtractIsolationLevel(SQLStatement: Text): Enum "Isolation Level"
    var
        UpperSQL: Text;
        Pos: Integer;
    begin
        UpperSQL := UpperCase(SQLStatement);

        // Check for WITH hints in order of specificity
        if StrPos(UpperSQL, 'WITH(UPDLOCK') > 0 then
            exit("Isolation Level"::UpdLock);

        if StrPos(UpperSQL, 'WITH(REPEATABLEREAD') > 0 then
            exit("Isolation Level"::RepeatableRead);

        if StrPos(UpperSQL, 'WITH(READCOMMITTED') > 0 then
            exit("Isolation Level"::ReadCommitted);

        if StrPos(UpperSQL, 'WITH(READUNCOMMITTED') > 0 then
            exit("Isolation Level"::ReadUncommitted);

        // Check without parentheses format
        if StrPos(UpperSQL, 'WITH UPDLOCK') > 0 then
            exit("Isolation Level"::UpdLock);

        if StrPos(UpperSQL, 'REPEATABLEREAD') > 0 then
            exit("Isolation Level"::RepeatableRead);

        if StrPos(UpperSQL, 'READCOMMITTED') > 0 then
            exit("Isolation Level"::ReadCommitted);

        if StrPos(UpperSQL, 'READUNCOMMITTED') > 0 then
            exit("Isolation Level"::ReadUncommitted);

        exit("Isolation Level"::Default);
    end;

    /// <summary>
    /// Extracts the main table name from the FROM clause.
    /// Pattern: FROM "database".dbo."company$TableName$extension" AS "alias"
    /// </summary>
    procedure ExtractMainTableName(SQLStatement: Text): Text
    var
        FromPos: Integer;
        TableStart: Integer;
        TableEnd: Integer;
        TableFullName: Text;
        TableName: Text;
        UpperSQL: Text;
    begin
        UpperSQL := UpperCase(SQLStatement);

        // Find the main FROM clause (first FROM)
        FromPos := StrPos(UpperSQL, ' FROM ');
        if FromPos = 0 then
            exit('');

        // Start after "FROM "
        TableStart := FromPos + 6;

        // Find the table name after FROM - it's typically quoted
        TableFullName := ExtractTableFromPosition(SQLStatement, TableStart);

        // Extract just the table name from full path
        TableName := ExtractTableNameFromFullPath(TableFullName);

        exit(TableName);
    end;

    local procedure ExtractTableFromPosition(SQLStatement: Text; StartPos: Integer): Text
    var
        QuoteStart: Integer;
        QuoteEnd: Integer;
        TablePart: Text;
        SubStr: Text;
        i: Integer;
    begin
        if StartPos > StrLen(SQLStatement) then
            exit('');

        SubStr := CopyStr(SQLStatement, StartPos);

        // Skip whitespace
        i := 1;
        while (i <= StrLen(SubStr)) and (SubStr[i] = ' ') do
            i += 1;

        if i > StrLen(SubStr) then
            exit('');

        // Check if quoted table name
        if SubStr[i] = '"' then begin
            // Find closing quote, but handle "database".dbo."table"
            // We need the last quoted segment before AS or WITH
            TablePart := FindLastTableSegment(CopyStr(SubStr, i));
            exit(TablePart);
        end else begin
            // Unquoted table name - find end (space, WITH, AS)
            QuoteStart := i;
            while (i <= StrLen(SubStr)) and (SubStr[i] <> ' ') do
                i += 1;
            exit(CopyStr(SubStr, QuoteStart, i - QuoteStart));
        end;
    end;

    local procedure FindLastTableSegment(SQLPart: Text): Text
    var
        Segments: List of [Text];
        Segment: Text;
        Result: Text;
        InQuote: Boolean;
        CurrentSegment: Text;
        i: Integer;
        c: Char;
        UpperPart: Text;
        EndPos: Integer;
    begin
        // Find where table reference ends (before AS, WITH, OUTER, LEFT, etc.)
        UpperPart := UpperCase(SQLPart);

        // Find the boundary markers
        EndPos := FindTableEndPosition(UpperPart);
        if EndPos > 0 then
            SQLPart := CopyStr(SQLPart, 1, EndPos - 1);

        // Now extract all quoted segments
        InQuote := false;
        CurrentSegment := '';

        for i := 1 to StrLen(SQLPart) do begin
            c := SQLPart[i];
            if c = '"' then begin
                if InQuote then begin
                    // End of quoted segment
                    if CurrentSegment <> '' then
                        Segments.Add(CurrentSegment);
                    CurrentSegment := '';
                    InQuote := false;
                end else begin
                    InQuote := true;
                    CurrentSegment := '';
                end;
            end else if InQuote then
                    CurrentSegment += Format(c);
        end;

        // Find the segment containing '$' - this is the table path (format: company$TableName$extension)
        // The last segment might be an alias (e.g., "5802") which doesn't contain '$'
        for i := Segments.Count() downto 1 do begin
            Segment := Segments.Get(i);
            if StrPos(Segment, '$') > 0 then
                exit(Segment);
        end;

        // No segment with '$' found - return the last segment as fallback
        if Segments.Count() > 0 then
            exit(Segments.Get(Segments.Count()));

        exit('');
    end;

    local procedure FindTableEndPosition(UpperSQL: Text): Integer
    var
        Pos: Integer;
        MinPos: Integer;
        Keywords: List of [Text];
        Keyword: Text;
        i: Integer;
    begin
        MinPos := 0;

        // Standard keyword searches
        Keywords.Add(' AS ');
        Keywords.Add(' OUTER ');
        Keywords.Add(' LEFT ');
        Keywords.Add(' RIGHT ');
        Keywords.Add(' INNER ');
        Keywords.Add(' JOIN ');
        Keywords.Add(' WHERE ');
        Keywords.Add(' ORDER ');
        Keywords.Add(' GROUP ');

        foreach Keyword in Keywords do begin
            Pos := StrPos(UpperSQL, Keyword);
            if (Pos > 0) and ((MinPos = 0) or (Pos < MinPos)) then
                MinPos := Pos;
        end;

        // Handle WITH with variable whitespace (e.g., "  WITH(" or " WITH(")
        for i := 1 to StrLen(UpperSQL) - 4 do begin
            if (UpperSQL[i] = ' ') and (CopyStr(UpperSQL, i + 1, 4) = 'WITH') then begin
                if (MinPos = 0) or (i < MinPos) then
                    MinPos := i;
                break;
            end;
        end;

        exit(MinPos);
    end;

    /// <summary>
    /// Extracts table name from full SQL path like "company$TableName$extension"
    /// </summary>
    local procedure ExtractTableNameFromFullPath(FullPath: Text): Text
    var
        Parts: List of [Text];
        TablePart: Text;
        DollarPos1: Integer;
        DollarPos2: Integer;
    begin
        if FullPath = '' then
            exit('');

        // Remove any remaining quotes
        FullPath := DelChr(FullPath, '=', '"');

        // Find table name between $ signs
        // Format: COMPANY$TableName$extension-guid
        DollarPos1 := StrPos(FullPath, '$');
        if DollarPos1 = 0 then
            exit(FullPath); // No $ sign, return as is

        TablePart := CopyStr(FullPath, DollarPos1 + 1);
        DollarPos2 := StrPos(TablePart, '$');

        if DollarPos2 > 0 then
            TablePart := CopyStr(TablePart, 1, DollarPos2 - 1);

        exit(TablePart);
    end;

    /// <summary>
    /// Counts the number of OUTER APPLY clauses (FlowFields)
    /// </summary>
    procedure CountOuterApply(SQLStatement: Text): Integer
    var
        UpperSQL: Text;
        Count: Integer;
        Pos: Integer;
        SearchFrom: Integer;
    begin
        UpperSQL := UpperCase(SQLStatement);
        Count := 0;
        SearchFrom := 1;

        repeat
            Pos := StrPos(CopyStr(UpperSQL, SearchFrom), 'OUTER APPLY');
            if Pos > 0 then begin
                Count += 1;
                SearchFrom := SearchFrom + Pos + 10;
            end;
        until (Pos = 0) or (SearchFrom > StrLen(UpperSQL));

        exit(Count);
    end;

    /// <summary>
    /// Counts the number of JOIN clauses
    /// </summary>
    procedure CountJoins(SQLStatement: Text): Integer
    var
        UpperSQL: Text;
        Count: Integer;
        Pos: Integer;
        SearchFrom: Integer;
    begin
        UpperSQL := UpperCase(SQLStatement);
        Count := 0;
        SearchFrom := 1;

        // Count various JOIN types but exclude OUTER APPLY
        repeat
            Pos := StrPos(CopyStr(UpperSQL, SearchFrom), ' JOIN ');
            if Pos > 0 then begin
                Count += 1;
                SearchFrom := SearchFrom + Pos + 5;
            end;
        until (Pos = 0) or (SearchFrom > StrLen(UpperSQL));

        exit(Count);
    end;

    /// <summary>
    /// Extracts equality and inequality fields from the WHERE clause.
    /// </summary>
    procedure ExtractWhereClauseFields(SQLStatement: Text; MainTableAlias: Text; var EqualityFields: Text; var InequalityFields: Text)
    var
        WhereClause: Text;
        UpperSQL: Text;
        WherePos: Integer;
        EndPos: Integer;
        Alias: Text;
    begin
        EqualityFields := '';
        InequalityFields := '';

        UpperSQL := UpperCase(SQLStatement);
        WherePos := StrPos(UpperSQL, ' WHERE ');
        if WherePos = 0 then
            exit;

        // Find the end of WHERE clause (ORDER BY, GROUP BY, OPTION, or end)
        EndPos := FindWhereClauseEnd(UpperSQL, WherePos + 7);
        if EndPos > 0 then
            WhereClause := CopyStr(SQLStatement, WherePos + 7, EndPos - WherePos - 7)
        else
            WhereClause := CopyStr(SQLStatement, WherePos + 7);

        // Use provided alias if available, otherwise extract it
        if MainTableAlias <> '' then
            Alias := MainTableAlias
        else
            Alias := ExtractTableAlias(SQLStatement, WherePos);

        ParseWhereClauseForFields(WhereClause, Alias, EqualityFields, InequalityFields);
    end;

    local procedure FindWhereClauseEnd(UpperSQL: Text; StartPos: Integer): Integer
    var
        Pos: Integer;
        MinPos: Integer;
        Keywords: List of [Text];
        Keyword: Text;
        SubStr: Text;
    begin
        MinPos := 0;
        SubStr := CopyStr(UpperSQL, StartPos);

        Keywords.Add(' ORDER BY ');
        Keywords.Add(' GROUP BY ');
        Keywords.Add(' OPTION(');
        Keywords.Add(' OPTION (');

        foreach Keyword in Keywords do begin
            Pos := StrPos(SubStr, Keyword);
            if (Pos > 0) and ((MinPos = 0) or (Pos < MinPos)) then
                MinPos := Pos;
        end;

        if MinPos > 0 then
            exit(StartPos + MinPos - 1);

        exit(0);
    end;

    local procedure ExtractTableAlias(SQLStatement: Text; BeforePos: Integer): Text
    var
        UpperSQL: Text;
        FromPos: Integer;
        AsPos: Integer;
        WithPos: Integer;
        AliasStart: Integer;
        AliasEnd: Integer;
        QuoteStart: Integer;
        QuoteEnd: Integer;
        SubStr: Text;
        BoundaryPos: Integer;
        i: Integer;
    begin
        UpperSQL := UpperCase(CopyStr(SQLStatement, 1, BeforePos));

        // Find FROM clause
        FromPos := StrPos(UpperSQL, ' FROM ');
        if FromPos = 0 then
            exit('');

        SubStr := CopyStr(SQLStatement, FromPos);
        UpperSQL := UpperCase(SubStr);

        // Look for AS "alias" or just "alias" after table name
        AsPos := StrPos(UpperSQL, ' AS ');
        if AsPos > 0 then begin
            // Find the alias after AS
            SubStr := CopyStr(SubStr, AsPos + 4);
            // Skip whitespace
            i := 1;
            while (i <= StrLen(SubStr)) and (SubStr[i] = ' ') do
                i += 1;

            if (i <= StrLen(SubStr)) and (SubStr[i] = '"') then begin
                // Quoted alias
                QuoteStart := i + 1;
                QuoteEnd := StrPos(CopyStr(SubStr, QuoteStart), '"');
                if QuoteEnd > 0 then
                    exit(CopyStr(SubStr, QuoteStart, QuoteEnd - 1));
            end;
        end;

        // Find boundary (WITH or WHERE - whatever comes first after FROM)
        BoundaryPos := FindTableEndBoundary(CopyStr(SQLStatement, FromPos));
        if BoundaryPos > 0 then begin
            SubStr := CopyStr(SQLStatement, FromPos, BoundaryPos);
            // Find last quoted segment (should be the alias like "5802")
            exit(FindLastQuotedSegment(SubStr));
        end;

        exit('');
    end;

    local procedure FindTableEndBoundary(SQLPart: Text): Integer
    var
        UpperSQL: Text;
        Pos: Integer;
        MinPos: Integer;
        i: Integer;
    begin
        UpperSQL := UpperCase(SQLPart);
        MinPos := 0;

        // Find WITH (handle variable whitespace before it)
        for i := 1 to StrLen(UpperSQL) - 4 do begin
            if (SQLPart[i] = ' ') and (UpperCase(CopyStr(SQLPart, i + 1, 4)) = 'WITH') then begin
                MinPos := i;
                break;
            end;
        end;

        // Also check for WHERE
        Pos := StrPos(UpperSQL, ' WHERE ');
        if (Pos > 0) and ((MinPos = 0) or (Pos < MinPos)) then
            MinPos := Pos;

        exit(MinPos);
    end;

    local procedure FindLastQuotedSegment(Text: Text): Text
    var
        LastQuote: Integer;
        SecondLastQuote: Integer;
        i: Integer;
        QuotePositions: List of [Integer];
    begin
        for i := 1 to StrLen(Text) do
            if Text[i] = '"' then
                QuotePositions.Add(i);

        if QuotePositions.Count() >= 2 then begin
            LastQuote := QuotePositions.Get(QuotePositions.Count());
            SecondLastQuote := QuotePositions.Get(QuotePositions.Count() - 1);
            exit(CopyStr(Text, SecondLastQuote + 1, LastQuote - SecondLastQuote - 1));
        end;

        exit('');
    end;

    local procedure ParseWhereClauseForFields(WhereClause: Text; TableAlias: Text; var EqualityFields: Text; var InequalityFields: Text)
    var
        Conditions: List of [Text];
        Condition: Text;
        FieldName: Text;
        Operator: Text;
        EqualityList: List of [Text];
        InequalityList: List of [Text];
        AliasPrefix: Text;
        i: Integer;
    begin
        if TableAlias <> '' then
            AliasPrefix := '"' + TableAlias + '".'
        else
            AliasPrefix := '';

        // Split by AND (simplified - real SQL parsing would be more complex)
        SplitConditions(WhereClause, Conditions);

        foreach Condition in Conditions do begin
            // Skip conditions referencing SUB$ (subquery results)
            if StrPos(UpperCase(Condition), 'SUB$') > 0 then
                continue;

            // Skip ISNULL wrapped conditions from joins
            if StrPos(UpperCase(Condition), 'ISNULL(') > 0 then
                // Only process if it's for our table
                if (AliasPrefix <> '') and (StrPos(Condition, AliasPrefix) = 0) then
                    continue;

            // Extract field and operator
            if ExtractFieldAndOperator(Condition, AliasPrefix, FieldName, Operator) then begin
                if IsEqualityOperator(Operator) then begin
                    if not EqualityList.Contains(FieldName) then
                        EqualityList.Add(FieldName);
                end else if IsInequalityOperator(Operator) then begin
                    if not InequalityList.Contains(FieldName) then
                        InequalityList.Add(FieldName);
                end;
            end;
        end;

        // Build comma-separated strings
        EqualityFields := BuildFieldList(EqualityList);
        InequalityFields := BuildFieldList(InequalityList);
    end;

    local procedure SplitConditions(WhereClause: Text; var Conditions: List of [Text])
    var
        UpperWhere: Text;
        AndPos: Integer;
        OrPos: Integer;
        CurrentPos: Integer;
        ConditionStart: Integer;
        ParenDepth: Integer;
        i: Integer;
        c: Char;
        InString: Boolean;
        CurrentCondition: Text;
    begin
        Clear(Conditions);

        // Simple split by AND while respecting parentheses
        ParenDepth := 0;
        InString := false;
        ConditionStart := 1;

        for i := 1 to StrLen(WhereClause) do begin
            c := WhereClause[i];

            if c = '''' then
                InString := not InString
            else if not InString then begin
                if c = '(' then
                    ParenDepth += 1
                else if c = ')' then
                    ParenDepth -= 1
                else if (ParenDepth = 0) and (i + 4 <= StrLen(WhereClause)) then begin
                    // Check for " AND "
                    if UpperCase(CopyStr(WhereClause, i, 5)) = ' AND ' then begin
                        CurrentCondition := CopyStr(WhereClause, ConditionStart, i - ConditionStart);
                        CurrentCondition := DelChr(CurrentCondition, '<>', ' ()');
                        if CurrentCondition <> '' then
                            Conditions.Add(CurrentCondition);
                        ConditionStart := i + 5;
                    end;
                end;
            end;
        end;

        // Add last condition
        CurrentCondition := CopyStr(WhereClause, ConditionStart);
        CurrentCondition := DelChr(CurrentCondition, '<>', ' ()');
        if CurrentCondition <> '' then
            Conditions.Add(CurrentCondition);
    end;

    local procedure ExtractFieldAndOperator(Condition: Text; AliasPrefix: Text; var FieldName: Text; var Operator: Text): Boolean
    var
        QuoteStart: Integer;
        QuoteEnd: Integer;
        OpPos: Integer;
        FieldWithAlias: Text;
        SubStr: Text;
    begin
        FieldName := '';
        Operator := '';

        // Look for operators
        OpPos := FindOperatorPosition(Condition, Operator);
        if OpPos = 0 then
            exit(false);

        // Get the left side of the operator (field reference)
        SubStr := CopyStr(Condition, 1, OpPos - 1);
        SubStr := DelChr(SubStr, '<>', ' ');

        // Handle ISNULL wrapper
        if StrPos(UpperCase(SubStr), 'ISNULL(') > 0 then
            SubStr := ExtractFromISNULL(SubStr);

        // Check if it's from our table
        if AliasPrefix <> '' then begin
            if StrPos(SubStr, AliasPrefix) = 0 then
                exit(false);
            // Remove alias prefix
            SubStr := CopyStr(SubStr, StrLen(AliasPrefix) + 1);
        end;

        // Extract field name (should be quoted)
        SubStr := DelChr(SubStr, '=', '"');
        FieldName := SubStr;

        exit(FieldName <> '');
    end;

    local procedure FindOperatorPosition(Condition: Text; var Operator: Text): Integer
    var
        Pos: Integer;
        Operators: List of [Text];
        Op: Text;
        BestPos: Integer;
        BestOp: Text;
    begin
        BestPos := 0;
        BestOp := '';

        // Check operators in order of length (longer first to avoid partial matches)
        Operators.Add('<>');
        Operators.Add('>=');
        Operators.Add('<=');
        Operators.Add('!=');
        Operators.Add('>');
        Operators.Add('<');
        Operators.Add('=');

        foreach Op in Operators do begin
            Pos := StrPos(Condition, Op);
            if (Pos > 0) and ((BestPos = 0) or (Pos < BestPos)) then begin
                BestPos := Pos;
                BestOp := Op;
            end;
        end;

        Operator := BestOp;
        exit(BestPos);
    end;

    local procedure ExtractFromISNULL(Text: Text): Text
    var
        StartPos: Integer;
        EndPos: Integer;
        ParenDepth: Integer;
        i: Integer;
    begin
        StartPos := StrPos(UpperCase(Text), 'ISNULL(');
        if StartPos = 0 then
            exit(Text);

        StartPos := StartPos + 7; // Skip "ISNULL("
        ParenDepth := 1;

        for i := StartPos to StrLen(Text) do begin
            if Text[i] = '(' then
                ParenDepth += 1
            else if Text[i] = ')' then
                ParenDepth -= 1
            else if (Text[i] = ',') and (ParenDepth = 1) then begin
                // First comma at depth 1 ends the field reference
                exit(CopyStr(Text, StartPos, i - StartPos));
            end;

            if ParenDepth = 0 then
                exit(CopyStr(Text, StartPos, i - StartPos));
        end;

        exit(CopyStr(Text, StartPos));
    end;

    local procedure IsEqualityOperator(Operator: Text): Boolean
    begin
        exit(Operator = '=');
    end;

    local procedure IsInequalityOperator(Operator: Text): Boolean
    begin
        exit(Operator in ['<>', '!=', '>', '<', '>=', '<=']);
    end;

    local procedure BuildFieldList(FieldList: List of [Text]): Text
    var
        Result: Text;
        Field: Text;
    begin
        Result := '';
        foreach Field in FieldList do begin
            if Result <> '' then
                Result += ', ';
            Result += Field;
        end;
        exit(Result);
    end;

    /// <summary>
    /// Extracts aggregate function from SQL (SUM, COUNT, AVG, MIN, MAX)
    /// </summary>
    procedure ExtractAggregateFunction(SQLStatement: Text): Text
    var
        UpperSQL: Text;
        Functions: List of [Text];
        Func: Text;
    begin
        UpperSQL := UpperCase(SQLStatement);

        Functions.Add('SUM(');
        Functions.Add('COUNT(');
        Functions.Add('AVG(');
        Functions.Add('MIN(');
        Functions.Add('MAX(');

        foreach Func in Functions do begin
            if StrPos(UpperSQL, Func) > 0 then
                exit(CopyStr(Func, 1, StrLen(Func) - 1)); // Remove opening paren
        end;

        exit('');
    end;

    /// <summary>
    /// Extracts all OUTER APPLY subqueries from SQL statement.
    /// </summary>
    local procedure ExtractOuterApplySubqueries(SQLStatement: Text; var SubQueries: List of [Text])
    var
        UpperSQL: Text;
        OuterApplyPos: Integer;
        SearchFrom: Integer;
        SubQueryStart: Integer;
        SubQueryEnd: Integer;
        ParenDepth: Integer;
        SubQuerySQL: Text;
        i: Integer;
    begin
        Clear(SubQueries);
        UpperSQL := UpperCase(SQLStatement);
        SearchFrom := 1;

        repeat
            // Reset for each iteration
            SubQueryEnd := 0;
            SubQueryStart := 0;

            OuterApplyPos := StrPos(CopyStr(UpperSQL, SearchFrom), 'OUTER APPLY');
            if OuterApplyPos > 0 then begin
                OuterApplyPos := SearchFrom + OuterApplyPos - 1;

                // Find the opening parenthesis after OUTER APPLY
                SubQueryStart := StrPos(CopyStr(SQLStatement, OuterApplyPos + 11), '(');
                if SubQueryStart > 0 then begin
                    SubQueryStart := OuterApplyPos + 11 + SubQueryStart - 1;

                    // Find matching closing parenthesis
                    ParenDepth := 1;
                    for i := SubQueryStart + 1 to StrLen(SQLStatement) do begin
                        if SQLStatement[i] = '(' then
                            ParenDepth += 1
                        else if SQLStatement[i] = ')' then begin
                            ParenDepth -= 1;
                            if ParenDepth = 0 then begin
                                SubQueryEnd := i;
                                break;
                            end;
                        end;
                    end;

                    if SubQueryEnd > SubQueryStart then begin
                        // Extract including the AS alias after the closing paren
                        SubQuerySQL := ExtractSubQueryWithAlias(SQLStatement, SubQueryStart, SubQueryEnd);
                        if SubQuerySQL <> '' then
                            SubQueries.Add(SubQuerySQL);
                    end;
                end;

                SearchFrom := OuterApplyPos + 11;
            end;
        until (OuterApplyPos = 0) or (SearchFrom > StrLen(SQLStatement));
    end;

    local procedure ExtractSubQueryWithAlias(SQLStatement: Text; StartPos: Integer; EndPos: Integer): Text
    var
        UpperSQL: Text;
        AsPos: Integer;
        AliasEnd: Integer;
        SubStr: Text;
        SubQueryLen: Integer;
        i: Integer;
    begin
        // Validate positions
        if (StartPos <= 0) or (EndPos <= 0) or (StartPos > StrLen(SQLStatement)) then
            exit('');

        if EndPos > StrLen(SQLStatement) then
            EndPos := StrLen(SQLStatement);

        if EndPos < StartPos then
            exit('');

        SubQueryLen := EndPos - StartPos + 1;

        // Get the subquery
        SubStr := CopyStr(SQLStatement, StartPos, SubQueryLen);

        // Look for AS "alias" after the closing paren
        if EndPos < StrLen(SQLStatement) then begin
            UpperSQL := UpperCase(CopyStr(SQLStatement, EndPos + 1));
            AsPos := StrPos(UpperSQL, ' AS ');

            if AsPos > 0 then begin
                // Find the end of alias
                SubStr := CopyStr(SQLStatement, EndPos + AsPos + 4);
                // Find closing quote
                i := 1;
                while (i <= StrLen(SubStr)) and (SubStr[i] = ' ') do
                    i += 1;

                if (i <= StrLen(SubStr)) and (SubStr[i] = '"') then begin
                    AliasEnd := StrPos(CopyStr(SubStr, i + 1), '"');
                    if AliasEnd > 0 then begin
                        // Return subquery with alias
                        exit(CopyStr(SQLStatement, StartPos, SubQueryLen) + ' AS ' + CopyStr(SubStr, i, AliasEnd + 1));
                    end;
                end;
            end;
        end;

        exit(CopyStr(SQLStatement, StartPos, SubQueryLen));
    end;

    local procedure ExtractSubQueryAlias(OuterApplySql: Text): Text
    var
        UpperSQL: Text;
        AsPos: Integer;
        QuoteStart: Integer;
        QuoteEnd: Integer;
        SubStr: Text;
    begin
        UpperSQL := UpperCase(OuterApplySql);
        AsPos := StrPos(UpperSQL, ') AS ');

        if AsPos = 0 then
            exit('');

        SubStr := CopyStr(OuterApplySql, AsPos + 5);
        SubStr := DelChr(SubStr, '<>', ' ');

        if (StrLen(SubStr) > 0) and (SubStr[1] = '"') then begin
            QuoteEnd := StrPos(CopyStr(SubStr, 2), '"');
            if QuoteEnd > 0 then
                exit(CopyStr(SubStr, 2, QuoteEnd - 1));
        end;

        exit(SubStr);
    end;

    local procedure ExtractFlowFieldNameFromAlias(Alias: Text): Text
    var
        Parts: List of [Text];
        Part: Text;
        DollarPos: Integer;
    begin
        // Alias format: SUB$TableAlias$FieldName
        // e.g., SUB$Cust_Ledger_Entry$Remaining_Amount -> Remaining Amount
        if StrPos(Alias, 'SUB$') <> 1 then
            exit(Alias);

        Alias := CopyStr(Alias, 5); // Remove SUB$

        DollarPos := StrPos(Alias, '$');
        if DollarPos > 0 then
            Alias := CopyStr(Alias, DollarPos + 1);

        // Replace underscores with spaces
        Alias := Alias.Replace('_', ' ');

        exit(Alias);
    end;

    local procedure ExtractTableNameFromSubQuery(OuterApplySql: Text): Text
    var
        FromPos: Integer;
        TableName: Text;
        UpperSQL: Text;
    begin
        UpperSQL := UpperCase(OuterApplySql);
        FromPos := StrPos(UpperSQL, ' FROM ');

        if FromPos = 0 then
            exit('');

        TableName := ExtractTableFromPosition(OuterApplySql, FromPos + 6);
        exit(ExtractTableNameFromFullPath(TableName));
    end;

    local procedure ExtractSubQueryWhereFields(OuterApplySql: Text; SubQueryTable: Text; var EqualityFields: Text; var InequalityFields: Text)
    var
        Alias: Text;
    begin
        // For subqueries, extract the alias used in the FROM clause
        Alias := ExtractSubQueryTableAlias(OuterApplySql);
        ExtractWhereClauseFields(OuterApplySql, Alias, EqualityFields, InequalityFields);
    end;

    local procedure ExtractSubQueryTableAlias(OuterApplySql: Text): Text
    var
        UpperSQL: Text;
        FromPos: Integer;
        AsPos: Integer;
        WithPos: Integer;
        SubStr: Text;
        QuoteStart: Integer;
        QuoteEnd: Integer;
    begin
        UpperSQL := UpperCase(OuterApplySql);
        FromPos := StrPos(UpperSQL, ' FROM ');

        if FromPos = 0 then
            exit('');

        SubStr := CopyStr(OuterApplySql, FromPos);
        UpperSQL := UpperCase(SubStr);

        AsPos := StrPos(UpperSQL, ' AS ');
        if AsPos > 0 then begin
            SubStr := CopyStr(SubStr, AsPos + 4);
            // Find quoted alias
            QuoteStart := StrPos(SubStr, '"');
            if QuoteStart > 0 then begin
                QuoteEnd := StrPos(CopyStr(SubStr, QuoteStart + 1), '"');
                if QuoteEnd > 0 then
                    exit(CopyStr(SubStr, QuoteStart + 1, QuoteEnd - 1));
            end;
        end;

        exit('');
    end;

    /// <summary>
    /// Prettifies SQL statement for better readability.
    /// </summary>
    procedure PrettifySQL(SQLStatement: Text): Text
    var
        Result: Text;
        IndentLevel: Integer;
        CR: Text[2];
        Tab: Text[4];
        UpperSQL: Text;
        i: Integer;
    begin
        CR := GetCRLF();
        Tab := '    ';
        IndentLevel := 0;

        Result := SQLStatement;

        // Add line breaks before major keywords
        Result := InsertLineBreakBefore(Result, 'SELECT');
        Result := InsertLineBreakBefore(Result, 'FROM');
        Result := InsertLineBreakBefore(Result, 'WHERE');
        Result := InsertLineBreakBefore(Result, 'ORDER BY');
        Result := InsertLineBreakBefore(Result, 'GROUP BY');
        Result := InsertLineBreakBefore(Result, 'HAVING');
        Result := InsertLineBreakBefore(Result, 'LEFT OUTER JOIN');
        Result := InsertLineBreakBefore(Result, 'LEFT JOIN');
        Result := InsertLineBreakBefore(Result, 'RIGHT OUTER JOIN');
        Result := InsertLineBreakBefore(Result, 'RIGHT JOIN');
        Result := InsertLineBreakBefore(Result, 'INNER JOIN');
        Result := InsertLineBreakBefore(Result, 'OUTER APPLY');
        Result := InsertLineBreakBefore(Result, 'CROSS APPLY');
        Result := InsertLineBreakBefore(Result, 'OPTION(');

        // Add line breaks and indentation for AND/OR in WHERE
        Result := InsertLineBreakBefore(Result, ' AND ');
        Result := InsertLineBreakBefore(Result, ' OR ');

        // Clean up multiple line breaks
        Result := CleanupLineBreaks(Result);

        // Add proper indentation
        Result := AddIndentation(Result);

        exit(Result);
    end;

    local procedure GetCRLF(): Text[2]
    var
        CR: Char;
        LF: Char;
    begin
        CR := 13;
        LF := 10;
        exit(Format(CR) + Format(LF));
    end;

    local procedure InsertLineBreakBefore(Text: Text; Keyword: Text): Text
    var
        UpperText: Text;
        UpperKeyword: Text;
        Pos: Integer;
        SearchStartPos: Integer;
        FoundPos: Integer;
        CR: Text[2];
        NeedsLineBreak: Boolean;
    begin
        // Handle empty or very short text
        if (StrLen(Text) < StrLen(Keyword)) or (Keyword = '') then
            exit(Text);

        CR := GetCRLF();
        UpperText := UpperCase(Text);
        UpperKeyword := UpperCase(Keyword);
        Pos := StrPos(UpperText, UpperKeyword);

        while Pos > 0 do begin
            // Check if we need to add a line break
            NeedsLineBreak := false;
            if Pos > 1 then
                if Text[Pos - 1] <> GetLF() then
                    NeedsLineBreak := true;

            if NeedsLineBreak then begin
                Text := CopyStr(Text, 1, Pos - 1) + CR + CopyStr(Text, Pos);
                UpperText := UpperCase(Text);
                // Search from position after the keyword we just processed (plus 2 for CRLF we inserted)
                SearchStartPos := Pos + StrLen(Keyword) + 2;
            end else begin
                // No break needed, search from position after the keyword
                SearchStartPos := Pos + StrLen(Keyword);
            end;

            // Find next occurrence
            if SearchStartPos <= StrLen(UpperText) then begin
                FoundPos := StrPos(CopyStr(UpperText, SearchStartPos), UpperKeyword);
                if FoundPos > 0 then
                    Pos := SearchStartPos + FoundPos - 1
                else
                    Pos := 0;
            end else
                Pos := 0;
        end;

        exit(Text);
    end;

    local procedure GetLF(): Char
    begin
        exit(10);
    end;

    local procedure CleanupLineBreaks(Text: Text): Text
    var
        CR: Text[2];
        DoubleCR: Text[4];
    begin
        CR := GetCRLF();
        DoubleCR := CR + CR;

        // Remove multiple consecutive line breaks
        while StrPos(Text, DoubleCR) > 0 do
            Text := Text.Replace(DoubleCR, CR);

        // Trim leading/trailing whitespace from each line
        exit(Text);
    end;

    local procedure AddIndentation(Text: Text): Text
    var
        Lines: List of [Text];
        Line: Text;
        Result: Text;
        IndentLevel: Integer;
        UpperLine: Text;
        CR: Text[2];
        Tab: Text[4];
        i: Integer;
    begin
        CR := GetCRLF();
        Tab := '    ';

        // Split into lines
        SplitIntoLines(Text, Lines);

        IndentLevel := 0;
        Result := '';

        foreach Line in Lines do begin
            Line := DelChr(Line, '<', ' ');
            UpperLine := UpperCase(Line);

            // Decrease indent for closing elements
            if (StrPos(UpperLine, ')') = 1) then
                if IndentLevel > 0 then
                    IndentLevel -= 1;

            // Add current line with indentation
            for i := 1 to IndentLevel do
                Line := Tab + Line;

            if Result <> '' then
                Result += CR;
            Result += Line;

            // Increase indent after SELECT, FROM with subquery start
            if StrPos(UpperLine, 'OUTER APPLY (') > 0 then
                IndentLevel += 1
            else if StrPos(UpperLine, 'CROSS APPLY (') > 0 then
                IndentLevel += 1;
        end;

        exit(Result);
    end;

    local procedure SplitIntoLines(Text: Text; var Lines: List of [Text])
    var
        CR: Text[2];
        LF: Text[1];
        Line: Text;
        Pos: Integer;
    begin
        Clear(Lines);
        CR := GetCRLF();

        // Replace CRLF with just LF for consistent splitting
        Text := Text.Replace(CR, Format(GetLF()));

        while Text <> '' do begin
            Pos := StrPos(Text, Format(GetLF()));
            if Pos > 0 then begin
                Line := CopyStr(Text, 1, Pos - 1);
                Text := CopyStr(Text, Pos + 1);
            end else begin
                Line := Text;
                Text := '';
            end;
            Lines.Add(Line);
        end;
    end;

    local procedure CountFieldsInList(FieldList: Text): Integer
    var
        FieldCount: Integer;
        i: Integer;
    begin
        if FieldList = '' then
            exit(0);

        FieldCount := 1;
        for i := 1 to StrLen(FieldList) do begin
            if FieldList[i] = ',' then
                FieldCount += 1;
        end;
        exit(FieldCount);
    end;

    local procedure MatchTableName(var LRQEntry: Record "LRQ Entry")
    var
        AllObj: Record AllObjWithCaption;
        NormalizedSQLName: Text;
        NormalizedALName: Text;
    begin
        if LRQEntry."SQL Table Name" = '' then
            exit;

        NormalizedSQLName := NormalizeNameForComparison(LRQEntry."SQL Table Name");

        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        if AllObj.FindSet() then
            repeat
                NormalizedALName := NormalizeNameForComparison(AllObj."Object Name");
                if NormalizedSQLName = NormalizedALName then begin
                    LRQEntry."Table ID" := AllObj."Object ID";
                    LRQEntry."AL Table Name" := AllObj."Object Name";
                    exit;
                end;
            until AllObj.Next() = 0;
    end;

    local procedure MatchFlowFieldTableName(var LRQFlowFieldEntry: Record "LRQ FlowField Entry")
    var
        AllObj: Record AllObjWithCaption;
        NormalizedSQLName: Text;
        NormalizedALName: Text;
    begin
        if LRQFlowFieldEntry."SQL Table Name" = '' then
            exit;

        NormalizedSQLName := NormalizeNameForComparison(LRQFlowFieldEntry."SQL Table Name");

        AllObj.Reset();
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        if AllObj.FindSet() then
            repeat
                NormalizedALName := NormalizeNameForComparison(AllObj."Object Name");
                if NormalizedSQLName = NormalizedALName then begin
                    LRQFlowFieldEntry."Table ID" := AllObj."Object ID";
                    LRQFlowFieldEntry."Table Name" := AllObj."Object Name";
                    exit;
                end;
            until AllObj.Next() = 0;
    end;

    local procedure NormalizeNameForComparison(Name: Text): Text
    var
        NormalizedName: Text;
    begin
        if StrPos(Name, '$') > 0 then
            Name := CopyStr(Name, StrPos(Name, '$') + 1);

        if StrPos(Name, '$') > 0 then
            Name := CopyStr(Name, 1, StrPos(Name, '$') - 1);

        NormalizedName := UpperCase(Name);
        // Remove special characters that SQL replaces with underscores: ."\'/%][
        // Also remove spaces and underscores for normalized comparison
        NormalizedName := DelChr(NormalizedName, '=', '."\/''"%][ _');

        exit(NormalizedName);
    end;

    /// <summary>
    /// Transforms SQL field names to AL field names by matching against table metadata.
    /// SQL uses _ for special characters like . " \ / ' % ] [
    /// </summary>
    local procedure TransformFieldNames(TableID: Integer; SQLFieldList: Text): Text
    var
        RecRef: RecordRef;
        FieldList: List of [Text];
        ALFieldList: Text;
        SQLFieldName: Text;
        ALFieldName: Text;
    begin
        if (TableID = 0) or (SQLFieldList = '') then
            exit(SQLFieldList);

        // Parse the comma-separated list of SQL field names
        ParseFieldListForTransform(SQLFieldList, FieldList);

        if not TryOpenRecRef(TableID, RecRef) then
            exit(SQLFieldList);

        ALFieldList := '';
        foreach SQLFieldName in FieldList do begin
            // Try to match the SQL field name to an AL field
            ALFieldName := FindALFieldName(RecRef, SQLFieldName);

            if ALFieldList <> '' then
                ALFieldList += ', ';

            if ALFieldName <> '' then
                ALFieldList += ALFieldName
            else
                ALFieldList += SQLFieldName; // Keep original if no match found
        end;

        RecRef.Close();
        exit(ALFieldList);
    end;

    local procedure FindALFieldName(var RecRef: RecordRef; SQLFieldName: Text): Text
    var
        FldRef: FieldRef;
        i: Integer;
        FieldCount: Integer;
        NormalizedSQLName: Text;
        NormalizedALName: Text;
    begin
        // Remove square brackets and quotes if present
        SQLFieldName := DelChr(SQLFieldName, '=', '[]"');

        // Normalize SQL field name for comparison
        // SQL uses _ for special characters: ."\'/%][
        NormalizedSQLName := NormalizeNameForComparison(SQLFieldName);

        FieldCount := RecRef.FieldCount();
        for i := 1 to FieldCount do begin
            FldRef := RecRef.FieldIndex(i);
            NormalizedALName := NormalizeNameForComparison(FldRef.Name);

            if NormalizedSQLName = NormalizedALName then
                exit(FldRef.Name);
        end;

        exit('');
    end;

    local procedure ParseFieldListForTransform(FieldList: Text; var FieldNames: List of [Text])
    var
        FieldName: Text;
        CommaPos: Integer;
    begin
        Clear(FieldNames);
        if FieldList = '' then
            exit;

        // Remove square brackets from the field list (e.g., ["Field1","Field2"] -> Field1,Field2)
        FieldList := DelChr(FieldList, '=', '[]"');

        // Handle different separators (comma, semicolon, newline)
        FieldList := FieldList.Replace(';', ',');

        while FieldList <> '' do begin
            CommaPos := StrPos(FieldList, ',');
            if CommaPos > 0 then begin
                FieldName := CopyStr(FieldList, 1, CommaPos - 1);
                FieldList := CopyStr(FieldList, CommaPos + 1);
            end else begin
                FieldName := FieldList;
                FieldList := '';
            end;

            // Trim spaces and remove any remaining quotes
            FieldName := DelChr(FieldName, '<>', ' ');
            FieldName := DelChr(FieldName, '=', '"''');
            if FieldName <> '' then
                FieldNames.Add(FieldName);
        end;
    end;

    [TryFunction]
    local procedure TryOpenRecRef(TableID: Integer; var RecRef: RecordRef)
    begin
        RecRef.Open(TableID);
    end;
}
