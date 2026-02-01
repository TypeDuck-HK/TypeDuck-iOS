#!/bin/sh

TMPDIR="${TMPDIR:-/tmp}"

cat ../CantoboardFramework/Data/Rime/jyut6ping3.dict.yaml | cut -d"	" -f2 | grep -v " " | sort -u | tee "$TMPDIR/combo_with_words.txt"
