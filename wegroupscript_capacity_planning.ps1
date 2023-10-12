param(
    [string]$vCenterServer,
    [string]$OutputPath,
    [string]$Username,
    [string]$Password
)

Connect-VIServer -Server $vCenterServer -User $Username -Password $Password

$allHosts = Get-VMHost
$allDatastores = Get-Datastore

$csvData = @()
foreach ($VMhost in $allHosts) {
    foreach ($VMdatastore in $allDatastores) {
        $hostCapacity = $VMhost | Select-Object -Property Name, MemoryUsageGB, MemoryTotalGB, NumCpuCores, NumCpuThreads
        $datastoreCapacity = $VMdatastore | Select-Object -Property Name, CapacityGB, FreeSpaceGB

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $csvObject = New-Object PSObject -Property @{
            "Timestamp" = $timestamp
            "Host Name" = $hostCapacity.Name
            "Usage Memory (GB)" = $hostCapacity.MemoryUsageGB
            "Total Memory (GB)" = $hostCapacity.MemoryTotalGB
            "Number of CPU Cores" = $hostCapacity.NumCpuCores
            "Number of CPU Threads" = $hostCapacity.NumCpuThreads
            "Datastore Name" = $datastoreCapacity.Name
            "Total Capacity (GB)" = $datastoreCapacity.CapacityGB
            "Free Space (GB)" = $datastoreCapacity.FreeSpaceGB
        }

        $outputFile = Join-Path -Path $OutputPath -ChildPath "$($VMhost.Name)_$($VMdatastore.Name)_capacity_report.csv"
        $csvObject | Export-Csv -Path $outputFile -NoTypeInformation

        $csvData += $csvObject
    }
}

Disconnect-VIServer -Server $vCenterServer -Confirm:$false

$combinedCsvFile = Join-Path -Path $OutputPath -ChildPath "summary_capacity_report.csv"

if (Test-Path $combinedCsvFile) {
    $existingCsvData = Import-Csv -Path $combinedCsvFile
    $combinedCsvData = $existingCsvData + $csvData
    $combinedCsvData | Export-Csv -Path $combinedCsvFile -NoTypeInformation
} else {
    $csvData | Export-Csv -Path $combinedCsvFile -NoTypeInformation
}

Write-Host "Combined CSV file saved to: $combinedCsvFile"
