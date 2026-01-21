$path = [Environment]::GetEnvironmentVariable("Path", "User")
$flutterBin = "C:\flutter\bin"
if ($path -notlike "*$flutterBin*") {
    $newPath = "$path;$flutterBin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "Success: Added Flutter to User Path."
} else {
    Write-Host "Flutter is already in the Path."
}
