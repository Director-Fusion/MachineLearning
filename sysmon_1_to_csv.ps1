# 1. Define the Sysmon Event ID 1 mapping for your system
$SysmonId1Map = @{
    0  = 'RuleName'
    1  = 'UtcTime'
    2  = 'ProcessGuid'
    3  = 'ProcessId'
    4  = 'Image'
    5  = 'FileVersion'
    6  = 'Description'
    7  = 'Product'
    8  = 'Company'
    9  = 'OriginalFilename'
    10 = 'CommandLine'
    11 = 'CurrentDirectory'
    12 = 'User'
    13 = 'LogonGuid'
    14 = 'LogonId'
    15 = 'TerminalSessionId'
    16 = 'IntegrityLevel'
    17 = 'Hashes'
    18 = 'ParentProcessGuid'
    19 = 'ParentProcessId'
    20 = 'ParentImage'
    21 = 'ParentCommandLine'
    22 = 'ParentUser'
}

Get-ChildItem -Path 'PATH TO LOGS TO PARSE' -Filter '*.evtx' |
ForEach-Object {
    $evtxFile = $_.FullName
    Write-Host "Processing: $evtxFile"

    # Read from each EVTX
    Get-WinEvent -Path $evtxFile |
    # Filter to Sysmon Event ID 1
    Where-Object { $_.Id -eq 1 } |
    ForEach-Object {
        # 1. Grab all top-level fields (TimeCreated, Message, etc.)
        $top = $_ | Select-Object -Property *

        # 2. Create an ordered hashtable for consistent column ordering
        $obj = [ordered]@{}

        # Record which file this event came from
        $obj['SourceFile'] = $evtxFile

        # 3. Copy each top-level property except 'Properties' itself
        $top.PSObject.Properties | ForEach-Object {
            if ($_.Name -ne 'Properties') {
                $obj[$_.Name] = $_.Value
            }
        }

        # 4. Expand the .Properties array into named columns via our mapping
        for ($i = 0; $i -lt $_.Properties.Count; $i++) {
            $fieldName = $SysmonId1Map[$i]
            if (-not $fieldName) {
                # Fallback name if there's no match in the map
                $fieldName = "Property_$i"
            }
            $obj[$fieldName] = $_.Properties[$i].Value
        }

        # Convert to PSCustomObject for CSV export
        [PSCustomObject]$obj
    }
} |
Export-Csv -Path 'PATH TO LOGS TO EXPORT' -NoTypeInformation
