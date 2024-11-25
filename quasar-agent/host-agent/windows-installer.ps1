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
    Start-Service -Name "wazuh-agent"
    Set-Service -Name "wazuh-agent" -StartupType Automatic
    Write-Host "Wazuh Agent installation completed."
}

# Function to uninstall Wazuh Agent
function Uninstall-WazuhAgent {
    Write-Host "Uninstalling Wazuh Agent..."
    Get-WmiObject Win32_Product | Where-Object { $_.Name -match "Wazuh Agent" } | ForEach-Object {
        $_.Uninstall()
    }
    Write-Host "Wazuh Agent uninstalled successfully."
}

# Function to install Suricata
function Install-Suricata {
    Write-Host "Installing Suricata..."
    $tempPath = "$env:TEMP\suricata.msi"
    Invoke-WebRequest -Uri "https://www.openinfosecfoundation.org/download/suricata-6.0.8.msi" -OutFile $tempPath
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $tempPath /quiet" -Wait
    Write-Host "Suricata installation completed."
}

# Function to configure Suricata
function Configure-Suricata {
    Write-Host "Configuring Suricata..."
    $homeNetIP = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -ne "Loopback" }).IPAddress
    if (-not $homeNetIP) {
        Write-Error "Unable to determine HOME_NET IP. Exiting."
        return
    }

    $suricataYamlPath = "C:\Program Files\Suricata\etc\suricata.yaml"
    (Get-Content $suricataYamlPath) -replace "HOME_NET:.*", "HOME_NET: `"$homeNetIP`"" | Set-Content $suricataYamlPath
    (Get-Content $suricataYamlPath) -replace "- .*rules", "- `*.rules" | Set-Content $suricataYamlPath
    Write-Host "Suricata configuration updated."
}

# Function to download and setup Emerging Threats rules
function Setup-Rules {
    Write-Host "Downloading and extracting Emerging Threats Suricata ruleset..."
    $rulesPath = "C:\Program Files\Suricata\rules"
    Invoke-WebRequest -Uri "https://rules.emergingthreats.net/open/suricata-6.0.8/emerging.rules.tar.gz" -OutFile "$env:TEMP\emerging.rules.tar.gz"
    Expand-Archive -Path "$env:TEMP\emerging.rules.tar.gz" -DestinationPath $rulesPath
    Write-Host "Ruleset setup completed."
}

# Function to restart Suricata
function Restart-Suricata {
    Write-Host "Restarting Suricata service..."
    Restart-Service -Name "Suricata"
    Write-Host "Suricata service restarted."
}

# Function to configure Wazuh Agent for Suricata logs
function Configure-WazuhForSuricata {
    Write-Host "Configuring Wazuh Agent to monitor Suricata logs..."
    $ossecConfPath = "C:\Program Files (x86)\ossec-agent\ossec.conf"
    Add-Content -Path $ossecConfPath -Value @"
<localfile>
  <log_format>json</log_format>
  <location>C:\Program Files\Suricata\logs\eve.json</location>
</localfile>
"@
    Restart-Service -Name "wazuh-agent"
    Write-Host "Wazuh Agent configuration for Suricata completed."
}

# Function to install all add-ons
function Install-AddOns {
    Install-Suricata
    Configure-Suricata
    Setup-Rules
    Restart-Suricata
    Configure-WazuhForSuricata
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