# Changelog

All notable changes to the Motor Vehicle Inspection App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-11-02

### Added
- ✨ Complete digital inspection form matching original PDF layout
- ✨ Professional PDF generation with all inspection details
- ✨ PDF sharing functionality (email, WhatsApp, other apps)
- ✨ All inspection checkboxes pre-checked by default for efficiency
- ✨ Bulk backdated reports generator (1-50 reports at once)
- ✨ Intelligent odometer calculation (decreases for past dates)
- ✨ Repeat inspection feature (copy vehicle/store/driver from previous inspection)
- ✨ Custom notification settings per vehicle
- ✨ Notification presets (1 day, 1 week, 30 days, custom date)
- ✨ WOF & Rego reminders with color-coded alerts
- ✨ Advanced reports filtering (vehicle, store, driver, date range)
- ✨ Bulk PDF generation for filtered reports
- ✨ Vehicle management with WOF/Rego tracking
- ✨ Store management
- ✨ Driver/Employee management
- ✨ Settings screen for default selections
- ✨ Navigation drawer menu for easy access
- ✨ Dashboard with quick stats and alerts
- ✨ Local data persistence using Hive database
- ✨ Material Design 3 modern UI

### Features in Detail

#### Inspection Management
- Complete checklist: Tyres, Outside, Mechanical, Electrical, Cab
- Odometer reading tracking
- Corrective actions notes field
- Digital signature capture
- Inspection history with search
- Edit and delete capabilities
- View-only mode for reviewing past inspections

#### Bulk Operations
- Generate multiple inspections with evenly distributed dates
- Automatic odometer calculation (decreases going backward in time)
- Pre-fill all inspection items as passed
- Optional bulk PDF generation after creation
- Configurable date range and report count

#### Reminders System
- Tracks WOF expiry dates
- Tracks Registration expiry dates
- Visual alerts: Red (expired), Orange (expiring soon), Green (upcoming)
- Shows days remaining until expiry
- 30-day warning threshold
- Individual notification settings per vehicle
- Custom notification scheduling

#### Reports & Analytics
- Filter by vehicle, store, driver
- Date range filtering
- Real-time results count
- Single or bulk PDF generation
- Share and export capabilities

#### Settings
- Set default vehicle for new inspections
- Set default store for new inspections
- Set default driver for new inspections
- Persistent across app sessions

### Technical Details
- Flutter 3.35.4
- Dart 3.9.2
- Hive 2.2.3 for local database
- Provider 6.1.5+1 for state management
- PDF 3.11.1 for PDF generation
- Printing 5.13.3 for PDF sharing
- shared_preferences 2.5.3 for settings

### Fixed
- N/A (Initial release)

### Changed
- N/A (Initial release)

### Deprecated
- N/A (Initial release)

### Removed
- N/A (Initial release)

### Security
- All data stored locally on device
- No external data transmission
- No user accounts or authentication required

---

## [Unreleased]

### Planned Features
- Cloud backup and synchronization
- Email notifications for WOF/Rego reminders
- Photo attachments for damage documentation
- QR code scanning for vehicle identification
- Export to Excel/CSV format
- Advanced analytics with charts
- Multi-user support with roles
- Integration with fleet management systems
- Offline mode indicator
- Data export/import functionality

---

## Version History Template

```
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```
