& "$PSScriptRoot\timer-control.ps1" -Action start -TotalSeconds 5 -Name "LiveTest"

for ($i=0; $i -lt 7; $i++) {
    Start-Sleep -Seconds 1
    Write-Host "Second $i" -NoNewline
    Write-Host " - Output: " -NoNewline
    & "$PSScriptRoot\timer.ps1"
}
