param([string]$InFolder, [string]$OutFolder, [string]$Bitrate="160k")
$DebugPreference = "Continue"

$FlacFiles = Get-ChildItem $InFolder | Where-Object {
    $_.Name -like "*.flac"
}
if ($FlacFiles.Length -lt 1){
    throw "No FLAC files found"
}

if (-not (Test-Path $OutFolder)){
    throw "Output folder not found"
}

$FlacFiles | ForEach-Object {
    $OutName = ($_.Name -replace " ", "_")
    $OutName = ($OutName -replace ".flac", ".ogg")
    $OutFullName = "$OutFolder\$OutName"

    Write-Host ($_.FullName + " -> " + $OutFullName)

    ./ffmpeg.exe -v quiet -stats -i $_.FullName -c:a libopus -b:a $Bitrate -vn $OutFullName 
}