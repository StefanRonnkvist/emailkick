// ignore_for_file: invalid_use_of_protected_member
part of 'email_composer_page.dart';

extension _EmailComposerSectionCoworker on _EmailComposerPageState {
  void _bindCoworkerDraftListeners() {
    for (final _CoworkerEntry coworker in _coworkers) {
      for (final TextEditingController controller in coworker.controllers) {
        controller.addListener(_handleCoworkerChanged);
        _coworkerDraftControllers.add(controller);
      }
    }
  }

  void _unbindCoworkerDraftListeners() {
    for (final TextEditingController controller in _coworkerDraftControllers) {
      controller.removeListener(_handleCoworkerChanged);
    }
    _coworkerDraftControllers.clear();
  }

  Widget _coworkerCard() {
    return _SectionCard(
      title: 'Coworkers',
      children: <Widget>[
        if (_coworkers.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('No coworkers added.'),
          ),
        ...List<Widget>.generate(
          _coworkers.length,
          (int index) => _coworkerRow(index),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _addCoworker,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Coworker'),
          ),
        ),
      ],
    );
  }

  Widget _coworkerRow(int index) {
    final _CoworkerEntry coworker = _coworkers[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    coworker.name.text.trim().isEmpty
                        ? 'Coworker ${index + 1}'
                        : coworker.name.text.trim(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: coworker.isEditing
                      ? 'Save coworker ${index + 1}'
                      : 'Edit coworker ${index + 1}',
                  icon: Icon(
                    coworker.isEditing ? Icons.check : Icons.edit_outlined,
                  ),
                  onPressed: () => coworker.isEditing
                      ? _finishEditingCoworker(index)
                      : _editCoworker(index),
                ),
                IconButton(
                  tooltip: 'Delete coworker ${index + 1}',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteCoworker(index),
                ),
              ],
            ),
            if (coworker.isEditing) ...<Widget>[
              _textBox(
                coworker.name,
                'Coworker Name',
                hint: 'Alex Johnson',
                required: true,
                onChanged: (_) => _handleCoworkerChanged(),
              ),
              _textBox(
                coworker.email,
                'Coworker Email',
                hint: 'alex.johnson@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: _validateOptionalSingleEmail,
                onChanged: (_) => _handleCoworkerChanged(),
              ),
              _textBox(
                coworker.phone,
                'Coworker Phone',
                hint: '+1 555 123 4567',
                keyboardType: TextInputType.phone,
                onChanged: (_) => _handleCoworkerChanged(),
              ),
              _textBox(
                coworker.role,
                'Coworker Role',
                hint: 'Account Manager',
                onChanged: (_) => _handleCoworkerChanged(),
              ),
            ] else ...<Widget>[
              if (coworker.email.text.trim().isNotEmpty)
                _summaryTextLine('Email', coworker.email.text),
              if (coworker.phone.text.trim().isNotEmpty)
                _summaryTextLine('Phone', coworker.phone.text),
              if (coworker.role.text.trim().isNotEmpty)
                _summaryTextLine('Role', coworker.role.text),
            ],
          ],
        ),
      ),
    );
  }

  void _handleCoworkerChanged() {
    setState(() {});
    _syncSelectedCoworkersToCc();
    _saveDraftState();
  }

  void _addCoworker() {
    final _CoworkerEntry coworker = _CoworkerEntry();
    for (final TextEditingController controller in coworker.controllers) {
      controller.addListener(_handleCoworkerChanged);
      _coworkerDraftControllers.add(controller);
    }
    setState(() {
      _coworkers.add(coworker);
    });
    _saveDraftState();
  }

  void _editCoworker(int index) {
    setState(() {
      _coworkers[index].isEditing = true;
    });
    _saveDraftState();
  }

  void _finishEditingCoworker(int index) {
    setState(() {
      _coworkers[index].isEditing = false;
    });
    _saveDraftState();
  }

  void _deleteCoworker(int index) {
    final _CoworkerEntry coworker = _coworkers.removeAt(index);
    for (final TextEditingController controller in coworker.controllers) {
      controller.removeListener(_handleCoworkerChanged);
      _coworkerDraftControllers.remove(controller);
    }
    _selectedCoworkerCcEmails.remove(coworker.email.text.trim().toLowerCase());
    setState(() {
      _recipientContacts.removeWhere(
        (_EmailRecipient contact) =>
            contact.email.toLowerCase() ==
            coworker.email.text.trim().toLowerCase(),
      );
      coworker.dispose();
      _syncRecipientContactFields();
    });
    _saveDraftState();
  }
}
