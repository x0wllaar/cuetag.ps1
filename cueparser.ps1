param(
    [Parameter(Mandatory=$true)]$InCue, 
    [switch]$TotalAcrossFiles=$false, 
    [switch]$RawInfo=$false
)
function Split-Quoted($string) {
    $Raw = [regex]::Split($string, ' (?=(?:[^"]|"[^"]*")*$)' )
    $Filtered = $Raw | ForEach-Object {$_.Trim("`"")}
    return $Filtered
}

class CueIndex{
    [int]$IndexNum = $null
    [string]$IndexTime = $null
}

class CueTrack{
    [int]$Number = $null
    [string]$Type = $null

    [string]$Isrc = $null
    [string]$Performer = $null
    [string]$Pregap = $null
    [string]$Postgrap = $null
    [string]$Songwriter = $null
    [string]$Title = $null
    [string]$Flags = $null

    [string]$Composer = $null

    [CueIndex[]]$Indices = $Null

    [void]ParseTrackProp($line){
        $SplitLine = Split-Quoted $line
        if ($SplitLine.Length -lt 2){
            throw "Failed to parse line $line"
        }

        $FomattedPropName = (Get-Culture).TextInfo.ToTitleCase($SplitLine[0].ToLower())
        if ($SplitLine.Length -eq 2){
            $PropValue = $SplitLine[1]
        }else{
            $PropValue = $SplitLine[1..$SplitLine.Length - 1]
        }

        $this.$FomattedPropName = $PropValue
    }

    [void]ParseIndex($line){
        $SplitLine = Split-Quoted $line

        $IndexNum = [int]$SplitLine[1].Trim("`"")
        $IndexTime = $SplitLine[2]

        if ($null -eq $this.Indices){
            $this.Indices = [CueIndex[]]@()
        }

        [CueIndex]$NewIndex = New-Object CueIndex
        $NewIndex.IndexNum = $IndexNum
        $NewIndex.IndexTime = $IndexTime

        $this.Indices += $NewIndex
    }
}

class CueFile{
    [string]$Name = $null
    [string]$Type = $null

    [CueTrack[]]$Tracks = $null

    [CueTrack]GetCurrentTrack(){
        if ($null -eq $this.Tracks){
            throw "Cannot get current track (not initialized)"
        }

        $alen = $this.Tracks.Length
        if ($alen -eq 0){
            throw "Cannot get current track (array length 0)"
        }

        return $this.Tracks[$alen - 1]
    }

    [void]ParseTrack($line){
        $SplitLine = Split-Quoted $line

        $TrackNum = [int]$SplitLine[1].Trim("`"")
        $TrackType = $SplitLine[2]

        [CueTrack]$NewTrack = New-Object CueTrack
        $NewTrack.Number = $TrackNum
        $NewTrack.Type = $TrackType

        if ($null -eq $this.Tracks){
            $this.Tracks = [CueTrack[]]@()
        }
        $this.Tracks += $NewTrack
    }

}

#https://wiki.hydrogenaud.io/index.php?title=Cue_sheet
class CueSheet{
    [string]$Catalog = $null
    [string]$CdTextFile = $null
    [string]$Performer = $null
    [string]$Songwriter = $null
    [string]$Title = $null

    #Rems for files
    [string]$Date = $null
    [string]$Genre = $null
    [string]$Discid = $null
    [string]$Comment = $null
    [string]$Composer = $null

    [CueFile[]]$Files = $null

    [CueFile]GetCurrentFile(){
        if ($null -eq $this.Files){
            throw "Cannot get current file (not initialized)"
        }

        $alen = $this.Files.Length
        if ($alen -eq 0){
            throw "Cannot get current file (array length 0)"
        }

        return $this.Files[$alen - 1]
    }

    [void]ParseREM($line){
        $line = $line.Replace("REM ", "")
        $this.ParseLine($line)
    } 
    
    [void]ParseFile($line){
        $SplitLine = Split-Quoted $line

        $FileName = $SplitLine[1].Trim("`"")
        $FileType = $SplitLine[2]

        [CueFile]$NewFile = New-Object CueFile
        $NewFile.Name = $FileName
        $NewFile.Type = $FileType

        if ($null -eq $this.Files){
            $this.Files = [CueFile[]]@()
        }
        $this.Files += $NewFile

    } 
    
    [void]ParseTrack($line){
        [CueFile]$CurFile = $this.GetCurrentFile()
        $CurFile.ParseTrack($line)
    }

    [void]ParseGlobalProp($line){
        $SplitLine = Split-Quoted $line
        if ($SplitLine.Length -lt 2){
            throw "Failed to parse line $line"
        }

        $FomattedPropName = (Get-Culture).TextInfo.ToTitleCase($SplitLine[0].ToLower())
        if ($SplitLine.Length -eq 2){
            $PropValue = $SplitLine[1]
        }else{
            $PropValue = $SplitLine[1..$SplitLine.Length - 1]
        }

        $this.$FomattedPropName = $PropValue
    }

    [void]ParseTrackProp($line){
        $CurFile = $this.GetCurrentFile()
        $CurTrack = $CurFile.GetCurrentTrack()
        $CurTrack.ParseTrackProp($line)
    }

    [void]ParseIndex($line){
        $CurFile = $this.GetCurrentFile()
        $CurTrack = $CurFile.GetCurrentTrack()
        $CurTrack.ParseIndex($line)
    }
    
    [void]ParseGlobalOrTrackProp($line){
        if($null -eq $this.Files){
            $this.ParseGlobalProp($line)
        }else{
            $this.ParseTrackProp($line)
        }
    }
    
    [void]ParseLine($line){
        $SplitLine = $line -split " ",2
        $FieldName = $SplitLine[0]

        switch ($FieldName) {
            "REM" { $this.ParseREM($line) }

            "FILE" {$this.ParseFile($line)}
            "TRACK" {$this.ParseTrack($line)}
            "INDEX" {$this.ParseIndex($line)}

            "CATALOG" {$this.ParseGlobalProp($line)}
            "CDTEXTFILE" {$this.ParseGlobalProp($line)}

            "DATE" {$this.ParseGlobalProp($line)}
            "GENRE" {$this.ParseGlobalProp($line)}
            "DISCID" {$this.ParseGlobalProp($line)}
            "COMMENT" {$this.ParseGlobalProp($line)}

            "FLAGS" {$this.ParseTrackProp($line)}
            "ISRC" {$this.ParseTrackProp($line)}
            "POSTGAP" {$this.ParseTrackProp($line)}
            "PREGAP" {$this.ParseTrackProp($line)}

            "SONGWRITER" {$this.ParseGlobalOrTrackProp($line)}
            "PERFORMER" {$this.ParseGlobalOrTrackProp($line)}
            "TITLE" {$this.ParseGlobalOrTrackProp($line)}
            "COMPOSER" {$this.ParseGlobalProp($line)}


            Default {throw "Unknown field name $FieldName"}
        }
    }

}

Set-PSDebug -Strict

[CueSheet]$CueSheet = New-Object CueSheet
Get-Content $InCue | ForEach-Object {
    $_.Trim()
} | ForEach-Object {
    $CueSheet.ParseLine($_)
}

if($RawInfo){
    return $CueSheet
}

#https://wiki.hydrogenaud.io/index.php?title=Tag_Mapping
$CueTracks = @()
foreach ($CurFile in $CueSheet.Files){
    $TrackCount = $CurFile.Tracks.Length
    foreach ($CurTrack in $CurFile.Tracks){
        [CueTrack]$CurTrack = $CurTrack
        $CurTrackInfo = [ordered]@{}
        
        if ($null -ne $CueSheet.Title){
            $CurTrackInfo["ALBUM"] = $CueSheet.Title
        }
        if ($null -ne $CurTrack.Title){
            $CurTrackInfo["TITLE"] = $CurTrack.Title
        }
        if ($null -ne $CueSheet.Performer){
            $CurTrackInfo["ALBUMARTIST"] = $CueSheet.Performer
        }
        if ($null -ne $CueSheet.Date){
            $CurTrackInfo["DATE"] = $CueSheet.Date
        }
        if ($null -ne $CueSheet.Comment){
            $CurTrackInfo["COMMENT"] = $CueSheet.Comment
        }
        if ($null -ne $CurTrack.Number){
            $CurTrackInfo["TRACKNUMBER"] = $CurTrack.Number
        }

        if ($null -ne $CurTrack.Performer){
            $CurTrackInfo["ARTIST"] = $CurTrack.Performer
        }elseif ($null -ne $CueSheet.Performer) {
            $CurTrackInfo["ARTIST"] = $CueSheet.Performer
        }

        if ($null -ne $CurTrack.Songwriter){
            $CurTrackInfo["WRITER"] = $CurTrack.Songwriter
        }elseif ($null -ne $CueSheet.Songwriter) {
            $CurTrackInfo["WRITER"] = $CueSheet.Songwriter
        }

        if ($null -ne $CurTrack.Composer){
            $CurTrackInfo["COMPOSER"] = $CurTrack.Composer
        }elseif ($null -ne $CueSheet.Composer) {
            $CurTrackInfo["COMPOSER"] = $CueSheet.Composer
        }

        $CurTrackInfo["TRACKTOTAL"] = $TrackCount
        $CurTrackInfo["TOTALTRACKS"] = $TrackCount

        $CueTracks += $CurTrackInfo
    }
}

if ($TotalAcrossFiles){
    (0..$CueTracks.Length - 1) | ForEach-Object {
        $CueTracks[$_]["TOTALTRACKS"] = $CueTracks.Length
    }
} 

$CueTracks