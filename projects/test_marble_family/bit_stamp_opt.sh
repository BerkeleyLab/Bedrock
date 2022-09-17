#!/bin/sh
# Wrapper around plain bit_stamp_mod, to only run it when wanted
# $1 is base name of bitfile

# This file has features used if processed by git archive, and ignored
# otherwise; see the export-subst paragraph in man gitattributes.
# This next line just gives shellcheck(1) one less thing to complain about.
Format=discarded

if [ "$Format:%%$" = "%" ]; then
    echo "Detected output of git archive; guessing unmodified"
    G=$Format:%H$
    G=$1.$(echo "$G" | cut -c1-8)
    D="$Format:%ct$"
    ./bit_stamp_mod -s "$D" "$G.bit" < "$G.x.bit" && rm "$G.x.bit" && sha256sum "$G.bit"
else
    G=$1.$(git rev-parse --short=8 --verify HEAD)
    if git diff | grep -q .; then
        echo "modified code; not coercing bitfile header timestamp"
        mv "$G.x.bit" "$G.bit"
    else
        D=$(git log -1 --pretty=%ct)
        ./bit_stamp_mod -s "$D" "$G.bit" < "$G.x.bit" && rm "$G.x.bit" && sha256sum "$G.bit"
    fi
fi
