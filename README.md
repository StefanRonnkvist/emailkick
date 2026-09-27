# EmailKick

EmailKick is a Flutter app for service and support teams that prepare repeatable customer emails. It combines contacts, customer and machine context, order and part details, and message content in one guided composer, then opens the completed draft in the user's preferred mail app.

## Features

- Guided sections for sender, recipients, customer, coworker, content, data actions, information, and help.
- Reusable sender, recipient, and customer profiles with customer machine records.
- Local draft restoration and remembered values for frequently used fields.
- To, Cc, and Bcc recipient lists with validation before the draft is opened.
- Service content modes that build an editable subject and order fields that build an editable preheader.
- JSON and CSV import, JSON and CSV backup export, and reusable CSV templates.
- Responsive phone, tablet, and desktop navigation.
- Built-in import and export guidance, contact form, and app-specific support-submission view.

## Typical workflow

1. Enter or select a saved sender profile.
2. Add To, Cc, and Bcc recipients.
3. Add optional customer, coworker, machine, order, and part context.
4. Choose content modes, review the generated subject and preheader, and write the plain-text body.
5. Select any supporting documents and open the prepared draft.
6. Review the email and attach the actual files in the mail app before sending.

EmailKick prepares a draft but never sends email automatically. Selected documents are written into the message as file references because the receiving mail app controls attachments.

## Data and platforms

- Installed app builds store drafts, profiles, remembered values, and customer machine records locally on the device.
- Web builds use temporary in-memory data for the current browser session; persistent database features are unavailable.
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

This workspace includes VS Code tasks for common release builds:

- Build APK (release)
- Build AppBundle (release)
- Build Web (release)
- Build Windows (release)
- Build MSIX (release)
- Build All Release Targets

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
- `lib/app/`: app shell and shared UI setup.
- `lib/core/storage/app_db.dart`: Hive-backed local storage wrapper.
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
