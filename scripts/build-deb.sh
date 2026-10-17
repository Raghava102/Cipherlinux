#!/bin/bash
# Build packages/cipher-desktop into out/cipher-desktop_<version>_all.deb
# Works on any Linux with dpkg-deb (no Debian packaging toolchain needed).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=${CIPHER_VERSION:-$(cat "$ROOT/VERSION")}
MAINTAINER=${CIPHER_MAINTAINER:-"Cipher Project <cipher@example.invalid>"}
HOMEPAGE=${CIPHER_HOMEPAGE:-"https://github.com/your-name/cipher"}
SRC="$ROOT/packages/cipher-desktop"
OUT="$ROOT/out"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

command -v dpkg-deb >/dev/null || { echo "dpkg-deb not found (apt install dpkg)" >&2; exit 1; }

cp -a "$SRC/." "$STAGE/"
rm -f "$STAGE/DEBIAN/control.in"
sed -e "s|@VERSION@|$VERSION|" -e "s|@MAINTAINER@|$MAINTAINER|" -e "s|@HOMEPAGE@|$HOMEPAGE|" \
    "$SRC/DEBIAN/control.in" > "$STAGE/DEBIAN/control"

# Sane permissions regardless of the checkout's umask
find "$STAGE" -path "$STAGE/DEBIAN" -prune -o -type d -exec chmod 755 {} +
find "$STAGE" -path "$STAGE/DEBIAN" -prune -o -type f -exec chmod 644 {} +
chmod 755 "$STAGE"/usr/bin/* "$STAGE/DEBIAN/postinst"

# Every regular file under /etc is a conffile, so local edits survive upgrades
(cd "$STAGE" && find etc -type f | sort | sed 's|^|/|') > "$STAGE/DEBIAN/conffiles"
(cd "$STAGE" && find . -path ./DEBIAN -prune -o -type f -print0 | sort -z \
   | xargs -0 md5sum | sed 's|  \./|  |') > "$STAGE/DEBIAN/md5sums"
SIZE=$(du -sk --exclude=DEBIAN "$STAGE" | cut -f1)
echo "Installed-Size: $SIZE" >> "$STAGE/DEBIAN/control"

mkdir -p "$OUT"
DEB="$OUT/cipher-desktop_${VERSION}_all.deb"
dpkg-deb --root-owner-group -Zxz --build "$STAGE" "$DEB" >/dev/null
echo "$DEB"
