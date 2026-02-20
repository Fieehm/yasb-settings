# Timer input dialog with GUI
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Lock file to prevent multiple instances
$lockFile = "$env:TEMP\yasb_timer_ui_lock.txt"
$windowHandleFile = "$env:TEMP\yasb_timer_ui_hwnd.txt"

# Check if UI is already open
if (Test-Path $lockFile) {
    $lockTime = (Get-Item $lockFile).LastWriteTime
    $timeSinceLock = (Get-Date) - $lockTime
    
    # If lock is less than 0.5 seconds old, ignore this click
    if ($timeSinceLock.TotalSeconds -lt 0.5) {
        exit
    }
    
    # If lock exists and it's been more than 0.5 seconds, close the existing window
    if (Test-Path $windowHandleFile) {
        try {
            $hwnd = [int](Get-Content $windowHandleFile)
            Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
}
"@
            [Win32]::PostMessage([IntPtr]$hwnd, 0x0010, [IntPtr]::Zero, [IntPtr]::Zero) # WM_CLOSE
        } catch {}
    }
    Remove-Item $lockFile -ErrorAction SilentlyContinue
    Remove-Item $windowHandleFile -ErrorAction SilentlyContinue
    exit
}

# Create lock file
New-Item -Path $lockFile -ItemType File -Force | Out-Null

# Get cursor position to place window near the clicked widget
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class MousePos {
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    public struct POINT {
        public int X;
        public int Y;
    }
}
"@

$mousePos = New-Object MousePos+POINT
[MousePos]::GetCursorPos([ref]$mousePos) | Out-Null

# Create the form with dark theme
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Timer'
$form.Size = New-Object System.Drawing.Size(320,280)
$form.StartPosition = 'Manual'
$form.Location = New-Object System.Drawing.Point(($mousePos.X - 160), ($mousePos.Y + 10))
$form.FormBorderStyle = 'None'
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ShowInTaskbar = $false
$form.Opacity = 0  # Start invisible for fade-in effect

# Add rounded corners effect (Windows 11)
try {
    $DWM_WINDOW_CORNER_PREFERENCE = 2
    $DWMWA_WINDOW_CORNER_PREFERENCE = 33
    Add-Type @"
using System;
using System.Runtime.InteropServices;
public class DwmApi {
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);
}
"@
    $cornerPref = $DWM_WINDOW_CORNER_PREFERENCE
    [DwmApi]::DwmSetWindowAttribute($form.Handle, $DWMWA_WINDOW_CORNER_PREFERENCE, [ref]$cornerPref, 4)
} catch {}

# Title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(15,15)
$titleLabel.Size = New-Object System.Drawing.Size(290,25)
$titleLabel.Text = 'Set Timer'
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI",12,[System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($titleLabel)

# Separator line
$separator = New-Object System.Windows.Forms.Panel
$separator.Location = New-Object System.Drawing.Point(15,45)
$separator.Size = New-Object System.Drawing.Size(290,1)
$separator.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$form.Controls.Add($separator)

# Timer name label
$nameLabel = New-Object System.Windows.Forms.Label
$nameLabel.Location = New-Object System.Drawing.Point(15,55)
$nameLabel.Size = New-Object System.Drawing.Size(290,20)
$nameLabel.Text = 'Timer name (optional):'
$nameLabel.Font = New-Object System.Drawing.Font("Segoe UI",9)
$nameLabel.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$nameLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($nameLabel)

# Timer name textbox
$nameBox = New-Object System.Windows.Forms.TextBox
$nameBox.Location = New-Object System.Drawing.Point(15,80)
$nameBox.Size = New-Object System.Drawing.Size(290,25)
$nameBox.Text = 'Work Session'
$nameBox.Font = New-Object System.Drawing.Font("Segoe UI",10)
$nameBox.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$nameBox.ForeColor = [System.Drawing.Color]::White
$nameBox.BorderStyle = 'FixedSingle'
$form.Controls.Add($nameBox)

# Duration label
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(15,115)
$label.Size = New-Object System.Drawing.Size(290,20)
$label.Text = 'Duration:'
$label.Font = New-Object System.Drawing.Font("Segoe UI",9)
$label.ForeColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
$label.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($label)

# Minutes textbox
$minutesLabel = New-Object System.Windows.Forms.Label
$minutesLabel.Location = New-Object System.Drawing.Point(15,140)
$minutesLabel.Size = New-Object System.Drawing.Size(60,20)
$minutesLabel.Text = 'Minutes:'
$minutesLabel.Font = New-Object System.Drawing.Font("Segoe UI",8)
$minutesLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$minutesLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($minutesLabel)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(15,160)
$textBox.Size = New-Object System.Drawing.Size(135,25)
$textBox.Text = '0'
$textBox.Font = New-Object System.Drawing.Font("Segoe UI",10)
$textBox.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$textBox.ForeColor = [System.Drawing.Color]::White
$textBox.BorderStyle = 'FixedSingle'
$textBox.TextAlign = 'Center'
$form.Controls.Add($textBox)

# Seconds textbox
$secondsLabel = New-Object System.Windows.Forms.Label
$secondsLabel.Location = New-Object System.Drawing.Point(170,140)
$secondsLabel.Size = New-Object System.Drawing.Size(60,20)
$secondsLabel.Text = 'Seconds:'
$secondsLabel.Font = New-Object System.Drawing.Font("Segoe UI",8)
$secondsLabel.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 180)
$secondsLabel.BackColor = [System.Drawing.Color]::Transparent
$form.Controls.Add($secondsLabel)

