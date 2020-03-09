function Install-Chocolatey {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Justification = "Trusting Chocolatey installer")]
    param()

    if (!$env:ChocolateyInstall) {
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
    'potplayer',
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
    mklink "%APPDATA%\Code\User\settings.json" "%HOMEDRIVE%%HOMEPATH%\workspaces\dotfiles\.config\Code\User\settings.json"
}

function Install-VSCode-Extensions {
    Get-Content "..\.config\Code\extensions.txt" | ForEach-Object {
        code --install-extension $_
    }
}

function Install-WSL {
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile Ubuntu.appx -UseBasicParsing
    Add-AppxPackage .\Ubuntu.appx
}

Install-Chocolatey
choco upgrade -y all
Install-Packages
Initialize-VSCode
Install-VSCode-Extensions
Install-WSL
