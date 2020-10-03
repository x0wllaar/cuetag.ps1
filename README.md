# cuetag.ps1

A cue sheet parser (and converter) in PowerShell


When using Linux, I got quite used to the shnsplit + cuetag.sh + ffmpeg workflow to convert (single FLAC + cue) music files that a lot of CD ripping programs create to individual Opus files that are easy to import into library managers and players (and generally easier to work with)

  
On Windows, I did not find a good replacement for this, so I have decided to take matters into my own hands and recreate it to the best of my ability.
  

As of right now, I have implemented a script that parses cue sheets into data a usable data structure. The same script also converts this data structure into an array of hashtables with corresponding Vorbis comment tags as keys.


On top of this script I have also made a helper script that first splits an input FLAC file into individual tracks with shntool, and then tags the tracks with data from the cuesheet using my parser and metaflac.

  
Also I have implemented a small helper script that uses ffmpeg to convert individual FLAC files to Opus (in ogg container) on a folder-by-folder basis.


As of right now, the parser can parse all cue sheets I've thrown at it, but it's very much work in progress at this point. The main problem is that I've decided to treat (REM *) comments in cue files as full-fledged fields, and there's a lot of variety in there.

## How to use  

##### Download

 1. shntool.exe (http://shnutils.freeshell.org/shntool/)
 2. flac.exe (https://sourceforge.net/projects/flac/files/flac-win/)
 3. ffmpeg.exe (https://www.gyan.dev/ffmpeg/builds/)
 
 And place them in the same folder with the scripts

##### To split single FLAC + cue:

    > .\cue2tracks.ps1 -OutFolder 'Where\To\PutTracks\' -InCue 'Path\To\Cue' -InFile 'Path\To\Flac'
    
This will split the file into tracks, save them into the folder you specified, then tag them with info from the cue sheet

##### To convert a folder with *.flac files to Opus files:

    > .\flactracks2opus.ps1 -InFolder 'Path\To\Tracks' -OutFolder 'Where\To\Put\Opus'

You can also set the bitrate with the  `-Bitrate` flag (the same format as ffmpeg, "160k" by default)