// ignore_for_file: invalid_use_of_protected_member

part of 'email_composer_page.dart';

extension _EmailComposerSectionActions on _EmailComposerPageState {
  Widget _actionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            FilledButton.tonalIcon(
              onPressed: _deleteDbTables,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const Text('Delete DB Tables'),
            ),
            OutlinedButton.icon(
              onPressed: _importDbData,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Import JSON/CSV'),
            ),
            OutlinedButton.icon(
              onPressed: _exportJsonData,
              icon: const Icon(Icons.data_object_outlined),
              label: const Text('Export JSON Data'),
            ),
            OutlinedButton.icon(
              onPressed: _exportCsvData,
              icon: const Icon(Icons.table_chart_outlined),
              label: const Text('Export CSV Data'),
            ),
            OutlinedButton.icon(
              onPressed: _exportCsvTemplates,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Export CSV Templates'),
            ),
            FutureBuilder<Directory>(
              future: _exportDirectory(),
              builder:
                  (BuildContext context, AsyncSnapshot<Directory> snapshot) {
                    final String exportPath = snapshot.hasData
                        ? snapshot.data!.path
                        : 'Loading export path...';
                    return SizedBox(
                      width: 420,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Current Export Path',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: snapshot.hasData
                                ? () async {
                                    await Clipboard.setData(
                                      ClipboardData(text: snapshot.data!.path),
                                    );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Export path copied.'),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.copy_outlined),
                            tooltip: 'Copy path',
                          ),
                        ),
                        child: SelectableText(exportPath),
                      ),
                    );
                  },
            ),
            OutlinedButton.icon(
              onPressed: _openExportFolder,
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Open Export Folder'),
            ),
          ],
        ),
      ),
    );
  }
}
