#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction']='Stop'

function Confirm-Return-Code {
    $ReturnCode = $?
    if (-not $ReturnCode)
    {
        throw "Native Failure. Got return code: $ReturnCode"
    }
}

function Install-Chocolatey {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Justification = "Trusting Chocolatey installer")]
    param()

    Write-Output "Checking if Chocolatey is installed..."

    if (!$Env:ChocolateyInstall) {
        Write-Output "Installing Chocolatey..."
        Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    else {
        Write-Output "Chocolatey is already installed."
    }

    # Make `refreshenv` available right away, by defining the $env:ChocolateyInstall
    # variable and importing the Chocolatey profile module.
    $env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."
    Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

    # refreshenv is now an alias for Update-SessionEnvironment
    # (rather than invoking refreshenv.cmd, the *batch file* for use with cmd.exe)
    Write-Output "Refreshing the environment because we might have installed chocolatey..."
    refreshenv
}

function Install-Chocolatey-Package {
    Get-Process -Id (Get-NetTCPConnection -LocalPort YourPortNumberHere).OwningProcess

    Write-Output "Currently installed Chocolatey packages:"
    & "choco" list --local-only
    Confirm-Return-Code

    & "choco" upgrade chocolatey --yes --no-progress
    Confirm-Return-Code

    & "choco" upgrade all --yes --no-progress
    Confirm-Return-Code

    $Packages =
    'conemu',
    'keepass',
    'qbittorrent',
    'vlc',
    'vscode'

    ForEach ($Package in $Packages) {
        # choco upgrade installs the package if missing not installed.
        # See https://docs.chocolatey.org/en-us/choco/commands/upgrade
        & "choco" upgrade $Package --yes --no-progress
        Confirm-Return-Code
    }

    Write-Output "Refreshing the environment because we might have installed new packages..."
    refreshenv

    Write-Output "Current path: $env:PATH"

    Write-Output "Currently installed Chocolatey packages:"
    & "choco" list --local-only
    Confirm-Return-Code
}

function Initialize-VSCode {
    Write-Output "Initializing Visual Studio Code"

    $VsCodeConfigSourcePath = ".\.config\Code\User\settings.json"
    $VsCodeConfigDestinationPath = "$Env:APPDATA\Code\User\settings.json"
    Write-Output "Creating a symbolic link to the VS Code configuration files. Source: $VsCodeConfigSourcePath, destination: $VsCodeConfigDestinationPath..."
    New-Item -Force -ItemType SymbolicLink -Path $VsCodeConfigDestinationPath -Value $VsCodeConfigSourcePath
}

function Install-VSCode-Extension {
    Get-Content ".\.config\ferrarimarco-dotfiles\vs-code\extensions.txt" | ForEach-Object {
        & "code" --force --install-extension $_
        Confirm-Return-Code
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

    Write-Output "Setting WSL 2 as the default version (this may fail if WSL2 is not supported)..."
    # Skipping the return code check because this command may fail if WSL2 is not available.
    & "wsl" --set-default-version 2

    $WslPackage = Get-AppxPackage -AllUsers -Name CanonicalGroupLimited.Ubuntu20.04onWindows
    if (!$WslPackage) {
        Write-Output "Installing Ubuntu (WSL)..."
        Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu.appx -UseBasicParsing
        Add-AppxPackage .\Ubuntu.appx
        Remove-Item .\Ubuntu.appx
    }
    else {
        Write-Output "The WSL package is already installed."
    }

    Write-Output "Installed distributions:"
    & "wsl" --list --verbose
}

Install-Chocolatey
Install-Chocolatey-Package
Initialize-VSCode
Install-VSCode-Extension
Install-WSL
