// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionInformation on _EmailComposerPageState {
  String get _contactServerUrl => 'https://stefanronnkvist.com/contact.php';

  Widget _informationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Tips for import, export, and attachments:'),
            const SizedBox(height: 8),
            const Text(
              '• Export files are saved to your host Downloads folder when available.',
            ),
            const SizedBox(height: 4),
            const Text(
              '• If Downloads is not writable, the app automatically falls back to app documents.',
            ),
            const SizedBox(height: 4),
            const Text(
              '• Import supports JSON and CSV from file paths and Android storage providers.',
            ),
            const SizedBox(height: 4),
            const Text(
              '• Use Open Export Folder in Actions to quickly find generated files.',
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) {
                      return createContactPage(serverUrl: _contactServerUrl);
                    },
                  ),
                );
              },
              icon: const Icon(Icons.support_agent_outlined),
              label: const Text('Open Contact Form'),
            ),
            const SizedBox(height: 8),
            const Text('Contact endpoint is configured in this tab section.'),
            const SizedBox(height: 16),
            const Text(
              'Submissions for this app:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(height: 420, child: SubmissionsCsvCardsView()),
          ],
        ),
      ),
    );
  }
}
