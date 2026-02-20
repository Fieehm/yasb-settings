# Simple countdown timer display
# Reads timer state from a file and displays remaining time

$timerFile = "$env:TEMP\yasb_timer_state.txt"

if (Test-Path $timerFile) {
    $timerData = Get-Content $timerFile | ConvertFrom-Json
    
    if ($timerData.Running -eq $true) {
        $elapsed = (Get-Date) - [DateTime]$timerData.StartTime
        $remaining = $timerData.Duration - $elapsed.TotalSeconds
        
        if ($remaining -le 0) {
            # Timer finished - show notification and play sound
            $timerName = if ($timerData.Name) { $timerData.Name } else { "Timer" }
            
            # Check if we already notified for this timer
            if ($timerData.PSObject.Properties['Notified'] -and $timerData.Notified -eq $true) {
                # Timer already completed and notified, delete the file
                Remove-Item $timerFile -ErrorAction SilentlyContinue
                Write-Output "--:--"
                return
            }
            
            # Create new timer data with Notified flag
            $newTimerData = @{
                Running = $false
                StartTime = $timerData.StartTime
                Duration = $timerData.Duration
                Remaining = $timerData.Remaining
                Name = $timerName
                Notified = $true
            }
            $newTimerData | ConvertTo-Json | Set-Content $timerFile
            
            # Start notification script in a HIDDEN window
            Start-Process powershell -WindowStyle Hidden -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-File","$PSScriptRoot\timer-notify.ps1","-TimerName","$timerName"
            
            Write-Output "00:00"
        } else{
            $minutes = [int][Math]::Floor($remaining / 60)
            $seconds = [int][Math]::Floor($remaining % 60)
            Write-Output ("{0:D2}:{1:D2}" -f $minutes, $seconds)
        }
    } else {
        # Timer paused
        $remaining = $timerData.Remaining
        $minutes = [int][Math]::Floor($remaining / 60)
        $seconds = [int][Math]::Floor($remaining % 60)
        Write-Output ("{0:D2}:{1:D2}" -f $minutes, $seconds)
    }
} else {
    # No active timer
    Write-Output "--:--"
}
