#Requires -RunAsAdministrator

function Install-Chocolatey {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Justification = "Trusting Chocolatey installer")]
    param()

    if (!$Env:ChocolateyInstall) {
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
        $Command = "code --install-extension $_"
        Invoke-Expression $Command
    }
}

function Install-WSL {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux

    $WslPackage = Get-AppxPackage -AllUsers -Name CanonicalGroupLimited.Ubuntu18.04onWindows

    if (!$WslPackage) {
        Write-Output "Installing Ubuntu (WSL)"
        Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile Ubuntu.appx -UseBasicParsing
        Add-AppxPackage .\Ubuntu.appx
        Remove-Item .\Ubuntu.appx
    }
    else {
        Write-Output "WSL package is already installed"
    }
}

Install-Chocolatey
choco upgrade -y all
Install-Packages
Initialize-VSCode
Install-VSCode-Extensions
Install-WSL
