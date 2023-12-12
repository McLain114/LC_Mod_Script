# Function to find SteamLibrary directory across all drives
function Find-SteamLibrary {
    # Get all logical drives on the system
    $drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID

    foreach ($drive in $drives) {
        $steamLibraryPath = Join-Path $drive 'SteamLibrary\steamapps\common\Lethal Company'
        if (Test-Path $steamLibraryPath) {
            return $steamLibraryPath
        }
    }

    return $null
}

# Function to get the latest version from GitHub releases using the GitHub API
function Get-LatestVersionFromGitHub($owner, $repo) {
    try {
        # Construct the GitHub API URL
        $apiUrl = "https://api.github.com/repos/$owner/$repo/releases/latest"

        # Use Invoke-RestMethod to get release information
        $releaseInfo = Invoke-RestMethod -Uri $apiUrl

        # Extract the version from the release information
        $version = $releaseInfo.tag_name -replace 'v', ''

        return $version
    } catch {
        Write-Host "Failed to retrieve version from GitHub API: $_"
        return $null
    }
}

# Function to get the latest version from Thunderstore page
function Get-LatestVersionFromThunderstore {
    param (
        [string]$url
    )

    $pageContent = Invoke-WebRequest -Uri $url
    $versionRegex = '(?<=<td>\s*\d{4}-\d{2}-\d{2}\s*<\/td>\s*<td>\s*)([\d\.]+)(?=\s*<\/td>\s*<td>\s*\d+\s*<\/td>\s*<td>\s*<a href="[^"]+">Version [\d\.]+<\/a>\s*<\/td>)'
    $latestVersion = [regex]::Match($pageContent.Content, $versionRegex).Groups[1].Value

    if ($latestVersion -ne "") {
        return $latestVersion
    }

    return $null
}

# Set the temporary directory path
$tempDir = Join-Path $env:TEMP "LethalCompanyScriptTemp"
# $tempDir = "C:\Temp\LethalCompanyScriptTemp"


Write-Host "Actual TEMP directory: $([System.IO.Path]::GetTempPath())"
Write-Host "TEMP Environment Variable: $env:TEMP"

# Ensure the temporary directory exists or create it
if (-not (Test-Path $tempDir -PathType Container)) {
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        Write-Host "Temporary Directory Created: $tempDir"
    } catch {
        Write-Host "Failed to create the temporary directory: $_"
        exit
    }
} else {
    Write-Host "Temporary Directory Already Exists: $tempDir"
}

# Find Lethal Company directory
$lethalCompanyDir = Find-SteamLibrary

if ($lethalCompanyDir -eq $null) {
    Write-Host "Lethal Company directory not found."
    exit
} else {
    Write-Host "Lethal Company directory: $lethalCompanyDir"
}

# Pause for 10 seconds before closing the PowerShell console
Start-Sleep -Seconds 10

# GitHub repository information
$githubOwner = 'BepInEx'
$githubRepo = 'BepInEx'

# Get the latest version from the GitHub API
$latestVersion = Get-LatestVersionFromGitHub -owner $githubOwner -repo $githubRepo

if ($latestVersion) {
    # Append a custom version identifier
    $customVersion = "$latestVersion.0"

    # Construct the correct download URL
    $downloadUrl = "https://github.com/$githubOwner/$githubRepo/releases/download/v$latestVersion/BepInEx_x64_$customVersion.zip"
    
    Write-Host "Latest version for BepInEx: $customVersion"
    Write-Host "Download URL: $downloadUrl"
} else {
    Write-Host "Failed to retrieve the latest version for BepInEx."
}

$urls = @(
    "$downloadUrl"
)

# Example Thunderstore URLs without version information
$baseUrls = @(
    "https://thunderstore.io/c/lethal-company/p/bizzlemip/BiggerLobby/",
    "https://thunderstore.io/c/lethal-company/p/2018/LC_API/",
    "https://thunderstore.io/c/lethal-company/p/tinyhoot/ShipLobby/"
)
$dlbaseUrls = @(
    "https://thunderstore.io/package/download/bizzlemip/BiggerLobby/",
    "https://thunderstore.io/package/download/2018/LC_API/",
    "https://thunderstore.io/package/download/tinyhoot/ShipLobby/"
)

