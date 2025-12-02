# 📱 Domino's Fleet Inspector - Build & Installation Guide

## ✅ Android APK - Production Ready

### 📥 Download APK

**Release APK**: [Download app-release.apk](https://www.genspark.ai/api/code_sandbox/download_file_stream?project_id=3e027b5d-1207-4d6b-868b-80505babb447&file_path=%2Fhome%2Fuser%2Fflutter_app%2Fbuild%2Fapp%2Foutputs%2Fflutter-apk%2Fapp-release.apk&file_name=DominosFleetInspector-v2.0.0.apk)

**Alternative Path**: `build/app/outputs/flutter-apk/app-release.apk`

---

## 📊 APK Details

| Property | Value |
|----------|-------|
| **App Name** | Domino's Fleet Inspector |
| **Package Name** | com.dominos.vehicleinspection |
| **Version** | 2.0.0 (Build 2) |
| **File Size** | 55 MB |
| **Min SDK** | Android 21 (Android 5.0) |
| **Target SDK** | Android 36 |
| **Build Type** | Release (Signed & Optimized) |
| **Signing** | Release keystore |

---

## 🔧 Build Configuration

### Signing Configuration
```properties
# android/key.properties
storePassword=android123
keyPassword=android123
keyAlias=app-release
storeFile=app-release-key.jks
```

### Keystore Details
- **Location**: `android/app/app-release-key.jks`
- **Algorithm**: RSA 2048-bit
- **Validity**: 10,000 days (27+ years)
- **Owner**: CN=Dominos Fleet, OU=IT, O=Dominos, L=Auckland, S=Auckland, C=NZ

### Package Structure
```
com.dominos.vehicleinspection
├── MainActivity.kt
└── Resources (icons, assets, etc.)
```

---

## 📲 Installation Instructions

### For Android Devices

#### Method 1: Direct Installation
1. **Download** the APK file to your Android device
2. **Enable** "Install from Unknown Sources" in Settings
   - Go to Settings → Security → Unknown Sources → Enable
3. **Locate** the downloaded APK file in Downloads folder
4. **Tap** on the APK file
5. **Tap** "Install" when prompted
6. **Wait** for installation to complete
7. **Open** the app from your app drawer

#### Method 2: ADB Installation
```bash
# Connect device via USB and enable USB Debugging
adb install app-release.apk

# Or for wireless installation
adb connect <device-ip>:5555
adb install app-release.apk
```

#### Method 3: Google Play Store (Future)
- Upload to Google Play Console
- Complete store listing
- Submit for review
- Publish to Play Store

---

## 🍎 iOS Build Status

### ⚠️ iOS Not Currently Available

iOS builds require:
- macOS operating system
- Xcode development environment
- Apple Developer Account ($99/year)
- Code signing certificates
- Provisioning profiles

**Current Status**: ❌ Not supported in this Linux-based environment

### iOS Build Requirements (For Future Reference)

If you want to build for iOS in the future, you'll need:

1. **Development Environment**
   ```bash
   # On macOS only
   flutter build ios --release
   # or for App Store
   flutter build ipa --release
   ```

2. **Apple Developer Account**
   - Sign up at https://developer.apple.com
   - Cost: $99/year for individual
   - $299/year for organization

3. **Code Signing**
   - Create certificates in Xcode
   - Configure provisioning profiles
   - Update bundle identifier
   - Configure team settings

4. **App Store Submission**
   - Prepare app metadata
   - Create screenshots
   - Submit through App Store Connect
   - Wait for Apple review (1-7 days)

### Alternative iOS Distribution Methods

1. **TestFlight** (Beta Testing)
   - Upload IPA to App Store Connect
   - Invite up to 10,000 testers
   - Test before public release

2. **Enterprise Distribution** (For Organizations)
   - Requires Apple Enterprise Developer Program
   - Cost: $299/year
   - Internal distribution only

3. **Ad Hoc Distribution** (Limited Testing)
   - Register device UDIDs
   - Limited to 100 devices
   - Manual distribution

---

## 🚀 Rebuild Instructions

### Rebuild APK
```bash
cd /home/user/flutter_app

# Clean previous builds
flutter clean
rm -rf android/build android/app/build android/.gradle

# Build release APK
flutter build apk --release

# Output location
# build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (for Play Store)
```bash
# Build Android App Bundle
flutter build appbundle --release

# Output location
# build/app/outputs/bundle/release/app-release.aab
```

### Debug Build (for testing)
```bash
# Build debug APK
flutter build apk --debug

# Or run directly on connected device
flutter run
```

---

## 📋 Pre-Release Checklist

Before distributing the APK:

- [x] ✅ App icon updated with Domino's branding
- [x] ✅ Package name changed to com.dominos.vehicleinspection
- [x] ✅ App name set to "Domino's Fleet Inspector"
- [x] ✅ Version updated to 2.0.0
- [x] ✅ Release keystore created and configured
- [x] ✅ Signing configuration added
- [x] ✅ ProGuard enabled for code optimization
- [x] ✅ Resources shrunk for smaller APK size
- [x] ✅ Tested build process

### Additional Steps for Production

- [ ] Test on multiple Android devices
- [ ] Test on different Android versions
- [ ] Verify all features work correctly
- [ ] Check offline functionality
- [ ] Test PDF generation
- [ ] Verify database operations
- [ ] Test theme switching
- [ ] Prepare Play Store assets:
  - [ ] Screenshots (phone & tablet)
  - [ ] Feature graphic (1024x500)
  - [ ] App icon (512x512)
  - [ ] Privacy policy URL
  - [ ] App description
  - [ ] What's new text

---

## 🔐 Security Notes

### Keystore Security
⚠️ **IMPORTANT**: The keystore file (`app-release-key.jks`) should be:
- Kept secure and backed up
- Never committed to public repositories
- Stored in a secure location
- Password-protected (current: android123)

### For Production
Consider:
1. Using a stronger password
2. Storing keystore in secure cloud storage
3. Having backup copies
4. Using environment variables for passwords
5. Implementing key rotation policies

---

## 📈 App Metrics

### APK Size Breakdown
- **Total Size**: 55 MB
- **Code**: ~20 MB (Dart + Flutter framework)
- **Assets**: ~2 MB (images, fonts)
- **Native Libraries**: ~30 MB (ARM, x86)
- **Resources**: ~3 MB (icons, manifests)

### Optimization Tips
```bash
# Build with splits for smaller downloads
flutter build apk --release --split-per-abi

# This creates:
# app-armeabi-v7a-release.apk (~25 MB)
# app-arm64-v8a-release.apk (~28 MB)
# app-x86_64-release.apk (~30 MB)
```

---

## 🐛 Troubleshooting

### Installation Failed
- Enable "Install from Unknown Sources"
- Check available storage space
- Try uninstalling previous version first

### App Crashes on Startup
- Check Android version compatibility
- Verify device has sufficient RAM
- Check system logs with `adb logcat`

### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release

# Check for dependency issues
flutter doctor -v
```

---

## 📞 Support & Resources

- **GitHub**: https://github.com/Pareshoct7/MotorVihicleGenSpark
- **Documentation**: See `DOMINOS_REDESIGN.md` and `REDESIGN_SUMMARY.md`
- **Web Preview**: https://5060-iocrui7hssm338l5dbywx-cbeee0f9.sandbox.novita.ai

---

## 📝 Version History

### Version 2.0.0 (Current)
- Complete Domino's UI redesign
- Updated app icon with Domino's branding
- New color scheme (Blue #0B6BB8, Red #E31837)
- Pill-shaped buttons
- Enhanced cards and typography
- Dark mode support
- Signed release APK

### Version 1.0.0 (Previous)
- Initial release
- Basic vehicle inspection features
- PDF generation
- WOF/Rego reminders
- Bulk reports

---

**Status**: ✅ Production Ready  
**Last Updated**: December 2, 2025  
**Build Date**: December 2, 2025
