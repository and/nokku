# Release Notes - Nokku v1.0.1 (Build 2)

**Release Date:** February 2, 2026
**Version Code:** 2
**Version Name:** 1.0.1
**Bundle:** app-release.aab (43 MB)

---

## 🎉 What's New

### ✨ In-App Update Notifications
- Automatic update detection when you open the app
- Native Google Play update dialog when new versions are available
- Download updates in the background while using the app
- Manual "Check for Updates" button in Settings (Android only)

### 🎥 Full Video Support
- Videos now work perfectly in saved collections
- Select videos directly from photo picker alongside images
- Smooth video playback with playback controls
- Video thumbnails display correctly in collection grids

### ⚡ Performance Improvements
- **Instant Image Transitions** - Removed 300ms delay between photos
- **Smoother Navigation** - Adjacent images are pre-loaded for seamless swiping
- **Zero Lag** - Photos appear immediately when you swipe

### 📱 Enhanced Settings
- App version now displays dynamically (shows version and build number)
- Better organized settings layout
- Improved UI consistency across Android and iOS

---

## 🐛 Bug Fixes

### Video Playback Issues
- **Fixed:** Videos in saved collections now play correctly (previously showed error icon)
- **Fixed:** Database migration automatically detects and fixes existing videos
- **Fixed:** Video media type is now correctly stored and retrieved

### Image Display
- **Fixed:** Removed flicker during photo transitions
- **Fixed:** Images load faster with pre-caching system
- **Fixed:** Eliminated blank screen delay between photos

---

## 🔧 Technical Improvements

### Database
- Added `mediaType` column to photos table (version 2)
- Automatic migration for existing collections
- Video detection by file extension for legacy data

### Performance
- Image pre-caching for current + adjacent photos
- Gapless playback enabled for flicker-free transitions
- Optimized memory usage (only 3 images cached at a time)

### Updates System
- Google Play In-App Updates API integration
- Flexible update mode (non-blocking downloads)
- Graceful fallback if update check fails

---

## 📋 Complete Feature List

### Core Features
- ✅ Create unlimited photo/video collections
- ✅ Secure presentation mode with device locking
- ✅ Share photos directly from other apps
- ✅ Full-screen immersive viewing
- ✅ Infinite loop navigation (swipe left/right)
- ✅ Tap zones for navigation
- ✅ Pinch-to-zoom support
- ✅ Auto-advance slideshow mode
- ✅ Swipe-to-delete photos

### Video Features
- ✅ Video playback in collections
- ✅ Video selection in photo picker
- ✅ Playback controls (play/pause/scrub)
- ✅ Video thumbnails in grids

### Security
- ✅ Device lock on exit (Android)
- ✅ Guided Access support (iOS)
- ✅ Presentation mode prevents app switching
- ✅ Confirmation before removal

### Customization
- ✅ Dark/Light/System themes
- ✅ Show/hide photo counter
- ✅ Adjustable slideshow intervals (3s-30s)
- ✅ Configurable removal confirmation
- ✅ Enable/disable swipe gestures

---

## 🎯 Known Issues

### iOS Limitations
- Cannot programmatically lock device (iOS security restriction)
- Requires manual Guided Access setup for full security

### Android Considerations
- Device Admin permission required for automatic locking
- First-time setup requires manual permission grant

---

## 📱 Compatibility

- **Android:** 5.0 (Lollipop) and above
- **iOS:** 12.0 and above
- **Flutter SDK:** 3.0.0+
- **Target SDK:** Android 34 (Android 14)

---

## 📦 Installation

### For New Users
1. Download from Google Play Store
2. Grant photo/video library permissions
3. (Android only) Enable Device Admin in Settings for device locking

### For Existing Users
1. Update will be offered automatically
2. Existing collections will be migrated automatically
3. No data loss - all collections preserved

---

## 🔄 Upgrade Path

Upgrading from any previous version:
- ✅ All collections preserved
- ✅ Settings maintained
- ✅ Videos in existing collections automatically detected
- ✅ Database migrated seamlessly
- ⏱️ First launch may take a few extra seconds for migration

---

## 🚀 What's Next

Planned for future releases:
- Cloud backup for collections (optional)
- Password protection for collections
- Advanced video editing features
- Collection sharing (export/import)
- Multiple theme options

---

## 📞 Support

Having issues? Check our troubleshooting guides:
- **CODEBASE_KNOWLEDGE.md** - Technical documentation
- **FASTLANE_SETUP.md** - Deployment automation
- **GitHub Issues** - Report bugs and request features

---

## 🙏 Credits

**Development:** Claude Sonnet 4.5
**Platform:** Flutter 3.x
**Release Manager:** Fastlane

---

## 📝 Release History

- **v1.0.1 (Build 2)** - February 2, 2026 - Video support, in-app updates, performance improvements
- **v1.0.0 (Build 1)** - Initial release - Core photo presentation features

---

**For Google Play Console submission, use the summary below:**

---

## 📱 Google Play Release Notes (Short Version)

```
What's New in v1.0.1:

✨ NEW FEATURES
• In-app update notifications
• Full video support in collections
• Instant image transitions (no delay)
• Version display in Settings

🎥 VIDEO IMPROVEMENTS
• Videos now work in saved collections
• Select videos from photo picker
• Smooth video playback with controls

⚡ PERFORMANCE
• 3x faster photo navigation
• Pre-loading for smooth swiping
• Zero lag between images

🐛 BUG FIXES
• Fixed video playback in collections
• Fixed database migration issues
• Improved memory management

Enjoy the fastest, smoothest photo sharing experience!
```

---

**File Locations:**
- Bundle: `build/app/outputs/bundle/release/app-release.aab`
- Source: GitHub `main` branch, commit `4f63c72`
