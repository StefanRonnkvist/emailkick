// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionSender on _EmailComposerPageState {
  Widget _senderCard() {
    if (_isSenderCollapsed) {
      return _SectionCard(
        title: 'Sender Details',
        children: <Widget>[
          _summaryTextLine('From Name', _fromNameController.text),
          _summaryTextLine('From Email', _fromEmailController.text),
          _summaryTextLine('Reply-To Email', _replyToController.text),
          _summaryTextLine('Phone Number', _phoneController.text),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isSenderCollapsed = false;
                  });
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Sender Details'),
              ),
              FilledButton.tonalIcon(
                onPressed: _resetSenderSetup,
                icon: const Icon(Icons.person_off_outlined),
                label: const Text('Reset Sender Setup'),
              ),
            ],
          ),
        ],
      );
    }

    return _SectionCard(
      title: 'Sender Details',
      children: <Widget>[
        _dropdownTextBox(
          _fromNameController,
          focusNode: _fromNameFocusNode,
          label: 'From Name',
          hint: 'EmailKick Team',
          options: _senderNameOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _senderNameOptions);
            _commitSenderProfile();
            _saveSenderSetup();
            _saveDraftState();
          },
          onOptionSelected: (String value) {
            _applySenderProfileFromField(_ProfileField.fromName, value);
            _saveDraftState();
          },
          onChanged: (_) {
            _saveSenderSetup();
            _saveDraftState();
          },
        ),
        _dropdownTextBox(
          _fromEmailController,
          focusNode: _fromEmailFocusNode,
          label: 'From Email',
          hint: 'team@example.com',
          validator: _validateOptionalSingleEmail,
          options: _senderEmailOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _senderEmailOptions);
            _commitSenderProfile();
            _saveSenderSetup();
            _saveDraftState();
          },
          onOptionSelected: (String value) {
            _applySenderProfileFromField(_ProfileField.fromEmail, value);
            _saveDraftState();
          },
          onChanged: (_) {
            _saveSenderSetup();
            _saveDraftState();
          },
        ),
        _dropdownTextBox(
          _replyToController,
          focusNode: _replyToFocusNode,
          label: 'Reply-To Email',
          hint: 'support@example.com',
          validator: _validateOptionalSingleEmail,
          options: _replyToOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _replyToOptions);
            _commitSenderProfile();
            _handleReplyToChanged(value);
            _saveDraftState();
          },
          onOptionSelected: (String value) {
            _applySenderProfileFromField(_ProfileField.replyTo, value);
            _saveDraftState();
          },
          onChanged: (String value) {
            _handleReplyToChanged(value);
            _saveDraftState();
          },
        ),
        _dropdownTextBox(
          _phoneController,
          focusNode: _senderPhoneFocusNode,
          label: 'Phone Number',
          hint: '+1 555 123 4567',
          keyboardType: TextInputType.phone,
          options: _senderPhoneOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _senderPhoneOptions);
            _commitSenderProfile();
            _saveSenderSetup();
            _saveDraftState();
          },
          onOptionSelected: (String value) {
            _applySenderProfileFromField(_ProfileField.phone, value);
            _saveDraftState();
          },
          onChanged: (_) {
            _saveSenderSetup();
            _saveDraftState();
          },
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _saveSenderDetails,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Sender Details'),
            ),
            FilledButton.tonalIcon(
              onPressed: _resetSenderSetup,
              icon: const Icon(Icons.person_off_outlined),
              label: const Text('Reset Sender Setup'),
            ),
          ],
        ),
      ],
    );
  }
}
