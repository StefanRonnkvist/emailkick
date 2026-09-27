// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionCustomer on _EmailComposerPageState {
  Widget _customerCard() {
    return _SectionCard(
      title: 'Customer',
      children: <Widget>[
        _dropdownTextBox(
          _customerNameController,
          focusNode: _customerNameFocusNode,
          label: 'Customer Name',
          hint: 'John Smith',
          options: _customerNameOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _customerNameOptions);
            _commitCustomerProfile();
          },
          onOptionSelected: (String value) {
            _applyCustomerProfileFromField(_ProfileField.customerName, value);
          },
        ),
        _dropdownTextBox(
          _customerEmailController,
          focusNode: _customerEmailFocusNode,
          label: 'Customer Email',
          hint: 'john.smith@example.com',
          validator: _validateOptionalSingleEmail,
          options: _customerEmailOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _customerEmailOptions);
            _commitCustomerProfile();
          },
          onOptionSelected: (String value) {
            _applyCustomerProfileFromField(_ProfileField.customerEmail, value);
          },
        ),
        _dropdownTextBox(
          _customerPhoneController,
          focusNode: _customerPhoneFocusNode,
          label: 'Customer Phone',
          hint: '+1 555 987 6543',
          keyboardType: TextInputType.phone,
          options: _customerPhoneOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _customerPhoneOptions);
            _commitCustomerProfile();
          },
          onOptionSelected: (String value) {
            _applyCustomerProfileFromField(_ProfileField.customerPhone, value);
          },
        ),
        _dropdownTextBox(
          _customerShippingAddressController,
          focusNode: _customerAddressFocusNode,
          label: 'Shipping Address',
          hint: '123 Main St\nSpringfield, IL 62701',
          minLines: 3,
          maxLines: 4,
          keyboardType: TextInputType.multiline,
          options: _customerAddressOptions,
          onValueCommitted: (String value) {
            _commitSingleValueOption(value, target: _customerAddressOptions);
            _commitCustomerProfile();
          },
          onOptionSelected: (String value) {
            _applyCustomerProfileFromField(
              _ProfileField.customerAddress,
              value,
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Customer Machines',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ..._buildMachineList(),
        OutlinedButton.icon(
          onPressed: _addMachine,
          icon: const Icon(Icons.add),
          label: const Text('Add Machine'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _saveCustomer,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Customer'),
          ),
        ),
        const SizedBox(height: 12),
        _savedCustomersTable(),
      ],
    );
  }

  Widget _savedCustomersTable() {
    if (_savedCustomerEntries.isEmpty) {
      return const Text('No saved customers yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Saved Customers',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 280,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const <DataColumn>[
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Shipping Address')),
                    DataColumn(label: Text('Machines')),
                  ],
                  rows: List<DataRow>.generate(_savedCustomerEntries.length, (
                    int index,
                  ) {
                    final _SavedCustomerEntry entry =
                        _savedCustomerEntries[index];
                    return DataRow.byIndex(
                      index: index,
                      selected: _expandedCustomerIndex == index,
                      onSelectChanged: (_) {
                        setState(() {
                          _expandedCustomerIndex =
                              _expandedCustomerIndex == index ? null : index;
                        });
                      },
                      cells: <DataCell>[
                        DataCell(Text(_tableValue(entry.name))),
                        DataCell(Text(_tableValue(entry.email))),
                        DataCell(Text(_tableValue(entry.phone))),
                        DataCell(Text(_tableValue(entry.shippingAddress))),
                        DataCell(Text('${entry.machines.length}')),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        if (_expandedCustomerIndex != null) ...<Widget>[
          const SizedBox(height: 8),
          _expandedCustomerMachines(
            _savedCustomerEntries[_expandedCustomerIndex!],
          ),
        ],
      ],
    );
  }

  Widget _expandedCustomerMachines(_SavedCustomerEntry entry) {
    if (entry.machines.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'No machine details saved for ${_tableValue(entry.name)}.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Machine Details - ${_tableValue(entry.name)}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...List<Widget>.generate(entry.machines.length, (int index) {
              final _SavedCustomerMachine machine = entry.machines[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 8),
                  title: Text(
                    'Machine ${index + 1} - ${_tableValue(machine.customerMachineName)}',
                  ),
                  children: <Widget>[
                    _summaryTextLine(
                      'Customer Machine Number',
                      machine.machineNumber,
                    ),
                    _summaryTextLine(
                      'Manufacturer Machine Name',
                      machine.manufacturerMachineName,
                    ),
                    _summaryTextLine(
                      'Manufacturer Model Name',
                      machine.modelName,
                    ),
                    _summaryTextLine(
                      'Manufacturer Model Number',
                      machine.modelNumber,
                    ),
                    _summaryTextLine(
                      'Manufacturer Serial Number',
                      machine.serialNumber,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMachineList() {
    final List<Widget> widgets = <Widget>[];

    for (int index = 0; index < _customerMachines.length; index++) {
      final _CustomerMachineEntry machine = _customerMachines[index];
      widgets.add(
        Card(
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
                        'Machine ${index + 1}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          machine.isExpanded = !machine.isExpanded;
                        });
                        _saveDraftState();
                      },
                      tooltip: machine.isExpanded
                          ? 'Collapse Machine'
                          : 'Expand Machine',
                      icon: Icon(
                        machine.isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                      ),
                    ),
                    if (_customerMachines.length > 1)
                      IconButton(
                        onPressed: () => _removeMachine(index),
                        tooltip: 'Remove Machine',
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                if (machine.isExpanded) ...<Widget>[
                  _textBox(
                    machine.customerMachineName,
                    'Customer Machine Name',
                    hint: 'Production Laser',
                    onChanged: (_) => _saveDraftState(),
                  ),
                  _textBox(
                    machine.machineNumber,
                    'Customer Machine Number',
                    hint: 'MC-001',
                    onChanged: (_) => _saveDraftState(),
                  ),
                  _textBox(
                    machine.manufacturerMachineName,
                    'Manufacturer Machine Name',
                    hint: 'ACME Industrial Cutter',
                    onChanged: (_) => _saveDraftState(),
                  ),
                  _textBox(
                    machine.modelName,
                    'Manufacturer Model Name',
                    hint: 'XSeries Pro',
                    onChanged: (_) => _saveDraftState(),
                  ),
                  _textBox(
                    machine.modelNumber,
                    'Manufacturer Model Number',
                    hint: 'XS-900',
                    onChanged: (_) => _saveDraftState(),
                  ),
                  _textBox(
                    machine.serialNumber,
                    'Manufacturer Serial Number',
                    hint: 'SN-293847',
                    onChanged: (_) => _saveDraftState(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  void _addMachine() {
    setState(() {
      for (final _CustomerMachineEntry machine in _customerMachines) {
        machine.isExpanded = false;
      }
      _customerMachines.add(_CustomerMachineEntry()..isExpanded = false);
    });
    _saveDraftState();
  }

  void _removeMachine(int index) {
    if (_customerMachines.length <= 1) {
      return;
    }

    final _CustomerMachineEntry removed = _customerMachines.removeAt(index);
    removed.dispose();
    setState(() {});
    _saveDraftState();
  }
}
