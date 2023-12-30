# Function to find all instances of the Lethal Company directory
function Find-LethalCompanyPaths {
    param (
        [string]$rootPath
    )
    Write-Host "Beginning search for any Lethal Company Steam directory on drive $rootPath..."
    # Function to check if the given path contains the Lethal Company directory
    function Test-LethalCompanyPath {
        param (
            [string]$path
        )

        $lethalCompanyPath = Join-Path $path 'steamapps\common\Lethal Company'
        return (Test-Path $lethalCompanyPath)
    }

    # Recursively search for all instances of the Lethal Company directory
    Get-ChildItem -Path $rootPath -Recurse -Directory -ErrorAction SilentlyContinue | Where-Object { Test-LethalCompanyPath $_.FullName } | ForEach-Object {
        $lethalCompanyPath = $_.FullName
        $lethalCompanyPath = Join-Path $lethalCompanyPath 'steamapps\common\Lethal Company'
        Write-Host "Found Lethal Company directory at: $lethalCompanyPath"
        return $lethalCompanyPath
    }
}

# Get all logical drives on the system
$drives = Get-WmiObject Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID

# Find all instances of the Lethal Company directory
$allLethalCompanyPaths = $drives | ForEach-Object { Find-LethalCompanyPaths -rootPath $_ }

