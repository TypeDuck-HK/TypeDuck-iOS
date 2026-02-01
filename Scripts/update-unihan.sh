#!/bin/bash

# Activate virtual environment if UNIHAN_ETL_VENV is set, otherwise assume unihan-etl is in PATH
if [ -n "$UNIHAN_ETL_VENV" ]; then
    source "$UNIHAN_ETL_VENV/bin/activate"
fi

# Dump selected fields in Unihan to csv 
unihan-etl -s https://www.unicode.org/Public/15.1.0/ucd/Unihan.zip -F csv -f kRSUnicode kTotalStrokes kIICore kUnihanCore2020 --destination ../CantoboardTestApp/UnihanSource/Unihan12.csv 

# DOS2UNIX
gsed -i 's/\r//g' ../CantoboardTestApp/UnihanSource/Unihan12.csv

# Create temp directory for intermediate files
TMPDIR="${TMPDIR:-/tmp}"

# Dump all chars in Hong Kong Core sets
echo "char,IsHCoreSim" > "$TMPDIR/UnihanH.csv"
csvgrep ../CantoboardTestApp/UnihanSource/Unihan12.csv -c kIICore -m H | csvcut -c char | sed 's/$/,h/g' >> "$TMPDIR/UnihanH.csv"

# Simplify chars in Hong Kong Core sets
opencc -i "$TMPDIR/UnihanH.csv" -o "$TMPDIR/UnihanHSim.csv" -c hk2s.json

csvjoin -c char --left ../CantoboardTestApp/UnihanSource/Unihan12.csv "$TMPDIR/UnihanHSim.csv" > "$TMPDIR/a.csv"
cp "$TMPDIR/a.csv" ../CantoboardTestApp/UnihanSource/Unihan12.csv

# Remove chars not supported by iOS/macOS
# Build MissingGlyphRemover first: xcodebuild -scheme MissingGlyphRemover -configuration Debug
# Set MISSING_GLYPH_REMOVER to the path of the built binary, or it will search in PATH
MISSING_GLYPH_REMOVER="${MISSING_GLYPH_REMOVER:-MissingGlyphRemover}"
"$MISSING_GLYPH_REMOVER" --line ../CantoboardTestApp/UnihanSource/Unihan12.csv
