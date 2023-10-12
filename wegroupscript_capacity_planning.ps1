param(
    [string]$vCenterServer,
    [string]$OutputPath,
    [string]$Username,
    [string]$Password
)

# เชื่อมต่อกับ vCenter Server
Connect-VIServer -Server $vCenterServer -User $Username -Password $Password

# ดึงข้อมูลทุก Host
$allHosts = Get-VMHost

# ดึงข้อมูลทุก Datastore
$allDatastores = Get-Datastore

# สร้างออบเจ็กต์ CSV สำหรับแต่ละ Host และ Datastore
$csvData = @()
foreach ($VMhost in $allHosts) {
    foreach ($VMdatastore in $allDatastores) {
        $hostCapacity = $VMhost | Select-Object -Property Name, MemoryUsageGB, MemoryTotalGB, NumCpuCores, NumCpuThreads
        $datastoreCapacity = $VMdatastore | Select-Object -Property Name, CapacityGB, FreeSpaceGB

        # สร้างออบเจ็กต์ CSV พร้อมเวลา
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

        # บันทึกออบเจ็กต์ CSV เป็นไฟล์ CSV แยกตาม Host และ Datastore
        $outputFile = Join-Path -Path $OutputPath -ChildPath "$($VMhost.Name)_$($VMdatastore.Name)_capacity_report.csv"
        $csvObject | Export-Csv -Path $outputFile -NoTypeInformation

        $csvData += $csvObject
    }
}

# ยกเลิกการเชื่อมต่อกับ vCenter Server
Disconnect-VIServer -Server $vCenterServer -Confirm:$false

# รวมไฟล์ CSV ทั้งหมดเป็นไฟล์ CSV เดียว
$combinedCsvFile = Join-Path -Path $OutputPath -ChildPath "summary_capacity_report.csv"

# ถ้ามีไฟล์ combined_capacity_report.csv อยู่แล้ว ให้รวมข้อมูลในไฟล์เดิมกับข้อมูลใหม่
if (Test-Path $combinedCsvFile) {
    $existingCsvData = Import-Csv -Path $combinedCsvFile
    $combinedCsvData = $existingCsvData + $csvData
    $combinedCsvData | Export-Csv -Path $combinedCsvFile -NoTypeInformation
} else {
    $csvData | Export-Csv -Path $combinedCsvFile -NoTypeInformation
}

Write-Host "Combined CSV file saved to: $combinedCsvFile"