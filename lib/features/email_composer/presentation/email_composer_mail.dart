// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

/// Synchronizes sender fields and builds the external email request.
extension _EmailComposerMail on _EmailComposerPageState {
  /// Mirrors the sender address into reply-to until the user overrides it.
  void _handleFromEmailChanged() {
    final String sender = _fromEmailController.text.trim();
    if (!_replyToManuallyEdited) {
      _replyToController.text = sender;
    }
  }

  /// Tracks whether reply-to should remain independent of the sender address.
  void _handleReplyToChanged(String value) {
    final String replyTo = value.trim();
    final String sender = _fromEmailController.text.trim();

    if (replyTo.isEmpty) {
      _replyToManuallyEdited = false;
      _replyToController.text = sender;
    } else {
      _replyToManuallyEdited = replyTo != sender;
    }

    _saveSenderSetup();
  }

  /// Clears persisted sender setup while retaining saved sender history.
  Future<void> _resetSenderSetup() async {
    await AppDb.instance.remove(_fromNameKey);
    await AppDb.instance.remove(_fromEmailKey);
    await AppDb.instance.remove(_replyToKey);
    await AppDb.instance.remove(_phoneKey);

    _fromNameController.clear();
    _fromEmailController.clear();
    _replyToController.clear();
    _phoneController.clear();
    _replyToManuallyEdited = false;

    if (mounted) {
      setState(() {
        _isSenderCollapsed = false;
      });
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sender setup reset.')));
  }

  /// Validates the draft, records current profiles, and launches a mailto URI.
  Future<void> _openInEmailClient() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete required fields.')),
      );
      return;
    }

    final List<String> toList = _splitList(_toController.text);
    if (toList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one To recipient is required.')),
      );
      return;
    }

    final List<String> ccList = _splitList(_ccController.text);
    final List<String> bccList = _splitList(_bccController.text);

    _commitRecipientOption(_companyController.text, forCompany: true);
    _commitRecipientOption(_departmentController.text, forCompany: false);
    _commitEmailListOptions(_toController.text, target: _toOptions);
    _commitEmailListOptions(_ccController.text, target: _ccOptions);
    _commitEmailListOptions(_bccController.text, target: _bccOptions);
    _commitSenderProfile();
    _commitRecipientProfile();
    _commitCustomerProfile();

    final String body = _buildPrefilledBody();

    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: toList.join(','),
      queryParameters: <String, String>{
        if (ccList.isNotEmpty) 'cc': ccList.join(','),
        if (bccList.isNotEmpty) 'bcc': bccList.join(','),
        'subject': _subjectController.text.trim(),
        'body': body,
      },
    );

    final bool opened = await launchUrl(
      mailtoUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open default email client.')),
      );
    }
  }

  /// Formats populated composer fields as the plain-text email body.
  String _buildPrefilledBody() {
    final String contentModes = _selectedContentModes.isEmpty
        ? 'None'
        : _selectedContentModes.map(_contentModeLabel).join(', ');

    final List<String> lines = <String>[
      if (_workOrderController.text.trim().isNotEmpty)
        'Work Order: ${_workOrderController.text.trim()}',
      if (_purchaseOrderController.text.trim().isNotEmpty)
        'Purchase Order: ${_purchaseOrderController.text.trim()}',
      if (_partNumberController.text.trim().isNotEmpty)
        'Part Number: ${_partNumberController.text.trim()}',
      if (_partDescriptionController.text.trim().isNotEmpty)
        'Part Description: ${_partDescriptionController.text.trim()}',
      'Content Mode: $contentModes',
      if (_selectedDocuments.isNotEmpty)
        'Documents: ${_selectedDocuments.map(_documentUrlPath).join(', ')}',
      if (_preheaderController.text.trim().isNotEmpty)
        'Preheader: ${_preheaderController.text.trim()}',
      if (_fromNameController.text.trim().isNotEmpty)
        'From Name: ${_fromNameController.text.trim()}',
      if (_fromEmailController.text.trim().isNotEmpty)
        'From Email: ${_fromEmailController.text.trim()}',
      if (_replyToController.text.trim().isNotEmpty)
        'Reply-To: ${_replyToController.text.trim()}',
      if (_phoneController.text.trim().isNotEmpty)
        'Phone: ${_phoneController.text.trim()}',
      if (_companyController.text.trim().isNotEmpty)
        'Company: ${_companyController.text.trim()}',
      if (_departmentController.text.trim().isNotEmpty)
        'Department: ${_departmentController.text.trim()}',
      if (_customerNameController.text.trim().isNotEmpty)
        'Customer Name: ${_customerNameController.text.trim()}',
      if (_customerEmailController.text.trim().isNotEmpty)
        'Customer Email: ${_customerEmailController.text.trim()}',
      if (_customerPhoneController.text.trim().isNotEmpty)
        'Customer Phone: ${_customerPhoneController.text.trim()}',
      if (_customerShippingAddressController.text.trim().isNotEmpty)
        'Shipping Address:\n${_customerShippingAddressController.text.trim()}',
      ..._buildMachineBodyLines(),
      '',
      'Message:',
      _plainTextBodyController.text.trim(),
    ];

    return lines.join('\n');
  }

  /// Splits a comma-separated address field and removes empty segments.
  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((String s) => s.trim())
        .where((String s) => s.isNotEmpty)
        .toList();
  }

  /// Returns the stable key used to deduplicate selected documents.
  String _documentIdentity(_DraftDocument file) {
    return file.identity;
  }

  /// Returns a document's file URI or its name when no path is available.
  String _documentUrlPath(_DraftDocument file) {
    return file.urlPath;
  }

  /// Replaces the subject with labels for the currently selected modes.
  void _syncSubjectFromContentModes() {
    final String modesText = _selectedContentModes.isEmpty
        ? ''
        : _selectedContentModes.map(_contentModeLabel).join(' | ');
    _subjectController.text = modesText;
  }

  /// Replaces the preheader with the populated work and purchase orders.
  void _syncPreheaderFromOrderFields() {
    final List<String> parts = <String>[
      if (_workOrderController.text.trim().isNotEmpty)
        'WO: ${_workOrderController.text.trim()}',
      if (_purchaseOrderController.text.trim().isNotEmpty)
        'PO: ${_purchaseOrderController.text.trim()}',
    ];
    _preheaderController.text = parts.join(' | ');
  }

  /// Maps an internal content mode to user-facing email text.
  String _contentModeLabel(_ContentMode mode) {
    return switch (mode) {
      _ContentMode.expedite => 'Expedite Request',
      _ContentMode.rush => 'Technician on Site',
      _ContentMode.machineDown => 'Machine Down',
      _ContentMode.partLookup => 'Part Lookup',
      _ContentMode.quotePart => 'Quote Part',
      _ContentMode.shipImmediately => 'Ship Immediately',
    };
  }

  /// Formats every non-empty machine as an indented body section.
  List<String> _buildMachineBodyLines() {
    final List<String> lines = <String>[];

    for (int index = 0; index < _customerMachines.length; index++) {
      final _CustomerMachineEntry machine = _customerMachines[index];
      if (!machine.hasData) {
        continue;
      }

      lines.add('Machine ${index + 1}:');
      if (machine.customerMachineName.text.trim().isNotEmpty) {
        lines.add(
          '  Customer Machine Name: ${machine.customerMachineName.text.trim()}',
        );
      }
      if (machine.machineNumber.text.trim().isNotEmpty) {
        lines.add('  Machine Number: ${machine.machineNumber.text.trim()}');
      }
      if (machine.manufacturerMachineName.text.trim().isNotEmpty) {
        lines.add(
          '  Manufacturer Machine Name: ${machine.manufacturerMachineName.text.trim()}',
        );
      }
      if (machine.modelName.text.trim().isNotEmpty) {
        lines.add('  Model Name: ${machine.modelName.text.trim()}');
      }
      if (machine.modelNumber.text.trim().isNotEmpty) {
        lines.add('  Model Number: ${machine.modelNumber.text.trim()}');
      }
      if (machine.serialNumber.text.trim().isNotEmpty) {
        lines.add('  Serial Number: ${machine.serialNumber.text.trim()}');
      }
    }

    return lines;
  }
}
