#Requires -RunAsAdministrator

function Install-Chocolatey {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Justification = "Trusting Chocolatey installer")]
    param()

    if (!$Env:ChocolateyInstall) {
        Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    else {
        Write-Output "Chocolatey is already installed. Upgrading..."
        choco upgrade -y chocolatey
    }
}

function Install-Packages {
    $Packages =
    'conemu',
    'git',
    'keepass',
    'ruby',
    'terraform',
    'vagrant',
    'virtualbox --params "/NoDesktopShortcut /ExtensionPack"',
    'vlc',
    'vscode'

    ForEach ($Package in $Packages) {
        choco install -y $Package
    }
}

function Initialize-VSCode {
    Write-Host "Initializing Visual Studio Code"

    $VsCodeConfigSourcePath = "$Env:HOMEDRIVE$Env:HOMEPATH\workspaces\dotfiles\.config\Code\User\settings.json"
    $VsCodeConfigDestinationPath = "$Env:APPDATA\Code\User\settings.json"
    Write-Host "Creating a symbolic link to the VS Code configuration files. Source: $VsCodeConfigSourcePath, destination: $VsCodeConfigDestinationPath..."
    New-Item -Force -ItemType SymbolicLink -Path $VsCodeConfigDestinationPath -Value $VsCodeConfigSourcePath
}

function Install-VSCode-Extensions {
    Get-Content "..\.config\Code\extensions.txt" | ForEach-Object {
        code --install-extension $_
    }
}

function Install-WSL {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

    $WslPackage = Get-AppxPackage -AllUsers -Name CanonicalGroupLimited.Ubuntu18.04onWindows

    if (!$WslPackage) {
        Write-Host "Installing Ubuntu (WSL)"
        Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile Ubuntu.appx -UseBasicParsing
        Add-AppxPackage .\Ubuntu.appx
        Remove-Item .\Ubuntu.appx
    }
    else {
        Write-Host "WSL package is already installed"
    }
}

Install-Chocolatey
choco upgrade -y all
Install-Packages
Initialize-VSCode
Install-VSCode-Extensions
Install-WSL
