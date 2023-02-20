# Reference: 
# https://adoptium.net/installation/windows/
# https://api.adoptium.net/q/swagger-ui/#/Installer
# v2: Dynamically populate the feature_version parameter values with all available versions collected by API
# https://stackoverflow.com/questions/68824015/what-is-the-proper-way-to-define-a-dynamic-validateset-in-a-powershell-script


# Install latest Adoptium Java
# Default values: 64 bit architecture and jre image type
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
    [ValidateScript(
        {$_ -in $(Invoke-Webrequest -Uri "https://api.adoptium.net/v3/info/available_releases" -UseBasicParsing | ConvertFrom-Json).available_releases }
        #ErrorMessage = 'Invalid Java version number'
    )]
    [ArgumentCompleter(
    {
      param($cmd, $param, $wordToComplete)
      # This is the duplicated part of the code in the [ValidateScipt] attribute.
      [array] $validValues = $((Invoke-Webrequest -Uri "https://api.adoptium.net/v3/info/available_releases" -UseBasicParsing | ConvertFrom-Json).available_releases)
      $validValues -like "$wordToComplete*"
    }
  )]
  [String]$feature_version,
    #[Parameter(Mandatory=$false)] [ValidateSet('8','11','16','17','18','19')] [string]$feature_version = '8',
	[Parameter(Mandatory=$false)] [ValidateSet('x86','x64')] [string]$architecture = 'x64',
	[Parameter(Mandatory=$false)] [ValidateSet('jre','jdk')] [string]$image_type = 'jre'
)

$jvm_impl = "hotspot"
$os = "windows"
$vendor = "eclipse"

# Get the download link for the latest download
$Uri = "https://api.adoptium.net/v3/assets/latest/$feature_version/$($jvm_impl)?architecture=$($architecture)&image_type=$($image_type)&os=$($os)&vendor=$($vendor)"
Write-Host "The download link for the Adoptium Java $feature_version $image_type is: $Uri"
$HTML = Invoke-WebRequest -Uri $Uri -UseBasicParsing | ConvertFrom-Json
$downloadlink = $HTML.binary.installer.link

# Download the install msi file
$wc = New-Object System.Net.WebClient
$outputfile = "$env:TEMP\$($HTML.release_name).msi"
Write-Host $outputfile
$wc.DownloadFile($downloadlink, $outputfile)

# Install
Start-Process msiexec.exe -ArgumentList "/i $outputfile ADDLOCAL=FeatureMain,FeatureEnvironment,FeatureJarFileRunWith,FeatureJavaHome /quiet" -Wait -NoNewWindow
 
