.PHONY: build run test app open clean

build:
	swift build

run:
	swift run Tinta

test:
	swift test

app:
	chmod +x scripts/bundle_app.sh
	./scripts/bundle_app.sh release

open: app
	open Tinta.app

clean:
	swift package clean
	rm -rf Tinta.app
