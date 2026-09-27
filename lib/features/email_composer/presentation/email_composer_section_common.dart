// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionCommon on _EmailComposerPageState {
  Widget _summaryTextLine(String label, String value) {
    final String displayValue = value.trim().isEmpty ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $displayValue'),
    );
  }

  String _tableValue(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  Widget _dropdownTextBox(
    TextEditingController controller, {
    required FocusNode focusNode,
    required String label,
    String? hint,
    bool filterOptionsByQuery = true,
    int maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    required List<String> options,
    required ValueChanged<String> onValueCommitted,
    ValueChanged<String>? onOptionSelected,
    ValueChanged<String>? onChanged,
  }) {
    if (options.isEmpty) {
      return _textBox(
        controller,
        label,
        hint: hint,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (!filterOptionsByQuery) {
            return options;
          }
          final String query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) {
            return options;
          }
          return options.where(
            (String option) => option.toLowerCase().contains(query),
          );
        },
        displayStringForOption: (String option) => option,
        onSelected: (String selection) {
          controller.text = selection;
          onOptionSelected?.call(selection);
          onValueCommitted(selection);
        },
        fieldViewBuilder:
            (
              BuildContext context,
              TextEditingController textEditingController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted,
            ) {
              return TextFormField(
                controller: textEditingController,
                focusNode: fieldFocusNode,
                keyboardType: keyboardType,
                maxLines: maxLines,
                minLines: minLines,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  border: const OutlineInputBorder(),
                ),
                validator: validator,
                onChanged: onChanged,
                onFieldSubmitted: (String value) {
                  onValueCommitted(value);
                  onFieldSubmitted();
                },
                onTapOutside: (_) =>
                    onValueCommitted(textEditingController.text),
              );
            },
        optionsViewBuilder:
            (
              BuildContext context,
              AutocompleteOnSelected<String> onSelected,
              Iterable<String> values,
            ) {
              final List<String> optionsList = values.toList();
              if (optionsList.isEmpty) {
                return const SizedBox.shrink();
              }

              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                      maxHeight: 220,
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: optionsList.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = optionsList[index];
                        return ListTile(
                          dense: true,
                          title: Text(option),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
      ),
    );
  }

  Widget _textBox(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    bool obscureText = false,
    int maxLines = 1,
    int? minLines,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: obscureText ? 1 : maxLines,
        minLines: obscureText ? null : minLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
        validator:
            validator ??
            (required
                ? (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  }
                : null),
      ),
    );
  }
}
