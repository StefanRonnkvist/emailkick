# EmailKick

EmailKick is a Flutter app for service and support teams that prepare repeatable customer emails. It combines contacts, customer and machine context, order and part details, and message content in one guided composer, then opens the completed draft in the user's preferred mail app.

## Features

- Guided sections: **Sender, Contacts, Coworker, Content, Actions, Information, Help**. Contacts combines recipient company/department information with customer contact and machine records.
- Reusable sender profiles (From Name, From Email, Reply-To, Phone) with save, reset, and remembered history.
- Individual recipient contacts with Name, Position, Phone, and Email fields. Assign each contact to exactly one of **To**, **CC**, or **BCC**; edit or delete contacts in the table.
- Reusable recipient profiles that can be edited or deleted from a saved-values table.
- Customer phone and shipping-address information, saved customer records, and repeatable customer machine records (customer machine name/number, manufacturer machine name, model name, model number, serial number).
- Multiple coworker records (name, email, phone, role), with edit/delete controls. In Content, add the selected customer's email to To and select multiple coworkers for CC.
- Content modes (Expedite Request, Technician on Site, Machine Down, Part Lookup, Quote Part, Ship Immediately) that build an editable subject, and Work Order / Purchase Order fields that build an editable preheader.
- Editable plain-text body, document selection, and **Open Draft in Mail App** to launch a `mailto:` draft. Draft text, contacts and selections are saved as you edit them.
- Local draft restoration and remembered values for frequently used fields, persisted through Hive.
- JSON and CSV import, JSON and CSV backup export, reusable CSV templates, plus a current export path you can copy or open.
- Responsive phone, tablet, and desktop navigation.
- Built-in import/export guidance, contact form, and app-specific support-submission view.

## Typical workflow

1. Enter or select a saved sender profile.
2. In Contacts, add recipient contacts and assign each to To, CC, or BCC. Add customer phone/address and machine details if needed.
3. Add coworker contacts in Coworker. In Content, select a saved customer for To and choose multiple coworkers for CC.
4. Choose content modes, review the generated subject and preheader, and write the plain-text body.
5. Select any supporting documents and open the prepared draft.
6. Review the email and attach the actual files in the mail app before sending.

EmailKick prepares a draft but never sends email automatically. Selected documents are written into the message as file references because the receiving mail app controls attachments. On first use, when the local database is empty, EmailKick opens the **Help** section.

## Data and platforms

- Installed app builds store drafts, profiles, remembered values, and customer machine records locally on the device.
- Web/PWA builds display a notice that database functions are unavailable. Draft and app data are temporary for the current browser session and are not retained after that session ends.
- Exports use the host Downloads folder when available and fall back to the app documents directory.
- **Delete DB Tables** immediately clears all persisted composer data and resets the current UI. Export a backup first when the data must be retained.
- Import accepts EmailKick JSON or CSV data from regular file paths and Android storage providers.

## Tech stack

- Flutter and Dart
- Material 3 UI
- Hive for local persistence
- `url_launcher` for opening drafts
- `file_picker` and `share_plus` for document handling and sharing
- `http` and `package_info_plus` for support requests and app information

## Getting started

1. Install a Flutter SDK compatible with the Dart constraint in `pubspec.yaml`.
2. Fetch dependencies:

```bash
flutter pub get
```

3. Run on an available target:

```bash
flutter run
```

4. Run the project checks:

```bash
flutter analyze
flutter test
```

## Release builds

This workspace includes VS Code tasks in `.vscode/tasks.json` for common release builds:

- Build Release APK
- Build Release App Bundle
- Build Release Web
- Build Release Windows
- Build Release MSIX (runs Build Release Windows first)
- Build All Release Targets (default build task: precleans Android release locks, bumps the version, then builds every target above)
- Google Store (updates packages, bumps the version, then runs Build All Release Targets)
- Flutter: Version Bump (runs `scripts/bump-version.ps1`)

Equivalent Flutter commands are:

```bash
flutter build apk --release
flutter build appbundle --release
flutter build web --release
flutter build windows --release
dart run msix:create --build-windows=false
```

## Project structure

- `lib/main.dart`: app bootstrap and initialization.
- `lib/app/`: app shell, theme, splash screen, and web database notice.
- `lib/core/storage/app_db.dart`: Hive-backed local storage wrapper (re-exported by `lib/data/app_db.dart`).
- `lib/features/email_composer/presentation/`: the full email composer workflow and UI.
- `lib/data/contact/`: support contact and submission views.
- `store_listing/short_description.txt`: short Google Play description.
- `store_listing/long_description.txt`: detailed Google Play description.
- `test/`: Flutter widget and behavior tests.
- `scripts/` and `tool/`: release, versioning, cleanup, and dependency utilities.

## Notes

- The contact form sends the entered request and app version information to the configured support endpoint.
- The support-submission view loads records from the configured remote CSV feed and filters them for this app package.
- Store-facing copy lives in `store_listing/`; release automation is responsible for publishing it.
