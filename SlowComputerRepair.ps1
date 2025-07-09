# =========================
# Step Control Variables
# =========================
$Run_TempCleanup       = "True"
$Run_RecycleBin        = "True"
$Run_DiskCleanup       = "True"
$Run_SFC               = "True"
$Run_DISM              = "True"
$Run_Defrag            = "True"
$Run_DNSFlush          = "True"
$Run_WUReset           = "True"
$Run_ComponentCleanup  = "True"

# =========================
# Logging Function
# =========================
function Write-Log {
    param (
        [string]$Message,
        [string]$Step
    )
    $logDir = "C:\Temp\Slow_Computer_Repair"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir | Out-Null
    }
    $logFile = Join-Path $logDir "$(Get-Date -Format 'yyyy-MM-dd')_${Step}.log"
    $timestamp = Get-Date -Format "HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

Write-Host "[INFO] Starting system cleanup and optimization..." -ForegroundColor Cyan
Write-Log "Starting cleanup and optimization process..." "Main"

# =========================
# Step 1: Clean Temp Files
# =========================
if ($Run_TempCleanup -eq "True") {
    Write-Host "[INFO] Running TempCleanup..." -ForegroundColor Cyan
    Write-Log "Starting temp cleanup..." "TempCleanup"
    
    $profiles = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false }
    foreach ($profile in $profiles) {
        $userTempFolder = Join-Path $profile.LocalPath 'AppData\Local\Temp'
        if (Test-Path $userTempFolder) {
            Write-Log "Clearing temp files for user: $($profile.LocalPath)" "TempCleanup"
            Remove-Item "$userTempFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Log "Temp folder not found for user: $($profile.LocalPath)" "TempCleanup"
        }
    }

    $systemTempFolder = Join-Path $env:SystemRoot 'Temp'
    if (Test-Path $systemTempFolder) {
        Write-Log "Clearing system temp folder: $systemTempFolder" "TempCleanup"
        Remove-Item "$systemTempFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Log "System temp folder not found." "TempCleanup"
    }
}

# =========================
# Step 2: Clean Recycle Bin
# =========================
if ($Run_RecycleBin -eq "True") {
    Write-Host "[INFO] Running RecycleBin Cleanup..." -ForegroundColor Cyan
    try {
        Get-PSDrive -PSProvider FileSystem | ForEach-Object {
            Clear-RecycleBin -DriveLetter $_.Name -Force -ErrorAction SilentlyContinue
        }
        Write-Log "Recycle Bin cleaned for all drives." "RecycleBin"
    } catch {
        Write-Log "Error cleaning Recycle Bin: $_" "RecycleBin"
    }
}

# =========================
# Step 3: Disk Cleanup
# =========================
if ($Run_DiskCleanup -eq "True") {
    Write-Host "[INFO] Running DiskCleanup..." -ForegroundColor Cyan
    $cleanMgrKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches'
    $categories = Get-ChildItem -Path $cleanMgrKey

    foreach ($category in $categories) {
        try {
            Set-ItemProperty -Path $category.PSPath -Name StateFlags0001 -Value 2 -Force
        } catch {
            Write-Log "Could not set cleanup flag for: $($category.PSChildName)" "DiskCleanup"
        }
    }

    try {
        Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait
        Write-Log "Disk Cleanup completed." "DiskCleanup"
    } catch {
        Write-Log "Disk Cleanup failed: $_" "DiskCleanup"
    }
}

# =========================
# Step 4: SFC Scan
# =========================
if ($Run_SFC -eq "True") {
    Write-Host "[INFO] Running SFC..." -ForegroundColor Cyan
    $sfcLog = "C:\Temp\Slow_Computer_Repairs\SFC_$(Get-Date -Format 'yyyy-MM-dd').txt"
    try {
        Write-Log "Running SFC scan..." "SFC"
        Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -RedirectStandardOutput $sfcLog -Wait -NoNewWindow
        Write-Log "SFC scan completed. Log saved: $sfcLog" "SFC"
    } catch {
        Write-Log "SFC scan failed: $_" "SFC"
    }
}