# Get the latest version for each Thunderstore mod
$versions = @()
foreach ($baseUrl in $baseUrls) {
    $latestVersion = Get-LatestVersionFromThunderstore -url $baseUrl
    if ($latestVersion) {
        Write-Host "Latest version for ${baseUrl}: $latestVersion"
        $versions += $latestVersion
    } else {
        Write-Host "Failed to retrieve version for $baseUrl"
        Exit
    }
}

# Combine base URLs with the latest versions
$urls += for ($i = 0; $i -lt $dlbaseUrls.Count; $i++) {
    $dlbaseUrls[$i] + $versions[$i] + '/'
}

Write-Host "urls: $urls"

# Set the destination paths for the downloaded files and extracted folders in the temp directory
$downloadPaths = @(
    [System.IO.Path]::Combine($tempDir, 'BepInEx_x64.zip'),
    [System.IO.Path]::Combine($tempDir, 'BiggerLobby.zip'),
    [System.IO.Path]::Combine($tempDir, 'LC_API.zip'),
    [System.IO.Path]::Combine($tempDir, 'ShipLobby.zip')
)

$extractPaths = @(
    [System.IO.Path]::Combine($tempDir, 'BepInEx'),
    [System.IO.Path]::Combine($tempDir, 'BiggerLobby'),
    [System.IO.Path]::Combine($tempDir, 'LC_API'),
    [System.IO.Path]::Combine($tempDir, 'ShipLobby')
)

# Download files to the temporary directory
for ($i=0; $i -lt $urls.Count; $i++) {
    try {
        Invoke-WebRequest -Uri $urls[$i] -OutFile $downloadPaths[$i]
    } catch {
        Write-Host "Error downloading $($urls[$i]): $_"
        # Exit the script or handle the error as needed
        exit 1
    }
}

# Extract files to the temporary directory
for ($i=0; $i -lt $downloadPaths.Count; $i++) {
    Expand-Archive -Path $downloadPaths[$i] -DestinationPath $extractPaths[$i] -Force
}

# Function to move files and folders with detailed error handling
function Move-WithErrorHandling {
    param(
        [string]$source,
        [string]$destination
    )

    # Ensure the source directory exists
    if (-not (Test-Path $source -PathType Container)) {
        Write-Host "Source directory $source does not exist."
        return
    }

    # Create the destination directory if it doesn't exist
    $destinationDir = Split-Path $destination
    if (-not (Test-Path $destinationDir -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    # Attempt to move the items
    try {
        Move-Item $source $destination -Force -ErrorAction Stop
        Write-Host "Moved items from $source to $destination"
    } catch {
        $errorMessage = $_.Exception.Message
        Write-Host "Failed to move items from $source to $destination. Error: $errorMessage"
    }
}

# Check if the directory is not null before proceeding
if ($lethalCompanyDir -ne $null) {
    # Set the destination paths for the downloaded files and extracted folders in the temp directory
    $destinationBepInEx = Join-Path $lethalCompanyDir 'BepInEx'
    $destinationBiggerLobby = Join-Path $lethalCompanyDir 'BepInEx'
    $destinationLC_API = Join-Path $lethalCompanyDir 'BepInEx\plugins'
    $destinationShipLobby = Join-Path $lethalCompanyDir 'BepInEx\plugins'

    # Copy specific files and folders from the temp directory to the desired location
    # Adjust the source and destination paths accordingly
    Copy-Item "$tempDir\BepInEx\BepInEx\core" $destinationBepInEx -Force
    Copy-Item "$tempDir\BepInEx\BepInEx\core\*" $destinationBepInEx\core -Force
    Copy-Item "$tempDir\BiggerLobby\BepInEx\*" $destinationBiggerLobby -Recurse -Force
    Copy-Item "$tempDir\LC_API\LC_API.dll" $destinationLC_API -Force
    Copy-Item "$tempDir\ShipLobby\plugins\ShipLobby\ShipLobby.dll" $destinationShipLobby -Force

} else {
    Write-Host "Lethal Company directory is null. Cannot proceed with moving items."
}

# Remove the temporary directory
Remove-Item $tempDir -Recurse -Force
