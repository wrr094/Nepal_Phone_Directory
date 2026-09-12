import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/legal_documents.dart';
import '../../../core/theme/app_radii.dart';
import '../../../shared/widgets/liquid_glass.dart';

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  static const routeName = '/legal-document';

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      appBar: AppBar(title: Text(document.title)),
      body: FutureBuilder<String>(
        future: _loadBody(),
        builder: (context, snapshot) {
          final body =
              (snapshot.data?.trim().isNotEmpty ?? false)
                  ? snapshot.data!.trim()
                  : document.fallbackBody.trim();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LiquidGlassCard(
                borderRadius: AppRadii.panel,
                enableBlur: false,
                blur: 0,
                shadow: false,
                gradientOverlay: false,
                child: SelectableText(
                  body,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.45),
                ),
              ),
              if (document.sourceUrl != null) ...[
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(document.sourceUrl!)),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open source document'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<String> _loadBody() async {
    final sourceUrl = document.sourceUrl;
    if (sourceUrl == null) return document.fallbackBody;

    try {
      final response = await http
          .get(Uri.parse(sourceUrl))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body.trim();
        if (body.length > 80 ||
            body.split('\n').where((line) => line.trim().isNotEmpty).length >
                2) {
          return body;
        }
      }
    } catch (_) {
      // Fall through to bundled legal text when offline or unavailable.
    }
    return document.fallbackBody;
  }
}
