param(
    [string]$AirSdk = $env:AIR_SDK_HOME,
    [int]$AndroidCompileSdk = 34,
    [switch]$SkipNative
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($AirSdk)) {
    throw "AIR SDK path is required. Use -AirSdk <path> or set AIR_SDK_HOME."
}
$AirSdk = (Resolve-Path -LiteralPath $AirSdk).Path
$compc = Join-Path $AirSdk "bin\compc.bat"
$adt = Join-Path $AirSdk "bin\adt.bat"
$freJar = Join-Path $AirSdk "lib\android\FlashRuntimeExtensions.jar"

foreach ($required in @($compc, $adt, $freJar)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Required AIR SDK file is missing: $required"
    }
}

$buildDir = Join-Path $projectRoot "build\ane"
$stageDir = Join-Path $buildDir "stage"
$distDir = Join-Path $projectRoot "dist"
New-Item -ItemType Directory -Force -Path $buildDir, $stageDir, $distDir | Out-Null

if (-not $SkipNative) {
    Push-Location $projectRoot
    try {
        & "$projectRoot\gradlew.bat" :native:clean :native:assembleRelease `
            "-PairSdkDir=$AirSdk" "-PandroidCompileSdk=$AndroidCompileSdk"
        if ($LASTEXITCODE -ne 0) { throw "Android native build failed." }
    } finally {
        Pop-Location
    }
}

$nativeJar = Join-Path $projectRoot "native\build\intermediates\aar_main_jar\release\syncReleaseLibJars\classes.jar"
if (-not (Test-Path -LiteralPath $nativeJar)) {
    $nativeJar = Get-ChildItem -Path (Join-Path $projectRoot "native\build") -Filter classes.jar -Recurse |
        Where-Object { $_.FullName -match "release" } |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $nativeJar -or -not (Test-Path -LiteralPath $nativeJar)) {
    throw "Native classes.jar was not found after the Gradle build."
}

$swc = Join-Path $buildDir "TapsellANE.swc"
& $compc `
    "-source-path=$projectRoot\actionscript\src" `
    "-include-classes=ir.tapsell.ane.TapsellANE,ir.tapsell.ane.TapsellEvent" `
    "-target-player=51.0" `
    "-output=$swc"
if ($LASTEXITCODE -ne 0) { throw "ActionScript SWC build failed." }

$swcExtract = Join-Path $buildDir "swc"
New-Item -ItemType Directory -Force -Path $swcExtract | Out-Null
Push-Location $swcExtract
try {
    & "$env:JAVA_HOME\bin\jar.exe" xf $swc library.swf
    if ($LASTEXITCODE -ne 0) { throw "Could not extract library.swf from SWC." }
} finally {
    Pop-Location
}
$librarySwf = Join-Path $swcExtract "library.swf"

$platforms = @("Android-ARM", "Android-ARM64", "Android-x86", "Android-x64")
foreach ($platform in $platforms) {
    $folder = Join-Path $stageDir $platform
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    Copy-Item -Force -LiteralPath $nativeJar -Destination (Join-Path $folder "classes.jar")
    Copy-Item -Force -LiteralPath $librarySwf -Destination (Join-Path $folder "library.swf")
}
$defaultFolder = Join-Path $stageDir "default"
New-Item -ItemType Directory -Force -Path $defaultFolder | Out-Null
Copy-Item -Force -LiteralPath $librarySwf -Destination (Join-Path $defaultFolder "library.swf")

$ane = Join-Path $distDir "TapsellANE.ane"
if (Test-Path -LiteralPath $ane) { Remove-Item -Force -LiteralPath $ane }

$adtArgs = @(
    "-package", "-target", "ane", $ane,
    (Join-Path $projectRoot "ane\extension.xml"),
    "-swc", $swc
)
foreach ($platform in $platforms) {
    $adtArgs += @(
        "-platform", $platform,
        "-platformoptions", (Join-Path $projectRoot "ane\platform.xml"),
        "-C", (Join-Path $stageDir $platform), "."
    )
}
$adtArgs += @("-platform", "default", "-C", $defaultFolder, ".")

& $adt @adtArgs
if ($LASTEXITCODE -ne 0) { throw "ANE packaging failed." }
if (-not (Test-Path -LiteralPath $ane)) { throw "ADT completed without creating the ANE." }

Write-Host "BUILD SUCCESSFUL"
Write-Host "ANE: $ane"