# Display the results
if ($allLethalCompanyPaths.Count -eq 1) {
    Write-Host "Lethal Company directory found at: $($allLethalCompanyPaths[0])"
} elseif ($allLethalCompanyPaths.Count -gt 1) {
    Write-Host "More than one Lethal Company directory found on the system. Please clean up the duplicates."
    Exit 1
} else {
    Write-Host "Couldn't find any instances of the Lethal Company directory..."
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

Write-Host "Actual TEMP directory: $([System.IO.Path]::GetTempPath())"
Write-Host "TEMP Environment Variable: $env:TEMP"

# Ensure the temporary directory exists or create it
if (-not (Test-Path $tempDir -PathType Container)) {
    try {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        Write-Host "Temporary Directory Created: $tempDir"
    } catch {
        Write-Host "Failed to create the temporary directory: $_"
        # Pause for 10 seconds before closing the PowerShell console
        Start-Sleep -Seconds 10
        exit
    }
} else {
    Write-Host "Temporary Directory Already Exists: $tempDir"
}

$lethalCompanyDir = $allLethalCompanyPaths

if ($lethalCompanyDir -eq $null) {
    Write-Host "Lethal Company directory not found."
    # Pause for 10 seconds before closing the PowerShell console
    Start-Sleep -Seconds 10
    exit
} else {
    Write-Host "Lethal Company directory: $lethalCompanyDir"
}

# Define a variable to indicate whether to clean up BepInEx folder
$CleanupBepInEx = $true

# Check if the script was called with the -CleanupBepInEx switch
foreach ($arg in $args) {
    if ($arg -eq "-NoCleanupBepInEx") {
        $CleanupBepInEx = $false
    }
}

# GitHub repository information
$githubOwner = 'BepInEx'
$githubRepo = 'BepInEx'

# Get the latest version from the GitHub API
$latestVersion = Get-LatestVersionFromGitHub -owner $githubOwner -repo $githubRepo

if ($latestVersion) {
    # Append a custom version identifier
    $customVersion = "$latestVersion.0"

    # Construct the correct download URL
    $bepinexdownloadUrl = "https://github.com/$githubOwner/$githubRepo/releases/download/v$latestVersion/BepInEx_x64_$customVersion.zip"
    
    Write-Host "Latest version for BepInEx: $customVersion"
    Write-Host "Download URL: $bepinexdownloadUrl"
} else {
    Write-Host "Failed to retrieve the latest version for BepInEx."
}

$bepinexdownloadPath = [System.IO.Path]::Combine($tempDir, "BepInEx.zip")
$bepinexextractPath = [System.IO.Path]::Combine($tempDir, "BepInEx")

# Define a hashtable or an array of objects with user/mod information
$mods = @(
    @{ User = "bizzlemip"; Mod = "BiggerLobby" },
    @{ User = "2018"; Mod = "LC_API" },
    @{ User = "tinyhoot"; Mod = "ShipLobby" },
    @{ User = "SirTyler"; Mod = "BetterTeleporter" },
    @{ User = "Suskitech"; Mod = "AlwaysHearActiveWalkies" },
    @{ User = "Sligili"; Mod = "More_Emotes" },
    @{ User = "FlipMods"; Mod = "ReservedItemSlotCore" },
    @{ User = "FlipMods"; Mod = "ReservedFlashlightSlot" },
    @{ User = "FlipMods"; Mod = "ReservedWalkieSlot" },
    @{ User = "FlipMods"; Mod = "BetterStamina" },
    @{ User = "AlexCodesGames"; Mod = "AdditionalSuits" },
    @{ User = "RugbugRedfern"; Mod = "Skinwalkers" },
    @{ User = "TheBeeTeam"; Mod = "PersistentPurchases" }
)

# Get the latest version for each Thunderstore mod
$versions = @()
foreach ($mod in $mods) {
    $baseUrl = "https://thunderstore.io/c/lethal-company/p/$($mod['User'])/$($mod['Mod'])/"
    $latestVersion = Get-LatestVersionFromThunderstore -url $baseUrl
    if ($latestVersion) {
        Write-Host "Latest version for $($mod['User'])/$($mod['Mod']): $latestVersion"
        $mod['Version'] = $latestVersion
    } else {
        Write-Host "Failed to retrieve version for $($mod['User'])/$($mod['Mod'])"
        # Pause for 10 seconds before closing the PowerShell console
        Start-Sleep -Seconds 10
        Exit
    }
}

# Combine base URLs with the latest versions
$urls = @(
    $bepinexdownloadUrl
    )
$urls = foreach ($mod in $mods) {
    "https://thunderstore.io/package/download/$($mod['User'])/$($mod['Mod'])/$($mod['Version'])/"
}

Write-Host "urls: $urls"

# Set the destination paths for the downloaded files and extracted folders in the temp directory
$downloadPaths = foreach ($mod in $mods) {
    [System.IO.Path]::Combine($tempDir, "$($mod['Mod']).zip")
}

$extractPaths = foreach ($mod in $mods) {
    [System.IO.Path]::Combine($tempDir, $mod['Mod'])
}

# Download files to the temporary directory
try {
    Write-Host "Downloading BepInEx..."
    Invoke-WebRequest -Uri $bepinexdownloadUrl -OutFile $bepinexdownloadPath
} catch {
    Write-Host "Error downloading BepInEx: $_"
    # Pause for 10 seconds before closing the PowerShell console
    Start-Sleep -Seconds 10
    # Exit the script or handle the error as needed
    exit 1
}
for ($i = 0; $i -lt $urls.Count; $i++) {
    try {
        Write-Host "Downloading $($mods[$i]['Mod'])..."
        Invoke-WebRequest -Uri $urls[$i] -OutFile $downloadPaths[$i]
    } catch {
        Write-Host "Error downloading $($urls[$i]): $_"
        # Pause for 10 seconds before closing the PowerShell console
        Start-Sleep -Seconds 10
        # Exit the script or handle the error as needed
        exit 1
    }
}

# Extract files to the temporary directory
Write-Host "Extracting BepInEx..."
Expand-Archive -Path $bepinexdownloadPath -DestinationPath $bepinexextractPath -Force

for ($i = 0; $i -lt $downloadPaths.Count; $i++) {
    Write-Host "Extracting $($mods[$i]['Mod'])..."
    Expand-Archive -Path $downloadPaths[$i] -DestinationPath $extractPaths[$i] -Force
}

# Check if the directory is not null before proceeding
if ($lethalCompanyDir -ne $null) {
    # Set the destination path for BepInEx
    $destinationBepInEx = Join-Path $lethalCompanyDir 'BepInEx'

    # Set the destination path for BepInEx core
    $destinationBepInExCore = Join-Path $destinationBepInEx 'core'

    # Check if the destination directory exists; if not, create it
    if (-not (Test-Path $destinationBepInExCore -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationBepInExCore -Force | Out-Null
    }

    # Check if the destination directory exists; if not, create it
    if ($CleanupBepInEx -and (Test-Path $destinationBepInEx -PathType Container)) {
        Write-Host "Cleaning up BepInEx folder..."
        Remove-Item $destinationBepInEx -Recurse -Force
    }

    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $destinationBepInEx -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationBepInEx -Force | Out-Null
    }

    # Check if the destination directory exists; if not, create it
    if (-not (Test-Path $destinationBepInExCore -PathType Container)) {
        New-Item -ItemType Directory -Path $destinationBepInExCore -Force | Out-Null
    }

    # Copy BepInEx core files
    Write-Host "Installing BepInEx..."
    Copy-Item "$tempDir\BepInEx\BepInEx\core\*" $destinationBepInExCore -Recurse -Force

    # Install each mod
    for ($i = 0; $i -lt $mods.Count; $i++) {
        $mod = $mods[$i]
        Write-Host "Installing $($mod['Mod'])..."

        # Set the source and destination paths for the mod
        $modSourcePath = $extractPaths[$i]
        $modDestinationPath = Join-Path $destinationBepInEx 'plugins'

        # Check if BepInEx folder exists in the extracted directory
        $bepInExFolder = Join-Path $modSourcePath 'BepInEx'
        if ((Test-Path $bepInExFolder) -and ((Get-ChildItem $bepInExFolder -Recurse) | Measure-Object).Count -gt 0) {
            Write-Host "Copying BepInEx folder from $($mod['Mod'])..."
            Copy-Item "$bepInExFolder\*" $destinationBepInEx -Recurse -Force
        } else {
            # If no BepInEx folder, create a subdirectory with the name of the mod
            $modDestinationPath = Join-Path $modDestinationPath $mod['Mod']
            
            # Check if the destination directory already exists
            if (-not (Test-Path $modDestinationPath -PathType Container)) {
                New-Item -ItemType Directory -Path $modDestinationPath | Out-Null
            }

            # Check if the extracted folder has a subfolder with the name of the mod
            $modSourceSubfolder = Join-Path $modSourcePath $mod['Mod']
            $modSourcePluginsSubfolder = Join-Path $modSourcePath 'plugins'
            if ((Test-Path $modSourceSubfolder) -and ((Get-ChildItem $modSourceSubfolder -Recurse) | Measure-Object).Count -gt 0) {
                Write-Host "Copying contents from subfolder $($mod['Mod'])..."
                Copy-Item "$modSourceSubfolder\*" $modDestinationPath -Recurse -Force
            } elseif ((Test-Path $modSourcePluginsSubfolder) -and ((Get-ChildItem $modSourcePluginsSubfolder -Recurse) | Measure-Object).Count -gt 0) {
                Write-Host "Copying contents from subfolder 'plugins'..."
                Copy-Item "$modSourcePluginsSubfolder\*" $modDestinationPath -Recurse -Force
            } else {
                # Copy mod files directly
                Copy-Item "$modSourcePath\*" $modDestinationPath -Recurse -Force
            }
        }
    }
} else {
    Write-Host "Lethal Company directory is null. Cannot proceed with moving items."
    # Pause for 10 seconds before closing the PowerShell console
    Start-Sleep -Seconds 10
}

# Remove the temporary directory
Remove-Item $tempDir -Recurse -Force

Write-Host "Lethal Company Mods Script completed."
# Pause for 10 seconds before closing the PowerShell console
Start-Sleep -Seconds 10