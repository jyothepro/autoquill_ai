# AutoQuill AI - Complete DMG Build, Sign & Notarization Guide

## 🎯 Overview

This guide covers the complete process for building, signing, and notarizing AutoQuill AI v1.4.0+7 for distribution on macOS. The process creates a fully notarized DMG that users can download and install without security warnings.

## 📋 Prerequisites

### 1. Apple Developer Account
- **Required**: Active Apple Developer Program membership ($99/year)
- **Team ID**: 562STT95YC
- **Developer ID**: Developer ID Application: Divyansh Lalwani (562STT95YC)

### 2. Development Environment
- macOS with Xcode and Command Line Tools
- Flutter SDK
- Fastforge (for DMG creation)
- Valid Developer ID certificate installed

### 3. Project Setup
- AutoQuill AI Flutter project
- Proper entitlements configured
- App bundle ID: `com.divyansh-lalwani.autoquill-ai`

---

## 🚀 Quick Start

### One-Command Build
```bash
# Run the complete process (after setup)
./scripts/build_dmg_complete.sh
```

This single script handles everything from Flutter build to final notarized DMG.

---

## 📖 Detailed Process

### Step 1: Environment Setup

#### Install Fastforge
```bash
dart pub global activate fastforge
```

#### Set up Notarization (First Time Only)
```bash
./scripts/setup_notarization.sh
```

This script will:
- Guide you through creating an app-specific password
- Store your credentials securely in keychain
- Create the `autoquill-notary` profile

### Step 2: Build Process Overview

The complete build process consists of 9 main steps:

1. **Prerequisites Check** - Verify all tools and certificates
2. **Flutter Build** - Clean build of the macOS app
3. **Code Signing** - Sign app with hardened runtime
4. **DMG Creation** - Create DMG using fastforge
5. **DMG Signing** - Sign the DMG file
6. **ZIP Creation** - Create ZIP for notarization
7. **Notarization** - Submit to Apple and staple ticket
8. **Final DMG** - Recreate DMG with notarized app
9. **Distribution Files** - Organize final files

### Step 3: Manual Process (If Needed)

#### Build Flutter App
```bash
flutter clean
flutter pub get
flutter build macos --release
```

#### Sign the Application
```bash
# Sign all frameworks and binaries
find "build/macos/Build/Products/Release/AutoQuill.app" -type f \
  \( -name "*.dylib" -o -name "*.framework" -o -perm +111 \) \
  -exec codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: Divyansh Lalwani (562STT95YC)" {} \;

# Sign main app bundle
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: Divyansh Lalwani (562STT95YC)" \
  --entitlements "macos/Runner/Release.entitlements" \
  "build/macos/Build/Products/Release/AutoQuill.app"
```

#### Create DMG
```bash
fastforge release --name prod --jobs macos-dmg
```

#### Sign DMG
```bash
codesign --force --sign "Developer ID Application: Divyansh Lalwani (562STT95YC)" \
  --timestamp "dist/1.4.0+7/autoquill_ai-1.4.0+7-macos.dmg"
```

#### Create ZIP for Notarization
```bash
cd "build/macos/Build/Products/Release"
ditto -c -k --keepParent "AutoQuill.app" "AutoQuill-notarization.zip"
```

#### Submit for Notarization
```bash
xcrun notarytool submit "AutoQuill-notarization.zip" \
  --keychain-profile "autoquill-notary" \
  --wait
```

#### Staple Notarization
```bash
# Staple to app
xcrun stapler staple "build/macos/Build/Products/Release/AutoQuill.app"

# Recreate DMG with notarized app
fastforge release --name prod --jobs macos-dmg

# Sign and staple DMG
codesign --force --sign "Developer ID Application: Divyansh Lalwani (562STT95YC)" \
  --timestamp "dist/1.4.0+7/autoquill_ai-1.4.0+7-macos.dmg"
xcrun stapler staple "dist/1.4.0+7/autoquill_ai-1.4.0+7-macos.dmg"
```

---

## 📁 File Structure

After successful build, you'll have:

```
dist/
├── final/
│   └── 1.4.0+7/
│       ├── AutoQuill-1.4.0+7-notarized.dmg
│       ├── AutoQuill-1.4.0+7-notarized.zip
│       └── checksums.txt
└── 1.4.0+7/
    ├── autoquill_ai-1.4.0+7-macos.dmg
    └── AutoQuill-1.4.0+7-notarization.zip
```

---

## 🔧 Troubleshooting

### Common Issues