$secondsBox = New-Object System.Windows.Forms.TextBox
$secondsBox.Location = New-Object System.Drawing.Point(170,160)
$secondsBox.Size = New-Object System.Drawing.Size(135,25)
$secondsBox.Text = '0'
$secondsBox.Font = New-Object System.Drawing.Font("Segoe UI",10)
$secondsBox.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$secondsBox.ForeColor = [System.Drawing.Color]::White
$secondsBox.BorderStyle = 'FixedSingle'
$secondsBox.TextAlign = 'Center'
$form.Controls.Add($secondsBox)

# Quick preset buttons with dark theme
$btnPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$btnPanel.Location = New-Object System.Drawing.Point(15,195)
$btnPanel.Size = New-Object System.Drawing.Size(290,30)
$btnPanel.FlowDirection = 'LeftToRight'
$btnPanel.BackColor = [System.Drawing.Color]::Transparent

$presets = @(5, 10, 15, 25, 30, 45, 60)
foreach ($preset in $presets) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Size = New-Object System.Drawing.Size(38,28)
    $btn.Text = $preset
    $btn.FlatStyle = 'Flat'
    $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $btn.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
    $btn.ForeColor = [System.Drawing.Color]::White
    $btn.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $btn.Cursor = 'Hand'
    $btn.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60) })
    $btn.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45) })
    $btn.Add_Click({
        $textBox.Text = $this.Text
        $secondsBox.Text = '0'
    })
    $btnPanel.Controls.Add($btn)
}
$form.Controls.Add($btnPanel)

# OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(15,235)
$okButton.Size = New-Object System.Drawing.Size(65,30)
$okButton.Text = 'Start'
$okButton.FlatStyle = 'Flat'
$okButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$okButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$okButton.ForeColor = [System.Drawing.Color]::White
$okButton.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$okButton.Cursor = 'Hand'
$okButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 100, 195) })
$okButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215) })
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

# Pause button
$pauseButton = New-Object System.Windows.Forms.Button
$pauseButton.Location = New-Object System.Drawing.Point(90,235)
$pauseButton.Size = New-Object System.Drawing.Size(65,30)
$pauseButton.Text = 'Pause'
$pauseButton.FlatStyle = 'Flat'
$pauseButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$pauseButton.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$pauseButton.ForeColor = [System.Drawing.Color]::White
$pauseButton.Font = New-Object System.Drawing.Font("Segoe UI",9)
$pauseButton.Cursor = 'Hand'
$pauseButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60) })
$pauseButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45) })
$pauseButton.Add_Click({
    & "$PSScriptRoot\timer-control.ps1" -Action stop
    $form.Close()
})
$form.Controls.Add($pauseButton)

# Reset button
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Location = New-Object System.Drawing.Point(165,235)
$resetButton.Size = New-Object System.Drawing.Size(65,30)
$resetButton.Text = 'Reset'
$resetButton.FlatStyle = 'Flat'
$resetButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$resetButton.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$resetButton.ForeColor = [System.Drawing.Color]::White
$resetButton.Font = New-Object System.Drawing.Font("Segoe UI",9)
$resetButton.Cursor = 'Hand'
$resetButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60) })
$resetButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45) })
$resetButton.Add_Click({
    & "$PSScriptRoot\timer-control.ps1" -Action reset
    $form.Close()
})
$form.Controls.Add($resetButton)

# Cancel button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(240,235)
$cancelButton.Size = New-Object System.Drawing.Size(65,30)
$cancelButton.Text = 'Close'
$cancelButton.FlatStyle = 'Flat'
$cancelButton.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$cancelButton.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$cancelButton.ForeColor = [System.Drawing.Color]::White
$cancelButton.Font = New-Object System.Drawing.Font("Segoe UI",9)
$cancelButton.Cursor = 'Hand'
$cancelButton.Add_MouseEnter({ $this.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60) })
$cancelButton.Add_MouseLeave({ $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45) })
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

# Store window handle for later closing
$form.Add_Shown({
    $windowHandleFile = "$env:TEMP\yasb_timer_ui_hwnd.txt"
    $this.Handle.ToInt32() | Out-File -FilePath $windowHandleFile -Force
    
    # Fade-in animation
    $fadeTimer = New-Object System.Windows.Forms.Timer
    $fadeTimer.Interval = 15
    $script:targetOpacity = 1.0
    $script:fadeStep = 0.1
    
    $fadeTimer.Add_Tick({
        if ($form.Opacity -lt $script:targetOpacity) {
            $form.Opacity = [Math]::Min($form.Opacity + $script:fadeStep, $script:targetOpacity)
        } else {
            $fadeTimer.Stop()
            $fadeTimer.Dispose()
        }
    })
    $fadeTimer.Start()
})

# Clean up lock file when form closes
$form.Add_FormClosed({
    $lockFile = "$env:TEMP\yasb_timer_ui_lock.txt"
    $windowHandleFile = "$env:TEMP\yasb_timer_ui_hwnd.txt"
    Remove-Item $lockFile -ErrorAction SilentlyContinue
    Remove-Item $windowHandleFile -ErrorAction SilentlyContinue
})

# Show the form
$form.Topmost = $true
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $minutes = [int]$textBox.Text
    $seconds = [int]$secondsBox.Text
    
    $totalSeconds = ($minutes * 60) + $seconds
    
    if ($totalSeconds -gt 0) {
        # Start the timer with the specified duration and name
        $timerName = $nameBox.Text
        if ([string]::IsNullOrWhiteSpace($timerName)) {
            $timerName = "Timer"
        }
        & "$PSScriptRoot\timer-control.ps1" -Action start -TotalSeconds $totalSeconds -Name $timerName
    }
}
