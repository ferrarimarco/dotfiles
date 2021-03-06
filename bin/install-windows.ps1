#Requires -RunAsAdministrator

function Install-Chocolatey {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Justification = "Trusting Chocolatey installer")]
    param()

    Write-Output "Checking if Chocolatey is installed..."

    if (!$Env:ChocolateyInstall) {
        Write-Output "Installing Chocolatey..."
        Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

        # Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
        # variable and importing the Chocolatey profile module.
        $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
        Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

        # refreshenv is now an alias for Update-SessionEnvironment
        # (rather than invoking refreshenv.cmd, the *batch file* for use with cmd.exe)
    }
    else {
        Write-Output "Chocolatey is already installed. Upgrading..."
        choco upgrade -y chocolatey
    }
}

function Install-Packages {
    $Packages =
    'conemu',
    'docker-desktop',
    'keepass',
    'qbittorrent',
    'vagrant',
    'virtualbox --params "/NoDesktopShortcut /ExtensionPack"',
    'vlc',
    'vscode'

    ForEach ($Package in $Packages) {
        if (-not (& "choco" list $Package --local-only)) {
            Write-Output "Installing $Package chocolatey package..."
            choco install -y $Package
        }
        else {
            Write-Output "$Package chocolatey package is already installed"
        }
    }

    # Refresh the environment variables because we might have installed new
    # binaries with chocolatey.
    refreshenv
}

function Initialize-VSCode {
    Write-Output "Initializing Visual Studio Code"

    $VsCodeConfigSourcePath = "..\.config\Code\User\settings.json"
    $VsCodeConfigDestinationPath = "$Env:APPDATA\Code\User\settings.json"
    Write-Output "Creating a symbolic link to the VS Code configuration files. Source: $VsCodeConfigSourcePath, destination: $VsCodeConfigDestinationPath..."
    New-Item -Force -ItemType SymbolicLink -Path $VsCodeConfigDestinationPath -Value $VsCodeConfigSourcePath
}

function Install-VSCode-Extensions {
    Get-Content "..\.config\ferrarimarco-dotfiles\vs-code\extensions.txt" | ForEach-Object {
        & "code" --force --install-extension $_
    }
}

function Install-WSL {
    if ((Get-WindowsOptionalFeature -FeatureName Microsoft-Windows-Subsystem-Linux -Online).State -eq "Enabled") {
        Write-Output "The WSL feature is already enabled."
    }
    else {
        Write-Output "Enabling WSL..."
        Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName Microsoft-Windows-Subsystem-Linux
    }

    if ((Get-WindowsOptionalFeature -FeatureName VirtualMachinePlatform -Online).State -eq "Enabled") {
        Write-Output "The Virtual Machine Platform feature is already enabled."
    }
    else {
        Write-Output "Enabling the Virtual Machine Platform feature..."
        Enable-WindowsOptionalFeature -Online -NoRestart -FeatureName VirtualMachinePlatform
        Write-Output "A restart is required. Run this script again after restarting the system."
        exit
    }

    Write-Output "Setting WSL 2 as the default version..."
    wsl --set-default-version 2

    $WslPackage = Get-AppxPackage -AllUsers -Name CanonicalGroupLimited.Ubuntu20.04onWindows
    if (!$WslPackage) {
        Write-Output "Installing Ubuntu (WSL)"
        Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu.appx -UseBasicParsing
        Add-AppxPackage .\Ubuntu.appx
        Remove-Item .\Ubuntu.appx
    }
    else {
        Write-Output "WSL package is already installed"
    }
}

Install-Chocolatey
& "choco" upgrade -y all
Install-Packages
Initialize-VSCode
Install-VSCode-Extensions
Install-WSL
