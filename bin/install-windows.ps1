function Install-Chocolatey
{
  Set-ExecutionPolicy Bypass -Scope Process -Force
  iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

function Install-Package-Providers
{
  $PackageProviders =
    'chocolatey',
	'nuget'

  ForEach ($Provider in $PackageProviders)
  {
    if ((Get-PackageProvider -Name $Provider).Count -eq 0) {
      try {
        Write-Output "Installing $Provider provider"
        Install-PackageProvider -Force -Name $Provider -Scope CurrentUser
      }
      catch [Exception]{
          $_.message
          exit
      }
    } else {
      Write-Host "$Provider provider already installed"
    }
  }
}

function Install-Packages
{
  $Packages =
    'conemu',
    'git'

  ForEach ($Package in $Packages)
  {
    Write-Output "Installing $Package Package"
    Install-Package `
	  -Name $Package `
	  -ProviderName chocolatey `
  }
}


Install-Package-Providers
Install-Packages
