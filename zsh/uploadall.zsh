# Upload Card Backs

zsh zsh/upload.zsh art/back-fate.webp "Fate Card Back" "back fate" "An alpha map for the Fate card back"
zsh zsh/upload.zsh art/back-saxon.webp "Saxon Card Back" "back saxon" "An alpha map for the Saxon card back"
zsh zsh/upload.zsh art/back-saxon-bordered.webp "Bordered Saxon Card Back" "back bordered-saxon" "An alpha map for the Bordered Saxon card back"
zsh zsh/upload.zsh art/back-saxon-worn.webp "Worn Saxon Card Back" "back worn-saxon" "An alpha map for the Worn Saxon card back"

# Upload Layers

zsh zsh/upload.zsh art/fool-layer-a.webp "Fool Layer A" "layer" "The first layer in the parallax"
zsh zsh/upload.zsh art/fool-layer-b.webp "Fool Layer B" "layer" "The second layer in the parallax"
zsh zsh/upload.zsh art/fool-layer-c.webp "Fool Layer C" "layer" "The third layer in the parallax"
zsh zsh/upload.zsh art/fool-layer-d.webp "Fool Layer D" "layer" "The fourth layer in the parallax"
zsh zsh/upload.zsh art/fool-layer-e.webp "Fool Layer E" "layer" "The fifth layer in the parallax"
zsh zsh/upload.zsh art/fool-bg.webp "Fool Background" "background" "A flat background to be used in simplified parallax"

# Upload Card Borders

zsh zsh/upload.zsh art/border-greek.webp "Greek Card Border" "border greek" "An alpha map for the Greek card border"
zsh zsh/upload.zsh art/border-line.webp "Line Card Border" "border line" "An alpha map for the Line card border"
zsh zsh/upload.zsh art/border-naked.webp "Nake Card Border" "border naked" "An alpha map for the Nake card border"
zsh zsh/upload.zsh art/border-round.webp "Round Card Border" "border round" "An alpha map for the Round card border"
zsh zsh/upload.zsh art/border-saxon-worn.webp "Worn Saxon Card Border" "border worn-saxon" "An alpha map for the Worn Saxon card border"
zsh zsh/upload.zsh art/border-saxon.webp "Saxon Card Border" "border saxon" "An alpha map for the Saxon card border"
zsh zsh/upload.zsh art/border-staggered.webp "Staggered Card Border" "border staggered" "An alpha map for the Staggered card border"
zsh zsh/upload.zsh art/border-thicc.webp "Thicc Card Border" "border thicc" "An alpha map for the Thicc card border"

# Upload Noise

zsh zsh/upload.zsh art/normal.webp "Normal Map" "normal" "A noise based normal map for a gold foil like texture"

# Upload Flat Previews

zsh zsh/upload.zsh art/fool-flat.webp "Flat Preview" "preview flat" "A preview of the card art"

# Upload Side-By-Side Previews

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

for file in art/preview-side-by-side/*; zsh zsh/upload.zsh $file "Side by Side Preview" "$(tags $file)" "A static preview displaying the card back and border"

# Upload Preview App

zsh zsh/upload.zsh client/dist/index.html "Animated Preview App" "preview-app" "A javascript/html client for previewing legends" "text/html; charset=utf-8"
