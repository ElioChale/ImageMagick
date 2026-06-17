param(
    [string]$BuildType = "dynamic"
)

if ($BuildType -ne "dynamic") {
    Write-Output "Static build - no DLL patching needed"
    exit 0
}

$issFile = "Configure\Installer\Inno\ImageMagick.iss"

if (-not (Test-Path $issFile)) {
    Write-Warning ".iss file not found at $issFile - skipping HEIF DLL patch"
    exit 0
}

$content = Get-Content $issFile -Raw

# Check if already patched (idempotent)
if ($content -match 'heif\.dll') {
    Write-Output "HEIF DLL entries already present in .iss"
    exit 0
}

# Find the last Source line referencing Artifacts\bin DLLs
$lines = [System.Collections.ArrayList]@(Get-Content $issFile)
$lastDllIdx = -1
for ($i = $lines.Count - 1; $i -ge 0; $i--) {
    if ($lines[$i] -match 'Source:\s*"[^"]*Artifacts\\bin\\[^"]*\.dll"') {
        $lastDllIdx = $i
        break
    }
}

if ($lastDllIdx -ge 0) {
    Write-Output "Inserting HEIF DLL entries after line $($lastDllIdx + 1)"
    $heifEntries = @(
        'Source: "..\..\Artifacts\bin\heif.dll"; DestDir: "{app}"; Flags: ignoreversion',
        'Source: "..\..\Artifacts\bin\libde265.dll"; DestDir: "{app}"; Flags: ignoreversion'
    )
    # Insert in reverse order so they appear in correct order after insertion
    for ($j = $heifEntries.Count - 1; $j -ge 0; $j--) {
        $lines.Insert($lastDllIdx + 1, $heifEntries[$j])
    }
    $lines | Set-Content $issFile -Encoding UTF8
    Write-Output "HEIF DLL entries added to installer script"
} else {
    Write-Warning "Could not find DLL entries in .iss - HEIF DLLs will NOT be in installer"
}
