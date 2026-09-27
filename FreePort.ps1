# Prompt the user to enter the port number
$Port = Read-Host "Enter the port number you want to free"

# Find the PID (process ID) listening on this port
$connection = netstat -ano | Select-String ":$Port\s+.*LISTENING\s+(\d+)" | ForEach-Object {
    ($_ -match "(\d+)$") | Out-Null
    $matches[1]
}

if ($connection) {
    foreach ($procId in $connection) {
        Write-Host "Port $Port is occupied by PID $procId. Attempting to free it..."
        try {
            Stop-Process -Id $procId -Force -ErrorAction Stop
            Write-Host "Process $procId successfully stopped."
        } catch {
            Write-Host "Error while stopping process ${procId}: $_"
        }
    }
} else {
    Write-Host "No process is occupying port $Port."
}
