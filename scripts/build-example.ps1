param(
    [string]$AirSdk = $env:AIR_SDK_HOME,
    [string]$AndroidSdk = $env:ANDROID_HOME,
    [string]$AppKey = $env:TAPSELL_APP_KEY,
    [string]$ZoneId = $env:TAPSELL_REWARDED_ZONE_ID,
    [int]$AndroidCompileSdk = 34,
    [string]$Certificate,
    [string]$StorePassword
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$exampleDir = Join-Path $projectRoot "example"
$ane = Join-Path $projectRoot "dist\TapsellANE.ane"

if (-not (Test-Path -LiteralPath $ane)) { throw "Build the ANE first: .\build.bat" }
if ([string]::IsNullOrWhiteSpace($AirSdk)) { throw "Use -AirSdk or set AIR_SDK_HOME." }
if ([string]::IsNullOrWhiteSpace($AppKey)) { throw "Use -AppKey or set TAPSELL_APP_KEY." }
if ([string]::IsNullOrWhiteSpace($ZoneId)) { throw "Use -ZoneId or set TAPSELL_REWARDED_ZONE_ID." }

$AirSdk = (Resolve-Path -LiteralPath $AirSdk).Path
$amxmlc = Join-Path $AirSdk "bin\amxmlc.bat"
$adt = Join-Path $AirSdk "bin\adt.bat"
$binDir = Join-Path $exampleDir "bin"
$tmpDir = Join-Path $exampleDir ".tmp"
$tmpSrcDir = Join-Path $tmpDir "src"
New-Item -ItemType Directory -Force -Path $binDir, $tmpDir, $tmpSrcDir | Out-Null

$exampleSource = (Get-Content -Raw -LiteralPath (Join-Path $exampleDir "src\Main.as"))
$exampleSource = $exampleSource.Replace("YOUR_TAPSELL_APP_ID", $AppKey)
$exampleSource = $exampleSource.Replace("YOUR_REWARDED_ZONE_ID", $ZoneId)
$tmpMain = Join-Path $tmpSrcDir "Main.as"
[System.IO.File]::WriteAllText($tmpMain, $exampleSource, [System.Text.UTF8Encoding]::new($false))

& $amxmlc `
    "-source-path+=$tmpSrcDir" `
    "-library-path+=$ane" `
    "-swf-version=51" `
    "-default-size=480,640" `
    "-output=$binDir\Main.swf" `
    $tmpMain
if ($LASTEXITCODE -ne 0) { throw "Example SWF compilation failed." }

if ([string]::IsNullOrWhiteSpace($Certificate)) {
    Write-Host "SWF BUILD SUCCESSFUL: $binDir\Main.swf"
    Write-Host "APK was skipped because -Certificate was not supplied."
    exit 0
}
if ([string]::IsNullOrWhiteSpace($AndroidSdk)) { throw "Use -AndroidSdk or set ANDROID_HOME." }
if ([string]::IsNullOrWhiteSpace($StorePassword)) { throw "-StorePassword is required for APK signing." }

$descriptor = Get-Content -Raw -LiteralPath (Join-Path $exampleDir "application.xml")
$descriptor = $descriptor.Replace(
    "<androidCompileSdkVersion>35</androidCompileSdkVersion>",
    "<androidCompileSdkVersion>$AndroidCompileSdk</androidCompileSdkVersion>")
$descriptor = $descriptor.Replace(
    'android:targetSdkVersion="35"',
    "android:targetSdkVersion=`"$AndroidCompileSdk`"")
$tmpDescriptor = Join-Path $tmpDir "application.xml"
[System.IO.File]::WriteAllText($tmpDescriptor, $descriptor, [System.Text.UTF8Encoding]::new($false))

& $adt -package -target apk-captive-runtime -arch armv8 `
    -storetype pkcs12 -keystore $Certificate -storepass $StorePassword `
    (Join-Path $binDir "TapsellANEExample.apk") $tmpDescriptor `
    -platformsdk $AndroidSdk -extdir (Join-Path $projectRoot "dist") `
    -C $binDir Main.swf
if ($LASTEXITCODE -ne 0) { throw "Example APK packaging failed." }

Write-Host "APK BUILD SUCCESSFUL: $binDir\TapsellANEExample.apk"
