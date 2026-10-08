part of 'email_composer_page.dart';

/// Describes a file selected for inclusion in the generated email body.
class _DraftDocument {
  const _DraftDocument({required this.name, this.path, this.size = 0});

  final String name;
  final String? path;
  final int size;

  /// Stable comparison key used to distinguish documents with similar names.
  String get identity => '$name|${path ?? ''}|$size';

  /// Returns a file URI when a local path exists, otherwise the display name.
  String get urlPath {
    final String? documentPath = path;
    if (documentPath == null || documentPath.isEmpty) {
      return name;
    }
    return Uri.file(documentPath).toString();
  }

  /// Creates a document and resolves its current size from the local file.
  static _DraftDocument fromPlatformFile(PlatformFile file) {
    final String? filePath = file.path;
    final int resolvedSize = filePath == null || filePath.isEmpty
        ? 0
        : File(filePath).existsSync()
        ? File(filePath).lengthSync()
        : 0;

    return _DraftDocument(name: file.name, path: filePath, size: resolvedSize);
  }
}

/// Persistable sender details with case-insensitive matching semantics.
class _SenderProfile {
  const _SenderProfile({
    required this.fromName,
    required this.fromEmail,
    required this.replyTo,
    required this.phone,
  });

  final String fromName;
  final String fromEmail;
  final String replyTo;
  final String phone;

  /// Whether at least one sender field contains a value worth saving.
  bool get hasData {
    return fromName.isNotEmpty ||
        fromEmail.isNotEmpty ||
        replyTo.isNotEmpty ||
        phone.isNotEmpty;
  }

  /// Compares every field case-insensitively for history deduplication.
  bool matchesExactly(_SenderProfile other) {
    return fromName.toLowerCase() == other.fromName.toLowerCase() &&
        fromEmail.toLowerCase() == other.fromEmail.toLowerCase() &&
        replyTo.toLowerCase() == other.replyTo.toLowerCase() &&
        phone.toLowerCase() == other.phone.toLowerCase();
  }

  /// Encodes this profile for storage in the string-list database API.
  String toStorageString() {
    return jsonEncode(<String, String>{
      'fromName': fromName,
      'fromEmail': fromEmail,
      'replyTo': replyTo,
      'phone': phone,
    });
  }

