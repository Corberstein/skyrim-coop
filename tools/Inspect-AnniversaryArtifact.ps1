# Inspects existing release archives. Never starts an executable from an archive.
# An on-demand scan does not reproduce or clear a behavior-based launch alert.
param(
    [Parameter(Mandatory)]
    [ValidateSet('baseline', 'candidate')]
    [string]$Variant
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repository = 'Corberstein/skyrim-coop'
$sourceRun = 37696430203L
$specifications = @{
    baseline = @{
        Source = '115b5019609b96eb9d63bbd03962043c30437dc8'
        PackageId = 11517175649L
        PackageHash = '7f773f40b461596ad4c8b5870e2e71fff093b9926fb6dd84521ead2c02d35d38'
        SymbolsId = 11517110759L
        SymbolsHash = 'cd7181b21ac5f024466fbf347b0888e378e84c19cbd8e19c9de2c8382a9d146f'
    }
    candidate = @{
        Source = 'aa61edfe2562ca00b94c51c9b84adc9f5aaf5c97'
        PackageId = 11515724459L
        PackageHash = '02eaca195c5edb67f829054db9ad885a01b537b629495b0416ba995118825979'
        SymbolsId = 11516591381L
        SymbolsHash = 'fd7402385311c74c419b1e0809972d7995659c1b4be881293bffa91b82d45c05'
    }
}
$specification = $specifications[$Variant]
$evidence = Join-Path $PWD 'audit-results'
$inspectionRoot = Join-Path $env:RUNNER_TEMP ('anniversary-inspection-' + $Variant)
New-Item -ItemType Directory -Force $evidence, $inspectionRoot | Out-Null
$result = [ordered]@{
    Variant = $Variant
    SourceRun = $sourceRun
    ExpectedSource = $specification.Source
    StartedAtUtc = [DateTime]::UtcNow.ToString('o')
    Archives = @()
    Binaries = @()
    IntegrityVerified = $false
    Scan = [ordered]@{ Status = 'not-run'; RuntimeReplayPerformed = $false }
    Limit = 'Static inspection and an on-demand scan do not verify Skyrim behavior or clear Behavior:Win32/DefenseEvasion.A!ml on the player PC.'
    Errors = @()
}

function Expand-CheckedZip([string]$Archive, [string]$Destination)
{
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try
    {
        $root = [IO.Path]::GetFullPath($Destination) + [IO.Path]::DirectorySeparatorChar
        [long]$total = 0
        $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($entry in $zip.Entries)
        {
            $relative = $entry.FullName.Replace('/', [IO.Path]::DirectorySeparatorChar)
            if ([IO.Path]::IsPathRooted($relative) -or $relative.Contains(':'))
            {
                throw "Invalid rooted or alternate-stream archive path: $relative"
            }
            $target = [IO.Path]::GetFullPath([IO.Path]::Combine($root, $relative))
            if (-not $target.StartsWith($root, [StringComparison]::OrdinalIgnoreCase))
            {
                throw "Archive path escapes inspection folder: $relative"
            }
            if (-not $seen.Add($target)) { throw "Duplicate archive path: $relative" }
            if ((($entry.ExternalAttributes -shr 16) -band 0xF000) -eq 0xA000)
            {
                throw "Archive contains a symbolic link: $relative"
            }
            $total += $entry.Length
            if ($total -gt 2GB) { throw 'Uncompressed archive exceeds the inspection limit.' }
        }
    }
    finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($Archive, $Destination)
}

try
{
    if ($env:GITHUB_REPOSITORY -ne $repository) { throw 'Unexpected repository context.' }
    if (-not $env:AUDIT_TOKEN) { throw 'Read-only Actions token is missing.' }
    $headers = @{
        Authorization = 'Bearer ' + $env:AUDIT_TOKEN
        Accept = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    $roots = @{}
    foreach ($kind in @('Package', 'Symbols'))
    {
        $id = $specification[$kind + 'Id']
        $expectedHash = $specification[$kind + 'Hash']
        $apiUrl = "https://api.github.com/repos/$repository/actions/artifacts/$id"
        $metadata = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 60
        if ($metadata.id -ne $id -or $metadata.workflow_run.id -ne $sourceRun)
        {
            throw "Unexpected $kind artifact identity."
        }
        if ($metadata.expired -or [DateTimeOffset]$metadata.expires_at -le [DateTimeOffset]::UtcNow)
        {
            throw "$kind artifact has expired."
        }
        if ($metadata.digest -ne ('sha256:' + $expectedHash))
        {
            throw "$kind metadata digest differs from the originally recorded digest."
        }
        $archive = Join-Path $inspectionRoot ($kind + '.zip')
        # PowerShell strips Authorization when following a redirect by default.
        # Do not enable PreserveAuthorizationOnRedirect for signed storage URLs.
        Invoke-WebRequest -Uri ($apiUrl + '/zip') -Headers $headers -OutFile $archive -TimeoutSec 180
        $actualHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) { throw "$kind archive SHA-256 mismatch." }
        $result.Archives += [ordered]@{
            Kind = $kind; ArtifactId = $id; Name = $metadata.name
            SHA256 = $actualHash; ExpiresAt = $metadata.expires_at
            DigestVerified = $true
        }
        $root = Join-Path $inspectionRoot $kind
        Expand-CheckedZip $archive $root
        # Support both a direct ZIP artifact and a ZIP wrapped by Actions.
        $files = @(Get-ChildItem -LiteralPath $root -Recurse -File)
        if ($files.Count -eq 1 -and $files[0].Extension -eq '.zip')
        {
            $innerRoot = Join-Path $inspectionRoot ($kind + '-inner')
            Expand-CheckedZip $files[0].FullName $innerRoot
            $root = $innerRoot
        }
        $roots[$kind] = $root
        Get-ChildItem -LiteralPath $root -Recurse -File | ForEach-Object {
            [pscustomobject]@{
                Path = [IO.Path]::GetRelativePath($root, $_.FullName)
                Bytes = $_.Length
                SHA256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
        } | Export-Csv -NoTypeInformation -Path (Join-Path $evidence ($kind + '-manifest.csv'))
    }

    $sourceFiles = @(Get-ChildItem -LiteralPath $roots.Package -Filter BUILD_SOURCE.txt -Recurse -File)
    if ($sourceFiles.Count -ne 1) { throw 'Expected exactly one BUILD_SOURCE.txt.' }
    $source = (Get-Content -LiteralPath $sourceFiles[0].FullName -Raw).Trim()
    $result['ObservedSource'] = $source
    if ($source -ne $specification.Source) { throw 'BUILD_SOURCE.txt revision mismatch.' }
    Copy-Item -LiteralPath $sourceFiles[0].FullName -Destination (Join-Path $evidence 'BUILD_SOURCE.txt')
    foreach ($name in @('SkyrimTogether.exe', 'SkyrimTogetherServer.exe', 'STServer.dll'))
    {
        $matches = @(Get-ChildItem -LiteralPath $roots.Package -Filter $name -Recurse -File)
        if ($matches.Count -ne 1 -or $matches[0].Length -eq 0) { throw "Missing or ambiguous binary: $name" }
        $binary = $matches[0]
        $signature = Get-AuthenticodeSignature -LiteralPath $binary.FullName
        $result.Binaries += [ordered]@{
            Name = $name; Bytes = $binary.Length
            SHA256 = (Get-FileHash -LiteralPath $binary.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            AuthenticodeStatus = $signature.Status.ToString()
        }
    }
    foreach ($name in @('SkyrimTogether.pdb', 'SkyrimTogetherServer.pdb'))
    {
        $matches = @(Get-ChildItem -LiteralPath $roots.Symbols -Filter $name -Recurse -File)
        if ($matches.Count -ne 1 -or $matches[0].Length -eq 0) { throw "Missing or ambiguous symbol file: $name" }
    }
    $result.IntegrityVerified = $true

    $status = Get-MpComputerStatus -ErrorAction Stop
    $result.Scan['InitialStatus'] = $status | Select-Object AMServiceEnabled, AntivirusEnabled, AMRunningMode,
        BehaviorMonitorEnabled, RealTimeProtectionEnabled, AntivirusSignatureVersion, AntivirusSignatureLastUpdated
    if (-not $status.AMServiceEnabled -or -not $status.AntivirusEnabled)
    {
        throw 'Microsoft Defender is not active on this runner; no scan result can be claimed.'
    }
    Update-MpSignature -ErrorAction Stop
    $platformRoot = Join-Path $env:ProgramData 'Microsoft/Windows Defender/Platform'
    $commands = @(Get-ChildItem -LiteralPath $platformRoot -Filter MpCmdRun.exe -Recurse -File |
        Sort-Object FullName -Descending)
    $scanner = if ($commands.Count) { $commands[0].FullName } else {
        Join-Path $env:ProgramFiles 'Windows Defender/MpCmdRun.exe'
    }
    if (-not (Test-Path -LiteralPath $scanner)) { throw 'Defender scanner executable is unavailable.' }
    $result.Scan['SignatureVersion'] = (Get-MpComputerStatus).AntivirusSignatureVersion
    $result.Scan['StartedAtUtc'] = [DateTime]::UtcNow.ToString('o')
    # DisableRemediation is a documented scan-only option: it does not disable
    # antivirus protection or add exclusions. Detections remain in command output.
    $scanOutput = & $scanner -Scan -ScanType 3 -File $roots.Package -DisableRemediation 2>&1
    $scanCode = $LASTEXITCODE
    $scanOutput | Out-File -FilePath (Join-Path $evidence 'Defender-scan.txt') -Encoding utf8
    $result.Scan['ExitCode'] = $scanCode
    $result.Scan.Status = if ($scanCode -eq 0) { 'no-threats-reported-by-on-demand-scan' } else { 'detection-or-scan-error' }
    if ($scanCode -ne 0) { throw "Defender returned $scanCode; see Defender-scan.txt. This is not a clean scan." }
    # Detect removal or modification by concurrent real-time protection.
    foreach ($binary in $result.Binaries)
    {
        $matches = @(Get-ChildItem -LiteralPath $roots.Package -Filter $binary.Name -Recurse -File)
        if ($matches.Count -ne 1) { throw "Binary disappeared during scan: $($binary.Name)" }
        $hashAfter = (Get-FileHash -LiteralPath $matches[0].FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hashAfter -ne $binary.SHA256) { throw "Binary changed during scan: $($binary.Name)" }
    }
}
catch
{
    $result.Errors += $_.Exception.Message
    if ($result.Scan.Status -eq 'not-run') { $result.Scan.Status = 'blocked' }
}
finally
{
    $result['FinishedAtUtc'] = [DateTime]::UtcNow.ToString('o')
    $json = $result | ConvertTo-Json -Depth 8
    $json | Set-Content -LiteralPath (Join-Path $evidence 'inspection.json') -Encoding utf8
    Write-Output $json
    if ($env:GITHUB_STEP_SUMMARY)
    {
        @(
            "## $Variant artifact inspection"
            "Source run: $sourceRun"
            "Expected revision: $($specification.Source)"
            "Archive and source checks complete: $($result.IntegrityVerified)"
            "On-demand Defender scan: $($result.Scan.Status)"
            $result.Limit
            ($result.Errors -join "`n")
        ) | Add-Content -LiteralPath $env:GITHUB_STEP_SUMMARY
    }
}
if ($result.Errors.Count -gt 0) { exit 1 }
