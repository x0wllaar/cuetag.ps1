param(
    [Parameter(Mandatory=$true)]$InCue, 
    [Parameter(Mandatory=$true)]$InFile,
    $OutFolder="."
)

.\shntool.exe split -o flac -f $InCue -t "%n_%t" -d $OutFolder -n "%d" $InFile

$Tracks = .\cueparser.ps1 -InCue $InCue

$Tracks | ForEach-Object {
    $TrackNum = $_["TRACKNUMBER"]
    $File = Get-ChildItem $OutFolder | Where-Object {$_.Name -like ("$TrackNum" + "_*")}
    if ($File -is [string]){
        throw "File name or not found ambiguous for track $_ $TrackNum"
    }
    Write-Host ($File.FullName + " -> " + $_["TITLE"])

    $TagFile = New-TemporaryFile | Rename-Item -NewName { $_ -replace 'tmp$', 'txt' } –PassThru
    try{
        $CurTrack = $_
        $_.Keys | ForEach-Object {
            $TagLine = $_ + "=" + $CurTrack[$_]
            $TagLine >> $TagFile
        }

        .\metaflac.exe --remove-all-tags --import-tags-from="$TagFile" $File
        
    }finally{
        Remove-Item $TagFile
    }
}