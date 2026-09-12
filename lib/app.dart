import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/legal_documents.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_controller.dart';
import 'features/categories_screen.dart';
import 'features/contacts/domain/contact.dart';
import 'features/contacts/presentation/contact_detail_screen.dart';
import 'features/corrections/presentation/suggest_correction_screen.dart';
import 'features/emergency/presentation/emergency_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/location/presentation/location_browser_screen.dart';
import 'features/search/presentation/search_screen.dart';
import 'features/settings/presentation/legal_document_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

class NepalHelplineApp extends ConsumerWidget {
  const NepalHelplineApp({this.onExit, super.key});

  /// When supplied, Nepal HelpLine is hosted inside another Flutter app.
  /// Standalone builds leave this null and do not display an EXIT control.
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp(
      title: 'Nepal HelpLine',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightLiquidGlassTheme,
      darkTheme: AppTheme.darkLiquidGlassTheme,
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (_) => HomeScreen(onExit: onExit),
        EmergencyScreen.routeName: (_) => const EmergencyScreen(),
        CategoriesScreen.routeName: (_) => const CategoriesScreen(),
        SearchScreen.routeName: (_) => const SearchScreen(),
        LocationBrowserScreen.routeName: (_) => const LocationBrowserScreen(),
        SettingsScreen.routeName: (_) => SettingsScreen(onExit: onExit),
      },
      onGenerateRoute: (settings) {
        if (settings.name == ContactDetailScreen.routeName) {
          final contact = settings.arguments! as Contact;
          return MaterialPageRoute<void>(
            builder: (_) => ContactDetailScreen(contact: contact),
          );
        }
        if (settings.name == SuggestCorrectionScreen.routeName) {
          final contact = settings.arguments as Contact?;
          return MaterialPageRoute<void>(
            builder: (_) => SuggestCorrectionScreen(contact: contact),
          );
        }
        if (settings.name == LegalDocumentScreen.routeName) {
          final document = settings.arguments! as LegalDocument;
          return MaterialPageRoute<void>(
            builder: (_) => LegalDocumentScreen(document: document),
          );
        }
        return null;
      },
    );
  }
}
