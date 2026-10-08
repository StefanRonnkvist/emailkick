// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionContent on _EmailComposerPageState {
  Widget _buildCustomerToSelector() {
    final String customerEmail = _selectedContentCustomer?.email.trim() ?? '';
    final bool hasEmail = customerEmail.isNotEmpty;
    final bool isCustomerInRecipientTable = _recipientContacts.any(
      (_EmailRecipient contact) =>
          contact.email.toLowerCase() == customerEmail.toLowerCase(),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: _isCustomerToTableExpanded,
          onExpansionChanged: (bool expanded) {
            setState(() => _isCustomerToTableExpanded = expanded);
            _saveDraftState();
          },
          title: const Text('Customer to To field'),
          subtitle: Text(
            _selectedContentCustomer == null
                ? 'Select a saved customer first'
                : hasEmail
                ? customerEmail
                : 'Selected customer has no email address',
          ),
          children: <Widget>[
            if (_selectedContentCustomer == null)
              const ListTile(title: Text('Choose a saved customer above.'))
            else
              CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  _selectedContentCustomer!.name.trim().isEmpty
                      ? 'Customer'
                      : _selectedContentCustomer!.name.trim(),
                ),
                subtitle: Text(hasEmail ? customerEmail : 'No email address'),
                value:
                    hasEmail &&
                    (isCustomerInRecipientTable ||
                        _selectedCustomerToEmail?.toLowerCase() ==
                            customerEmail.toLowerCase()),
                onChanged: !hasEmail
                    ? null
                    : (bool? checked) => _setCustomerToSelection(
                        customerEmail,
                        checked ?? false,
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoworkerCcSelector() {
    final int selectedCount = _recipientContacts
        .where(
          (_EmailRecipient contact) =>
              _coworkers.any(
                (_CoworkerEntry coworker) =>
                    coworker.email.text.trim().toLowerCase() ==
                    contact.email.toLowerCase(),
              ) &&
              contact.type == 'cc',
        )
        .length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ExpansionTile(
          initiallyExpanded: _isCoworkerCcTableExpanded,
          onExpansionChanged: (bool expanded) {
            setState(() => _isCoworkerCcTableExpanded = expanded);
            _saveDraftState();
          },
          title: const Text('Coworkers to CC field'),
          subtitle: Text('$selectedCount selected'),
          children: <Widget>[
            if (_coworkers.isEmpty)
              const ListTile(title: Text('No coworkers added yet.'))
            else
              ...List<Widget>.generate(_coworkers.length, (int index) {
                final _CoworkerEntry coworker = _coworkers[index];
                final String email = coworker.email.text.trim();
                return CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    coworker.name.text.trim().isEmpty
                        ? 'Coworker ${index + 1}'
                        : coworker.name.text.trim(),
                  ),
                  subtitle: Text(email.isEmpty ? 'No email address' : email),
                  value: _recipientContacts.any(
                    (_EmailRecipient contact) =>
                        contact.email.toLowerCase() == email.toLowerCase() &&
                        contact.type == 'cc',
                  ),
                  onChanged: email.isEmpty
                      ? null
                      : (bool? checked) =>
                            _setCoworkerCcSelection(index, checked ?? false),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _setCustomerToSelection(String email, bool selected) {
    final String? previousCustomerEmail = _selectedCustomerToEmail;
    final String normalizedEmail = email.trim().toLowerCase();
    setState(() {
      _selectedCustomerToEmail = selected ? email.trim() : null;
      final int existingContactIndex = _recipientContacts.indexWhere(
        (_EmailRecipient contact) =>
            contact.email.toLowerCase() == normalizedEmail,
      );
      if (selected && _selectedContentCustomer != null) {
        final _EmailRecipient customerContact = _EmailRecipient(
          name: _selectedContentCustomer!.name,
          position: 'Customer',
          phone: _selectedContentCustomer!.phone,
          email: email.trim(),
          type: 'to',
        );
        if (existingContactIndex < 0) {
          _recipientContacts.add(customerContact);
        } else {
          final _EmailRecipient existing =
              _recipientContacts[existingContactIndex];
          _recipientContacts[existingContactIndex] = _EmailRecipient(
            name: existing.name.isEmpty ? customerContact.name : existing.name,
            position: existing.position.isEmpty
                ? customerContact.position
                : existing.position,
            phone: existing.phone.isEmpty
                ? customerContact.phone
                : existing.phone,
            email: existing.email,
            type: 'to',
          );
        }
      } else if (!selected && existingContactIndex >= 0) {
        final _EmailRecipient existing =
            _recipientContacts[existingContactIndex];
        if (existing.position == 'Customer') {
          _recipientContacts.removeAt(existingContactIndex);
        } else if (existing.type == 'to') {
          final String newType =
              existing.email.toLowerCase() ==
                  previousCustomerEmail?.toLowerCase()
              ? 'cc'
              : 'to';
          _recipientContacts[existingContactIndex] = _EmailRecipient(
            name: existing.name,
            position: existing.position,
            phone: existing.phone,
            email: existing.email,
            type: newType,
          );
        }
      }
      _syncRecipientContactFields();
    });
    _saveDraftState();
  }

  void _setCoworkerCcSelection(int index, bool selected) {
    if (index < 0 || index >= _coworkers.length) {
      return;
    }
    final _CoworkerEntry coworker = _coworkers[index];
    final String email = coworker.email.text.trim();
    final String normalizedEmail = email.toLowerCase();
    setState(() {
      if (selected) {
        _selectedCoworkerCcEmails.add(normalizedEmail);
        final int existingContactIndex = _recipientContacts.indexWhere(
          (_EmailRecipient contact) =>
              contact.email.toLowerCase() == normalizedEmail,
        );
        final String position = coworker.role.text.trim();
        if (existingContactIndex < 0) {
          _recipientContacts.add(
            _EmailRecipient(
              name: coworker.name.text.trim(),
              position: position,
              phone: coworker.phone.text.trim(),
              email: email,
              type: 'cc',
            ),
          );
        } else {
          final _EmailRecipient existing =
              _recipientContacts[existingContactIndex];
          _recipientContacts[existingContactIndex] = _EmailRecipient(
            name: existing.name.isEmpty
                ? coworker.name.text.trim()
                : existing.name,
            position: existing.position.isEmpty ? position : existing.position,
            phone: existing.phone.isEmpty
                ? coworker.phone.text.trim()
                : existing.phone,
            email: existing.email,
            type: 'cc',
          );
        }
      } else {
        _selectedCoworkerCcEmails.remove(normalizedEmail);
        final int selectedContactIndex = _recipientContacts.indexWhere(
          (_EmailRecipient contact) =>
              contact.email.toLowerCase() == normalizedEmail &&
              contact.position == coworker.role.text.trim(),
        );
        if (selectedContactIndex >= 0) {
          final _EmailRecipient contact =
              _recipientContacts[selectedContactIndex];
          _recipientContacts[selectedContactIndex] = _EmailRecipient(
            name: contact.name,
            position: contact.position,
            phone: contact.phone,
            email: contact.email,
            type: 'to',
          );
        }
      }
      _syncRecipientContactFields();
    });
    _saveDraftState();
  }

  void _syncSelectedCoworkersToCc() {
    final Set<String> selectedCoworkerEmails = _selectedCoworkerCcEmails;
    final Set<String> coworkerEmails = _coworkers
        .map(
          (_CoworkerEntry coworker) => coworker.email.text.trim().toLowerCase(),
        )
        .where((String email) => email.isNotEmpty)
        .toSet();
    _recipientContacts.removeWhere(
      (_EmailRecipient contact) =>
          coworkerEmails.contains(contact.email.toLowerCase()) &&
          contact.position.isNotEmpty &&
          _coworkers.any(
            (_CoworkerEntry coworker) =>
                coworker.email.text.trim().toLowerCase() ==
                    contact.email.toLowerCase() &&
                coworker.role.text.trim().toLowerCase() ==
                    contact.position.toLowerCase(),
          ) &&
          !selectedCoworkerEmails.contains(contact.email.toLowerCase()),
    );
    final Set<String> recipientEmails = _recipientContacts
        .where((_EmailRecipient contact) => contact.type == 'cc')
        .map((_EmailRecipient contact) => contact.email.trim().toLowerCase())
        .toSet();
    for (final String email in _selectedCoworkerCcEmails) {
      if (email.isEmpty) {
        continue;
      }
      final int existingContactIndex = _recipientContacts.indexWhere(
        (_EmailRecipient contact) =>
            contact.email.trim().toLowerCase() == email,
      );
      if (existingContactIndex >= 0) {
        final _EmailRecipient existing =
            _recipientContacts[existingContactIndex];
        _recipientContacts[existingContactIndex] = _EmailRecipient(
          name: existing.name,
          position: existing.position,
          phone: existing.phone,
          email: existing.email,
          type: 'cc',
        );
        recipientEmails.add(email);
        continue;
      }
      final _CoworkerEntry? coworker = _coworkers
          .cast<_CoworkerEntry?>()
          .firstWhere(
            (_CoworkerEntry? entry) =>
                entry?.email.text.trim().toLowerCase() == email,
            orElse: () => null,
          );
      if (coworker != null) {
        _recipientContacts.add(
          _EmailRecipient(
            name: coworker.name.text.trim(),
            position: coworker.role.text.trim(),
            phone: coworker.phone.text.trim(),
            email: coworker.email.text.trim(),
            type: 'cc',
          ),
        );
        recipientEmails.add(email);
      }
    }
    _syncRecipientContactFields();
  }

  Widget _contentCard() {
    final List<String> recipientOptions = _contentRecipientSelectionOptions();
    final List<String> customerOptions = _contentCustomerSelectionOptions();
    final List<String> machineOptions = _selectedContentCustomerMachines.isEmpty
        ? <String>[]
        : List<String>.generate(
            _selectedContentCustomerMachines.length,
            (int index) => _savedMachineSelectionLabel(
              _selectedContentCustomerMachines[index],
              index,
            ),
          );

    return _SectionCard(
      title: 'Content',
      children: <Widget>[
        _buildCustomerToSelector(),
        _buildCoworkerCcSelector(),
        if (recipientOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue:
                  recipientOptions.contains(
                    _contentRecipientSelectorController.text,
                  )
                  ? _contentRecipientSelectorController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Select Saved Recipient',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose recipient data for this content'),
              isExpanded: true,
              items: recipientOptions
                  .map(
                    (String option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                _contentRecipientSelectorController.text = value;
                _applySavedRecipientFromSelection(value);
                _saveDraftState();
              },
            ),
          ),
        if (customerOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue:
                  customerOptions.contains(
                    _contentCustomerSelectorController.text,
                  )
                  ? _contentCustomerSelectorController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Select Saved Customer',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose customer data for this content'),
              isExpanded: true,
              items: customerOptions
                  .map(
                    (String option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                _contentCustomerSelectorController.text = value;
                _applySavedCustomerFromSelection(value);
                _saveDraftState();
              },
            ),
          ),
        if (machineOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${machineOptions.length} machines available',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (machineOptions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue:
                  machineOptions.contains(
                    _contentMachineSelectorController.text,
                  )
                  ? _contentMachineSelectorController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Select Saved Machine',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Choose machine for selected customer'),
              isExpanded: true,
              items: machineOptions
                  .map(
                    (String option) => DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    ),
                  )
                  .toList(),
              onChanged: (String? value) {
                if (value == null) {
                  return;
                }
                _contentMachineSelectorController.text = value;
                _applySavedMachineFromSelection(value);
                _saveDraftState();
              },
            ),
          ),
        if (_selectedContentCustomer != null && machineOptions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('No machines saved for this customer yet.'),
          ),
        _dropdownTextBox(
          _workOrderController,
          focusNode: _workOrderFocusNode,
          label: 'Work Order',
          hint: 'WO-12345',
          options: _workOrderOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _workOrderOptions);
            _syncPreheaderFromOrderFields();
            _saveDraftState();
          },
          onChanged: (_) {
            _syncPreheaderFromOrderFields();
            _saveDraftState();
          },
        ),
        _dropdownTextBox(
          _purchaseOrderController,
          focusNode: _purchaseOrderFocusNode,
          label: 'Purchase Order',
          hint: 'PO-12345',
          options: _purchaseOrderOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _purchaseOrderOptions);
            _syncPreheaderFromOrderFields();
            _saveDraftState();
          },
          onChanged: (_) {
            _syncPreheaderFromOrderFields();
            _saveDraftState();
          },
        ),
        _dropdownTextBox(
          _partNumberController,
          focusNode: _partNumberFocusNode,
          label: 'Part Number',
          hint: 'PN-12345',
          options: _partNumberOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _partNumberOptions);
            _saveDraftState();
          },
          onChanged: (_) => _saveDraftState(),
        ),
        _dropdownTextBox(
          _partDescriptionController,
          focusNode: _partDescriptionFocusNode,
          label: 'Part Description',
          hint: 'Example part details',
          options: _partDescriptionOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _partDescriptionOptions);
            _saveDraftState();
          },
          onChanged: (_) => _saveDraftState(),
        ),
        Text(
          'Content Mode',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Expedite'),
          value: _selectedContentModes.contains(_ContentMode.expedite),
          onChanged: (bool? checked) {
            setState(() {
              if (checked ?? false) {
                _selectedContentModes.add(_ContentMode.expedite);
              } else {
                _selectedContentModes.remove(_ContentMode.expedite);
              }
              _syncSubjectFromContentModes();
            });
            _saveDraftState();
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Technician on Site'),
          value: _selectedContentModes.contains(_ContentMode.rush),
          onChanged: (bool? checked) {
            setState(() {
              if (checked ?? false) {
                _selectedContentModes.add(_ContentMode.rush);
              } else {
                _selectedContentModes.remove(_ContentMode.rush);
              }
              _syncSubjectFromContentModes();
            });
            _saveDraftState();
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Machine Down'),
          value: _selectedContentModes.contains(_ContentMode.machineDown),
          onChanged: (bool? checked) {
            setState(() {
              if (checked ?? false) {
                _selectedContentModes.add(_ContentMode.machineDown);
              } else {
                _selectedContentModes.remove(_ContentMode.machineDown);
              }
              _syncSubjectFromContentModes();
            });
            _saveDraftState();
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Part Lookup'),
          value: _selectedContentModes.contains(_ContentMode.partLookup),
          onChanged: (bool? checked) {
            setState(() {
              if (checked ?? false) {
                _selectedContentModes.add(_ContentMode.partLookup);
              } else {
                _selectedContentModes.remove(_ContentMode.partLookup);
              }
              _syncSubjectFromContentModes();
            });
            _saveDraftState();
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Quote Part'),
          value: _selectedContentModes.contains(_ContentMode.quotePart),
          onChanged: (bool? checked) {
            setState(() {
              if (checked ?? false) {
                _selectedContentModes.add(_ContentMode.quotePart);
              } else {
                _selectedContentModes.remove(_ContentMode.quotePart);
              }
              _syncSubjectFromContentModes();
            });
            _saveDraftState();
          },
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ship Immediately'),
          value: _selectedContentModes.contains(_ContentMode.shipImmediately),
          onChanged: (bool? checked) {
            setState(() {
              if (checked ?? false) {
                _selectedContentModes.add(_ContentMode.shipImmediately);
              } else {
                _selectedContentModes.remove(_ContentMode.shipImmediately);
              }
              _syncSubjectFromContentModes();
            });
            _saveDraftState();
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Documents',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickDocuments,
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Upload Documents'),
        ),
        if (_selectedDocuments.isNotEmpty)
          ..._selectedDocuments.map(
            (_DraftDocument document) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined),
              title: Text(_documentUrlPath(document)),
              trailing: IconButton(
                tooltip: 'Remove Document',
                icon: const Icon(Icons.close),
                onPressed: () => _removeDocument(document),
              ),
            ),
          ),
        const SizedBox(height: 4),
        _dropdownTextBox(
          _subjectController,
          focusNode: _subjectFocusNode,
          label: 'Subject',
          options: _subjectOptions,
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Required';
            }
            return null;
          },
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _subjectOptions);
            _saveDraftState();
          },
          onChanged: (_) => _saveDraftState(),
        ),
        _dropdownTextBox(
          _preheaderController,
          focusNode: _preheaderFocusNode,
          label: 'Preheader',
          hint: 'Shown next to subject in inboxes',
          options: _preheaderOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _preheaderOptions);
            _saveDraftState();
          },
          onChanged: (_) => _saveDraftState(),
        ),
        _dropdownTextBox(
          _plainTextBodyController,
          focusNode: _plainTextBodyFocusNode,
          label: 'Plain Text Body',
          options: _plainTextBodyOptions,
          validator: (String? value) {
            if (value == null || value.trim().isEmpty) {
              return 'Required';
            }
            return null;
          },
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _plainTextBodyOptions);
            _saveDraftState();
          },
          onChanged: (_) => _saveDraftState(),
          maxLines: 8,
          minLines: 5,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _openInEmailClient,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Open Draft in Mail App'),
          ),
        ),
      ],
    );
  }
}