# =========================
# Step 5: DISM Repair
# =========================
if ($Run_DISM -eq "True") {
    Write-Host "[INFO] Running DISM..." -ForegroundColor Cyan
    $dismPath = "C:\Temp\Slow_Computer_Repairs"
    $today = Get-Date -Format 'yyyy-MM-dd'

    try {
        Write-Log "Running DISM /CheckHealth..." "DISM"
        Start-Process -FilePath "dism.exe" -ArgumentList '/Online', '/Cleanup-Image', '/CheckHealth' -RedirectStandardOutput "$dismPath\DISM_CheckHealth_$today.txt" -Wait -NoNewWindow

        Write-Log "Running DISM /ScanHealth..." "DISM"
        Start-Process -FilePath "dism.exe" -ArgumentList '/Online', '/Cleanup-Image', '/ScanHealth' -RedirectStandardOutput "$dismPath\DISM_ScanHealth_$today.txt" -Wait -NoNewWindow

        Write-Log "Running DISM /RestoreHealth..." "DISM"
        Start-Process -FilePath "dism.exe" -ArgumentList '/Online', '/Cleanup-Image', '/RestoreHealth' -RedirectStandardOutput "$dismPath\DISM_RestoreHealth_$today.txt" -Wait -NoNewWindow

        Write-Log "DISM completed. Logs saved." "DISM"
    } catch {
        Write-Log "DISM failed: $_" "DISM"
    }
}

# =========================
# Step 6: Optimize Drive
# =========================
if ($Run_Defrag -eq "True") {
    Write-Host "[INFO] Running Defrag..." -ForegroundColor Cyan
    try {
        Write-Log "Starting drive optimization..." "Defrag"
        Optimize-Volume -DriveLetter C -Defrag -Verbose
        Write-Log "Drive C optimized." "Defrag"
    } catch {
        Write-Log "Drive optimization failed: $_" "Defrag"
    }
}

# =========================
# Step 7: Flush DNS
# =========================
if ($Run_DNSFlush -eq "True") {
    Write-Host "[INFO] Running DNS Flush..." -ForegroundColor Cyan
    try {
        ipconfig /flushdns | Out-Null
        Write-Log "DNS cache flushed." "DNSFlush"
    } catch {
        Write-Log "Failed to flush DNS: $_" "DNSFlush"
    }
}

# =========================
# Step 8: Reset Windows Update
# =========================
if ($Run_WUReset -eq "True") {
    Write-Host "[INFO] Running Windows Update Reset..." -ForegroundColor Cyan
    try {
        Write-Log "Stopping Windows Update services..." "WUReset"
        net stop wuauserv | Out-Null
        net stop bits | Out-Null
        net stop cryptsvc | Out-Null

        Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:SystemRoot\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue

        Write-Log "Starting Windows Update services..." "WUReset"
        net start wuauserv | Out-Null
        net start bits | Out-Null
        net start cryptsvc | Out-Null

        Write-Log "Windows Update components reset." "WUReset"
    } catch {
        Write-Log "Failed to reset Windows Update components: $_" "WUReset"
    }
}

# =========================
# Step 9: Component Cleanup
# =========================
if ($Run_ComponentCleanup -eq "True") {
    Write-Host "[INFO] Running Component Cleanup..." -ForegroundColor Cyan
    try {
        Write-Log "Running DISM StartComponentCleanup..." "ComponentCleanup"
        Start-Process -FilePath "dism.exe" -ArgumentList "/Online", "/Cleanup-Image", "/StartComponentCleanup" -Wait -NoNewWindow
        Write-Log "StartComponentCleanup completed." "ComponentCleanup"
    } catch {
        Write-Log "Failed StartComponentCleanup: $_" "ComponentCleanup"
    }
}

# =========================
# Final Output
# =========================
Write-Host "[INFO] All cleanup steps completed!" -ForegroundColor Green
Write-Log "System cleanup and optimization completed!" "Main"
Write-Log "All tasks completed." "Main"
