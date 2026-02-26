SHELL := /bin/bash

.PHONY: icon launcher

icon:
	./scripts/make_icon.sh

launcher: icon
	./scripts/build_macos_launcher.sh
