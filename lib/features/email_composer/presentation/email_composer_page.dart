import 'dart:convert';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:emailkick/core/storage/app_db.dart';
import 'package:emailkick/data/contact/contact_page.dart';
import 'package:emailkick/data/contact/submissions_csv_page.dart';

part 'email_composer_types.dart';
part 'email_composer_models.dart';
part 'email_composer_widgets.dart';
part 'email_composer_mail.dart';
part 'email_composer_profiles.dart';
part 'email_composer_data_state.dart';
part 'email_composer_section_common.dart';
part 'email_composer_section_sender.dart';
part 'email_composer_section_recipients.dart';
part 'email_composer_section_customer.dart';
part 'email_composer_section_coworker.dart';
part 'email_composer_section_content.dart';
part 'email_composer_section_actions.dart';
part 'email_composer_section_information.dart';

class HelpAnalysisCard extends StatelessWidget {
  const HelpAnalysisCard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_HelpSection> sections = <_HelpSection>[
      _HelpSection(
        title: 'Start here',
        icon: Icons.flag_outlined,
        items: <String>[
          'On first use, EmailKick opens Help. Begin in Sender and move through the sections in order; your current draft is restored when you return.',
          'Required fields are checked when you open the draft. Optional customer, coworker, machine, order, and part details add context to the message.',
        ],
      ),
      _HelpSection(
        title: 'Build the message',
        icon: Icons.route_outlined,
        items: <String>[
          'Sender stores your identity. Recipients supports To, Cc, and Bcc lists. Customer and Coworker add service contacts and machine details.',
          'In Content, choose service modes to build the subject. Work and purchase orders build the preheader; both fields remain editable.',
          'Enter the plain-text body, select any document references, then use Open Draft in Mail App.',
        ],
      ),
      _HelpSection(
        title: 'Reuse and transfer data',
        icon: Icons.save_outlined,
        items: <String>[
          'Save sender, recipient, and customer profiles to reuse them. Common field values, customer machines, and the current draft are also remembered locally.',
          'Actions imports JSON or CSV, exports saved data as JSON or CSV, and creates CSV templates for preparing bulk data.',
          'Exports normally go to Downloads and fall back to app documents when needed. Actions shows the current path and can open or copy it.',
        ],
      ),
      _HelpSection(
        title: 'Review and send',
        icon: Icons.attach_file_outlined,
        items: <String>[
          'EmailKick opens a prepared draft in your default mail app; it never sends the email automatically.',
          'Selected documents appear as file references in the message. Attach the actual files in your mail app before sending.',
          'Review recipients, subject, body, and attachments in the mail app before you send.',
        ],
      ),
      _HelpSection(
        title: 'Data and support',
        icon: Icons.info_outline,
        items: <String>[
          'Actions > Delete DB Tables immediately clears the draft, profiles, remembered values, and customer machine records. Export a backup first if you need the data.',
          'Web builds keep data only for the current browser session; persistent database features are available in installed app builds.',
          'Information contains platform-specific import and export tips, the contact form, and support submissions for this app.',
        ],
      ),
    ];

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Help', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'EmailKick turns service and support details into a reusable draft that you review and send from your preferred mail app.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ...sections.map((section) => _buildSection(context, section)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, _HelpSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(section.icon, size: 18),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...section.items.map(
            (String item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.arrow_right, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection {
  const _HelpSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;
}

class EmailComposerPage extends StatefulWidget {
  const EmailComposerPage({super.key});

  @override
  State<EmailComposerPage> createState() => _EmailComposerPageState();
}

/// Owns composer controllers, navigation state, persistence, and validation.
class _EmailComposerPageState extends State<EmailComposerPage> {
  static const int _helpSectionIndex = 7;

  final double tabletBreakpoint = 700;
  final double desktopBreakpoint = 1100;
  final String _fromNameKey = 'setup_from_name';
  final String _fromEmailKey = 'setup_from_email';
  final String _replyToKey = 'setup_reply_to';
  final String _phoneKey = 'setup_sender_phone';
  final String _companyOptionsKey = 'recipients_company_options';
  final String _departmentOptionsKey = 'recipients_department_options';
  final String _toOptionsKey = 'recipients_to_options';
  final String _ccOptionsKey = 'recipients_cc_options';
  final String _bccOptionsKey = 'recipients_bcc_options';
  final String _workOrderOptionsKey = 'content_work_order_options';
  final String _purchaseOrderOptionsKey = 'content_purchase_order_options';
  final String _partNumberOptionsKey = 'content_part_number_options';
  final String _partDescriptionOptionsKey = 'content_part_description_options';
  final String _subjectOptionsKey = 'content_subject_options';
  final String _preheaderOptionsKey = 'content_preheader_options';
  final String _plainTextBodyOptionsKey = 'content_plain_text_body_options';
  final String _senderProfilesKey = 'history_sender_profiles';
  final String _recipientProfilesKey = 'history_recipient_profiles';
  final String _customerProfilesKey = 'history_customer_profiles';
  final String _customerEntriesKey = 'history_customer_entries';
  final String _draftStateKey = 'draft_state';
  final RegExp _emailRegExp = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fromNameController = TextEditingController();
  final TextEditingController _fromEmailController = TextEditingController();
  final TextEditingController _replyToController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _toController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerEmailController =
      TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerShippingAddressController =
      TextEditingController();
  final TextEditingController _contentCustomerSelectorController =
      TextEditingController();
  final TextEditingController _contentRecipientSelectorController =
      TextEditingController();
  final TextEditingController _contentMachineSelectorController =
      TextEditingController();
  final TextEditingController _coworkerNameController = TextEditingController();
  final TextEditingController _coworkerEmailController =
      TextEditingController();
  final TextEditingController _coworkerPhoneController =
      TextEditingController();
  final TextEditingController _coworkerRoleController = TextEditingController();
  final FocusNode _fromNameFocusNode = FocusNode();
  final FocusNode _fromEmailFocusNode = FocusNode();
  final FocusNode _replyToFocusNode = FocusNode();
  final FocusNode _senderPhoneFocusNode = FocusNode();
  final FocusNode _companyFocusNode = FocusNode();
  final FocusNode _departmentFocusNode = FocusNode();
  final FocusNode _toFocusNode = FocusNode();
  final FocusNode _ccFocusNode = FocusNode();
  final FocusNode _bccFocusNode = FocusNode();
  final FocusNode _customerNameFocusNode = FocusNode();
  final FocusNode _customerEmailFocusNode = FocusNode();
  final FocusNode _customerPhoneFocusNode = FocusNode();
  final FocusNode _customerAddressFocusNode = FocusNode();
  final FocusNode _workOrderFocusNode = FocusNode();
  final FocusNode _purchaseOrderFocusNode = FocusNode();
  final FocusNode _partNumberFocusNode = FocusNode();
  final FocusNode _partDescriptionFocusNode = FocusNode();
  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _preheaderFocusNode = FocusNode();
  final FocusNode _plainTextBodyFocusNode = FocusNode();
  final FocusNode _contentCustomerSelectorFocusNode = FocusNode();
  final FocusNode _contentMachineSelectorFocusNode = FocusNode();

  List<String> _senderNameOptions = <String>[];
  List<String> _senderEmailOptions = <String>[];
  List<String> _replyToOptions = <String>[];
  List<String> _senderPhoneOptions = <String>[];
  List<String> _companyOptions = <String>[];
  List<String> _departmentOptions = <String>[];
  List<String> _toOptions = <String>[];
  List<String> _ccOptions = <String>[];
  List<String> _bccOptions = <String>[];
  List<String> _customerNameOptions = <String>[];
  List<String> _customerEmailOptions = <String>[];
  List<String> _customerPhoneOptions = <String>[];
  List<String> _customerAddressOptions = <String>[];
  List<String> _workOrderOptions = <String>[];
  List<String> _purchaseOrderOptions = <String>[];
  List<String> _partNumberOptions = <String>[];
  List<String> _partDescriptionOptions = <String>[];
  List<String> _subjectOptions = <String>[];
  List<String> _preheaderOptions = <String>[];
  List<String> _plainTextBodyOptions = <String>[];

  List<_SenderProfile> _senderProfiles = <_SenderProfile>[];
  List<_RecipientProfile> _recipientProfiles = <_RecipientProfile>[];
  List<_CustomerProfile> _customerProfiles = <_CustomerProfile>[];
  List<_SavedCustomerEntry> _savedCustomerEntries = <_SavedCustomerEntry>[];

  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _workOrderController = TextEditingController();
  final TextEditingController _purchaseOrderController =
      TextEditingController();
  final TextEditingController _partNumberController = TextEditingController();
  final TextEditingController _partDescriptionController =
      TextEditingController();
  final TextEditingController _preheaderController = TextEditingController();
  final TextEditingController _plainTextBodyController =
      TextEditingController();
  final List<_CustomerMachineEntry> _customerMachines =
      <_CustomerMachineEntry>[];
  final List<_DraftDocument> _selectedDocuments = <_DraftDocument>[];
  bool _replyToManuallyEdited = false;
  final Set<_ContentMode> _selectedContentModes = <_ContentMode>{};
  bool _isRestoringDraft = false;
  bool _isSenderCollapsed = false;
  bool _isRecipientsCollapsed = true;
  int _selectedSectionIndex = 0;
  int? _expandedCustomerIndex;
  _SavedCustomerEntry? _selectedContentCustomer;
  List<_SavedCustomerMachine> _selectedContentCustomerMachines =
      <_SavedCustomerMachine>[];
  _RecipientProfile? _editingRecipientProfile;

  List<TextEditingController> get _draftControllers => <TextEditingController>[
    _fromNameController,
    _fromEmailController,
    _replyToController,
    _phoneController,
    _toController,
    _ccController,
    _bccController,
    _companyController,
    _departmentController,
    _customerNameController,
    _customerEmailController,
    _customerPhoneController,
    _customerShippingAddressController,
    _subjectController,
    _workOrderController,
    _purchaseOrderController,
    _partNumberController,
    _partDescriptionController,
    _preheaderController,
    _plainTextBodyController,
  ];

  @override
  /// Initializes listeners and restores state, showing Help for an empty DB.
  void initState() {
    super.initState();
    _selectedSectionIndex = AppDb.instance.isEmpty ? _helpSectionIndex : 0;
    _customerMachines.add(_CustomerMachineEntry());
    _fromEmailController.addListener(_handleFromEmailChanged);
    _bindDraftListeners();
    _syncSubjectFromContentModes();
    _syncPreheaderFromOrderFields();
    _restoreAllState();
  }

  @override
  void dispose() {
    _fromEmailController.removeListener(_handleFromEmailChanged);
    _unbindDraftListeners();
    _fromNameController.dispose();
    _fromEmailController.dispose();
    _replyToController.dispose();
    _phoneController.dispose();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _companyController.dispose();
    _departmentController.dispose();
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _customerShippingAddressController.dispose();
    _contentCustomerSelectorController.dispose();
    _contentRecipientSelectorController.dispose();
    _contentMachineSelectorController.dispose();
    _coworkerNameController.dispose();
    _coworkerEmailController.dispose();
    _coworkerPhoneController.dispose();
    _coworkerRoleController.dispose();
    _fromNameFocusNode.dispose();
    _fromEmailFocusNode.dispose();
    _replyToFocusNode.dispose();
    _senderPhoneFocusNode.dispose();
    _companyFocusNode.dispose();
    _departmentFocusNode.dispose();
    _toFocusNode.dispose();
    _ccFocusNode.dispose();
    _bccFocusNode.dispose();
    _customerNameFocusNode.dispose();
    _customerEmailFocusNode.dispose();
    _customerPhoneFocusNode.dispose();
    _customerAddressFocusNode.dispose();
    _workOrderFocusNode.dispose();
    _purchaseOrderFocusNode.dispose();
    _partNumberFocusNode.dispose();
    _partDescriptionFocusNode.dispose();
    _subjectFocusNode.dispose();
    _preheaderFocusNode.dispose();
    _plainTextBodyFocusNode.dispose();
    _contentCustomerSelectorFocusNode.dispose();
    _contentMachineSelectorFocusNode.dispose();
    _subjectController.dispose();
    _workOrderController.dispose();
    _purchaseOrderController.dispose();
    _partNumberController.dispose();
    _partDescriptionController.dispose();
    _preheaderController.dispose();
    _plainTextBodyController.dispose();
    for (final _CustomerMachineEntry machine in _customerMachines) {
      machine.dispose();
    }
    super.dispose();
  }

  @override
  /// Chooses the phone, tablet, or desktop navigation layout by width.
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth >= desktopBreakpoint) {
          return _desktopLayout();
        }
        if (constraints.maxWidth >= tabletBreakpoint) {
          return _tabletLayout();
        }
        return _phoneLayout();
      },
    );
  }

