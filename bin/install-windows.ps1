function Install-Chocolatey
{
  if (!$env:ChocolateyInstall) {
    Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
  } else {
    Write-Output "Chocolatey is already installed"
  }
}

function Install-Packages
{
  $Packages =
    'chocolatey',
    'conemu',
    'git',
    'keepass',
    'notepadplusplus',
    'vscode'

  ForEach ($Package in $Packages)
  {
    choco install -y $Package
  }
}

function Install-VSCode-Extensions
{
  $Extensions =
    'ms-azuretools.vscode-docker',
    'ms-vscode.powershell'

  ForEach ($Extension in $Extensions)
  {
    code --install-extension $Extension
  }
}

Install-Chocolatey
choco upgrade -y all
Install-Packages
Install-VSCode-Extensions
