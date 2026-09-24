APP = build/Disko.app
DMG = build/Disko.dmg
IDENTITY = Developer ID Application: Leif-Erik Hvide (5MW753YT87)
NOTARY_PROFILE = disko-notary
VERSION = $(shell /usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)

.PHONY: app run install print release notarize publish clean

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

release:
	swift build -c release --triple arm64-apple-macosx14.0
	swift build -c release --triple x86_64-apple-macosx14.0
	mkdir -p $(APP)/Contents/MacOS build/dmg
	lipo -create -output $(APP)/Contents/MacOS/Disko \
		.build/arm64-apple-macosx/release/Disko .build/x86_64-apple-macosx/release/Disko
	cp Info.plist $(APP)/Contents/Info.plist
	codesign --force --options runtime --timestamp --sign "$(IDENTITY)" $(APP)
	codesign --verify --strict --verbose=2 $(APP)
	ditto $(APP) build/dmg/Disko.app
	ln -sfn /Applications build/dmg/Applications
	hdiutil create -volname Disko -srcfolder build/dmg -ov -format UDZO $(DMG)
	codesign --force --timestamp --sign "$(IDENTITY)" $(DMG)

notarize: release
	xcrun notarytool submit $(DMG) --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple $(DMG)
	spctl --assess --type open --context context:primary-signature --verbose $(DMG)

publish: notarize
	gh release create v$(VERSION) $(DMG) --title "Disko $(VERSION)" --generate-notes

clean:
	swift package clean
	/opt/homebrew/opt/trash/bin/trash build 2>/dev/null || true
