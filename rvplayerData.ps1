#
# Author: Nelson Vergel
#
#v3 adds handles count per process
#v4 adds thread count per process
#v5 adds "noData" if there are no pids available (easier to read output)
#v6 fixes silent failure on Windows 11:
#    - Guards against null paths when processes aren't running
#    - Replaces deprecated Get-WmiObject with Get-CimInstance
#    - Adds error output so failures are visible
#

#$Allservers = Get-Content "Allservers.txt"
$Allservers = Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty Name
$Output = @()
 
ForEach ($Server in $Allservers) 
{
    $Processor = $null
    $Memory = $null
    $RoundMemory = $null
    $Object = $null
    $Server = $Server.trim()
 
    Try {
        # Processor Check
        $Processor = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object Average).Average
		
        # Memory Check
        $TotMemory = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
	   
        $MemInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $Memory = ((($MemInfo.TotalVisibleMemorySize - $MemInfo.FreePhysicalMemory) * 100) / $MemInfo.TotalVisibleMemorySize)
        $RoundMemory = [math]::Round($Memory, 2)

        $Date = Get-Date

        # --- RP_PlayerSvc2 ---
        $RVPlayerProcs = Get-CimInstance Win32_Process -Filter "name = 'RP_PlayerSvc2.exe'" -ErrorAction SilentlyContinue
        $RVPpid = $null
        if ($RVPlayerProcs) {
            ForEach ($proc in $RVPlayerProcs) {
                $epid = $proc.ProcessId
                $pidHandles = $proc.HandleCount
                $pidThreads = $proc.ThreadCount
                if ($RVPpid) {
                    $RVPpid = -join($RVPpid, " | ", $epid, "(", $pidHandles, "/", $pidThreads, ")")
                } else {
                    $RVPpid = -join($epid, "(", $pidHandles, "/", $pidThreads, ")")
                }
            }
        } else {
            $RVPpid = "NoData"
        }

        # --- RP_ActiveChromium ---
        $RPActiveChromProcs = Get-CimInstance Win32_Process -Filter "name = 'RP_ActiveChromium.exe'" -ErrorAction SilentlyContinue
        $RPChrompid = $null
        if ($RPActiveChromProcs) {
            ForEach ($proc in $RPActiveChromProcs) {
                $epid = $proc.ProcessId
                $pidHandles = $proc.HandleCount
                $pidThreads = $proc.ThreadCount
                if ($RPChrompid) {
                    $RPChrompid = -join($RPChrompid, " | ", $epid, "(", $pidHandles, "/", $pidThreads, ")")
                } else {
                    $RPChrompid = -join($epid, "(", $pidHandles, "/", $pidThreads, ")")
                }
            }
        } else {
            $RPChrompid = "NoData"
        }

        # --- RP_Monitor ---
        $RPMonitorProcs = Get-CimInstance Win32_Process -Filter "name = 'RP_Monitor.exe'" -ErrorAction SilentlyContinue
        $RPMonpid = $null
        if ($RPMonitorProcs) {
            ForEach ($proc in $RPMonitorProcs) {
                $epid = $proc.ProcessId
                $pidHandles = $proc.HandleCount
                $pidThreads = $proc.ThreadCount
                if ($RPMonpid) {
                    $RPMonpid = -join($RPMonpid, " | ", $epid, "(", $pidHandles, "/", $pidThreads, ")")
                } else {
                    $RPMonpid = -join($epid, "(", $pidHandles, "/", $pidThreads, ")")
                }
            }
        } else {
            $RPMonpid = "NoData"
        }

        # --- RP_ExternalVideo ---
        $RPExtVideoProcs = Get-CimInstance Win32_Process -Filter "name = 'RP_ExternalVideo.exe'" -ErrorAction SilentlyContinue
        $RPExtVpid = $null
        if ($RPExtVideoProcs) {
            ForEach ($proc in $RPExtVideoProcs) {
                $epid = $proc.ProcessId
                $pidHandles = $proc.HandleCount
                $pidThreads = $proc.ThreadCount
                if ($RPExtVpid) {
                    $RPExtVpid = -join($RPExtVpid, " | ", $epid, "(", $pidHandles, "/", $pidThreads, ")")
                } else {
                    $RPExtVpid = -join($epid, "(", $pidHandles, "/", $pidThreads, ")")
                }
            }
        } else {
            $RPExtVpid = "NoData"
        }

        # --- ReflectEdge ---
        $RVEdgeProcs = Get-CimInstance Win32_Process -Filter "name = 'ReflectEdge.exe'" -ErrorAction SilentlyContinue
        $RVEpid = $null
        if ($RVEdgeProcs) {
            ForEach ($proc in $RVEdgeProcs) {
                $epid = $proc.ProcessId
                $pidHandles = $proc.HandleCount
                $pidThreads = $proc.ThreadCount
                if ($RVEpid) {
                    $RVEpid = -join($RVEpid, " | ", $epid, "(", $pidHandles, "/", $pidThreads, ")")
                } else {
                    $RVEpid = -join($epid, "(", $pidHandles, "/", $pidThreads, ")")
                }
            }
        } else {
            $RVEpid = "NoData"
        }

        # --- Disk usage and PlayLog (only if ReflectEdge is running) ---
        $diskUsage = "NoData"
        $tailPlayLog = "NoData"

        $RVEpathProc = Get-CimInstance Win32_Process -Filter "name = 'ReflectEdge.exe'" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($RVEpathProc -and $RVEpathProc.ExecutablePath) {
            $RVEpath = Split-Path -Parent $RVEpathProc.ExecutablePath

            # Disk usage for ReflectEdge install drive
            $driveLetter = $RVEpath.Substring(0, 2)
            $driveFilter = "DeviceId='$driveLetter'"
            $disk = Get-CimInstance Win32_LogicalDisk -Filter $driveFilter -ErrorAction SilentlyContinue
            if ($disk) {
                $diskFree = [int]($disk.FreeSpace / 1GB)
                $diskSize = [int]($disk.Size / 1GB)
                $diskUsage = "${diskFree}Gb/${diskSize}Gb"
            }

            # PlayLog - last line from most recent upload log
            $RVEuploadPath = Join-Path -Path $RVEpath -ChildPath "LogUpload"
            if (Test-Path $RVEuploadPath) {
                $playLogFile = Get-ChildItem $RVEuploadPath -File -ErrorAction SilentlyContinue | Sort-Object -Descending -Property LastWriteTime | Select-Object -First 1
                if ($playLogFile) {
                    $playLogFullPath = $playLogFile.FullName
                    $tailPlayLog = Get-Content -Tail 1 $playLogFullPath -ErrorAction SilentlyContinue
                    if (-not $tailPlayLog) { $tailPlayLog = "EmptyLog" }
                }
            }
        }

        # Build output object
        $Object = New-Object PSCustomObject
        $Object | Add-Member -MemberType NoteProperty -Name "Date" -Value $Date
        $Object | Add-Member -MemberType NoteProperty -Name "CPU Usage %" -Value $Processor
        $Object | Add-Member -MemberType NoteProperty -Name "Memory Usage %" -Value $RoundMemory
        $Object | Add-Member -MemberType NoteProperty -Name "Total Memory (GB)" -Value $TotMemory
        $Object | Add-Member -MemberType NoteProperty -Name "Server name" -Value $Server
        $Object | Add-Member -MemberType NoteProperty -Name "Cache Drive (free/size)" -Value $diskUsage
        $Object | Add-Member -MemberType NoteProperty -Name "Player PID (handles/threads)" -Value $RVPpid
        $Object | Add-Member -MemberType NoteProperty -Name "RVEdge PID (handles/threads)" -Value $RVEpid
        $Object | Add-Member -MemberType NoteProperty -Name "ActiveChromium PID (handles/threads)" -Value $RPChrompid
        $Object | Add-Member -MemberType NoteProperty -Name "Monitor PID (handles/threads)" -Value $RPMonpid
        $Object | Add-Member -MemberType NoteProperty -Name "External Video PID (handles/threads)" -Value $RPExtVpid
        $Object | Add-Member -MemberType NoteProperty -Name "PlayLog" -Value $tailPlayLog

        $Output += $Object
    }
    Catch {
        Write-Host "Error on ($Server): $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  At: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Yellow
        Continue
    }
}

# Export to CSV
If ($Output) { 
    $Output | Export-Csv -Path "rvplayerDataResults.csv" -NoTypeInformation -Force -Append
    Write-Host "CSV exported successfully with $($Output.Count) record(s)." -ForegroundColor Green
} else {
    Write-Host "No data collected. Check that the required processes are running or review errors above." -ForegroundColor Yellow
}
