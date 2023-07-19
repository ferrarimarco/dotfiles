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
    Write-Output "Currently installed Chocolatey packages:"
    & "choco" list
    Confirm-Return-Code

    & "choco" upgrade chocolatey --yes --no-progress
    Confirm-Return-Code

    $Packages =
    '7zip',
    'conemu',
    'googlechrome',
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
    & "choco" list
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
    Write-Output "Installing WSL..."
    & "wsl" --install
    Confirm-Return-Code

    Write-Output "WSL distribution list:"
    & "wsl" --list --online
    Confirm-Return-Code

    $WslPackage = Get-AppxPackage -AllUsers -Name CanonicalGroupLimited.Ubuntu22.04onWindows
    if (!$WslPackage) {
        Write-Output "Installing Ubuntu (WSL)..."
        Invoke-WebRequest -Uri https://aka.ms/wslubuntu2204 -OutFile Ubuntu.appx -UseBasicParsing
        Add-AppxPackage .\Ubuntu.appx
        Remove-Item .\Ubuntu.appx
    }
    else {
        Write-Output "The WSL package is already installed."
    }

    Write-Output "Installed WSL distributions:"
    & "wsl" --list --verbose
    Confirm-Return-Code
}

if ($env:GITHUB_ACTIONS -ne "true")
{
    Write-Output "Not running in the CI environment, so we can install WSL2 that needs virtualization support."
    Install-WSL
}
else{
    Write-Output "Running in a CI environment, skipping WSL2 installation."
}

Install-Chocolatey
Install-Chocolatey-Package
Initialize-VSCode
Install-VSCode-Extension
