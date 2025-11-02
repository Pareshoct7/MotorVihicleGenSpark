# Motor Vehicle Inspection App

A comprehensive Flutter application for managing motor vehicle inspections with PDF generation, WOF/Rego reminders, and advanced reporting features.

## 🚀 Features

### Core Inspection Features
- ✅ **Complete Digital Inspection Form** - All checklist items from your original PDF form
- ✅ **PDF Generation** - Professional PDF reports matching your form layout
- ✅ **PDF Sharing** - Share via email, WhatsApp, or any app
- ✅ **All Checkboxes Pre-checked** - Saves time on routine inspections
- ✅ **Repeat Inspection** - Quickly create new inspection from previous one

### Bulk Operations
- 📊 **Bulk Backdated Reports Generator**
  - Generate 1-50 inspection reports at once
  - Evenly distributed across date range
  - Odometer automatically decreases for past dates (realistic historical data)
  - Optional bulk PDF generation

### Reminders & Notifications
- 🔔 **WOF & Rego Reminders**
  - Color-coded alerts (expired, expiring soon, upcoming)
  - Days remaining display
  - Custom notification settings per vehicle
  - Notification presets: 1 day, 1 week, 30 days before expiry
  - Custom date picker for specific notification dates

### Reports & Analytics
- 📈 **Advanced Filtering**
  - Filter by vehicle, store, driver, or date range
  - Real-time results count
  - Generate PDFs for filtered results
  - Export and share reports

### Management
- 🚗 **Vehicle Management** - Track vehicles with WOF/Rego dates
- 🏪 **Store Management** - Manage multiple store locations
- 👤 **Driver Management** - Track employees/drivers
- ⚙️ **Settings** - Set default vehicle, store, and driver for new inspections

### Navigation
- 📱 **Drawer Menu** - Easy access to all features
- 🏠 **Dashboard** - Quick stats and alerts
- 🎨 **Modern Material Design 3** UI

## 📱 Screenshots

(Add screenshots here)

## 🛠️ Technical Stack

- **Framework**: Flutter 3.35.4
- **Language**: Dart 3.9.2
- **State Management**: Provider
- **Local Database**: Hive (document storage)
- **PDF Generation**: pdf & printing packages
- **Storage**: shared_preferences (settings)

## 📦 Installation

### Prerequisites
- Flutter SDK 3.35.4 or higher
- Dart 3.9.2 or higher
- Android Studio / Xcode (for mobile deployment)

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/Pareshoct7/MotorVihicleGenSpark.git
cd MotorVihicleGenSpark
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Generate Hive adapters**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. **Run the app**
```bash
# For web
flutter run -d chrome

# For Android
flutter run -d android

# For iOS
flutter run -d ios
```

## 🏗️ Build for Production

### Web
```bash
flutter build web --release
```

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 📂 Project Structure

```
lib/
├── models/              # Data models (Vehicle, Store, Driver, Inspection)
│   ├── vehicle.dart
│   ├── store.dart
│   ├── driver.dart
│   ├── inspection.dart
│   └── notification_settings.dart
├── screens/             # UI screens
│   ├── home_screen.dart
│   ├── inspection_form_screen.dart
│   ├── inspection_history_screen.dart
│   ├── bulk_reports_screen.dart
│   ├── reports_screen.dart
│   ├── reminders_screen.dart
│   ├── notification_settings_screen.dart
│   ├── vehicles_screen.dart
│   ├── stores_screen.dart
│   ├── drivers_screen.dart
│   └── settings_screen.dart
├── services/            # Business logic and services
│   ├── database_service.dart
│   ├── pdf_service.dart
│   └── preferences_service.dart
└── main.dart           # App entry point
```

## 🔧 Configuration

### Default Settings
Set default values for new inspections:
1. Open the app
2. Go to Settings (gear icon or drawer menu)
3. Select default vehicle, store, and driver
4. These will be pre-selected in new inspections

### Notification Settings
Configure WOF/Rego reminders per vehicle:
1. Go to "WOF & Rego Reminders"
2. Find your vehicle
3. Click the 🔔 notification icon
4. Choose notification timeframe (1 day, 1 week, 30 days, or custom)

## 📖 Usage Guide

### Creating a New Inspection
1. Click "New Inspection" from home or drawer menu
2. Select vehicle, store, and employee (or use defaults)
3. Enter odometer reading and date
4. Review pre-checked items (uncheck if issues found)
5. Add corrective actions if needed
6. Sign off and save
7. Generate PDF to share or print

### Generating Bulk Reports
1. Go to "Bulk Reports Generator"
2. Select vehicle, store, and driver
3. Choose date range (start and end dates)
4. Enter number of reports (1-50)
5. Enter current odometer reading
6. Generate reports (odometer decreases automatically for past dates)
7. Optionally generate PDFs for all reports

### Repeat Inspection
1. Go to "Inspection History"
2. Find the inspection you want to repeat
3. Click 3-dot menu → "Repeat Inspection"
4. Vehicle, store, and driver are pre-selected
5. Just enter new odometer and save

### Viewing Reports
1. Go to "Reports & Analytics"
2. Apply filters (vehicle, store, driver, date range)
3. View filtered results
4. Generate PDFs for selected reports
5. Share or save PDFs

## 🔐 Data Storage

All data is stored locally on the device using Hive database:
- No internet connection required
- Fast and efficient
- Data persists across app restarts
- Settings stored with shared_preferences

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Version History

### v1.0.0 (Current)
- Initial release with all core features
- Complete inspection form with PDF generation
- Bulk backdated reports generator (odometer decreases correctly)
- Repeat inspection feature
- Custom notification settings for WOF & Rego
- Advanced filtering and reporting
- Default selections for quick inspections
- PDF sharing via email and apps

## 🐛 Known Issues

None currently. Please report issues on GitHub Issues page.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- **Paresh** - Initial work - [Pareshoct7](https://github.com/Pareshoct7)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Hive for fast local database
- pdf & printing packages for PDF generation
- Material Design 3 for beautiful UI components

## 📞 Support

For support, email or open an issue on GitHub.

## 🔮 Future Enhancements

Planned features for future versions:
- Cloud backup and sync
- Multi-user support
- Advanced analytics and charts
- Export to Excel/CSV
- Email notifications for reminders
- Integration with fleet management systems
- Photo attachments for damage documentation
- QR code scanning for vehicle identification

---

**Made with ❤️ using Flutter**
