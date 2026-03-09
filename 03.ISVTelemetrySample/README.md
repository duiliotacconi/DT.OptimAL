# ISV Telemetry Sample

This Business Central AL extension demonstrates all major telemetry signals that can be emitted to Application Insights through extension telemetry.

## Setup

1. **Configure Application Insights Connection String**
   
   Edit the `app.json` file and replace `YOUR_APPLICATION_INSIGHTS_CONNECTION_STRING_HERE` with your actual Application Insights connection string.

2. **Download Symbols**
   
   Run the AL: Download Symbols command in VS Code to download the required symbols.

3. **Publish the Extension**
   
   Press F5 to publish and run the extension.

## Telemetry Signals Demonstrated

### Performance Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **RT0018** | Long Running AL Method | Click "Simulate Long Running AL" - runs a procedure for ~12 seconds |
| **RT0005** | Long Running SQL Query | Click "Simulate Long Running SQL" - creates 1000 records and performs queries |

### Error Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **RT0030** | Error Dialog Displayed | Click "Simulate Error Dialog" - displays an error using a Label constant |
| **RT0010** | Extension Update Failed | Uncomment the error in the Upgrade codeunit and upgrade the extension |

### Report Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **RT0006** | Successful/Failed Report Generation | Run "Telemetry Demo Report" (enable "Simulate Error" for failure) |
| **RT0007** | Report Cancelled | Run the report and cancel from the request page |
| **RT0011** | Report Cancelled with Commit | Run "Telemetry Demo Commit Report" and cancel after commit |

### Upgrade Tag Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **AL0000EJ9** | Upgrade Tag Searched | Click "Check Upgrade Tag" - calls HasUpgradeTag() |
| **AL0000EJA** | Upgrade Tag Set | Click "Set Upgrade Tag" - calls SetUpgradeTag() |

### Page View Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **CL0001** | Page Opened | Open any page in this extension (Demo Card, Demo List) |

### Web Service Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **RT0019** | Outgoing Web Service Call | Click "Outgoing Web Service Call" - calls https://httpbin.org/get |
| **RT0008** | Incoming Web Service Request | Call the API page endpoint from an external application |
| **RT0053** | Deprecated Endpoint Called | Call a deprecated SOAP endpoint |

### Report Layout Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **AL0000N0E** | Report Layout Added | Add a new layout via Report Layouts page |
| **AL0000N0F** | Report Layout Deleted | Delete a layout via Report Layouts page |
| **AL0000N0G** | Report Layout Replaced | Replace a layout via Report Layouts page |
| **AL0000N0H** | Report Layout Properties Changed | Edit layout properties via Report Layouts page |
| **AL0000N0I** | Report Layout Exported | Export a layout via Report Layouts page |

### Table Index Signals

| Event ID | Signal Name | How to Trigger |
|----------|-------------|----------------|
| **LC0025** | Table Index Disabled | Disable a table index through administrative actions |

## Objects in This Extension

### Tables
- **50100 Telemetry Demo** - Main table for storing demo data

### Pages
- **50100 Telemetry Demo** - Main card page with all demo actions
- **50101 Telemetry Demo List** - List page for demo records
- **50102 Telemetry Demo API** - API page for web service telemetry

### Reports
- **50100 Telemetry Demo Report** - Standard report for RT0006/RT0007 telemetry
- **50101 Telemetry Demo Commit Report** - Report for RT0011 telemetry

### Codeunits
- **50100 Telemetry Demo Mgt.** - Management functions for triggering telemetry
- **50101 Telemetry Demo Install** - Install codeunit
- **50102 Telemetry Demo Upgrade** - Upgrade codeunit with upgrade tag examples

### Enums
- **50100 Telemetry Demo Type** - Enum for categorizing demo types

## Viewing Telemetry

After triggering the signals, you can view them in Azure Application Insights:

1. Go to your Application Insights resource in Azure Portal
2. Navigate to **Logs** (Analytics)
3. Use KQL queries to analyze the telemetry data

### Sample KQL Queries

```kql
// View all extension telemetry events
traces
| where timestamp > ago(1h)
| where customDimensions.extensionName == "ISV Telemetry Sample"
| project timestamp, message, customDimensions.eventId, customDimensions
| order by timestamp desc

// View error dialogs (RT0030)
traces
| where customDimensions.eventId == "RT0030"
| project timestamp, message, customDimensions.alErrorMessage

// View long running AL methods (RT0018)
traces
| where customDimensions.eventId == "RT0018"
| project timestamp, message, customDimensions.executionTime

// View upgrade tag operations
traces
| where customDimensions.eventId in ("AL0000EJ9", "AL0000EJA")
| project timestamp, message, customDimensions.alUpgradeTag
```

## Notes

- Some telemetry signals require specific thresholds to be exceeded (e.g., RT0018 requires methods to run longer than the configured threshold)
- The Application Insights connection string in app.json is required for telemetry to be sent
- Telemetry data may take a few minutes to appear in Application Insights
- For Business Central online, some thresholds are managed by Microsoft and cannot be configured

## License

This sample is provided as-is for demonstration purposes.
