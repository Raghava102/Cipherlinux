.PHONY: deb iso iso-nvidia art install check clean

deb:            ## build out/cipher-desktop_<ver>_all.deb
	./scripts/build-deb.sh

iso:            ## build the live ISO (root, Debian 13, live-build)
	sudo ./scripts/build-iso.sh

iso-nvidia:
	sudo ./scripts/build-iso.sh --nvidia

art:            ## regenerate backgrounds, logo and boot splash
	python3 scripts/gen-art.py

install:        ## install Cipher onto this Debian 13 system
	./scripts/install-on-debian.sh

check:          ## lint scripts and JSON
	shellcheck -S warning scripts/*.sh iso/auto/* iso/config/hooks/live/*.hook.chroot \
	  $$(grep -l '^#!/bin/bash' packages/cipher-desktop/usr/bin/*)
	for f in packages/cipher-desktop/usr/share/cipher/menu.json packages/cipher-desktop/usr/share/cipher/themes/*/theme.json; do \
	  python3 -m json.tool "$$f" >/dev/null || exit 1; done
	@echo ok

clean:
	rm -rf out
