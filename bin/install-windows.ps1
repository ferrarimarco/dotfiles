function Install-Chocolatey
{
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "", Justification="Trusting Chocolatey installer")]
  param()

  if (!$env:ChocolateyInstall) {
    Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  } else {
    Write-Output "Chocolatey is already installed. Upgrading..."
    choco upgrade -y chocolatey
  }
}

function Install-Packages
{
  $Packages =
    'conemu',
    'git',
    'keepass',
    'notepadplusplus',
    'vagrant',
    'virtualbox --params "/NoDesktopShortcut /ExtensionPack"',
    'vscode'

  ForEach ($Package in $Packages)
  {
    choco install -y $Package
  }
}

function Install-VSCode-Extensions
{
  Get-Content ..\.config\Code\extenstions.txt | ForEach-Object {
    code --install-extension $_
  }
}

Install-Chocolatey
choco upgrade -y all
Install-Packages
Install-VSCode-Extensions
