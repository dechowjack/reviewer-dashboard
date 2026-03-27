SHELL := /bin/bash

.PHONY: icon desktop desktop-build windows-build windows-run

icon:
	./scripts/make_icon.sh

desktop:
	python3 -m app.desktop

desktop-build: icon
	./scripts/build_macos_desktop_app.sh

windows-build:
	powershell -NoProfile -File .\\scripts\\build_windows_desktop_app.ps1

windows-run:
	powershell -NoProfile -File .\\scripts\\run_windows_desktop_app.ps1
