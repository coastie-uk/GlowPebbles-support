[CmdletBinding()]
param(
    [string]$PrivateRepository = (Join-Path $PSScriptRoot '..\..\TinyTaps'),
    [string]$Version
)

$ErrorActionPreference = 'Stop'

$publicRepository = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$privateRepository = (Resolve-Path $PrivateRepository).Path

if (-not $Version) {
    $gradleFile = Join-Path $privateRepository 'app\build.gradle.kts'
    if (-not (Test-Path -LiteralPath $gradleFile -PathType Leaf)) {
        throw "Cannot find $gradleFile. Pass -PrivateRepository or -Version explicitly."
    }

    $match = [regex]::Match(
        [System.IO.File]::ReadAllText($gradleFile),
        'versionName\s*=\s*"([^"]+)"'
    )
    if (-not $match.Success) {
        throw "Could not read versionName from $gradleFile."
    }
    $Version = $match.Groups[1].Value
}

if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$') {
    throw "Version '$Version' is not a supported release directory name."
}

$releaseDirectory = Join-Path $privateRepository (Join-Path 'releases' $Version)
$sourceApk = Join-Path $releaseDirectory "GlowPebbles-$Version.apk"
$sourceChecksums = Join-Path $releaseDirectory 'SHA256SUMS.txt'

if (-not (Test-Path -LiteralPath $sourceApk -PathType Leaf)) {
    throw "Release APK not found: $sourceApk"
}
if (-not (Test-Path -LiteralPath $sourceChecksums -PathType Leaf)) {
    throw "Release checksum file not found: $sourceChecksums"
}

$hash = (Get-FileHash -LiteralPath $sourceApk -Algorithm SHA256).Hash.ToLowerInvariant()
$recordedChecksum = [System.IO.File]::ReadAllText($sourceChecksums)
if ($recordedChecksum -notmatch [regex]::Escape($hash)) {
    throw "The APK hash does not match the private release checksum."
}

$downloads = Join-Path $publicRepository 'downloads'
[System.IO.Directory]::CreateDirectory($downloads) | Out-Null
$versionedName = "GlowPebbles-$Version.apk"
$versionedApk = Join-Path $downloads $versionedName
$latestApk = Join-Path $downloads 'GlowPebbles-latest.apk'

Copy-Item -LiteralPath $sourceApk -Destination $versionedApk -Force
Copy-Item -LiteralPath $sourceApk -Destination $latestApk -Force

$checksumText = @(
    "$hash  $versionedName"
    "$hash  GlowPebbles-latest.apk"
) -join [Environment]::NewLine
[System.IO.File]::WriteAllText(
    (Join-Path $downloads 'SHA256SUMS.txt'),
    $checksumText + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

$metadata = [ordered]@{
    version = $Version
    file = $versionedName
    latest_alias = 'GlowPebbles-latest.apk'
    sha256 = $hash
    source = "releases/$Version/$versionedName"
}
[System.IO.File]::WriteAllText(
    (Join-Path $downloads 'latest.json'),
    ($metadata | ConvertTo-Json) + [Environment]::NewLine,
    [System.Text.UTF8Encoding]::new($false)
)

$indexPath = Join-Path $publicRepository 'index.html'
$index = [System.IO.File]::ReadAllText($indexPath)
$index = [regex]::Replace(
    $index,
    '<!-- release-version -->.*?<!-- /release-version -->',
    "<!-- release-version -->$Version<!-- /release-version -->"
)
$index = [regex]::Replace(
    $index,
    '<!-- release-sha256 -->.*?<!-- /release-sha256 -->',
    "<!-- release-sha256 -->$hash<!-- /release-sha256 -->"
)
[System.IO.File]::WriteAllText($indexPath, $index, [System.Text.UTF8Encoding]::new($false))

Write-Host "Synced GlowPebbles $Version to $downloads"
Write-Host "SHA-256: $hash"
Write-Host 'Review the website copy, then commit and push the public repository.'
