#!/bin/bash

inputfile="dance_of_the_sugar_plum_fairy_from_the_nutcracker_the_royal_ballet.mp4"
shortname="plum"

indir="data/input"
outdir="data/output/$shortname"

framesdir="$outdir/frames"
audiodir="$outdir/audio"
clipsdir="$outdir/clips"

CLIPDUR="8"

mkdir -p $framesdir
mkdir -p $audiodir
mkdir -p $clipsdir

#frame extracion
ffmpeg -hide_banner -i $indir/$inputfile -vf "scale=600:400:force_original_aspect_ratio=decrease,pad=600:400:(ow-iw)/2:(oh-ih)/2,setsar=1" -r 30 $framesdir/${shortname}_%05d.png

#clip extraction
ffmpeg -hide_banner -i $indir/$inputfile -acodec copy -f segment -segment_time $CLIPDUR -vcodec copy -reset_timestamps 1 -map 0 $clipsdir/${shortname}_%05d.mp4

#audio extraction
ffmpeg -hide_banner -i $indir/$inputfile -acodec pcm_s16le -ac 1 -ar 16000 $audiodir/${shortname}.wav
ffmpeg -hide_banner -i $audiodir/${shortname}.wav -acodec copy -f segment -segment_time $CLIPDUR -vcodec copy -reset_timestamps 1 -map 0 $audiodir/${shortname}_%05d.wav
rm $audiodir/${shortname}.wav