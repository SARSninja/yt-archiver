split -n l/8 ytdl.txt dlist_
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_aa > log1.txt &
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_ab > log2.txt &
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_ac > log3.txt &
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_ad > log4.txt &
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_ae > log5.txt &
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_af > log6.txt &
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_ag > log7.txt &
youtube-dl --continue --ignore-errors --no-overwrites -f "[filesize<200M]" --batch-file dlist_ah > log8.txt &
