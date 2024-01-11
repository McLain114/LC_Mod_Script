# Lethal Company Mods Installer

This PowerShell script automates the installation of mods for the game Lethal Company. It allows you to easily manage and update your mods, providing a seamless experience for enhancing your gameplay.

## Usage

### Parameters

- **modListFile:** Path to a file containing a list of mods to install. If not provided, the script will use a default list.

- **NoCleanupBepInEx:** A switch that, when present, prevents the script from cleaning up the BepInEx folder during execution.

### Example with mod list override file

```powershell
.\LethalCompanyBLMv2.ps1 -modListFile "myModList.txt"
```

### Example with defaulted mods

```powershell
.\LethalCompanyBLMv2.ps1
```

- Alternatively, you can just double-click the downloaded .ps1 file.

## Mod List

By default, the script installs a set of default mods. If you want to customize the list of mods, create a text file with one mod per line in the format `User/Mod`, and use the `-modListFile` parameter to specify the file.

```powershell
# Default mods
$defaultMods = @(
    "bizzlemip/BiggerLobby",
    "2018/LC_API",
    "tinyhoot/ShipLobby",
    "SirTyler/BetterTeleporter",
    "Suskitech/AlwaysHearActiveWalkies",
    "Sligili/More_Emotes",
    "FlipMods/BetterStamina",
    "AlexCodesGames/AdditionalSuits",
    "RugbugRedfern/Skinwalkers",
    "TheBeeTeam/PersistentPurchases"
)
```

**Note:**
- The script does not check for mod dependencies. Ensure that the required dependencies for each mod are provided either in the defaults or in your modListFile before running the script.

### Example modListFile Format:

Create a text file (e.g., `myModList.txt`) with the following format:

```plaintext
2018/LC_API
bizzlemip/BiggerLobby
tinyhoot/ShipLobby
Sligili/More_Emotes
FlipMods/BetterStamina
AlexCodesGames/AdditionalSuits
RugbugRedfern/Skinwalkers
```

## Mod Installation

1. **BepInEx Installation:**
   - The script automatically downloads the latest version of BepInEx from GitHub and installs it in the Lethal Company directory.
   - **Note:** BepInEx is required and included by default regardless of what is in the modListFile.

2. **LC_API Requirement:**
   - LC_API should be included in every modListFile as it is a required dependency for many mods. I may include it outside of the other mods similar to the BepInEx mod in the near future.

3. **Mod Installations:**
   - For each mod specified in the mod list, the script checks Thunderstore for the latest version and downloads it.
   - Mod files are then extracted and installed in the appropriate directories within the Lethal Company folder.

## Cleanup

- The script performs cleanup by removing temporary files and cleaning up the BepInEx folder, unless the `-NoCleanupBepInEx` switch is specified.

## Finding Lethal Company Directory

The script automatically searches for the Lethal Company directory on all logical drives to ensure the correct installation location.

## Note

- Make sure to run the script with appropriate permissions and execution policies enabled.