#### 1. "Fastforge not found"
```bash
# Install fastforge
dart pub global activate fastforge

# Ensure pub cache is in PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

#### 2. "Notarization profile not found"
```bash
# Run setup script
./scripts/setup_notarization.sh

# Or manually create
xcrun notarytool store-credentials "autoquill-notary" \
  --apple-id "your-apple-id@email.com" \
  --password "xxxx-xxxx-xxxx-xxxx" \
  --team-id "562STT95YC"
```

#### 3. "Developer ID certificate not found"
- Check Keychain Access for the certificate
- Ensure it's valid and not expired
- Download from Apple Developer portal if missing

#### 4. "Code signing failed"
```bash
# Check available certificates
security find-identity -v -p codesigning

# Verify certificate
security find-certificate -c "Developer ID Application: Divyansh Lalwani"
```

#### 5. "Notarization failed"
```bash
# Check notarization history
xcrun notarytool history --keychain-profile "autoquill-notary"

# Get detailed error log
xcrun notarytool log [SUBMISSION-ID] --keychain-profile "autoquill-notary"
```

### Common Notarization Errors

#### "Missing Hardened Runtime"
- Already handled in our signing process
- Verify with: `codesign -dv --verbose=4 "AutoQuill.app"`

#### "Unsigned Code Found"
- Re-run the signing process
- Ensure all nested frameworks are signed

#### "Invalid Bundle Structure"
- Check app bundle integrity
- Verify entitlements are correctly applied

---

## ✅ Verification Commands

### Verify App Signature
```bash
codesign --verify --deep --strict --verbose=2 "AutoQuill.app"
spctl --assess --type exec --verbose "AutoQuill.app"
```

### Verify DMG Signature
```bash
codesign --verify --deep --strict --verbose=2 "autoquill_ai-1.4.0+7-macos.dmg"
spctl --assess --type open --context context:primary-signature "autoquill_ai-1.4.0+7-macos.dmg"
```

### Verify Notarization
```bash
xcrun stapler validate "AutoQuill.app"
xcrun stapler validate "autoquill_ai-1.4.0+7-macos.dmg"
```

---

## 📦 Distribution Checklist

- [ ] **Build Completed**: App built with Flutter
- [ ] **Code Signed**: App signed with Developer ID
- [ ] **DMG Created**: DMG created with fastforge
- [ ] **DMG Signed**: DMG signed with Developer ID
- [ ] **Notarized**: App submitted to and approved by Apple
- [ ] **Stapled**: Notarization ticket attached to files
- [ ] **Verified**: All signatures and notarization verified
- [ ] **Tested**: DMG tested on clean macOS system
- [ ] **Checksums**: SHA256 checksums generated
- [ ] **Ready**: Files ready for distribution

---

## 🌐 Distribution

### Upload Files
1. **Website**: Upload DMG to your download server
2. **Auto-Updates**: Upload ZIP to your update server
3. **Backup**: Keep signed files in secure backup

### Update Website
1. Update download links to point to new DMG
2. Update version number on landing page
3. Update changelog/release notes

### Auto-Updater
1. Sign the update ZIP:
   ```bash
   dart run auto_updater:sign_update dist/final/1.4.0+7/AutoQuill-1.4.0+7-notarized.zip
   ```
2. Update `appcast.xml` with new version and signature
3. Upload both ZIP and appcast.xml to your server

---

## 🔒 Security Notes

### Certificate Management
- Keep Developer ID certificate secure
- Monitor expiration dates
- Renew before expiry to avoid distribution interruption

### App-Specific Password
- Store securely (it's in keychain after setup)
- Rotate periodically for security
- Only use for notarization

### Code Signing Best Practices
- Always use hardened runtime
- Sign all nested components
- Verify signatures before distribution
- Test on different macOS versions

---

## 📞 Support

### Apple Resources
- [Notarization Documentation](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Developer Forums](https://developer.apple.com/forums/)

### Debugging Commands
```bash
# Check notarization history
xcrun notarytool history --keychain-profile "autoquill-notary"

# Detailed app signature info
codesign -dv --verbose=4 "AutoQuill.app"

# Check Gatekeeper status
spctl --status

# Reset Gatekeeper (if needed)
sudo spctl --master-disable
sudo spctl --master-enable
```

---

## 🎉 Success!

Once you see "Ready for distribution! 🚀", your AutoQuill AI v1.4.0+7 is fully built, signed, notarized, and ready for users to download without any security warnings.

The complete process typically takes 5-15 minutes, depending on:
- Build time (2-5 minutes)
- Notarization wait time (2-10 minutes)
- File size and network speed

**Happy distributing!** 🎊 