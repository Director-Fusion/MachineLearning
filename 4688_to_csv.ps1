# 1. Define the property-index-to-field-name mapping for 4688
$Event4688Map = @{
    0  = 'SubjectUserSid'
    1  = 'SubjectUserName'
    2  = 'SubjectDomainName'
    3  = 'SubjectLogonId'
    4  = 'NewProcessId'
    5  = 'NewProcessName'
    6  = 'TokenElevationType'
    7  = 'ProcessId'
    8  = 'CommandLine'
    9  = 'TargetUserSid'
    10 = 'TargetUserName'
    11 = 'TargetDomainName'
    12 = 'TargetLogonId'
    13 = 'ParentProcessName'
    14 = 'MandatoryLabel'
}

Get-ChildItem -Path 'PATH TO LOGS TO PARSE' -Filter '*.evtx' |
ForEach-Object {
    $evtxFile = $_.FullName
    Write-Host "Processing: $evtxFile"

    # Read from each EVTX
    # Get-WinEvent -Path $evtxFile |
    Get-WinEvent -PAth $evtxFile | 
    Where-Object { $_.Id -eq 4688 } |
    ForEach-Object {
        # 1. Grab all top-level fields (TimeCreated, Message, etc.)
        $top = $_ | Select-Object -Property *

        # 2. Create an ordered hashtable for consistent column ordering
        $obj = [ordered]@{}

        # Record which file this event came from
        $obj['SourceFile'] = $evtxFile

        # 3. Copy each top-level property except 'Properties'
        $top.PSObject.Properties | ForEach-Object {
            if ($_.Name -ne 'Properties') {
                $obj[$_.Name] = $_.Value
            }
        }

        # 4. Expand the .Properties array using the $Event4688Map
        for ($i = 0; $i -lt $_.Properties.Count; $i++) {
            $fieldName = $Event4688Map[$i]
            if (-not $fieldName) {
                $fieldName = "Property_$i"
            }
            $obj[$fieldName] = $_.Properties[$i].Value
        }

        # Convert to PSCustomObject for CSV export
        [PSCustomObject]$obj
    }
} |
Export-Csv -Path 'PATH TO CSV' -NoTypeInformation