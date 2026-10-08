// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionRecipients on _EmailComposerPageState {
  Widget _contactsCard() {
    return Column(
      children: <Widget>[
        _recipientCard(),
        const SizedBox(height: 16),
        _customerCard(),
      ],
    );
  }

  Widget _recipientCard() {
    return _SectionCard(
      title: 'Recipients',
      children: <Widget>[
        if (_editingRecipientProfile != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.edit_note_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Editing saved recipients. Save Recipients will update this entry.',
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _editingRecipientProfile = null;
                    });
                    _saveDraftState();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Company and department details, plus the To, CC, and BCC contact roster.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        _dropdownTextBox(
          _companyController,
          focusNode: _companyFocusNode,
          label: 'Company',
          hint: 'Acme Corp',
          options: _companyOptions,
          onValueCommitted: (String value) {
            _commitRecipientOption(value, forCompany: true);
            _commitRecipientProfile();
            _saveDraftState();
          },
          onOptionSelected: (String value) {
            _applyRecipientProfileFromField(_ProfileField.company, value);
            _saveDraftState();
          },
          onChanged: (_) => _saveDraftState(),
        ),
        _dropdownTextBox(
          _departmentController,
          focusNode: _departmentFocusNode,
          label: 'Department',
          hint: 'Sales',
          options: _departmentOptions,
          onValueCommitted: (String value) {
            _commitRecipientOption(value, forCompany: false);
            _commitRecipientProfile();
            _saveDraftState();
          },
          onOptionSelected: (String value) {
            _applyRecipientProfileFromField(_ProfileField.department, value);
            _saveDraftState();
          },
          onChanged: (_) => _saveDraftState(),
        ),
        ..._recipientContactsFields(),
        _recipientContactsTable(),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _saveRecipients,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Recipients'),
          ),
        ),
        const SizedBox(height: 12),
        _recipientValuesTable(),
      ],
    );
  }

  Widget _recipientValuesTable() {
    if (_recipientProfiles.isEmpty) {
      return const Text('No saved recipient values yet.');
    }

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Company')),
            DataColumn(label: Text('Department')),
            DataColumn(label: Text('To')),
            DataColumn(label: Text('CC')),
            DataColumn(label: Text('BCC')),
            DataColumn(label: Text('Actions')),
          ],
          rows: List<DataRow>.generate(_recipientProfiles.length, (int index) {
            final _RecipientProfile profile = _recipientProfiles[index];
            return DataRow(
              cells: <DataCell>[
                DataCell(Text(_tableValue(profile.company))),
                DataCell(Text(_tableValue(profile.department))),
                DataCell(Text(_tableValue(profile.to))),
                DataCell(Text(_tableValue(profile.cc))),
                DataCell(Text(_tableValue(profile.bcc))),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Edit Recipients',
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editRecipientProfile(index),
                      ),
                      IconButton(
                        tooltip: 'Delete Recipients',
                        constraints: const BoxConstraints.tightFor(
                          width: 36,
                          height: 36,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteRecipientProfile(index),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

extension _EmailComposerRecipientContacts on _EmailComposerPageState {
  List<Widget> _recipientContactsFields() {
    return <Widget>[
      if (_editingRecipientContact != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _cancelRecipientContactEdit,
            icon: const Icon(Icons.close),
            label: const Text('Cancel editing individual'),
          ),
        ),
      _textBox(
        _recipientNameController,
        'Name',
        onChanged: (_) => _saveDraftState(),
      ),
      _textBox(
        _recipientPositionController,
        'Position',
        onChanged: (_) => _saveDraftState(),
      ),
      _textBox(
        _recipientPhoneController,
        'Phone',
        keyboardType: TextInputType.phone,
        onChanged: (_) => _saveDraftState(),
      ),
      _textBox(
        _recipientEmailController,
        'Email',
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) => _saveDraftState(),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: _addRecipientContact,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Individual'),
        ),
      ),
    ];
  }

  Widget _recipientContactsTable() {
    if (_recipientContacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text('No individuals added yet.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const <DataColumn>[
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Position')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Recipient Type')),
            DataColumn(label: Text('Actions')),
          ],
          rows: List<DataRow>.generate(_recipientContacts.length, (int index) {
            final _EmailRecipient contact = _recipientContacts[index];
            return DataRow(
              cells: <DataCell>[
                DataCell(Text(_tableValue(contact.name))),
                DataCell(Text(_tableValue(contact.position))),
                DataCell(Text(_tableValue(contact.phone))),
                DataCell(Text(contact.email)),
                DataCell(
                  DropdownButton<String>(
                    value: contact.type,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(value: 'to', child: Text('To')),
                      DropdownMenuItem<String>(value: 'cc', child: Text('CC')),
                      DropdownMenuItem<String>(
                        value: 'bcc',
                        child: Text('BCC'),
                      ),
                    ],
                    onChanged: (String? selectedType) {
                      if (selectedType != null) {
                        _setRecipientContactType(index, selectedType);
                      }
                    },
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        tooltip: 'Edit individual',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _editRecipientContact(index),
                      ),
                      IconButton(
                        tooltip: 'Delete individual',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteRecipientContact(index),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  void _addRecipientContact() {
    final String name = _recipientNameController.text.trim();
    final String position = _recipientPositionController.text.trim();
    final String phone = _recipientPhoneController.text.trim();
    final String email = _recipientEmailController.text.trim();
    if (email.isEmpty || _validateOptionalSingleEmail(email) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid individual email address.'),
        ),
      );
      return;
    }

    final _EmailRecipient contact = _EmailRecipient(
      name: name,
      position: position,
      phone: phone,
      email: email,
      type: _recipientContactType,
    );
    final int? editingIndex = _editingRecipientContact;
    setState(() {
      if (editingIndex != null &&
          editingIndex >= 0 &&
          editingIndex < _recipientContacts.length) {
        _recipientContacts[editingIndex] = contact;
      } else {
        _recipientContacts.removeWhere(
          (_EmailRecipient existing) =>
              existing.email.toLowerCase() == email.toLowerCase(),
        );
        _recipientContacts.add(contact);
      }
      _editingRecipientContact = null;
      _recipientNameController.clear();
      _recipientPositionController.clear();
      _recipientPhoneController.clear();
      _recipientEmailController.clear();
      _recipientContactType = 'to';
      _syncRecipientContactFields();
    });
    _saveDraftState();
  }

  void _editRecipientContact(int index) {
    if (index < 0 || index >= _recipientContacts.length) {
      return;
    }
    final _EmailRecipient contact = _recipientContacts[index];
    setState(() {
      _editingRecipientContact = index;
      _recipientNameController.text = contact.name;
      _recipientPositionController.text = contact.position;
      _recipientPhoneController.text = contact.phone;
      _recipientEmailController.text = contact.email;
      _recipientContactType = contact.type;
    });
    _saveDraftState();
  }

  void _cancelRecipientContactEdit() {
    setState(() {
      _editingRecipientContact = null;
      _recipientNameController.clear();
      _recipientPositionController.clear();
      _recipientPhoneController.clear();
      _recipientEmailController.clear();
      _recipientContactType = 'to';
    });
    _saveDraftState();
  }

  void _deleteRecipientContact(int index) {
    if (index < 0 || index >= _recipientContacts.length) {
      return;
    }
    setState(() {
      _recipientContacts.removeAt(index);
      if (_editingRecipientContact == index) {
        _editingRecipientContact = null;
      } else if (_editingRecipientContact case final int editIndex
          when editIndex > index) {
        _editingRecipientContact = editIndex - 1;
      }
      _syncRecipientContactFields();
    });
    _saveDraftState();
  }

  void _setRecipientContactType(int index, String type) {
    if (index < 0 || index >= _recipientContacts.length) {
      return;
    }
    final _EmailRecipient contact = _recipientContacts[index];
    setState(() {
      _recipientContacts[index] = _EmailRecipient(
        name: contact.name,
        position: contact.position,
        phone: contact.phone,
        email: contact.email,
        type: type,
      );
      _syncRecipientContactFields();
    });
    _saveDraftState();
  }

  List<_EmailRecipient> _contactsForRecipientProfile(
    _RecipientProfile profile,
  ) {
    if (profile.contacts.isNotEmpty) {
      return List<_EmailRecipient>.from(profile.contacts);
    }
    return <_EmailRecipient>[
      for (final (String, String) assignment in <(String, String)>[
        ('to', profile.to),
        ('cc', profile.cc),
        ('bcc', profile.bcc),
      ])
        for (final String email
            in assignment.$2
                .split(',')
                .map((String item) => item.trim())
                .where((String item) => item.isNotEmpty))
          _EmailRecipient(
            name: '',
            position: '',
            phone: '',
            email: email,
            type: assignment.$1,
          ),
    ];
  }

  void _syncRecipientContactFields() {
    final List<String> toEmails = _recipientContacts
        .where((_EmailRecipient contact) => contact.type == 'to')
        .map((_EmailRecipient contact) => contact.email)
        .toList();
    final List<String> ccEmails = _recipientContacts
        .where((_EmailRecipient contact) => contact.type == 'cc')
        .map((_EmailRecipient contact) => contact.email)
        .toList();
    final List<String> bccEmails = _recipientContacts
        .where((_EmailRecipient contact) => contact.type == 'bcc')
        .map((_EmailRecipient contact) => contact.email)
        .toList();
    if (_selectedCustomerToEmail case final String email
        when email.isNotEmpty && !toEmails.contains(email)) {
      toEmails.add(email);
    }
    for (final String email in _selectedCoworkerCcEmails) {
      if (email.isNotEmpty && !ccEmails.contains(email)) {
        ccEmails.add(email);
      }
    }
    _toController.text = toEmails.join(', ');
    _ccController.text = ccEmails.join(', ');
    _bccController.text = bccEmails.join(', ');
    _saveDraftState();
  }
}
