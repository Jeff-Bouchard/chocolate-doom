#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 ./chocolate-doom/doom1.wad ./chocolate-doom/chocolate-doom.js ./chocolate-doom/chocolate-doom.wasm" >&2
  exit 1
fi

WAD_PATH="$1"
JS_PATH="$2"
WASM_PATH="$3"

for f in "$WAD_PATH" "$JS_PATH" "$WASM_PATH"; do
  if [ ! -f "$f" ]; then
    echo "Missing file: $f" >&2
    exit 1
  fi
done

for bin in sha256sum ipfs; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Required binary not found in PATH: $bin" >&2
    exit 1
  fi
done

hash_file() {
  sha256sum "$1" | awk '{print $1}'
}

add_ipfs() {
  # Use CIDv1; adjust if you have stricter policy
  ipfs add --cid-version=1 -Q "$1"
}

TRACKERS=(
  "udp://tracker.opentrackr.org:1337/announce"
  "udp://tracker.torrent.eu.org:451/announce"
  "udp://open.stealth.si:80/announce"
  "udp://tracker.qu.ax:6969/announce"
)

build_magnet() {
  local cid="$1"
  local dn="$2"
  local magnet="magnet:?xt=urn:ipfs:${cid}&dn=${dn}&ws=https://ipfs.ness.cx/ipfs/${cid}"
  for tr in "${TRACKERS[@]}"; do
    magnet+="&tr=${tr}"
  done
  printf '%s\n' "$magnet"
}

echo ">> Computing SHA-256 digests..."
WAD_SHA256="$(hash_file "$WAD_PATH")"
JS_SHA256="$(hash_file "$JS_PATH")"
WASM_SHA256="$(hash_file "$WASM_PATH")"

echo "WAD  sha256: $WAD_SHA256"
echo "JS   sha256: $JS_SHA256"
echo "WASM sha256: $WASM_SHA256"
echo

echo ">> Adding files to IPFS..."
WAD_CID="$(add_ipfs "$WAD_PATH")"
JS_CID="$(add_ipfs "$JS_PATH")"
WASM_CID="$(add_ipfs "$WASM_PATH")"

echo "WAD  CID: $WAD_CID"
echo "JS   CID: $JS_CID"
echo "WASM CID: $WASM_CID"
echo

echo "================ EmerDNS mappings (logical names) ================"
echo "doomwad.private.ness  ->  $WAD_CID"
echo "doomjs.private.ness   ->  $JS_CID"
echo "doomwasm.private.ness ->  $WASM_CID"
echo
echo "# In EmerDNS/NVS you will store those CIDs under the appropriate d:* records."
echo

echo "================ IPFS URLs via ipfs.ness.cx ======================"
echo "WAD  URL: https://ipfs.ness.cx/ipfs/$WAD_CID"
echo "JS   URL: https://ipfs.ness.cx/ipfs/$JS_CID"
echo "WASM URL: https://ipfs.ness.cx/ipfs/$WASM_CID"
echo

echo "================ Magnet URIs (3-way backup) ======================"
echo "WAD  magnet:"
echo "  $(build_magnet "$WAD_CID" "doom-wad")"
echo
echo "JS   magnet:"
echo "  $(build_magnet "$JS_CID" "doom-js")"
echo
echo "WASM magnet:"
echo "  $(build_magnet "$WASM_CID" "doom-wasm")"
echo

echo "================ JS constants for production_doom.html =========="
cat <<EOF
// Expected digests for integrity enforcement (SHA-256 hex)
const EXPECTED_WAD_SHA256  = "$WAD_SHA256";
const EXPECTED_JS_SHA256   = "$JS_SHA256";
const EXPECTED_WASM_SHA256 = "$WASM_SHA256";

// EmerDNS names (kept as requested)
const WAD_DOMAIN_NAME  = "doomwad.private.ness";
const JS_DOMAIN_NAME   = "doomjs.private.ness";
const WASM_DOMAIN_NAME = "doomwasm.private.ness";
TRACKERS=(
  "udp://tracker.opentrackr.org:1337/announce"
  "udp://tracker.torrent.eu.org:451/announce"
  "udp://open.stealth.si:80/announce"
  "udp://tracker.qu.ax:6969/announce"
)

build_magnet() {
  local cid="$1"
  local dn="$2"
  local magnet="magnet:?xt=urn:ipfs:${cid}&dn=${dn}&ws=https://ipfs.ness.cx/ipfs/${cid}"
  for tr in "${TRACKERS[@]}"; do
    magnet+="&tr=${tr}"
  done
  printf '%s\n' "$magnet"
}

EOF
echo
echo "Done. Use the above constants and mappings in production_doom.html."
