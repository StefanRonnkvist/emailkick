// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionCoworker on _EmailComposerPageState {
  Widget _coworkerCard() {
    return _SectionCard(
      title: 'Coworker Contact Information',
      children: <Widget>[
        _textBox(
          _coworkerNameController,
          'Coworker Name',
          hint: 'Alex Johnson',
          required: true,
        ),
        _textBox(
          _coworkerEmailController,
          'Coworker Email',
          hint: 'alex.johnson@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: _validateOptionalSingleEmail,
        ),
        _textBox(
          _coworkerPhoneController,
          'Coworker Phone',
          hint: '+1 555 123 4567',
          keyboardType: TextInputType.phone,
        ),
        _textBox(
          _coworkerRoleController,
          'Coworker Role',
          hint: 'Account Manager',
        ),
      ],
    );
  }
}
