APP = build/Disko.app

.PHONY: app run install print clean

app:
	swift build -c release
	mkdir -p $(APP)/Contents/MacOS
	cp .build/release/Disko $(APP)/Contents/MacOS/Disko
	cp Info.plist $(APP)/Contents/Info.plist
	codesign --force --sign - $(APP)

run: app
	open $(APP)

install: app
	ditto $(APP) /Applications/Disko.app
	open /Applications/Disko.app

print:
	swift run -c release Disko --print

clean:
	swift package clean
	/opt/homebrew/opt/trash/bin/trash build 2>/dev/null || true
