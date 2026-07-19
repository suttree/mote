.PHONY: app test

app:
	./scripts/build-app.sh

test:
	DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --disable-sandbox
