#!/bin/bash

TMPDIR="${TMPDIR:-/tmp}"

cat ../CantoboardFramework/Data/Rime/essay.txt | grep -E "^.\t" > "$TMPDIR/essay-1char-t.txt"
opencc -i "$TMPDIR/essay-1char-t.txt" -o "$TMPDIR/essay-1char-s.txt" -c hk2s.json
comm -13 "$TMPDIR/essay-1char-t.txt" "$TMPDIR/essay-1char-s.txt" > "$TMPDIR/essay-1char-s-uniq.txt"
cat "$TMPDIR/essay-1char-s-uniq.txt" | awk -F "\t" '{ printf("%s\t%.0f\n", $1,$2*0.9) }' > "$TMPDIR/essay-1char-s-uniq-with-freq.txt"
cat "$TMPDIR/essay-1char-s-uniq-with-freq.txt" | awk -F $'\t' '{count[$1]+=$2} END {for (word in count) printf("%s\t%d\n", word, count[word])}' > "$TMPDIR/essay-1char-s-uniq-with-freq-dedup.txt"
cat ../CantoboardFramework/Data/Rime/essay.txt "$TMPDIR/essay-1char-s-uniq-with-freq-dedup.txt" > ../CantoboardFramework/Data/Rime/essay-s1c.txt