  /// Builds drawer-based navigation for widths below [tabletBreakpoint].
  Widget _phoneLayout() {
    final List<String> titles = _sectionTitles();
    final List<IconData> icons = _sectionIcons();

    return Scaffold(
      appBar: AppBar(
        title: Text('Email Composer - ${titles[_selectedSectionIndex]}'),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView.builder(
            itemCount: titles.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                leading: Icon(icons[index]),
                title: Text(titles[index]),
                selected: _selectedSectionIndex == index,
                onTap: () {
                  setState(() {
                    _selectedSectionIndex = index;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: _scrollableSection(_buildSectionByIndex(_selectedSectionIndex)),
      ),
    );
  }

  /// Builds tab-based navigation for intermediate viewport widths.
  Widget _tabletLayout() {
    final List<String> titles = _sectionTitles();

    return DefaultTabController(
      length: titles.length,
      initialIndex: _selectedSectionIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Email Composer'),
          bottom: TabBar(
            isScrollable: true,
            tabs: titles.map((String title) => Tab(text: title)).toList(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: TabBarView(
            children: List<Widget>.generate(
              titles.length,
              (int index) => _scrollableSection(_buildSectionByIndex(index)),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds persistent sidebar navigation for wide viewports.
  Widget _desktopLayout() {
    final List<String> titles = _sectionTitles();
    final List<IconData> icons = _sectionIcons();

    return Scaffold(
      appBar: AppBar(title: const Text('Email Composer')),
      body: Form(
        key: _formKey,
        child: Row(
          children: <Widget>[
            Container(
              width: 260,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: SafeArea(
                child: ListView.builder(
                  itemCount: titles.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading: Icon(icons[index]),
                      title: Text(titles[index]),
                      selected: _selectedSectionIndex == index,
                      onTap: () {
                        setState(() {
                          _selectedSectionIndex = index;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: _scrollableSection(
                _buildSectionByIndex(_selectedSectionIndex),
                padding: const EdgeInsets.all(24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _sectionTitles() {
    return <String>[
      'Sender',
      'Recipients',
      'Customer',
      'Coworker',
      'Content',
      'Actions',
      'Information',
      'Help',
    ];
  }

  List<IconData> _sectionIcons() {
    return <IconData>[
      Icons.person_outline,
      Icons.group_outlined,
      Icons.badge_outlined,
      Icons.contact_mail_outlined,
      Icons.description_outlined,
      Icons.playlist_add_check_outlined,
      Icons.help_outline,
      Icons.support_agent_outlined,
    ];
  }

  /// Dispatches a navigation index to its corresponding composer section.
  Widget _buildSectionByIndex(int index) {
    switch (index) {
      case 0:
        return _senderCard();
      case 1:
        return _recipientCard();
      case 2:
        return _customerCard();
      case 3:
        return _coworkerCard();
      case 4:
        return _contentCard();
      case 5:
        return _actionsCard();
      case 6:
        return _informationCard();
      case 7:
        return _helpCard();
      default:
        return _senderCard();
    }
  }

  Widget _helpCard() {
    return const HelpAnalysisCard();
  }

  Widget _scrollableSection(Widget child, {EdgeInsetsGeometry? padding}) {
    return ListView(
      padding: padding ?? const EdgeInsets.all(16),
      children: <Widget>[child],
    );
  }

  /// Accepts an empty value or validates exactly one email address.
  String? _validateOptionalSingleEmail(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) {
      return null;
    }
    if (!_emailRegExp.hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates an optional comma-separated email list.
  String? _validateOptionalEmailList(String? value) {
    return _validateEmailList(value, required: false);
  }

  /// Validates each address and optionally requires at least one recipient.
  String? _validateEmailList(String? value, {required bool required}) {
    final String raw = (value ?? '').trim();

    if (raw.isEmpty) {
      return required ? 'Required' : null;
    }

    final List<String> emails = _splitList(raw);
    if (emails.isEmpty) {
      return required ? 'Required' : null;
    }

    for (final String email in emails) {
      if (!_emailRegExp.hasMatch(email)) {
        return 'Invalid email: $email';
      }
    }

    return null;
  }
}
