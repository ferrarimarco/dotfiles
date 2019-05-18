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
    Write-Output "Installing $Provider provider"
    Install-PackageProvider -Force -Name $Provider -Scope CurrentUser
  }
}

function Install-Packages
{
  $Packages =
    'git'

  ForEach ($Provider in $PackageProviders)
  {
    Write-Output "Installing $Provider provider"
    Install-PackageProvider -Force -Name $Provider -Scope CurrentUser
  }
}


Install-Package-Providers