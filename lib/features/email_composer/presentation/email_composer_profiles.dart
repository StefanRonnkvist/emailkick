// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

/// Manages profile history, autocomplete options, and saved selections.
extension _EmailComposerProfiles on _EmailComposerPageState {
  /// Prepends a non-empty option unless an equal value already exists.
  void _commitSingleValueOption(String value, {required List<String> target}) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    final bool exists = target.any(
      (String entry) => entry.toLowerCase() == normalized.toLowerCase(),
    );
    if (exists) {
      return;
    }

    setState(() {
      target.insert(0, normalized);
    });
  }

  /// Commits one content option and persists all content option lists.
  void _commitContentOption(String value, {required List<String> target}) {
    _commitSingleValueOption(value, target: target);
    _saveContentDropdownValues();
  }

  /// Moves the current sender profile to the front of the 40-item history.
  void _commitSenderProfile() {
    final _SenderProfile profile = _SenderProfile(
      fromName: _fromNameController.text.trim(),
      fromEmail: _fromEmailController.text.trim(),
      replyTo: _replyToController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (!profile.hasData) {
      return;
    }

    _senderProfiles.removeWhere(profile.matchesExactly);
    _senderProfiles.insert(0, profile);
    if (_senderProfiles.length > 40) {
      _senderProfiles = _senderProfiles.take(40).toList();
    }

    setState(() {
      _refreshSenderOptionsFromProfiles();
    });

    _saveSectionProfiles();
  }

  /// Moves the current recipient profile to the front of saved history.
  void _commitRecipientProfile() {
    final _RecipientProfile profile = _RecipientProfile(
      company: _companyController.text.trim(),
      department: _departmentController.text.trim(),
      to: _toController.text.trim(),
      cc: _ccController.text.trim(),
      bcc: _bccController.text.trim(),
      contacts: List<_EmailRecipient>.from(_recipientContacts),
    );
    if (!profile.hasData) {
      return;
    }

    _recipientProfiles.removeWhere(profile.matchesExactly);
    _recipientProfiles.insert(0, profile);
    if (_recipientProfiles.length > 40) {
      _recipientProfiles = _recipientProfiles.take(40).toList();
    }

    setState(() {});

    _saveSectionProfiles();
  }

  /// Moves the current customer profile to the front of saved history.
  void _commitCustomerProfile() {
    final _CustomerProfile profile = _CustomerProfile(
      name: _customerNameController.text.trim(),
      email: _customerEmailController.text.trim(),
      phone: _customerPhoneController.text.trim(),
      shippingAddress: _customerShippingAddressController.text.trim(),
    );
    if (!profile.hasData) {
      return;
    }

    _customerProfiles.removeWhere(profile.matchesExactly);
    _customerProfiles.insert(0, profile);
    if (_customerProfiles.length > 40) {
      _customerProfiles = _customerProfiles.take(40).toList();
    }

    setState(() {
      _refreshCustomerOptionsFromProfiles();
    });

    _saveSectionProfiles();
  }

  /// Finds a sender by one field and applies its complete saved profile.
  void _applySenderProfileFromField(_ProfileField field, String value) {
    final _SenderProfile? profile = _findSenderProfile(field, value);
    if (profile == null) {
      return;
    }

    _fromNameController.text = profile.fromName;
    _fromEmailController.text = profile.fromEmail;
    _replyToController.text = profile.replyTo;
    _phoneController.text = profile.phone;
    _replyToManuallyEdited = profile.replyTo.trim() != profile.fromEmail.trim();

    _saveSenderSetup();
  }

  /// Finds a recipient by one field and applies its complete saved profile.
  void _applyRecipientProfileFromField(_ProfileField field, String value) {
    final _RecipientProfile? profile = _findRecipientProfile(field, value);
    if (profile == null) {
      return;
    }

    _companyController.text = profile.company;
    _departmentController.text = profile.department;
    _toController.text = profile.to;
    _ccController.text = profile.cc;
    _bccController.text = profile.bcc;
    _selectedCoworkerCcEmails.clear();
    _selectedCustomerToEmail = null;
    _recipientContacts
      ..clear()
      ..addAll(_contactsForRecipientProfile(profile));
    _syncRecipientContactFields();
    _saveDraftState();
  }

  /// Finds a customer by one field and applies its complete saved profile.
  void _applyCustomerProfileFromField(_ProfileField field, String value) {
    final _CustomerProfile? profile = _findCustomerProfile(field, value);
    if (profile == null) {
      return;
    }

    _customerNameController.text = profile.name;
    _customerEmailController.text = profile.email;
    _customerPhoneController.text = profile.phone;
    _customerShippingAddressController.text = profile.shippingAddress;
    _saveDraftState();
  }

  /// Returns the first sender whose selected field matches [value].
  _SenderProfile? _findSenderProfile(_ProfileField field, String value) {
    final String target = value.trim().toLowerCase();
    if (target.isEmpty) {
      return null;
    }

    for (final _SenderProfile profile in _senderProfiles) {
      final String candidate = switch (field) {
        _ProfileField.fromName => profile.fromName,
        _ProfileField.fromEmail => profile.fromEmail,
        _ProfileField.replyTo => profile.replyTo,
        _ProfileField.phone => profile.phone,
        _ => '',
      };
      if (candidate.trim().toLowerCase() == target) {
        return profile;
      }
    }

    return null;
  }

  /// Returns the first recipient whose selected field matches [value].
  _RecipientProfile? _findRecipientProfile(_ProfileField field, String value) {
    final String target = value.trim().toLowerCase();
    if (target.isEmpty) {
      return null;
    }

    for (final _RecipientProfile profile in _recipientProfiles) {
      final String candidate = switch (field) {
        _ProfileField.company => profile.company,
        _ProfileField.department => profile.department,
        _ProfileField.to => profile.to,
        _ProfileField.cc => profile.cc,
        _ProfileField.bcc => profile.bcc,
        _ => '',
      };
      if (candidate.trim().toLowerCase() == target) {
        return profile;
      }
    }

    return null;
  }

  /// Returns the first customer whose selected field matches [value].
  _CustomerProfile? _findCustomerProfile(_ProfileField field, String value) {
    final String target = value.trim().toLowerCase();
    if (target.isEmpty) {
      return null;
    }

    for (final _CustomerProfile profile in _customerProfiles) {
      final String candidate = switch (field) {
        _ProfileField.customerName => profile.name,
        _ProfileField.customerEmail => profile.email,
        _ProfileField.customerPhone => profile.phone,
        _ProfileField.customerAddress => profile.shippingAddress,
        _ => '',
      };
      if (candidate.trim().toLowerCase() == target) {
        return profile;
      }
    }

    return null;
  }

  /// Adds a unique company or department option and persists the lists.
  void _commitRecipientOption(String value, {required bool forCompany}) {
    final String normalized = value.trim();
    if (normalized.isEmpty) {
      return;
    }

    final List<String> target = forCompany
        ? _companyOptions
        : _departmentOptions;
    final bool exists = target.any(
      (String entry) => entry.toLowerCase() == normalized.toLowerCase(),
    );

    if (exists) {
      return;
    }

    setState(() {
      target.insert(0, normalized);
    });

    _saveRecipientDropdownValues();
  }

  /// Adds unique addresses from a comma-separated field to an option list.
  void _commitEmailListOptions(
    String rawValue, {
    required List<String> target,
  }) {
    final List<String> values = rawValue
        .split(',')
        .map((String value) => value.trim())
        .where((String value) => value.isNotEmpty)
        .toList();
    if (values.isEmpty) {
      return;
    }

    bool changed = false;
    for (final String value in values) {
      final bool exists = target.any(
        (String entry) => entry.toLowerCase() == value.toLowerCase(),
      );
      if (!exists) {
        target.insert(0, value);
        changed = true;
      }
    }

    if (changed) {
      setState(() {});
      _saveRecipientDropdownValues();
    }
  }

  /// Saves recipient options and profile.
  void _saveRecipients() {
    _commitRecipientOption(_companyController.text, forCompany: true);
    _commitRecipientOption(_departmentController.text, forCompany: false);
    _syncRecipientContactFields();
    _commitEmailListOptions(_toController.text, target: _toOptions);
    _commitEmailListOptions(_ccController.text, target: _ccOptions);
    _commitEmailListOptions(_bccController.text, target: _bccOptions);
    _saveOrUpdateRecipientProfile();
    _saveDraftState();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recipients saved.')));
  }

  /// Replaces the edited recipient or inserts a new most-recent profile.
  void _saveOrUpdateRecipientProfile() {
    final _RecipientProfile profile = _RecipientProfile(
      company: _companyController.text.trim(),
      department: _departmentController.text.trim(),
      to: _toController.text.trim(),
      cc: _ccController.text.trim(),
      bcc: _bccController.text.trim(),
      contacts: List<_EmailRecipient>.from(_recipientContacts),
    );
    if (!profile.hasData) {
      return;
    }

    setState(() {
      if (_editingRecipientProfile != null) {
        _recipientProfiles.removeWhere(
          _editingRecipientProfile!.matchesExactly,
        );
      }
      _recipientProfiles.removeWhere(profile.matchesExactly);
      _recipientProfiles.insert(0, profile);
      if (_recipientProfiles.length > 40) {
        _recipientProfiles = _recipientProfiles.take(40).toList();
      }
      _editingRecipientProfile = null;
    });

    _saveSectionProfiles();
  }

  /// Loads a valid recipient history row and marks it for replacement.
  void _editRecipientProfile(int index) {
    if (index < 0 || index >= _recipientProfiles.length) {
      return;
    }

    final _RecipientProfile profile = _recipientProfiles[index];
    setState(() {
      _editingRecipientProfile = profile;
      _companyController.text = profile.company;
      _departmentController.text = profile.department;
      _toController.text = profile.to;
      _ccController.text = profile.cc;
      _bccController.text = profile.bcc;
      _selectedCoworkerCcEmails.clear();
      _selectedCustomerToEmail = null;
      _recipientContacts
        ..clear()
        ..addAll(_contactsForRecipientProfile(profile));
      _syncRecipientContactFields();
    });
    _saveDraftState();
  }

  /// Deletes a valid recipient row and clears matching edit state.
  void _deleteRecipientProfile(int index) {
    if (index < 0 || index >= _recipientProfiles.length) {
      return;
    }

    final _RecipientProfile removed = _recipientProfiles[index];
    setState(() {
      _recipientProfiles.removeAt(index);
      if (_editingRecipientProfile != null &&
          _editingRecipientProfile!.matchesExactly(removed)) {
        _editingRecipientProfile = null;
      }
    });

    _saveSectionProfiles();
  }

  /// Validates, persists, and collapses the sender setup section.
  void _saveSenderDetails() {
    final String? senderEmailError = _validateOptionalSingleEmail(
      _fromEmailController.text,
    );
    if (senderEmailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('From Email: $senderEmailError')));
      return;
    }

    final String? replyToError = _validateOptionalSingleEmail(
      _replyToController.text,
    );
    if (replyToError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reply-To Email: $replyToError')));
      return;
    }

    _commitSenderProfile();
    _saveSenderSetup();

    setState(() {
      _isSenderCollapsed = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sender details saved.')));
  }

  /// Saves the current customer together with all non-empty machines.
  void _saveCustomer() {
    _commitCustomerProfile();

    final _SavedCustomerEntry entry = _SavedCustomerEntry(
      name: _customerNameController.text.trim(),
      email: _customerEmailController.text.trim(),
      phone: _customerPhoneController.text.trim(),
      shippingAddress: _customerShippingAddressController.text.trim(),
      machines: _buildSavedMachines(),
    );

    if (entry.hasData) {
      setState(() {
        _savedCustomerEntries.removeWhere(entry.matchesExactly);
        _savedCustomerEntries.insert(0, entry);
        if (_savedCustomerEntries.length > 40) {
          _savedCustomerEntries = _savedCustomerEntries.take(40).toList();
        }
        _expandedCustomerIndex = 0;
      });
      _saveSectionProfiles();
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Customer saved.')));
  }

  /// Formats a stable human-readable customer selector label.
  String _savedCustomerSelectionLabel(_SavedCustomerEntry entry) {
    final String name = entry.name.trim().isEmpty
        ? 'Unnamed Customer'
        : entry.name.trim();
    final String email = entry.email.trim().isEmpty ? '-' : entry.email.trim();
    final String phone = entry.phone.trim().isEmpty ? '-' : entry.phone.trim();
    return '$name | $email | $phone';
  }

  /// Formats a stable human-readable recipient selector label.
  String _savedRecipientSelectionLabel(_RecipientProfile profile) {
    final String company = profile.company.trim().isEmpty
        ? 'No Company'
        : profile.company.trim();
    final String department = profile.department.trim().isEmpty
        ? 'No Department'
        : profile.department.trim();
    final String to = profile.to.trim().isEmpty ? '-' : profile.to.trim();
    return '$company | $department | $to';
  }

  /// Builds one-based recipient options so duplicate labels remain selectable.
  List<String> _contentRecipientSelectionOptions() {
    return List<String>.generate(_recipientProfiles.length, (int index) {
      final _RecipientProfile profile = _recipientProfiles[index];
      return '${index + 1}. ${_savedRecipientSelectionLabel(profile)}';
    });
  }

  /// Builds one-based customer options including associated machine counts.
  List<String> _contentCustomerSelectionOptions() {
    return List<String>.generate(_savedCustomerEntries.length, (int index) {
      final _SavedCustomerEntry entry = _savedCustomerEntries[index];
      return '${index + 1}. ${_savedCustomerSelectionLabel(entry)} | Machines: ${entry.machines.length}';
    });
  }

  /// Formats one machine option with its index, name, and serial number.
  String _savedMachineSelectionLabel(_SavedCustomerMachine machine, int index) {
    final String name = machine.customerMachineName.trim().isEmpty
        ? 'Machine ${index + 1}'
        : machine.customerMachineName.trim();
    final String serial = machine.serialNumber.trim().isEmpty
        ? '-'
        : machine.serialNumber.trim();
    return '${index + 1} | $name | $serial';
  }

  /// Applies a saved customer and replaces the editable machine controller set.
  void _applySavedCustomerFromSelection(String selection) {
    final String selected = selection.trim().toLowerCase();
    if (selected.isEmpty) {
      setState(() {
        _selectedContentCustomer = null;
        _selectedContentCustomerMachines = <_SavedCustomerMachine>[];
        _contentMachineSelectorController.clear();
      });
      return;
    }

    final List<String> options = _contentCustomerSelectionOptions();
    int selectedIndex = _customerOptionIndexFromSelection(selection);
    if (selectedIndex < 0) {
      for (int i = 0; i < options.length; i++) {
        if (options[i].toLowerCase() == selected) {
          selectedIndex = i;
          break;
        }
      }
    }

    if (selectedIndex < 0) {
      // Keep current selection on partial/non-exact text edits.
      return;
    }

    final _SavedCustomerEntry entry = _savedCustomerEntries[selectedIndex];
    final List<_SavedCustomerMachine> machinePool = _collectMachinesForCustomer(
      entry,
    );

    final List<_CustomerMachineEntry> restoredMachines = machinePool.isEmpty
        ? <_CustomerMachineEntry>[_CustomerMachineEntry()]
        : machinePool.map((_SavedCustomerMachine machine) {
            final _CustomerMachineEntry restored = _CustomerMachineEntry();
            _bindMachineDraftListeners(restored);
            restored.isExpanded = false;
            restored.customerMachineName.text = machine.customerMachineName;
            restored.machineNumber.text = machine.machineNumber;
            restored.manufacturerMachineName.text =
                machine.manufacturerMachineName;
            restored.modelName.text = machine.modelName;
            restored.modelNumber.text = machine.modelNumber;
            restored.serialNumber.text = machine.serialNumber;
            return restored;
          }).toList();

    setState(() {
      _contentCustomerSelectorController.text = options[selectedIndex];
      _selectedContentCustomer = entry;
      _selectedContentCustomerMachines = machinePool;
      _contentMachineSelectorController.clear();
      _customerNameController.text = entry.name;
      _customerEmailController.text = entry.email;
      _customerPhoneController.text = entry.phone;
      _customerShippingAddressController.text = entry.shippingAddress;
      if (_selectedCustomerToEmail != null) {
        _recipientContacts.removeWhere(
          (_EmailRecipient contact) =>
              contact.position == 'Customer' &&
              contact.email.toLowerCase() ==
                  _selectedCustomerToEmail!.toLowerCase(),
        );
      }
      _selectedCustomerToEmail = null;
      _syncRecipientContactFields();

      for (final _CustomerMachineEntry machine in _customerMachines) {
        _unbindMachineDraftListeners(machine);
        machine.dispose();
      }
      for (final _CustomerMachineEntry machine in restoredMachines) {
        _bindMachineDraftListeners(machine);
      }
      _customerMachines
        ..clear()
        ..addAll(restoredMachines);
    });

    _saveDraftState();
  }

  /// Parses and bounds-checks a customer's one-based selector prefix.
  int _customerOptionIndexFromSelection(String selection) {
    final RegExp prefix = RegExp(r'^\s*(\d+)\.');
    final Match? match = prefix.firstMatch(selection);
    if (match == null) {
      return -1;
    }

    final int? oneBased = int.tryParse(match.group(1) ?? '');
    if (oneBased == null) {
      return -1;
    }

    final int index = oneBased - 1;
    if (index < 0 || index >= _savedCustomerEntries.length) {
      return -1;
    }
    return index;
  }

  /// Parses and bounds-checks a recipient's one-based selector prefix.
  int _recipientOptionIndexFromSelection(String selection) {
    final RegExp prefix = RegExp(r'^\s*(\d+)\.');
    final Match? match = prefix.firstMatch(selection);
    if (match == null) {
      return -1;
    }

    final int? oneBased = int.tryParse(match.group(1) ?? '');
    if (oneBased == null) {
      return -1;
    }

    final int index = oneBased - 1;
    if (index < 0 || index >= _recipientProfiles.length) {
      return -1;
    }
    return index;
  }

  /// Applies a saved recipient selected by prefix or exact option label.
  void _applySavedRecipientFromSelection(String selection) {
    final String selected = selection.trim().toLowerCase();
    if (selected.isEmpty) {
      return;
    }

    final List<String> options = _contentRecipientSelectionOptions();
    int selectedIndex = _recipientOptionIndexFromSelection(selection);
    if (selectedIndex < 0) {
      for (int i = 0; i < options.length; i++) {
        if (options[i].toLowerCase() == selected) {
          selectedIndex = i;
          break;
        }
      }
    }

    if (selectedIndex < 0) {
      return;
    }

    final _RecipientProfile profile = _recipientProfiles[selectedIndex];
    setState(() {
      _contentRecipientSelectorController.text = options[selectedIndex];
      _companyController.text = profile.company;
      _departmentController.text = profile.department;
      _toController.text = profile.to;
      _ccController.text = profile.cc;
      _bccController.text = profile.bcc;
      _selectedCoworkerCcEmails.clear();
      _selectedCustomerToEmail = null;
      _recipientContacts
        ..clear()
        ..addAll(_contactsForRecipientProfile(profile));
      _syncRecipientContactFields();
    });

    _saveDraftState();
  }

  /// Replaces editable machines with the exactly selected saved machine.
  void _applySavedMachineFromSelection(String selection) {
    if (_selectedContentCustomerMachines.isEmpty) {
      return;
    }

    final String selected = selection.trim().toLowerCase();
    if (selected.isEmpty) {
      return;
    }

    int selectedIndex = -1;
    for (int i = 0; i < _selectedContentCustomerMachines.length; i++) {
      if (_savedMachineSelectionLabel(
            _selectedContentCustomerMachines[i],
            i,
          ).toLowerCase() ==
          selected) {
        selectedIndex = i;
        break;
      }
    }

    if (selectedIndex < 0) {
      return;
    }

    final _SavedCustomerMachine machine =
        _selectedContentCustomerMachines[selectedIndex];
    final _CustomerMachineEntry restored = _CustomerMachineEntry()
      ..isExpanded = true
      ..customerMachineName.text = machine.customerMachineName
      ..machineNumber.text = machine.machineNumber
      ..manufacturerMachineName.text = machine.manufacturerMachineName
      ..modelName.text = machine.modelName
      ..modelNumber.text = machine.modelNumber
      ..serialNumber.text = machine.serialNumber;

    setState(() {
      _contentMachineSelectorController.text = _savedMachineSelectionLabel(
        machine,
        selectedIndex,
      );
      for (final _CustomerMachineEntry existing in _customerMachines) {
        existing.dispose();
      }
      _customerMachines
        ..clear()
        ..add(restored);
    });

    _saveDraftState();
  }

  /// Collects machines from every entry representing the same customer.
  List<_SavedCustomerMachine> _collectMachinesForCustomer(
    _SavedCustomerEntry selected,
  ) {
    final List<_SavedCustomerMachine> result = <_SavedCustomerMachine>[];

    for (final _SavedCustomerEntry entry in _savedCustomerEntries) {
      if (!_isSameCustomerRecord(entry, selected)) {
        continue;
      }
      result.addAll(entry.machines);
    }

    return result;
  }

  /// Compares customer identity fields while deliberately ignoring machines.
  bool _isSameCustomerRecord(_SavedCustomerEntry a, _SavedCustomerEntry b) {
    return a.name.trim().toLowerCase() == b.name.trim().toLowerCase() &&
        a.email.trim().toLowerCase() == b.email.trim().toLowerCase() &&
        a.phone.trim().toLowerCase() == b.phone.trim().toLowerCase() &&
        a.shippingAddress.trim().toLowerCase() ==
            b.shippingAddress.trim().toLowerCase();
  }

  /// Converts non-empty machine controllers into persistable value objects.
  List<_SavedCustomerMachine> _buildSavedMachines() {
    return _customerMachines
        .where((_CustomerMachineEntry machine) => machine.hasData)
        .map(
          (_CustomerMachineEntry machine) => _SavedCustomerMachine(
            customerMachineName: machine.customerMachineName.text.trim(),
            machineNumber: machine.machineNumber.text.trim(),
            manufacturerMachineName: machine.manufacturerMachineName.text
                .trim(),
            modelName: machine.modelName.text.trim(),
            modelNumber: machine.modelNumber.text.trim(),
            serialNumber: machine.serialNumber.text.trim(),
          ),
        )
        .toList();
  }
}
