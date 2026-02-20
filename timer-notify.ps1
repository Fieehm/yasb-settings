param(
    [string]$TimerName = "Timer"
)

# Show balloon notification FIRST
Add-Type -AssemblyName System.Windows.Forms
$notification = New-Object System.Windows.Forms.NotifyIcon
$notification.Icon = [System.Drawing.SystemIcons]::Information
$notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
$notification.BalloonTipTitle = "$TimerName Complete!"
$notification.BalloonTipText = "Your timer has finished."
$notification.Visible = $true
$notification.ShowBalloonTip(10000)

# Play alarm sound in a loop for 10 seconds WHILE notification is visible
$alarmSound = "C:\Windows\Media\Alarm01.wav"
if (Test-Path $alarmSound) {
    $player = New-Object System.Media.SoundPlayer
    $player.SoundLocation = $alarmSound
    
    $endTime = (Get-Date).AddSeconds(10)
    
    # Loop alarm sound for 10 seconds
    while ((Get-Date) -lt $endTime) {
        $player.PlaySync()
    }
}

# Keep process alive briefly for cleanup
Start-Sleep -Seconds 1

# Cleanup
$notification.Dispose()
Remove-Item "$env:TEMP\yasb_timer_state.txt" -ErrorAction SilentlyContinue
