// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

/// Handles file transfer and persistence for the email composer state.
extension _EmailComposerDataState on _EmailComposerPageState {
  /// Writes an export, shares it on Android, and reports the final path.
  Future<void> _exportTextFile({
    required String fileName,
    required String content,
    required String successMessage,
  }) async {
    late final File file;
    try {
      file = await _writeExportFile(fileName, content);
    } on FileSystemException catch (error) {
      if (!mounted) {
        return;
      }
      final String message = error.message.isEmpty
          ? 'Could not write export file.'
          : error.message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $message')));
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
      return;
    }

    if (Platform.isAndroid) {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(file.path)],
          title: fileName,
          text: 'Exported from eMail Kick: ${file.uri.pathSegments.last}',
        ),
      );
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$successMessage Saved to ${file.path}')),
    );
  }

  /// Returns the app export folder under the best available downloads path.
  Future<Directory> _exportDirectory() async {
    final Directory baseDir = await _hostDownloadsDirectory();
    final Directory exportDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}emailkick_exports',
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Writes a sanitized export filename, falling back to app documents.
  Future<File> _writeExportFile(
    String fileName,
    String content, {
    bool includeTimestamp = true,
  }) async {
    final String ext = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '';
    final String stem = fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final String safeStem = stem.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final String finalName = includeTimestamp
        ? '${safeStem}_${DateTime.now().millisecondsSinceEpoch}$ext'
        : '$safeStem$ext';

    try {
      final Directory exportDir = await _exportDirectory();
      final String exportPath =
          '${exportDir.path}${Platform.pathSeparator}$finalName';
      final File file = File(exportPath);
      return await file.writeAsString(content);
    } on FileSystemException {
      final Directory fallbackDir = await _fallbackExportDirectory();
      final String fallbackPath =
          '${fallbackDir.path}${Platform.pathSeparator}$finalName';
      final File file = File(fallbackPath);
      return await file.writeAsString(content);
    }
  }

  /// Creates the private export folder used when downloads is not writable.
  Future<Directory> _fallbackExportDirectory() async {
    final Directory appDocsDir = await getApplicationDocumentsDirectory();
    final Directory exportDir = Directory(
      '${appDocsDir.path}${Platform.pathSeparator}emailkick_exports',
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Resolves the host downloads directory with platform-safe fallbacks.
  Future<Directory> _hostDownloadsDirectory() async {
    if (Platform.isAndroid) {
      for (final String path in <String>[
        '/storage/emulated/0/Download',
        '/sdcard/Download',
      ]) {
        final Directory dir = Directory(path);
        if (await dir.exists()) {
          return dir;
        }
      }

      final Directory? externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final int androidIndex = externalDir.path.indexOf('/Android/');
        if (androidIndex > 0) {
          final String rootPath = externalDir.path.substring(0, androidIndex);
          final Directory downloadDir = Directory(
            '$rootPath${Platform.pathSeparator}Download',
          );
          if (await downloadDir.exists()) {
            return downloadDir;
          }
        }
      }
    }

    final Directory? downloads = await getDownloadsDirectory();
    if (downloads != null) {
      return downloads;
    }

    return getApplicationDocumentsDirectory();
  }

  /// Opens the export folder or copies its path when no handler is available.
  Future<void> _openExportFolder() async {
    final Directory exportDir = await _exportDirectory();
    bool opened = false;

    if (Platform.isAndroid) {
      opened = await _openAndroidExportFolder(exportDir.path);
    }

    if (!opened) {
      final Uri folderUri = Uri.directory(exportDir.path);
      try {
        opened = await launchUrl(
          folderUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        opened = false;
      }
    }

    if (!opened && Platform.isAndroid) {
      opened = await _openAndroidDownloadsFolder();
    }

    if (!opened) {
      final Uri downloadsUri = Uri.parse(
        'content://downloads/public_downloads',
      );
      try {
        opened = await launchUrl(
          downloadsUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        opened = false;
      }
    }

    if (!mounted) {
      return;
    }

    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opened export folder: ${exportDir.path}')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: exportDir.path));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Could not open folder automatically. Path copied: ${exportDir.path}',
        ),
      ),
    );
  }

  /// Tries Android document-provider URIs for a specific export folder.
  Future<bool> _openAndroidExportFolder(String folderPath) async {
    final List<String> candidateUris = <String>[];
    final String normalized = folderPath.replaceAll('\\', '/');
    const String primaryRoot = '/storage/emulated/0/';

    if (normalized.startsWith(primaryRoot)) {
      final String relativePath = normalized.substring(primaryRoot.length);
      if (relativePath.isNotEmpty) {
        final String docId = Uri.encodeComponent('primary:$relativePath');
        candidateUris.add(
          'content://com.android.externalstorage.documents/document/$docId',
        );

        final String treeRoot = Uri.encodeComponent('primary:Download');
        candidateUris.add(
          'content://com.android.externalstorage.documents/tree/$treeRoot/document/$docId',
        );
      }
    }

    for (final String uri in candidateUris) {
      try {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: uri,
        );
        await intent.launch();
        return true;
      } catch (_) {}
    }

    return false;
  }

  /// Tries known Android document-provider URIs for the Downloads folder.
  Future<bool> _openAndroidDownloadsFolder() async {
    final List<String> downloadUris = <String>[
      'content://com.android.externalstorage.documents/document/${Uri.encodeComponent('primary:Download')}',
      'content://com.android.externalstorage.documents/tree/${Uri.encodeComponent('primary:Download')}',
      'content://downloads/public_downloads',
    ];

    for (final String uri in downloadUris) {
      try {
        final AndroidIntent intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: uri,
        );
        await intent.launch();
        return true;
      } catch (_) {}
    }

    return false;
  }

  List<String> get _allDbKeys => <String>[
    _fromNameKey,
    _fromEmailKey,
    _replyToKey,
    _phoneKey,
    _companyOptionsKey,
    _departmentOptionsKey,
    _toOptionsKey,
    _ccOptionsKey,
    _bccOptionsKey,
    _workOrderOptionsKey,
    _purchaseOrderOptionsKey,
    _partNumberOptionsKey,
    _partDescriptionOptionsKey,
    _subjectOptionsKey,
    _preheaderOptionsKey,
    _plainTextBodyOptionsKey,
    _senderProfilesKey,
    _recipientProfilesKey,
    _customerProfilesKey,
    _customerEntriesKey,
    _draftStateKey,
  ];

  /// Deletes all persisted composer data and resets its in-memory UI state.
  Future<void> _deleteDbTables() async {
    for (final String key in _allDbKeys) {
      await AppDb.instance.remove(key);
    }

    for (final TextEditingController controller in <TextEditingController>[
      _fromNameController,
      _fromEmailController,
      _replyToController,
      _phoneController,
      _toController,
      _ccController,
      _bccController,
      _recipientNameController,
      _recipientPositionController,
      _recipientPhoneController,
      _recipientEmailController,
      _companyController,
      _departmentController,
      _customerNameController,
      _customerEmailController,
      _customerPhoneController,
      _customerShippingAddressController,
      _workOrderController,
      _purchaseOrderController,
      _partNumberController,
      _partDescriptionController,
      _subjectController,
      _preheaderController,
      _plainTextBodyController,
      _contentRecipientSelectorController,
      _contentCustomerSelectorController,
      _contentMachineSelectorController,
    ]) {
      controller.clear();
    }

    for (final _CustomerMachineEntry machine in _customerMachines) {
      _unbindMachineDraftListeners(machine);
      machine.dispose();
    }
    _unbindCoworkerDraftListeners();
    for (final _CoworkerEntry coworker in _coworkers) {
      coworker.dispose();
    }

    setState(() {
      _coworkers
        ..clear()
        ..add(_CoworkerEntry());
      _bindCoworkerDraftListeners();
      final _CustomerMachineEntry initialMachine = _CustomerMachineEntry();
      _bindMachineDraftListeners(initialMachine);
      _customerMachines
        ..clear()
        ..add(initialMachine);
      _senderNameOptions = <String>[];
      _senderEmailOptions = <String>[];
      _replyToOptions = <String>[];
      _senderPhoneOptions = <String>[];
      _companyOptions = <String>[];
      _departmentOptions = <String>[];
      _toOptions = <String>[];
      _ccOptions = <String>[];
      _bccOptions = <String>[];
      _customerPhoneOptions = <String>[];
      _customerAddressOptions = <String>[];
      _workOrderOptions = <String>[];
      _purchaseOrderOptions = <String>[];
      _partNumberOptions = <String>[];
      _partDescriptionOptions = <String>[];
      _subjectOptions = <String>[];
      _preheaderOptions = <String>[];
      _plainTextBodyOptions = <String>[];
      _senderProfiles = <_SenderProfile>[];
      _recipientProfiles = <_RecipientProfile>[];
      _recipientContacts.clear();
      _editingRecipientContact = null;
      _recipientNameController.clear();
      _recipientPositionController.clear();
      _recipientPhoneController.clear();
      _recipientEmailController.clear();
      _recipientContactType = 'to';
      _customerProfiles = <_CustomerProfile>[];
      _savedCustomerEntries = <_SavedCustomerEntry>[];
      _selectedContentModes.clear();
      _selectedDocuments.clear();
      _selectedContentCustomer = null;
      _selectedContentCustomerMachines = <_SavedCustomerMachine>[];
      _selectedCoworkerCcEmails.clear();
      _isCustomerToTableExpanded = false;
      _isCoworkerCcTableExpanded = false;
      _selectedCustomerToEmail = null;
      _editingRecipientProfile = null;
      _isSenderCollapsed = false;
    });

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('DB tables deleted.')));
  }

  /// Picks a JSON or CSV backup, imports it, then refreshes all UI state.
  Future<void> _importDbData() async {
    final PlatformFile? selected = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: <String>['json', 'csv'],
    );
    if (selected == null) {
      return;
    }
    final String? path = selected.path;

    String raw;
    if (path != null && path.isNotEmpty) {
      final File file = File(path);
      if (!await file.exists()) {
        return;
      }
      raw = await file.readAsString();
    } else {
      final List<int> bytes = await selected.readAsBytes();
      raw = utf8.decode(bytes, allowMalformed: true);
    }

    if (raw.isEmpty) {
      return;
    }

    final String lower = (path ?? selected.name).toLowerCase();
    if (lower.endsWith('.json')) {
      await _importFromJson(raw);
    } else {
      await _importFromCsv(raw);
    }

    await _restoreAllState();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Data imported.')));
  }

  /// Exports sender setup, profiles, entries, and options as structured JSON.
  Future<void> _exportJsonData() async {
    final Map<String, dynamic> data = <String, dynamic>{
      'senderSetup': <String, String>{
        'fromName': _fromNameController.text.trim(),
        'fromEmail': _fromEmailController.text.trim(),
        'replyTo': _replyToController.text.trim(),
        'phone': _phoneController.text.trim(),
      },
      'senderProfiles': _senderProfiles
          .map((_SenderProfile p) => p.toStorageString())
          .toList(),
      'recipientProfiles': _recipientProfiles
          .map((_RecipientProfile p) => p.toStorageString())
          .toList(),
      'customerProfiles': _customerProfiles
          .map((_CustomerProfile p) => p.toStorageString())
          .toList(),
      'customerEntries': _savedCustomerEntries
          .map((_SavedCustomerEntry e) => e.toStorageString())
          .toList(),
      'options': <String, List<String>>{
        'company': _companyOptions,
        'department': _departmentOptions,
        'to': _toOptions,
        'cc': _ccOptions,
        'bcc': _bccOptions,
        'workOrder': _workOrderOptions,
        'purchaseOrder': _purchaseOrderOptions,
        'partNumber': _partNumberOptions,
        'partDescription': _partDescriptionOptions,
        'subject': _subjectOptions,
        'preheader': _preheaderOptions,
        'plainTextBody': _plainTextBodyOptions,
      },
    };

    await _exportTextFile(
      fileName: 'emailkick_export.json',
      content: const JsonEncoder.withIndent('  ').convert(data),
      successMessage: 'JSON data exported.',
    );
  }

  /// Exports profile history as typed rows in one RFC 4180-compatible CSV.
  Future<void> _exportCsvData() async {
    final StringBuffer csv = StringBuffer();
    csv.writeln(
      'table,fromName,fromEmail,replyTo,phone,company,department,to,cc,bcc,name,email,shippingAddress,machinesJson',
    );

    for (final _SenderProfile p in _senderProfiles) {
      csv.writeln(
        _csvRow(<String>[
          'sender_profile',
          p.fromName,
          p.fromEmail,
          p.replyTo,
          p.phone,
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
        ]),
      );
    }

    for (final _RecipientProfile p in _recipientProfiles) {
      csv.writeln(
        _csvRow(<String>[
          'recipient_profile',
          '',
          '',
          '',
          '',
          p.company,
          p.department,
          p.to,
          p.cc,
          p.bcc,
          '',
          '',
          '',
          '',
        ]),
      );
    }

    for (final _SavedCustomerEntry e in _savedCustomerEntries) {
      csv.writeln(
        _csvRow(<String>[
          'customer_entry',
          '',
          '',
          '',
          e.phone,
          '',
          '',
          '',
          '',
          '',
          e.name,
          e.email,
          e.shippingAddress,
          jsonEncode(
            e.machines.map((_SavedCustomerMachine m) => m.toMap()).toList(),
          ),
        ]),
      );
    }

    await _exportTextFile(
      fileName: 'emailkick_export.csv',
      content: csv.toString(),
      successMessage: 'CSV data exported.',
    );
  }

  /// Writes reusable CSV headers without timestamping their filenames.
  Future<void> _exportCsvTemplates() async {
    late final List<File> files;
    try {
      files = <File>[
        await _writeExportFile(
          'sender_template.csv',
          'fromName,fromEmail,replyTo,phone\n',
          includeTimestamp: false,
        ),
        await _writeExportFile(
          'recipients_template.csv',
          'company,department,to,cc,bcc\n',
          includeTimestamp: false,
        ),
        await _writeExportFile(
          'customer_template.csv',
          'name,email,phone,shippingAddress,customerMachineName,machineNumber,manufacturerMachineName,modelName,modelNumber,serialNumber\n',
          includeTimestamp: false,
        ),
      ];
    } on FileSystemException catch (error) {
      if (!mounted) {
        return;
      }
      final String message = error.message.isEmpty
          ? 'Could not write CSV template files.'
          : error.message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template export failed: $message')),
      );
      return;
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Template export failed: $error')));
      return;
    }

    if (Platform.isAndroid) {
      await SharePlus.instance.share(
        ShareParams(
          files: files.map((File file) => XFile(file.path)).toList(),
          title: 'Export CSV Templates',
          text: 'CSV templates exported from eMail Kick.',
        ),
      );
    }

    final Directory exportDir = files.first.parent;
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV templates exported to ${exportDir.path}.')),
    );
  }

  /// Replaces persisted data with supported, correctly typed JSON fields.
  Future<void> _importFromJson(String raw) async {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final Map<String, dynamic> sender =
        (decoded['senderSetup'] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    await AppDb.instance.setString(
      _fromNameKey,
      (sender['fromName'] as String? ?? '').trim(),
    );
    await AppDb.instance.setString(
      _fromEmailKey,
      (sender['fromEmail'] as String? ?? '').trim(),
    );
    await AppDb.instance.setString(
      _replyToKey,
      (sender['replyTo'] as String? ?? '').trim(),
    );
    await AppDb.instance.setString(
      _phoneKey,
      (sender['phone'] as String? ?? '').trim(),
    );

    final List<String> senderProfiles =
        (decoded['senderProfiles'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList();
    final List<String> recipientProfiles =
        (decoded['recipientProfiles'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList();
    final List<String> customerProfiles =
        (decoded['customerProfiles'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList();
    final List<String> customerEntries =
        (decoded['customerEntries'] as List<dynamic>? ?? <dynamic>[])
            .whereType<String>()
            .toList();

    await AppDb.instance.setStringList(_senderProfilesKey, senderProfiles);
    await AppDb.instance.setStringList(
      _recipientProfilesKey,
      recipientProfiles,
    );
    await AppDb.instance.setStringList(_customerProfilesKey, customerProfiles);
    await AppDb.instance.setStringList(_customerEntriesKey, customerEntries);

    final Map<String, dynamic> options =
        (decoded['options'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    await AppDb.instance.setStringList(
      _companyOptionsKey,
      (options['company'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _departmentOptionsKey,
      (options['department'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _toOptionsKey,
      (options['to'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _ccOptionsKey,
      (options['cc'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _bccOptionsKey,
      (options['bcc'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _workOrderOptionsKey,
      (options['workOrder'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _purchaseOrderOptionsKey,
      (options['purchaseOrder'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _partNumberOptionsKey,
      (options['partNumber'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _partDescriptionOptionsKey,
      (options['partDescription'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _subjectOptionsKey,
      (options['subject'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _preheaderOptionsKey,
      (options['preheader'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
    await AppDb.instance.setStringList(
      _plainTextBodyOptionsKey,
      (options['plainTextBody'] as List<dynamic>? ?? <dynamic>[])
          .whereType<String>()
          .toList(),
    );
  }

  /// Reconstructs profile records from the typed rows produced by the exporter.
  Future<void> _importFromCsv(String raw) async {
    final List<List<String>> rows = _parseCsv(raw);
    if (rows.length <= 1) {
      return;
    }

    final List<String> senderProfiles = <String>[];
    final List<String> recipientProfiles = <String>[];
    final List<String> customerEntries = <String>[];

    for (int i = 1; i < rows.length; i++) {
      final List<String> row = rows[i];
      if (row.isEmpty) {
        continue;
      }
      final String table = row[0].trim().toLowerCase();
      if (table == 'sender_profile' && row.length >= 5) {
        final _SenderProfile p = _SenderProfile(
          fromName: row[1].trim(),
          fromEmail: row[2].trim(),
          replyTo: row[3].trim(),
          phone: row[4].trim(),
        );
        if (p.hasData) {
          senderProfiles.add(p.toStorageString());
        }
      } else if (table == 'recipient_profile' && row.length >= 10) {
        final _RecipientProfile p = _RecipientProfile(
          company: row[5].trim(),
          department: row[6].trim(),
          to: row[7].trim(),
          cc: row[8].trim(),
          bcc: row[9].trim(),
        );
        if (p.hasData) {
          recipientProfiles.add(p.toStorageString());
        }
      } else if (table == 'customer_entry' && row.length >= 14) {
        final List<_SavedCustomerMachine> machines = <_SavedCustomerMachine>[];
        final String machinesRaw = row[13].trim();
        if (machinesRaw.isNotEmpty) {
          try {
            final Object? decoded = jsonDecode(machinesRaw);
            if (decoded is List) {
              for (final dynamic item in decoded) {
                if (item is Map) {
                  final _SavedCustomerMachine? m =
                      _SavedCustomerMachine.fromMap(item);
                  if (m != null) {
                    machines.add(m);
                  }
                }
              }
            }
          } catch (_) {}
        }
        final _SavedCustomerEntry e = _SavedCustomerEntry(
          name: row[10].trim(),
          email: row[11].trim(),
          phone: row[4].trim(),
          shippingAddress: row[12].trim(),
          machines: machines,
        );
        if (e.hasData) {
          customerEntries.add(e.toStorageString());
        }
      }
    }

    await AppDb.instance.setStringList(_senderProfilesKey, senderProfiles);
    await AppDb.instance.setStringList(
      _recipientProfilesKey,
      recipientProfiles,
    );
    await AppDb.instance.setStringList(_customerEntriesKey, customerEntries);
  }

  /// Encodes one CSV row using [_csvEscape] for every field.
  String _csvRow(List<String> fields) {
    return fields.map(_csvEscape).join(',');
  }

  /// Quotes values containing delimiters and doubles embedded quote marks.
  String _csvEscape(String value) {
    final String escaped = value.replaceAll('"', '""');
    if (escaped.contains(',') ||
        escaped.contains('"') ||
        escaped.contains('\n')) {
      return '"$escaped"';
    }
    return escaped;
  }

  /// Parses quoted CSV fields, escaped quotes, and either CRLF or LF endings.
  List<List<String>> _parseCsv(String text) {
    final List<List<String>> rows = <List<String>>[];
    List<String> row = <String>[];
    final StringBuffer cell = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < text.length; i++) {
      final String char = text[i];
      if (inQuotes) {
        if (char == '"') {
          final bool isEscapedQuote = i + 1 < text.length && text[i + 1] == '"';
          if (isEscapedQuote) {
            cell.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          cell.write(char);
        }
      } else {
        if (char == '"') {
          inQuotes = true;
        } else if (char == ',') {
          row.add(cell.toString());
          cell.clear();
        } else if (char == '\n') {
          row.add(cell.toString());
          cell.clear();
          rows.add(row);
          row = <String>[];
        } else if (char == '\r') {
          // Ignore carriage returns.
        } else {
          cell.write(char);
        }
      }
    }

    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }

    return rows;
  }

  /// Adds newly picked files while suppressing duplicate document identities.
  Future<void> _pickDocuments() async {
    final List<PlatformFile> result = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (result.isEmpty || !mounted) {
      return;
    }

    setState(() {
      for (final PlatformFile file in result) {
        final _DraftDocument document = _DraftDocument.fromPlatformFile(file);
        final bool exists = _selectedDocuments.any(
          (_DraftDocument existing) =>
              _documentIdentity(existing) == _documentIdentity(document),
        );
        if (!exists) {
          _selectedDocuments.add(document);
        }
      }
    });
    _saveDraftState();
  }

  /// Removes every selected document matching [document]'s stable identity.
  void _removeDocument(_DraftDocument document) {
    setState(() {
      _selectedDocuments.removeWhere(
        (_DraftDocument file) =>
            _documentIdentity(file) == _documentIdentity(document),
      );
    });
    _saveDraftState();
  }

  /// Restores independently persisted composer state in dependency order.
  Future<void> _restoreAllState() async {
    await _restoreSenderSetup();
    await _restoreRecipientDropdownValues();
    await _restoreContentDropdownValues();
    await _restoreSectionProfiles();
    await _restoreDraftState();
  }

  /// Subscribes draft persistence to every draft text controller.
  void _bindDraftListeners() {
    for (final TextEditingController controller in _draftControllers) {
      controller.addListener(_saveDraftState);
    }
  }

  /// Removes draft listeners before the owning widget is disposed.
  void _unbindDraftListeners() {
    for (final TextEditingController controller in _draftControllers) {
      controller.removeListener(_saveDraftState);
    }
  }

  /// Adds draft autosave listeners to all machine controllers.
  void _bindMachineDraftListeners(_CustomerMachineEntry machine) {
    for (final TextEditingController controller in machine.controllers) {
      controller.addListener(_saveDraftState);
    }
  }

  /// Removes draft autosave listeners before machine controllers are disposed.
  void _unbindMachineDraftListeners(_CustomerMachineEntry machine) {
    for (final TextEditingController controller in machine.controllers) {
      controller.removeListener(_saveDraftState);
    }
  }

  /// Builds one coworker entry from its draft JSON fields.
  _CoworkerEntry _coworkerFromMap(Map raw) {
    final _CoworkerEntry coworker = _CoworkerEntry();
    coworker.name.text = (raw['name'] as String?) ?? '';
    coworker.email.text = (raw['email'] as String?) ?? '';
    coworker.phone.text = (raw['phone'] as String?) ?? '';
    coworker.role.text = (raw['role'] as String?) ?? '';
    final dynamic isEditingRaw = raw['isEditing'];
    coworker.isEditing = switch (isEditingRaw) {
      bool value => value,
      String value => value.toLowerCase() == 'true',
      _ => false,
    };
    return coworker;
  }

  /// Restores fields, modes, documents, and machines from tolerant JSON data.
  Future<void> _restoreDraftState() async {
    final String? raw = AppDb.instance.getString(_draftStateKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    Map<String, dynamic> decoded;
    try {
      final Object? value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) {
        return;
      }
      decoded = value;
    } catch (_) {
      return;
    }

    final Map<String, dynamic> fields =
        (decoded['fields'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final List<dynamic> modesRaw =
        (decoded['contentModes'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> docsRaw =
        (decoded['documents'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> selectedCoworkerCcEmailsRaw =
        (decoded['selectedCoworkerCcEmails'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> machinesRaw =
        (decoded['machines'] as List<dynamic>?) ?? <dynamic>[];
    final List<dynamic> recipientContactsRaw =
        (decoded['recipientContacts'] as List<dynamic>?) ?? <dynamic>[];
    final List<_CoworkerEntry>? restoredCoworkers =
        decoded.containsKey('coworkers')
        ? <_CoworkerEntry>[
            for (final dynamic item
                in (decoded['coworkers'] as List<dynamic>? ?? <dynamic>[]))
              if (item is Map) _coworkerFromMap(item),
          ]
        : null;

    _isRestoringDraft = true;
    _unbindCoworkerDraftListeners();

    _fromNameController.text =
        (fields['fromName'] as String?) ?? _fromNameController.text;
    _fromEmailController.text =
        (fields['fromEmail'] as String?) ?? _fromEmailController.text;
    _replyToController.text =
        (fields['replyTo'] as String?) ?? _replyToController.text;
    _phoneController.text =
        (fields['phone'] as String?) ?? _phoneController.text;
    _toController.text = (fields['to'] as String?) ?? _toController.text;
    _ccController.text = (fields['cc'] as String?) ?? _ccController.text;
    _bccController.text = (fields['bcc'] as String?) ?? _bccController.text;
    _recipientNameController.text =
        (fields['recipientName'] as String?) ?? _recipientNameController.text;
    _recipientPositionController.text =
        (fields['recipientPosition'] as String?) ??
        _recipientPositionController.text;
    _recipientPhoneController.text =
        (fields['recipientPhone'] as String?) ?? _recipientPhoneController.text;
    _recipientEmailController.text =
        (fields['recipientEmail'] as String?) ?? _recipientEmailController.text;
    _companyController.text =
        (fields['company'] as String?) ?? _companyController.text;
    _departmentController.text =
        (fields['department'] as String?) ?? _departmentController.text;
    _customerNameController.text =
        (fields['customerName'] as String?) ?? _customerNameController.text;
    _customerEmailController.text =
        (fields['customerEmail'] as String?) ?? _customerEmailController.text;
    _customerPhoneController.text =
        (fields['customerPhone'] as String?) ?? _customerPhoneController.text;
    _customerShippingAddressController.text =
        (fields['customerShippingAddress'] as String?) ??
        _customerShippingAddressController.text;
    _subjectController.text =
        (fields['subject'] as String?) ?? _subjectController.text;
    _workOrderController.text =
        (fields['workOrder'] as String?) ?? _workOrderController.text;
    _purchaseOrderController.text =
        (fields['purchaseOrder'] as String?) ?? _purchaseOrderController.text;
    _partNumberController.text =
        (fields['partNumber'] as String?) ?? _partNumberController.text;
    _partDescriptionController.text =
        (fields['partDescription'] as String?) ??
        _partDescriptionController.text;
    _preheaderController.text =
        (fields['preheader'] as String?) ?? _preheaderController.text;
    _plainTextBodyController.text =
        (fields['plainTextBody'] as String?) ?? _plainTextBodyController.text;

    final Set<_ContentMode> restoredModes = <_ContentMode>{};
    for (final dynamic mode in modesRaw) {
      final String modeName = mode.toString();
      for (final _ContentMode candidate in _ContentMode.values) {
        if (candidate.name == modeName) {
          restoredModes.add(candidate);
          break;
        }
      }
    }

    final List<_DraftDocument> restoredDocuments = <_DraftDocument>[];
    for (final dynamic item in docsRaw) {
      if (item is! Map) {
        continue;
      }
      final String name = (item['name'] as String?) ?? '';
      final String? path = item['path'] as String?;
      final int size = (item['size'] as num?)?.toInt() ?? 0;
      if (name.isEmpty) {
        continue;
      }
      restoredDocuments.add(_DraftDocument(name: name, path: path, size: size));
    }

    final List<_CustomerMachineEntry> restoredMachines =
        <_CustomerMachineEntry>[];
    for (final dynamic item in machinesRaw) {
      if (item is! Map) {
        continue;
      }
      final _CustomerMachineEntry machine = _CustomerMachineEntry();
      _bindMachineDraftListeners(machine);
      machine.customerMachineName.text =
          (item['customerMachineName'] as String?) ?? '';
      machine.machineNumber.text = (item['machineNumber'] as String?) ?? '';
      machine.manufacturerMachineName.text =
          (item['manufacturerMachineName'] as String?) ?? '';
      machine.modelName.text = (item['modelName'] as String?) ?? '';
      machine.modelNumber.text = (item['modelNumber'] as String?) ?? '';
      machine.serialNumber.text = (item['serialNumber'] as String?) ?? '';
      final dynamic isExpandedRaw = item['isExpanded'];
      machine.isExpanded = switch (isExpandedRaw) {
        bool value => value,
        String value => value.toLowerCase() == 'true',
        _ => true,
      };
      restoredMachines.add(machine);
    }

    if (!mounted) {
      _isRestoringDraft = false;
      for (final _CustomerMachineEntry machine in restoredMachines) {
        machine.dispose();
      }
      for (final _CoworkerEntry coworker
          in restoredCoworkers ?? <_CoworkerEntry>[]) {
        coworker.dispose();
      }
      return;
    }

    setState(() {
      _selectedContentModes
        ..clear()
        ..addAll(restoredModes);
      _selectedDocuments
        ..clear()
        ..addAll(restoredDocuments);
      if (restoredCoworkers != null) {
        for (final _CoworkerEntry coworker in _coworkers) {
          coworker.dispose();
        }
        _coworkers
          ..clear()
          ..addAll(restoredCoworkers);
      }
      _coworkerDraftControllers.clear();
      _bindCoworkerDraftListeners();
      _selectedCoworkerCcEmails
        ..clear()
        ..addAll(
          selectedCoworkerCcEmailsRaw.whereType<String>().map(
            (String email) => email.toLowerCase(),
          ),
        );
      _recipientContacts
        ..clear()
        ..addAll(
          recipientContactsRaw
              .whereType<Map>()
              .map(_EmailRecipient.fromMap)
              .whereType<_EmailRecipient>(),
        );
      final String? selectedCustomerToEmail =
          decoded['selectedCustomerToEmail'] as String?;
      _selectedCustomerToEmail = selectedCustomerToEmail?.isEmpty ?? true
          ? null
          : selectedCustomerToEmail;
      final int? editingRecipientContact =
          (decoded['editingRecipientContact'] as num?)?.toInt();
      _editingRecipientContact =
          editingRecipientContact != null &&
              editingRecipientContact >= 0 &&
              editingRecipientContact < _recipientContacts.length
          ? editingRecipientContact
          : null;
      final String recipientContactType =
          decoded['recipientContactType'] as String? ?? 'to';
      _recipientContactType =
          <String>{'to', 'cc', 'bcc'}.contains(recipientContactType)
          ? recipientContactType
          : 'to';
      _isCoworkerCcTableExpanded =
          decoded['isCoworkerCcTableExpanded'] as bool? ?? false;
      _isCustomerToTableExpanded =
          decoded['isCustomerToTableExpanded'] as bool? ?? false;
      if (_recipientContacts.isNotEmpty) {
        _syncRecipientContactFields();
      } else {
        _recipientContacts.addAll(
          <(String, String)>[
            ('to', _toController.text),
            ('cc', _ccController.text),
            ('bcc', _bccController.text),
          ].expand(
            ((String, String) assignment) => assignment.$2
                .split(',')
                .map((String email) => email.trim())
                .where((String email) => email.isNotEmpty)
                .map(
                  (String email) => _EmailRecipient(
                    name: '',
                    position: '',
                    phone: '',
                    email: email,
                    type: assignment.$1,
                  ),
                ),
          ),
        );
      }
      for (final _CustomerMachineEntry machine in _customerMachines) {
        _unbindMachineDraftListeners(machine);
        machine.dispose();
      }
      final List<_CustomerMachineEntry> machinesToRestore =
          restoredMachines.isEmpty
          ? <_CustomerMachineEntry>[_CustomerMachineEntry()]
          : restoredMachines;
      for (final _CustomerMachineEntry machine in machinesToRestore) {
        _bindMachineDraftListeners(machine);
      }
      _customerMachines
        ..clear()
        ..addAll(machinesToRestore);
    });

    _isRestoringDraft = false;
    _saveDraftState();
  }

  /// Persists the current draft unless a restore is currently populating it.
  Future<void> _saveDraftState() async {
    if (_isRestoringDraft) {
      return;
    }
    _syncRecipientContactFields();
    final int revision = _draftSaveRevision + 1;
    _draftSaveRevision = revision;

    final Map<String, dynamic> draft = <String, dynamic>{
      'fields': <String, String>{
        'fromName': _fromNameController.text,
        'fromEmail': _fromEmailController.text,
        'replyTo': _replyToController.text,
        'phone': _phoneController.text,
        'to': _toController.text,
        'cc': _ccController.text,
        'bcc': _bccController.text,
        'recipientName': _recipientNameController.text,
        'recipientPosition': _recipientPositionController.text,
        'recipientPhone': _recipientPhoneController.text,
        'recipientEmail': _recipientEmailController.text,
        'company': _companyController.text,
        'department': _departmentController.text,
        'customerName': _customerNameController.text,
        'customerEmail': _customerEmailController.text,
        'customerPhone': _customerPhoneController.text,
        'customerShippingAddress': _customerShippingAddressController.text,
        'subject': _subjectController.text,
        'workOrder': _workOrderController.text,
        'purchaseOrder': _purchaseOrderController.text,
        'partNumber': _partNumberController.text,
        'partDescription': _partDescriptionController.text,
        'preheader': _preheaderController.text,
        'plainTextBody': _plainTextBodyController.text,
      },
      'contentModes': _selectedContentModes.map((mode) => mode.name).toList(),
      'documents': _selectedDocuments
          .map(
            (_DraftDocument file) => <String, dynamic>{
              'name': file.name,
              'path': file.path,
              'size': file.size,
            },
          )
          .toList(),
      'coworkers': _coworkers
          .map(
            (_CoworkerEntry coworker) => <String, dynamic>{
              'name': coworker.name.text,
              'email': coworker.email.text,
              'phone': coworker.phone.text,
              'role': coworker.role.text,
              'isEditing': coworker.isEditing,
            },
          )
          .toList(),
      'recipientContacts': _recipientContacts
          .map((_EmailRecipient contact) => contact.toMap())
          .toList(),
      'recipientContactType': _recipientContactType,
      'editingRecipientContact': _editingRecipientContact,
      'selectedCoworkerCcEmails': _selectedCoworkerCcEmails.toList(),
      'selectedCustomerToEmail': _selectedCustomerToEmail ?? '',
      'isCoworkerCcTableExpanded': _isCoworkerCcTableExpanded,
      'isCustomerToTableExpanded': _isCustomerToTableExpanded,
      'machines': _customerMachines
          .map(
            (_CustomerMachineEntry machine) => <String, dynamic>{
              'customerMachineName': machine.customerMachineName.text,
              'machineNumber': machine.machineNumber.text,
              'manufacturerMachineName': machine.manufacturerMachineName.text,
              'modelName': machine.modelName.text,
              'modelNumber': machine.modelNumber.text,
              'serialNumber': machine.serialNumber.text,
              'isExpanded': machine.isExpanded,
            },
          )
          .toList(),
    };

    if (_draftSaveRevision == revision) {
      await AppDb.instance.setString(_draftStateKey, jsonEncode(draft));
    }
  }

  /// Restores sender fields and derives whether reply-to was manually changed.
  Future<void> _restoreSenderSetup() async {
    final String? fromName = AppDb.instance.getString(_fromNameKey);
    final String? fromEmail = AppDb.instance.getString(_fromEmailKey);
    final String? replyTo = AppDb.instance.getString(_replyToKey);
    final String? phone = AppDb.instance.getString(_phoneKey);

    if (!mounted) {
      return;
    }

    _fromNameController.text = fromName ?? '';
    _fromEmailController.text = fromEmail ?? '';
    _phoneController.text = phone ?? '';

    final String restoredReply = (replyTo ?? '').trim();
    final String sender = _fromEmailController.text.trim();
    if (restoredReply.isEmpty) {
      _replyToController.text = sender;
      _replyToManuallyEdited = false;
    } else {
      _replyToController.text = restoredReply;
      _replyToManuallyEdited = restoredReply != sender;
    }

    final bool hasSavedSenderData =
        _fromNameController.text.trim().isNotEmpty ||
        _fromEmailController.text.trim().isNotEmpty ||
        _replyToController.text.trim().isNotEmpty ||
        _phoneController.text.trim().isNotEmpty;

    setState(() {
      _isSenderCollapsed = hasSavedSenderData;
    });

    _saveSenderSetup();
  }

  /// Persists the trimmed sender fields used on the next application launch.
  Future<void> _saveSenderSetup() async {
    await AppDb.instance.setString(
      _fromNameKey,
      _fromNameController.text.trim(),
    );
    await AppDb.instance.setString(
      _fromEmailKey,
      _fromEmailController.text.trim(),
    );
    await AppDb.instance.setString(_replyToKey, _replyToController.text.trim());
    await AppDb.instance.setString(_phoneKey, _phoneController.text.trim());
  }

  /// Restores saved recipient autocomplete values into mounted UI state.
  Future<void> _restoreRecipientDropdownValues() async {
    final List<String> companyOptions =
        AppDb.instance.getStringList(_companyOptionsKey) ?? <String>[];
    final List<String> departmentOptions =
        AppDb.instance.getStringList(_departmentOptionsKey) ?? <String>[];
    final List<String> toOptions =
        AppDb.instance.getStringList(_toOptionsKey) ?? <String>[];
    final List<String> ccOptions =
        AppDb.instance.getStringList(_ccOptionsKey) ?? <String>[];
    final List<String> bccOptions =
        AppDb.instance.getStringList(_bccOptionsKey) ?? <String>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _companyOptions = companyOptions;
      _departmentOptions = departmentOptions;
      _toOptions = toOptions;
      _ccOptions = ccOptions;
      _bccOptions = bccOptions;
    });
  }

  /// Restores valid profile records and rebuilds their autocomplete options.
  Future<void> _restoreSectionProfiles() async {
    final List<String> senderRaw =
        AppDb.instance.getStringList(_senderProfilesKey) ?? <String>[];
    final List<String> recipientRaw =
        AppDb.instance.getStringList(_recipientProfilesKey) ?? <String>[];
    final List<String> customerRaw =
        AppDb.instance.getStringList(_customerProfilesKey) ?? <String>[];
    final List<String> customerEntriesRaw =
        AppDb.instance.getStringList(_customerEntriesKey) ?? <String>[];

    final List<_SenderProfile> senderProfiles = senderRaw
        .map(_SenderProfile.tryParse)
        .whereType<_SenderProfile>()
        .toList();
    final List<_RecipientProfile> recipientProfiles = recipientRaw
        .map(_RecipientProfile.tryParse)
        .whereType<_RecipientProfile>()
        .toList();
    final List<_CustomerProfile> customerProfiles = customerRaw
        .map(_CustomerProfile.tryParse)
        .whereType<_CustomerProfile>()
        .toList();
    final List<_SavedCustomerEntry> customerEntries = customerEntriesRaw
        .map(_SavedCustomerEntry.tryParse)
        .whereType<_SavedCustomerEntry>()
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _senderProfiles = senderProfiles;
      _recipientProfiles = recipientProfiles;
      _customerProfiles = customerProfiles;
      _savedCustomerEntries = customerEntries;
      _refreshSenderOptionsFromProfiles();
      _refreshCustomerOptionsFromProfiles();
    });
  }

  /// Persists all recipient autocomplete lists.
  Future<void> _saveRecipientDropdownValues() async {
    await AppDb.instance.setStringList(_companyOptionsKey, _companyOptions);
    await AppDb.instance.setStringList(
      _departmentOptionsKey,
      _departmentOptions,
    );
    await AppDb.instance.setStringList(_toOptionsKey, _toOptions);
    await AppDb.instance.setStringList(_ccOptionsKey, _ccOptions);
    await AppDb.instance.setStringList(_bccOptionsKey, _bccOptions);
  }

  /// Restores saved content-field autocomplete values into mounted UI state.
  Future<void> _restoreContentDropdownValues() async {
    final List<String> workOrderOptions =
        AppDb.instance.getStringList(_workOrderOptionsKey) ?? <String>[];
    final List<String> purchaseOrderOptions =
        AppDb.instance.getStringList(_purchaseOrderOptionsKey) ?? <String>[];
    final List<String> partNumberOptions =
        AppDb.instance.getStringList(_partNumberOptionsKey) ?? <String>[];
    final List<String> partDescriptionOptions =
        AppDb.instance.getStringList(_partDescriptionOptionsKey) ?? <String>[];
    final List<String> subjectOptions =
        AppDb.instance.getStringList(_subjectOptionsKey) ?? <String>[];
    final List<String> preheaderOptions =
        AppDb.instance.getStringList(_preheaderOptionsKey) ?? <String>[];
    final List<String> plainTextBodyOptions =
        AppDb.instance.getStringList(_plainTextBodyOptionsKey) ?? <String>[];

    if (!mounted) {
      return;
    }

    setState(() {
      _workOrderOptions = workOrderOptions;
      _purchaseOrderOptions = purchaseOrderOptions;
      _partNumberOptions = partNumberOptions;
      _partDescriptionOptions = partDescriptionOptions;
      _subjectOptions = subjectOptions;
      _preheaderOptions = preheaderOptions;
      _plainTextBodyOptions = plainTextBodyOptions;
    });
  }

  /// Persists all content-field autocomplete lists.
  Future<void> _saveContentDropdownValues() async {
    await AppDb.instance.setStringList(_workOrderOptionsKey, _workOrderOptions);
    await AppDb.instance.setStringList(
      _purchaseOrderOptionsKey,
      _purchaseOrderOptions,
    );
    await AppDb.instance.setStringList(
      _partNumberOptionsKey,
      _partNumberOptions,
    );
    await AppDb.instance.setStringList(
      _partDescriptionOptionsKey,
      _partDescriptionOptions,
    );
    await AppDb.instance.setStringList(_subjectOptionsKey, _subjectOptions);
    await AppDb.instance.setStringList(_preheaderOptionsKey, _preheaderOptions);
    await AppDb.instance.setStringList(
      _plainTextBodyOptionsKey,
      _plainTextBodyOptions,
    );
  }

  /// Serializes every profile collection into the string-list database API.
  Future<void> _saveSectionProfiles() async {
    await AppDb.instance.setStringList(
      _senderProfilesKey,
      _senderProfiles.map((profile) => profile.toStorageString()).toList(),
    );
    await AppDb.instance.setStringList(
      _recipientProfilesKey,
      _recipientProfiles.map((profile) => profile.toStorageString()).toList(),
    );
    await AppDb.instance.setStringList(
      _customerProfilesKey,
      _customerProfiles.map((profile) => profile.toStorageString()).toList(),
    );
    await AppDb.instance.setStringList(
      _customerEntriesKey,
      _savedCustomerEntries.map((entry) => entry.toStorageString()).toList(),
    );
  }

  /// Rebuilds sender autocomplete lists from current fields and history.
  void _refreshSenderOptionsFromProfiles() {
    _senderNameOptions = _collectUniqueValues(<String>[
      _fromNameController.text,
      ..._senderProfiles.map((profile) => profile.fromName),
    ]);
    _senderEmailOptions = _collectUniqueValues(<String>[
      _fromEmailController.text,
      ..._senderProfiles.map((profile) => profile.fromEmail),
    ]);
    _replyToOptions = _collectUniqueValues(<String>[
      _replyToController.text,
      ..._senderProfiles.map((profile) => profile.replyTo),
    ]);
    _senderPhoneOptions = _collectUniqueValues(<String>[
      _phoneController.text,
      ..._senderProfiles.map((profile) => profile.phone),
    ]);
  }

  /// Rebuilds customer autocomplete lists from current fields and history.
  void _refreshCustomerOptionsFromProfiles() {
    _customerPhoneOptions = _collectUniqueValues(<String>[
      _customerPhoneController.text,
      ..._customerProfiles.map((profile) => profile.phone),
    ]);
    _customerAddressOptions = _collectUniqueValues(<String>[
      _customerShippingAddressController.text,
      ..._customerProfiles.map((profile) => profile.shippingAddress),
    ]);
  }

  /// Trims, removes blanks, and deduplicates values case-insensitively.
  List<String> _collectUniqueValues(Iterable<String> values) {
    final Set<String> seen = <String>{};
    final List<String> result = <String>[];

    for (final String value in values) {
      final String normalized = value.trim();
      if (normalized.isEmpty) {
        continue;
      }

      final String key = normalized.toLowerCase();
      if (seen.add(key)) {
        result.add(normalized);
      }
    }

    return result;
  }
}
