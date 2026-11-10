# Stages the minimal OBS Studio SDK consumed by obs-noter: libobs and
# obs-frontend-api headers, generated config headers and Release import
# libraries. The layout mirrors the OBS source/build tree so consumers keep
# using OBS_STUDIO_DIR=<root> and OBS_BUILD_DIR=<root>\build.
param(
  [Parameter(Mandatory = $true)][string]$SourceDir,
  [Parameter(Mandatory = $true)][string]$BuildDir,
  [Parameter(Mandatory = $true)][string]$Destination
)

$ErrorActionPreference = 'Stop'

if (Test-Path -LiteralPath $Destination) {
  throw "Destination already exists: $Destination"
}
New-Item -ItemType Directory -Path $Destination | Out-Null

function Copy-Headers([string]$From, [string]$To) {
  $root = (Resolve-Path -LiteralPath $From).Path.TrimEnd('\', '/')
  Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.Extension -in '.h', '.hpp' } | ForEach-Object {
    $target = Join-Path $To $_.FullName.Substring($root.Length + 1)
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $target) | Out-Null
    Copy-Item -LiteralPath $_.FullName -Destination $target
  }
}

function Copy-File([string]$From, [string]$To) {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $To) | Out-Null
  Copy-Item -LiteralPath $From -Destination $To
}

Copy-Headers (Join-Path $SourceDir 'libobs') (Join-Path $Destination 'libobs')
Copy-Headers (Join-Path $SourceDir 'frontend\api') (Join-Path $Destination 'frontend\api')
Copy-Headers (Join-Path $BuildDir 'config') (Join-Path $Destination 'build\config')
Copy-File (Join-Path $BuildDir 'libobs\Release\obs.lib') (Join-Path $Destination 'build\libobs\Release\obs.lib')
Copy-File (Join-Path $BuildDir 'frontend\api\Release\obs-frontend-api.lib') (Join-Path $Destination 'build\frontend\api\Release\obs-frontend-api.lib')
Copy-File (Join-Path $SourceDir 'COPYING') (Join-Path $Destination 'COPYING')

$requiredFiles = @(
  'libobs\obs-module.h',
  'libobs\obs.h',
  'libobs\util\darray.h',
  'frontend\api\obs-frontend-api.h',
  'build\config\obsconfig.h',
  'build\libobs\Release\obs.lib',
  'build\frontend\api\Release\obs-frontend-api.lib'
)
foreach ($file in $requiredFiles) {
  if (-not (Test-Path -LiteralPath (Join-Path $Destination $file))) {
    throw "Missing required OBS SDK file: $file"
  }
}
