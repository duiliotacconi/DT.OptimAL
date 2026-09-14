namespace DefaultNamespace;

controladdin "DTC SQL Viewer"
{
    // Renders a SQL statement with indentation and syntax-highlighting colors.
    RequestedHeight = 300;
    MinimumHeight = 80;
    RequestedWidth = 400;
    MinimumWidth = 200;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts =
        'src/ControlAddin/SQLViewer/sqlFormatter.js',
        'src/ControlAddin/SQLViewer/sqlViewer.js';
    StartupScript = 'src/ControlAddin/SQLViewer/startup.js';
    StyleSheets = 'src/ControlAddin/SQLViewer/sqlViewer.css';

    /// <summary>Sends a SQL statement to the control for prettifying and highlighting.</summary>
    procedure SetSQL(Sql: Text);

    /// <summary>Clears the control content.</summary>
    procedure ClearSQL();

    /// <summary>Raised once the control DOM is ready to receive SQL.</summary>
    event ControlReady();
}
