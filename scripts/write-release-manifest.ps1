# Writes <asset>.manifest.json next to a release asset: upstream origin,
# build parameters, tool versions, runner and SHA-256 of the asset.
param(
  [Parameter(Mandatory = $true)][string]$Asset,
  [Parameter(Mandatory = $true)][string]$Dependency,
  [Parameter(Mandatory = $true)][string]$Version,
  [Parameter(Mandatory = $true)][string]$Tag,
  [Parameter(Mandatory = $true)][string]$UpstreamUrl,
  [string]$UpstreamRef = '',
  [string]$UpstreamCommit = '',
  [string]$SourceArchive = '',
  [string[]]$Parameters = @()
)

$ErrorActionPreference = 'Stop'

function Get-ToolVersion([string]$Name, [string[]]$Arguments) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) { return $null }
  $output = & $Name @Arguments 2>&1 | ForEach-Object { "$_" } | Where-Object { $_.Trim() } | Select-Object -First 1
  # Version probes (e.g. cl without arguments) may exit non-zero; do not leak it to the step.
  $global:LASTEXITCODE = 0
  if ($output) { return $output.Trim() }
  return $null
}

function Get-Sha256([string]$Path) {
  (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

$tools = [ordered]@{}
foreach ($tool in @(
    @{ Name = 'cmake'; Args = @('--version') },
    @{ Name = 'ninja'; Args = @('--version') },
    @{ Name = 'cl'; Args = @() },
    @{ Name = 'gcc'; Args = @('--version') },
    @{ Name = 'git'; Args = @('--version') },
    @{ Name = '7z'; Args = @('i') }
  )) {
  $value = Get-ToolVersion $tool.Name $tool.Args
  if ($value) { $tools[$tool.Name] = $value }
}
$tools['pwsh'] = $PSVersionTable.PSVersion.ToString()

$assetItem = Get-Item -LiteralPath $Asset
$upstream = [ordered]@{ url = $UpstreamUrl; ref = $UpstreamRef; commit = $UpstreamCommit }
if ($SourceArchive) { $upstream['sourceArchiveSha256'] = Get-Sha256 $SourceArchive }

$manifest = [ordered]@{
  schema = 'obs-noter-toolchain.release-manifest/v1'
  dependency = $Dependency
  version = $Version
  tag = $Tag
  upstream = $upstream
  parameters = $Parameters
  tools = $tools
  build = [ordered]@{
    repository = $env:GITHUB_REPOSITORY
    commit = $env:GITHUB_SHA
    workflow = $env:GITHUB_WORKFLOW
    runId = $env:GITHUB_RUN_ID
    runNumber = $env:GITHUB_RUN_NUMBER
    runAttempt = $env:GITHUB_RUN_ATTEMPT
    runnerImage = "$env:ImageOS $env:ImageVersion".Trim()
    createdAt = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
  }
  asset = [ordered]@{
    name = $assetItem.Name
    size = $assetItem.Length
    sha256 = Get-Sha256 $assetItem.FullName
  }
}

$manifestPath = "$($assetItem.FullName).manifest.json"
$manifest | ConvertTo-Json -Depth 5 | Out-File -LiteralPath $manifestPath -Encoding utf8
Write-Host "Wrote $manifestPath"
