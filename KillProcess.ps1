function Show-ProcessMenu {
    param (
        [string[]]$Suggestions
    )

    $Suggestions += "Go Back", "Cancel"  # Add special choices
    $currentIndex = 0
    $processCount = $Suggestions.Count

    while ($true) {
        Clear-Host
        Write-Host "Use UP and DOWN arrow keys to navigate. Press Enter to select."
        Write-Host "`nThe following processes are available:"

        for ($i = 0; $i -lt $processCount; $i++) {
            if ($i -eq $currentIndex) {
                Write-Host "=> $($Suggestions[$i])" -ForegroundColor Cyan
            } else {
                Write-Host "   $($Suggestions[$i])"
            }
        }

        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

        if ($key.VirtualKeyCode -eq 38) {  # Up
            if ($currentIndex -gt 0) { $currentIndex-- }
        } elseif ($key.VirtualKeyCode -eq 40) {  # Down
            if ($currentIndex -lt ($processCount - 1)) { $currentIndex++ }
        } elseif ($key.VirtualKeyCode -eq 13) {  # Enter
            return $Suggestions[$currentIndex]
        }
    }
}

# Main loop
while ($true) {
    do {
        $processName = Read-Host "Enter the name of the process to kill (without .exe)"
        $processName = $processName.Trim()
    } until ($processName)

    $matchingProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue

    if ($null -eq $matchingProcesses) {
        $allProcesses = Get-Process | Select-Object -ExpandProperty ProcessName -Unique
        $suggestions = $allProcesses | Where-Object { $_ -like "*$processName*" }

        if ($suggestions.Count -eq 0) {
            Write-Host "No process found with the name '$processName'" -ForegroundColor Red
            continue
        }

        $processName = Show-ProcessMenu -Suggestions $suggestions

        if ($processName -eq "Go Back") {
            continue
        } elseif ($processName -eq "Cancel") {
            Write-Host "Operation cancelled by user." -ForegroundColor Cyan
            exit
        }

        $matchingProcesses = Get-Process -Name $processName -ErrorAction SilentlyContinue
    }

    if ($null -eq $matchingProcesses) {
        Write-Host "No running process named '$processName' found." -ForegroundColor Red
        continue
    }

    Write-Host "`nThe following processes will be terminated:" -ForegroundColor Yellow
    $matchingProcesses | Format-Table Id, ProcessName, CPU, Path -AutoSize

    $confirm = Read-Host "Are you sure you want to kill these processes? (Y/N) NO is DEFAULT"
    if ($confirm -notin @('Y', 'y')) {
        Write-Host "Operation cancelled." -ForegroundColor Cyan
        exit
    }

    foreach ($proc in $matchingProcesses) {
        try {
            Stop-Process -Id $proc.Id -Force -ErrorAction Stop
            Write-Host "Process '$($proc.ProcessName)' (ID: $($proc.Id)) terminated successfully." -ForegroundColor Green
        } catch {
            Write-Host "Error: $($proc.ProcessName) requires administrator privileges to terminate." -ForegroundColor Red
        }
    }

    exit  # Exit after attempt
}
