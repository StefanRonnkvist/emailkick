// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionContent on _EmailComposerPageState {
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
          },
          onChanged: (_) => _syncPreheaderFromOrderFields(),
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
          },
          onChanged: (_) => _syncPreheaderFromOrderFields(),
        ),
        _dropdownTextBox(
          _partNumberController,
          focusNode: _partNumberFocusNode,
          label: 'Part Number',
          hint: 'PN-12345',
          options: _partNumberOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _partNumberOptions);
          },
        ),
        _dropdownTextBox(
          _partDescriptionController,
          focusNode: _partDescriptionFocusNode,
          label: 'Part Description',
          hint: 'Example part details',
          options: _partDescriptionOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _partDescriptionOptions);
          },
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
          },
        ),
        _dropdownTextBox(
          _preheaderController,
          focusNode: _preheaderFocusNode,
          label: 'Preheader',
          hint: 'Shown next to subject in inboxes',
          options: _preheaderOptions,
          onValueCommitted: (String value) {
            _commitContentOption(value, target: _preheaderOptions);
          },
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
          },
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
