#!/bin/zsh
set -euo pipefail

HERE="${0:A:h}"
ROOT="${HERE:h:h}"
FIXTURES="$HERE/.fixtures"
MEDIA="$FIXTURES/media"
BUILD="$HERE/.build"
DESK="$ROOT/.build/debug/Desk"

cd "$ROOT"
swift build >/dev/null
mkdir -p "$BUILD"
rm -rf "$FIXTURES"
mkdir -p "$MEDIA"

SOURCES=(${(f)"$(ls "$ROOT"/Sources/Desk/*.swift | grep -v '/main.swift$')"})
swiftc -swift-version 5 -module-name DeskSeed -o "$BUILD/seed" "${SOURCES[@]}" "$HERE/Seeder/main.swift" >"$BUILD/seed-build.log" 2>&1 || true
[[ -x "$BUILD/seed" ]] || { echo "seed: build failed" >&2; exit 1; }

WALL="/System/Library/Desktop Pictures/Sonoma.heic"
PICS="/Library/User Pictures"
sips -s format jpeg -s formatOptions 82 -Z 4032 "$WALL" --out "$MEDIA/base.jpg" >/dev/null
sips --cropToHeightWidth 1512 2016 --cropOffset 1900 900 "$MEDIA/base.jpg" --out "$MEDIA/coast-landscape.jpg" >/dev/null
sips --cropToHeightWidth 2016 1512 --cropOffset 1200 2300 "$MEDIA/base.jpg" --out "$MEDIA/hills-portrait.jpg" >/dev/null
sips --cropToHeightWidth 1000 3600 --cropOffset 2600 200 "$MEDIA/base.jpg" --out "$MEDIA/dunes-panorama.jpg" >/dev/null
rm "$MEDIA/base.jpg"
sips -s format png "$PICS/Animals/Zebra.heic" --out "$MEDIA/zebra.png" >/dev/null
cp -L "$PICS/Flowers/Sunflower.heic" "$MEDIA/sunflower.heic"
sips -s format png -Z 40 "$PICS/Nature/Leaf.heic" --out "$MEDIA/leaf-icon.png" >/dev/null

"$BUILD/seed" "$FIXTURES" "$MEDIA"

drive() {
  local fixture="$1" steps="$2"
  mkdir -p "$FIXTURES/$fixture"
  print -r -- "$steps" > "$BUILD/$fixture.json"
  DESK_STORE_URL="$FIXTURES/$fixture/store.sqlite" \
  DESK_DEFAULTS_SUITE="$BUILD/$fixture-defaults" \
  DESK_VERIFY_SCRIPT="$BUILD/$fixture.json" \
  "$DESK" >/dev/null 2>&1
  echo "seeded $fixture with the Desk driver"
}

drive samples '[{"kind":"wait","ms":300},{"kind":"menu","name":"Add Sample Notes"},{"kind":"wait","ms":300}]'
drive first-note '[{"kind":"wait","ms":300},{"kind":"menu","name":"New Note"},{"kind":"wait","ms":300},{"kind":"key","chars":"\t","keyCode":48},{"kind":"key","chars":"\r","keyCode":36},{"kind":"wait","ms":800},{"kind":"text","text":"Call the landlord about the leak"},{"kind":"wait","ms":300},{"kind":"key","chars":"\u001b","keyCode":53},{"kind":"wait","ms":800}]'

for store in "$FIXTURES"/*/store.sqlite; do
  sqlite3 "$store" "PRAGMA wal_checkpoint(TRUNCATE);" >/dev/null
done
mkdir -p "$FIXTURES/corrupt"
head -c 12288 "$FIXTURES/typical/store.sqlite" > "$FIXTURES/corrupt/store.sqlite"
echo "fixtures ready in $FIXTURES"
