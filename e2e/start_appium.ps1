# Starts the Appium server with the Android SDK / JDK paths it needs.
# Usage: powershell -ExecutionPolicy Bypass -File e2e\start_appium.ps1

if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\sdk" }
if (-not $env:JAVA_HOME) {
    $env:JAVA_HOME = (Get-ChildItem "C:\Program Files\Microsoft" -Directory -Filter "jdk-17*" | Select-Object -First 1).FullName
}
$env:Path = "C:\Program Files\nodejs;$env:APPDATA\npm;$env:ANDROID_HOME\platform-tools;$env:Path"

Write-Host "ANDROID_HOME=$env:ANDROID_HOME"
Write-Host "JAVA_HOME=$env:JAVA_HOME"
appium
