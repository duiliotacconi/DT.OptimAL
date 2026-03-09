namespace DefaultNamespace;

enum 50920 "Isolation Level"
{
    Extensible = true;
    Caption = 'Isolation Level';

    value(0; Default)
    {
        Caption = 'Default';
    }
    value(1; ReadUncommitted)
    {
        Caption = 'Read Uncommitted';
    }
    value(2; ReadCommitted)
    {
        Caption = 'Read Committed';
    }
    value(3; RepeatableRead)
    {
        Caption = 'Repeatable Read';
    }
    value(4; UpdLock)
    {
        Caption = 'UpdLock';
    }
}
