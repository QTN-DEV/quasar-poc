# Clear the console for a clean start
Clear-Host

# Define the Wazuh MSI URL
$WazuhMsiUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.8.0-1.msi"

# Prompt for Wazuh Manager IP
$WazuhManager = Read-Host "Enter the Wazuh Manager IP"
if ([string]::IsNullOrEmpty($WazuhManager)) {
    Write-Host "Error: Wazuh Manager IP is required." -ForegroundColor Red
    exit 1
}

# Prompt for Wazuh Agent Name
$WazuhAgentName = Read-Host "Enter the Wazuh Agent Name"
if ([string]::IsNullOrEmpty($WazuhAgentName)) {
    Write-Host "Error: Wazuh Agent Name is required." -ForegroundColor Red
    exit 1
}

# Define the path to save the MSI installer
$MsiPath = Join-Path -Path $env:TEMP -ChildPath "wazuh-agent.msi"

try {
    # Download the Wazuh Agent MSI
    Write-Host "Downloading Wazuh Agent MSI from $WazuhMsiUrl..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $WazuhMsiUrl -OutFile $MsiPath -UseBasicParsing
    Write-Host "Download completed. MSI saved to $MsiPath" -ForegroundColor Green

    # Install the Wazuh Agent
    Write-Host "Installing Wazuh Agent..." -ForegroundColor Yellow
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$MsiPath`"", "/quiet", "WAZUH_MANAGER=$WazuhManager", "WAZUH_AGENT_NAME=$WazuhAgentName" -NoNewWindow -Wait
    Write-Host "Wazuh Agent installed successfully!" -ForegroundColor Green

    # Start the Wazuh Agent service
    Write-Host "Starting Wazuh Agent service..." -ForegroundColor Yellow
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c NET START WazuhSvc" -NoNewWindow -Wait

    # Confirm service started
    Write-Host "Wazuh Agent service started successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error during installation or service start: $_" -ForegroundColor Red
    exit 1
}

# Confirm successful installation
Write-Host "Installation complete. You can now verify the Wazuh Agent configuration." -ForegroundColor Green