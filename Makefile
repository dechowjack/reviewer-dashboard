SHELL := /bin/bash

.PHONY: icon desktop desktop-build desktop-dmg windows-build

icon:
	./scripts/make_icon.sh

desktop:
	python3 -m app.desktop

desktop-build: icon
	./scripts/build_macos_desktop_app.sh

desktop-dmg: desktop-build
	./scripts/package_macos_dmg.sh

windows-build:
	pwsh -NoProfile -ExecutionPolicy Bypass -File ./scripts/build_windows_desktop_app.ps1
