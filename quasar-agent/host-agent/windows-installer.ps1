# Function to prompt for Wazuh Manager IP and Agent Name
function Prompt-WazuhDetails {
    $global:wazuhManagerIP = Read-Host "Enter Wazuh Manager IP"
    $global:wazuhAgentName = Read-Host "Enter Wazuh Agent Name"
}

# Function to install Wazuh Agent
function Install-WazuhAgent {
    Write-Host "Installing Wazuh Agent..."
    $tempPath = "$env:TEMP\wazuh-agent.msi"
    Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.8.0-1.msi" -OutFile $tempPath
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $tempPath /q WAZUH_MANAGER=$wazuhManagerIP WAZUH_AGENT_NAME=$wazuhAgentName" -Wait
    Write-Host "Starting Wazuh Agent service..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c NET START WazuhSvc" -Wait
    Write-Host "Wazuh Agent installation completed and service started."
}

# Function to uninstall Wazuh Agent
function Uninstall-WazuhAgent {
    Write-Host "Uninstalling Wazuh Agent..."
    Get-WmiObject Win32_Product | Where-Object { $_.Name -match "Wazuh Agent" } | ForEach-Object {
        $_.Uninstall()
    }
    Write-Host "Wazuh Agent uninstalled successfully."
}

# Function to display menu and handle user input
function Show-Menu {
    Write-Host "Choose an installation option:"
    Write-Host "1) Install Wazuh Agent only"
    Write-Host "2) Uninstall Wazuh Agent"
    Write-Host "3) Exit"
    $choice = Read-Host "Enter your choice [1-3]"

    switch ($choice) {
        1 {
            Prompt-WazuhDetails
            Install-WazuhAgent
        }
        2 {
            Uninstall-WazuhAgent
        }
        3 {
            Write-Host "Exiting..."
            exit
        }
        default {
            Write-Host "Invalid choice. Please select a valid option."
        }
    }
}

# Main loop
while ($true) {
    Show-Menu
}
