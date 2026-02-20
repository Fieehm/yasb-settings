# Timer control script - Start/Stop/Reset
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "reset", "set", "resume")]
    [string]$Action,
    
    [int]$Minutes = 0,
    [int]$TotalSeconds = 0,  # Total duration in seconds (overrides Minutes if set)
    [string]$Name = "Timer"  # Timer session name
)

# Calculate total seconds - if TotalSeconds is provided, use it; otherwise convert minutes
if ($TotalSeconds -eq 0 -and $Minutes -gt 0) {
    $TotalSeconds = $Minutes * 60
} elseif ($TotalSeconds -eq 0 -and $Minutes -eq 0) {
    $TotalSeconds = 25 * 60  # Default to 25 minutes
}

$timerFile = "$env:TEMP\yasb_timer_state.txt"

switch ($Action) {
    "start" {
        # Always start a new timer with the specified duration
        $timerData = @{
            Running = $true
            StartTime = (Get-Date).ToString("o")
            Duration = $TotalSeconds
            Remaining = $TotalSeconds
            Name = $Name
        }
        $timerData | ConvertTo-Json | Set-Content $timerFile
    }
    
    "stop" {
        if (Test-Path $timerFile) {
            $timerData = Get-Content $timerFile | ConvertFrom-Json
            
            if ($timerData.Running -eq $true) {
                # Pause the timer
                $elapsed = (Get-Date) - [DateTime]$timerData.StartTime
                $timerData.Remaining = $timerData.Duration - $elapsed.TotalSeconds
                $timerData.Running = $false
                $timerData | ConvertTo-Json | Set-Content $timerFile
            }
        }
    }
    
    "reset" {
        Remove-Item $timerFile -ErrorAction SilentlyContinue
    }
    
    "set" {
        # Set new timer duration
        $timerData = @{
            Running = $false
            StartTime = (Get-Date).ToString("o")
            Duration = $TotalSeconds
            Remaining = $TotalSeconds
        }
        $timerData | ConvertTo-Json | Set-Content $timerFile
    }
    
    "resume" {
        # Resume a paused timer
        if (Test-Path $timerFile) {
            $timerData = Get-Content $timerFile | ConvertFrom-Json
            
            if ($timerData.Running -eq $false) {
                # Calculate new start time based on remaining time
                $timerData.Running = $true
                $timerData.StartTime = (Get-Date).ToString("o")
                $timerData.Duration = $timerData.Remaining
                $timerData | ConvertTo-Json | Set-Content $timerFile
            }
        }
    }
}
