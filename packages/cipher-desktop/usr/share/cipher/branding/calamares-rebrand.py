#!/usr/bin/env python3
"""Turn a copy of Debian's Calamares branding folder into Cipher's.
Usage: calamares-rebrand.py /etc/calamares/branding/cipher"""
import re
import shutil
import sys
from pathlib import Path

d = Path(sys.argv[1])
desc = d / "branding.desc"
text = desc.read_text()
version = "0.1"
try:
    for line in Path("/usr/lib/os-release").read_text().splitlines():
        if line.startswith("VERSION_ID="):
            version = line.split("=", 1)[1].strip('"')
except OSError:
    pass

strings = {
    "productName": "Cipher",
    "shortProductName": "Cipher",
    "version": version,
    "shortVersion": version,
    "versionedName": f"Cipher {version}",
    "shortVersionedName": f"Cipher {version}",
    "bootloaderEntryName": "Cipher",
    "productUrl": "https://github.com/Raghava102/Cipherlinux",
    "supportUrl": "https://github.com/Raghava102/Cipherlinux/issues",
    "releaseNotesUrl": "https://github.com/Raghava102/Cipherlinux",
}
for key, value in strings.items():
    text = re.sub(rf'(^\s*{key}:\s*).*$', rf'\g<1>"{value}"', text, flags=re.M)
text = re.sub(r'^componentName:.*$', 'componentName:  cipher', text, flags=re.M)

# Cipher colors for the sidebar
for key, value in {"sidebarBackground": "#0b0f14", "sidebarText": "#d6e2ea",
                   "sidebarTextSelect": "#0b0f14", "sidebarTextCurrent": "#2de2a6",
                   "sidebarBackgroundCurrent": "#2de2a6"}.items():
    text = re.sub(rf'(^\s*{key}:\s*).*$', rf'\g<1>"{value}"', text, flags=re.M)

# Swap every referenced image for the Cipher artwork
brand = Path("/usr/share/cipher/branding")
for m in re.finditer(r'^\s*(productLogo|productIcon|productWelcome):\s*"?([^"\n]+)"?', text, flags=re.M):
    key, name = m.group(1), m.group(2).strip()
    src = brand / ("boot-background.png" if key == "productWelcome" else "icon.png")
    target = d / name
    if target.suffix.lower() == ".png":
        shutil.copyfile(src, target)
    else:
        new = Path(name).with_suffix(".png").name
        shutil.copyfile(src, d / new)
        text = text.replace(name, new)

desc.write_text(text)

# Slideshow text, if it is a simple QML show
show = d / "show.qml"
if show.exists():
    show.write_text(re.sub(r"Debian", "Cipher", show.read_text()))
print("calamares branding: Cipher", version)
