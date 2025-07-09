# 🧹 Slow Computer Cleanup & Optimization Script

This PowerShell script performs a full system cleanup and optimization routine for Windows PCs. It runs several maintenance tasks like clearing temp files, cleaning up the disk, scanning system files, repairing Windows updates, and more. It’s especially useful for IT support and system administrators looking to automate routine PC health checks.

---

## 🚀 Features

The script includes the following steps, each of which can be enabled or disabled at the top of the script using variables:

| Step                         | Description                                         |
|-----------------------------|-----------------------------------------------------|
| Temp Cleanup                | Deletes temp files in user and system folders       |
| Recycle Bin Cleanup         | Empties recycle bin for all drives                  |
| Disk Cleanup                | Runs Windows Disk Cleanup tool silently             |
| SFC                         | Runs `sfc /scannow` for system file repair          |
| DISM                        | Performs health scan and repair with DISM           |
| Defrag                      | Defragments the C: drive (SSD-safe: uses defrag API)|
| DNS Flush                   | Clears the DNS resolver cache                       |
| Windows Update Reset        | Resets update services and cache folders            |
| Component Cleanup           | Cleans up old Windows Update components             |

---

## 🛠️ Configuration

You can enable or disable each task by modifying the following variables at the top of the script:

```powershell
$Run_TempCleanup       = "True"
$Run_RecycleBin        = "True"
$Run_DiskCleanup       = "True"
$Run_SFC               = "True"
$Run_DISM              = "True"
$Run_Defrag            = "True"
$Run_DNSFlush          = "True"
$Run_WUReset           = "True"
$Run_ComponentCleanup  = "True"
