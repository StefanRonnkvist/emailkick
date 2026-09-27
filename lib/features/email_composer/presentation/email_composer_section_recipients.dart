// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionRecipients on _EmailComposerPageState {
  Widget _recipientCard() {
    if (_isRecipientsCollapsed) {
      return _SectionCard(
        title: 'Recipients',
        children: <Widget>[
          FilledButton.icon(
            onPressed: () {
              setState(() {
                _isRecipientsCollapsed = false;
              });
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Recipients'),
          ),
          const SizedBox(height: 12),
          _recipientValuesTable(),
        ],
      );
    }

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
                  },
                  child: const Text('Cancel'),
                ),
              ],
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
          },
          onOptionSelected: (String value) {
            _applyRecipientProfileFromField(_ProfileField.company, value);
          },
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
          },
          onOptionSelected: (String value) {
            _applyRecipientProfileFromField(_ProfileField.department, value);
          },
        ),
        _dropdownTextBox(
          _toController,
          focusNode: _toFocusNode,
          label: 'To (comma-separated emails)',
          hint: 'alice@example.com,bob@example.com',
          options: _toOptions,
          onValueCommitted: (String value) {
            _commitEmailListOptions(value, target: _toOptions);
            _commitRecipientProfile();
          },
          onOptionSelected: (String value) {
            _applyRecipientProfileFromField(_ProfileField.to, value);
          },
          validator: (String? value) =>
              _validateEmailList(value, required: true),
          maxLines: 2,
        ),
        _dropdownTextBox(
          _ccController,
          focusNode: _ccFocusNode,
          label: 'CC (optional)',
          options: _ccOptions,
          onValueCommitted: (String value) {
            _commitEmailListOptions(value, target: _ccOptions);
            _commitRecipientProfile();
          },
          onOptionSelected: (String value) {
            _applyRecipientProfileFromField(_ProfileField.cc, value);
          },
          maxLines: 2,
          validator: _validateOptionalEmailList,
        ),
        _dropdownTextBox(
          _bccController,
          focusNode: _bccFocusNode,
          label: 'BCC (optional)',
          options: _bccOptions,
          onValueCommitted: (String value) {
            _commitEmailListOptions(value, target: _bccOptions);
            _commitRecipientProfile();
          },
          onOptionSelected: (String value) {
            _applyRecipientProfileFromField(_ProfileField.bcc, value);
          },
          maxLines: 2,
          validator: _validateOptionalEmailList,
        ),
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
