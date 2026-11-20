.DEFAULT_GOAL := all

YARN ?= yarn
NODE ?= node

ifeq ($(OS),Windows_NT)
ANDROID_GRADLE := mobile/android/gradlew.bat
else
ANDROID_GRADLE := mobile/android/gradlew
endif

.PHONY: all help install dev build test quick desktop desktop-win desktop-mac desktop-linux android ios deploy

all: desktop ## Build the Electron app for the current platform

help: ## Show available targets
	@echo "make                 Build the Electron app for this platform"
	@echo "make quick           Build frontend/backend, then package Electron"
	@echo "make build           Build frontend and backend"
	@echo "make test            Run backend tests"
	@echo "make dev             Start frontend and backend in development mode"
	@echo "make desktop         Package Electron for this platform"
	@echo "make desktop-win     Package Windows installer (requires Windows)"
	@echo "make desktop-mac     Package macOS DMG (requires macOS)"
	@echo "make desktop-linux   Package Linux AppImage (requires Linux)"
	@echo "make android         Build unsigned APK (requires Android SDK/JDK)"
	@echo "make ios             Build unsigned iOS bundle (requires macOS/Xcode)"
	@echo "make deploy          Build and deploy to Vercel"
	@echo "make install         Install locked Yarn dependencies"

install: ## Install dependencies from yarn.lock
	$(YARN) install --frozen-lockfile

dev: ## Start the frontend and backend
	$(YARN) dev

build: ## Build frontend and backend
	$(YARN) build

test: ## Run backend tests
	$(YARN) workspace cnc-chat-bot-backend test

quick: build desktop ## Build the application and package Electron

desktop: ## Package Electron for the current platform
	$(YARN) electron-build

desktop-win: ## Package the Windows installer
	$(YARN) workspace electron run package --win

desktop-mac: ## Package the macOS DMG
	$(YARN) workspace electron run package --mac

desktop-linux: ## Package the Linux AppImage
	$(YARN) workspace electron run package --linux

android: ## Build and name the unsigned Android APK
	$(NODE) -e "const fs=require('fs');if(!fs.existsSync('mobile/android/app/src/main/AndroidManifest.xml'))require('child_process').execSync('yarn workspace argon-mobile add:android',{stdio:'inherit'})"
	$(YARN) workspace argon-mobile assets:android
	$(YARN) workspace argon-mobile cap sync android
	$(ANDROID_GRADLE) -p mobile/android assembleRelease
	$(NODE) -e "const fs=require('fs'),path=require('path'),dir='mobile/android/app/build/outputs/apk/release',apk=fs.readdirSync(dir).find(name=>name.endsWith('-unsigned.apk'));if(!apk)throw new Error('Unsigned APK not found');fs.copyFileSync(path.join(dir,apk),'mobile/android/argon-ai-engineer-android.apk')"

ios: ## Build and archive the unsigned iOS app
	$(NODE) -e "if(process.platform!=='darwin')throw new Error('iOS builds require macOS and Xcode');const fs=require('fs');if(!fs.existsSync('mobile/ios/App/App.xcodeproj/project.pbxproj'))require('child_process').execSync('yarn workspace argon-mobile add:ios',{stdio:'inherit'})"
	$(YARN) workspace argon-mobile assets:ios
	$(YARN) workspace argon-mobile cap sync ios
	xcodebuild -project mobile/ios/App/App.xcodeproj -scheme App -configuration Release -destination 'generic/platform=iOS' -derivedDataPath mobile/ios/build CODE_SIGNING_ALLOWED=NO build
	ditto -c -k --sequesterRsrc --keepParent mobile/ios/build/Build/Products/Release-iphoneos/App.app mobile/ios/argon-ai-engineer-ios-unsigned.zip

deploy: build ## Build and deploy to Vercel
	$(YARN) deploy
