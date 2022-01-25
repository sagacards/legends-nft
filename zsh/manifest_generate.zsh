#!/bin/zsh
echo "---- side-by-side previews... ----"
tags() {  # xD
    x=$(echo $1 | sed -E "s/.+\///")
    x=$(echo $x | sed -E "s/.webp//")
    x=$(echo $x | sed -E "s/preview-side-by-side-//")
    x=$(echo $x | sed -E "s/worn-saxon/worn_saxon/")
    x=$(echo $x | sed -E "s/worn-saxon/worn_saxon/")
    x=$(echo $x | sed -E "s/bordered-saxon/bordered_saxon/")
    x=$(echo $x | sed -E "s/bordered-saxon/bordered_saxon/")
    x=$(echo $x | sed -E "s/-/:/")
    x=$(echo $x | sed -E "s/-/:/")
    x=$(echo $x | sed -E "s/-/:/")
    x=$(echo $x | sed -E "s/worn_saxon/worn-saxon/")
    x=$(echo $x | sed -E "s/worn_saxon/worn-saxon/")
    x=$(echo $x | sed -E "s/bordered_saxon/bordered-saxon/")
    x=$(echo $x | sed -E "s/bordered_saxon/bordered-saxon/")
    echo "preview side-by-side back-${x%%:*} border-${${x%:*}#*:} ink-${x##*:}"
}

for file in art/0-the-fool/side-by-side/*; echo $file, Side by Side Preview, $(tags $file), A static preview displaying the card back and border, image/webp

echo "---- animated previews... ----"
tags() {  # xD
    x=$(echo $1 | sed -E "s/.+\///")
    x=$(echo $x | sed -E "s/.webm//")
    x=$(echo $x | sed -E "s/preview-animated-//")
    x=$(echo $x | sed -E "s/worn-saxon/worn_saxon/")
    x=$(echo $x | sed -E "s/worn-saxon/worn_saxon/")
    x=$(echo $x | sed -E "s/bordered-saxon/bordered_saxon/")
    x=$(echo $x | sed -E "s/bordered-saxon/bordered_saxon/")
    x=$(echo $x | sed -E "s/-/:/")
    x=$(echo $x | sed -E "s/-/:/")
    x=$(echo $x | sed -E "s/-/:/")
    x=$(echo $x | sed -E "s/worn_saxon/worn-saxon/")
    x=$(echo $x | sed -E "s/worn_saxon/worn-saxon/")
    x=$(echo $x | sed -E "s/bordered_saxon/bordered-saxon/")
    x=$(echo $x | sed -E "s/bordered_saxon/bordered-saxon/")
    echo "preview animated back-${x%%:*} border-${${x%:*}#*:} ink-${x##*:}"
}

for file in art/0-the-fool/animated/compressed/*; echo $file, Animated Preview, $(tags $file), An animated preview displaying the rotating card, image/webm