  /// Parses a stored profile, returning `null` for malformed or legacy data.
  static _SenderProfile? tryParse(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _SenderProfile(
        fromName: (decoded['fromName'] as String? ?? '').trim(),
        fromEmail: (decoded['fromEmail'] as String? ?? '').trim(),
        replyTo: (decoded['replyTo'] as String? ?? '').trim(),
        phone: (decoded['phone'] as String? ?? '').trim(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// An individual recipient and their assigned email destination.
class _EmailRecipient {
  const _EmailRecipient({
    required this.name,
    required this.position,
    required this.phone,
    required this.email,
    required this.type,
  });

  final String name;
  final String position;
  final String phone;
  final String email;
  final String type;

  Map<String, String> toMap() => <String, String>{
    'name': name,
    'position': position,
    'phone': phone,
    'email': email,
    'type': type,
  };

  static _EmailRecipient? fromMap(Map raw) {
    final String email = (raw['email'] as String? ?? '').trim();
    if (email.isEmpty) {
      return null;
    }
    final String type = (raw['type'] as String? ?? 'to').toLowerCase();
    return _EmailRecipient(
      name: (raw['name'] as String? ?? '').trim(),
      position: (raw['position'] as String? ?? '').trim(),
      phone: (raw['phone'] as String? ?? '').trim(),
      email: email,
      type: <String>{'to', 'cc', 'bcc'}.contains(type) ? type : 'to',
    );
  }
}

/// Persistable recipient details with contact records and legacy address lists.
class _RecipientProfile {
  const _RecipientProfile({
    required this.company,
    required this.department,
    required this.to,
    required this.cc,
    required this.bcc,
    this.contacts = const <_EmailRecipient>[],
  });

  final String company;
  final String department;
  final String to;
  final String cc;
  final String bcc;
  final List<_EmailRecipient> contacts;

  /// Whether at least one recipient field contains a value worth saving.
  bool get hasData {
    return company.isNotEmpty ||
        department.isNotEmpty ||
        to.isNotEmpty ||
        cc.isNotEmpty ||
        bcc.isNotEmpty ||
        contacts.isNotEmpty;
  }

  /// Compares every field case-insensitively for history deduplication.
  bool matchesExactly(_RecipientProfile other) {
    return company.toLowerCase() == other.company.toLowerCase() &&
        department.toLowerCase() == other.department.toLowerCase() &&
        to.toLowerCase() == other.to.toLowerCase() &&
        cc.toLowerCase() == other.cc.toLowerCase() &&
        bcc.toLowerCase() == other.bcc.toLowerCase() &&
        jsonEncode(contacts.map((_EmailRecipient c) => c.toMap()).toList()) ==
            jsonEncode(
              other.contacts.map((_EmailRecipient c) => c.toMap()).toList(),
            );
  }

  /// Encodes this profile for storage in the string-list database API.
  String toStorageString() {
    return jsonEncode(<String, dynamic>{
      'company': company,
      'department': department,
      'to': to,
      'cc': cc,
      'bcc': bcc,
      'contacts': contacts.map((_EmailRecipient c) => c.toMap()).toList(),
    });
  }

  /// Parses a stored profile, returning `null` for malformed or legacy data.
  static _RecipientProfile? tryParse(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _RecipientProfile(
        company: (decoded['company'] as String? ?? '').trim(),
        department: (decoded['department'] as String? ?? '').trim(),
        to: (decoded['to'] as String? ?? '').trim(),
        cc: (decoded['cc'] as String? ?? '').trim(),
        bcc: (decoded['bcc'] as String? ?? '').trim(),
        contacts: ((decoded['contacts'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<Map>()
            .map(_EmailRecipient.fromMap)
            .whereType<_EmailRecipient>()
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persistable customer contact details without associated machines.
class _CustomerProfile {
  const _CustomerProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.shippingAddress,
  });

  final String name;
  final String email;
  final String phone;
  final String shippingAddress;

  /// Whether at least one customer field contains a value worth saving.
  bool get hasData {
    return name.isNotEmpty ||
        email.isNotEmpty ||
        phone.isNotEmpty ||
        shippingAddress.isNotEmpty;
  }

  /// Compares every field case-insensitively for history deduplication.
  bool matchesExactly(_CustomerProfile other) {
    return name.toLowerCase() == other.name.toLowerCase() &&
        email.toLowerCase() == other.email.toLowerCase() &&
        phone.toLowerCase() == other.phone.toLowerCase() &&
        shippingAddress.toLowerCase() == other.shippingAddress.toLowerCase();
  }

  /// Encodes this profile for storage in the string-list database API.
  String toStorageString() {
    return jsonEncode(<String, String>{
      'name': name,
      'email': email,
      'phone': phone,
      'shippingAddress': shippingAddress,
    });
  }

  /// Parses a stored profile, returning `null` for malformed or legacy data.
  static _CustomerProfile? tryParse(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return _CustomerProfile(
        name: (decoded['name'] as String? ?? '').trim(),
        email: (decoded['email'] as String? ?? '').trim(),
        phone: (decoded['phone'] as String? ?? '').trim(),
        shippingAddress: (decoded['shippingAddress'] as String? ?? '').trim(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persisted customer details paired with zero or more machine records.
class _SavedCustomerEntry {
  const _SavedCustomerEntry({
    required this.name,
    required this.email,
    required this.phone,
    required this.shippingAddress,
    required this.machines,
  });

  final String name;
  final String email;
  final String phone;
  final String shippingAddress;
  final List<_SavedCustomerMachine> machines;

  /// Whether the customer or any associated machine contains useful data.
  bool get hasData {
    return name.isNotEmpty ||
        email.isNotEmpty ||
        phone.isNotEmpty ||
        shippingAddress.isNotEmpty ||
        machines.isNotEmpty;
  }

  /// Compares customer fields and ordered machine details case-insensitively.
  bool matchesExactly(_SavedCustomerEntry other) {
    if (name.toLowerCase() != other.name.toLowerCase() ||
        email.toLowerCase() != other.email.toLowerCase() ||
        phone.toLowerCase() != other.phone.toLowerCase() ||
        shippingAddress.toLowerCase() != other.shippingAddress.toLowerCase() ||
        machines.length != other.machines.length) {
      return false;
    }

    for (int i = 0; i < machines.length; i++) {
      if (!machines[i].matchesExactly(other.machines[i])) {
        return false;
      }
    }

    return true;
  }

  /// Encodes the customer and nested machines as one JSON storage value.
  String toStorageString() {
    return jsonEncode(<String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'shippingAddress': shippingAddress,
      'machines': machines.map((m) => m.toMap()).toList(),
    });
  }

  /// Parses a stored entry and ignores malformed nested machine records.
  static _SavedCustomerEntry? tryParse(String raw) {
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final List<dynamic> machinesRaw =
          (decoded['machines'] as List<dynamic>?) ?? <dynamic>[];
      final List<_SavedCustomerMachine> machines = machinesRaw
          .whereType<Map>()
          .map((Map item) => _SavedCustomerMachine.fromMap(item))
          .whereType<_SavedCustomerMachine>()
          .toList();

      return _SavedCustomerEntry(
        name: (decoded['name'] as String? ?? '').trim(),
        email: (decoded['email'] as String? ?? '').trim(),
        phone: (decoded['phone'] as String? ?? '').trim(),
        shippingAddress: (decoded['shippingAddress'] as String? ?? '').trim(),
        machines: machines,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persistable machine details belonging to a saved customer.
class _SavedCustomerMachine {
  const _SavedCustomerMachine({
    required this.customerMachineName,
    required this.machineNumber,
    required this.manufacturerMachineName,
    required this.modelName,
    required this.modelNumber,
    required this.serialNumber,
  });

  final String customerMachineName;
  final String machineNumber;
  final String manufacturerMachineName;
  final String modelName;
  final String modelNumber;
  final String serialNumber;

  /// Compares all machine fields case-insensitively.
  bool matchesExactly(_SavedCustomerMachine other) {
    return customerMachineName.toLowerCase() ==
            other.customerMachineName.toLowerCase() &&
        machineNumber.toLowerCase() == other.machineNumber.toLowerCase() &&
        manufacturerMachineName.toLowerCase() ==
            other.manufacturerMachineName.toLowerCase() &&
        modelName.toLowerCase() == other.modelName.toLowerCase() &&
        modelNumber.toLowerCase() == other.modelNumber.toLowerCase() &&
        serialNumber.toLowerCase() == other.serialNumber.toLowerCase();
  }

  /// Converts the machine to a JSON-compatible string map.
  Map<String, String> toMap() {
    return <String, String>{
      'customerMachineName': customerMachineName,
      'machineNumber': machineNumber,
      'manufacturerMachineName': manufacturerMachineName,
      'modelName': modelName,
      'modelNumber': modelNumber,
      'serialNumber': serialNumber,
    };
  }

  /// Builds a machine from imported data, trimming absent fields to empty.
  static _SavedCustomerMachine? fromMap(Map raw) {
    return _SavedCustomerMachine(
      customerMachineName: (raw['customerMachineName'] as String? ?? '').trim(),
      machineNumber: (raw['machineNumber'] as String? ?? '').trim(),
      manufacturerMachineName: (raw['manufacturerMachineName'] as String? ?? '')
          .trim(),
      modelName: (raw['modelName'] as String? ?? '').trim(),
      modelNumber: (raw['modelNumber'] as String? ?? '').trim(),
      serialNumber: (raw['serialNumber'] as String? ?? '').trim(),
    );
  }
}

/// Owns the controllers and expansion state for one editable machine row.
class _CoworkerEntry {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController role = TextEditingController();
  bool isEditing = true;

  List<TextEditingController> get controllers => <TextEditingController>[
    name,
    email,
    phone,
    role,
  ];

  bool get hasData =>
      name.text.trim().isNotEmpty ||
      email.text.trim().isNotEmpty ||
      phone.text.trim().isNotEmpty ||
      role.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    role.dispose();
  }
}

class _CustomerMachineEntry {
  bool isExpanded = true;
  final TextEditingController customerMachineName = TextEditingController();
  final TextEditingController machineNumber = TextEditingController();
  final TextEditingController manufacturerMachineName = TextEditingController();
  final TextEditingController modelName = TextEditingController();
  final TextEditingController modelNumber = TextEditingController();
  final TextEditingController serialNumber = TextEditingController();

  List<TextEditingController> get controllers => <TextEditingController>[
    customerMachineName,
    machineNumber,
    manufacturerMachineName,
    modelName,
    modelNumber,
    serialNumber,
  ];

  /// Whether any machine controller currently contains non-whitespace text.
  bool get hasData {
    return customerMachineName.text.trim().isNotEmpty ||
        machineNumber.text.trim().isNotEmpty ||
        manufacturerMachineName.text.trim().isNotEmpty ||
        modelName.text.trim().isNotEmpty ||
        modelNumber.text.trim().isNotEmpty ||
        serialNumber.text.trim().isNotEmpty;
  }

  /// Releases all controllers owned by this machine entry.
  void dispose() {
    customerMachineName.dispose();
    machineNumber.dispose();
    manufacturerMachineName.dispose();
    modelName.dispose();
    modelNumber.dispose();
    serialNumber.dispose();
  }
}
