# Function to install Wazuh Agent
function Install-WazuhAgent {
    Write-Host "Installing Wazuh Agent..." -ForegroundColor Green
    Invoke-WebRequest -Uri "https://packages.wazuh.com/4.x/windows/wazuh-agent-4.x.msi" -OutFile "$env:TEMP\wazuh-agent.msi"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $env:TEMP\wazuh-agent.msi /quiet" -Wait
    Start-Service wazuh-agent
    Set-Service wazuh-agent -StartupType Automatic
    Write-Host "Wazuh Agent installation completed." -ForegroundColor Green
}

# Function to install ClamAV
function Install-ClamAV {
    Write-Host "Installing ClamAV..." -ForegroundColor Green
    Invoke-WebRequest -Uri "https://www.clamav.net/downloads/production/clamav-win-x64.zip" -OutFile "$env:TEMP\clamav.zip"
    Expand-Archive -Path "$env:TEMP\clamav.zip" -DestinationPath "C:\ClamAV" -Force
    Set-Location -Path "C:\ClamAV"
    Start-Process -FilePath ".\freshclam.exe" -ArgumentList "--quiet" -Wait
    Write-Host "ClamAV installation completed." -ForegroundColor Green
}

# Function to install YARA
function Install-YARA {
    Write-Host "Installing YARA..." -ForegroundColor Green
    Invoke-WebRequest -Uri "https://github.com/VirusTotal/yara/releases/download/v4.2.3/yara-4.2.3-win64.zip" -OutFile "$env:TEMP\yara.zip"
    Expand-Archive -Path "$env:TEMP\yara.zip" -DestinationPath "C:\YARA" -Force
    Write-Host "YARA installation completed." -ForegroundColor Green
}

# Function to install Suricata
function Install-Suricata {
    Write-Host "Installing Suricata..." -ForegroundColor Green
    Invoke-WebRequest -Uri "https://www.openinfosecfoundation.org/download/suricata-6.0.0.zip" -OutFile "$env:TEMP\suricata.zip"
    Expand-Archive -Path "$env:TEMP\suricata.zip" -DestinationPath "C:\Suricata" -Force
    Write-Host "Suricata installation completed." -ForegroundColor Green
}

# Function to configure Suricata logs for Wazuh
function Configure-Suricata {
    Write-Host "Configuring Suricata for Wazuh integration..." -ForegroundColor Green
    $suricataConfig = "C:\Suricata\suricata.yaml"
    (Get-Content $suricataConfig) -replace "# output-json:", "output-json:" | Set-Content $suricataConfig
    Write-Host "Suricata configuration completed." -ForegroundColor Green
}

# Menu for user to choose installation options
function Show-Menu {
    Write-Host "Select an installation option:" -ForegroundColor Cyan
    Write-Host "1) Default Installation (Wazuh Agent, ClamAV, YARA, Suricata)" -ForegroundColor White
    Write-Host "2) Wazuh Agent with ClamAV" -ForegroundColor White
    Write-Host "3) Wazuh Agent with YARA" -ForegroundColor White
    Write-Host "4) Wazuh Agent with Suricata" -ForegroundColor White
    Write-Host "5) Exit" -ForegroundColor White
    $choice = Read-Host "Enter your choice [1-5]"

    switch ($choice) {
        1 {
            Install-WazuhAgent
            Install-ClamAV
            Install-YARA
            Install-Suricata
            Configure-Suricata
        }
        2 {
            Install-WazuhAgent
            Install-ClamAV
        }
        3 {
            Install-WazuhAgent
            Install-YARA
        }
        4 {
            Install-WazuhAgent
            Install-Suricata
            Configure-Suricata
        }
        5 {
            Write-Host "Exiting..." -ForegroundColor Yellow
            exit
        }
        default {
            Write-Host "Invalid choice. Please select a valid option." -ForegroundColor Red
        }
    }
}

# Main Loop
while ($true) {
    Show-Menu
}