import 'package:flutter/material.dart';

import '../core/constants/categories.dart';
import '../core/constants/directory_icons.dart';
import '../core/theme/app_radii.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme_extension.dart';
import '../shared/widgets/liquid_glass.dart';
import 'search/presentation/search_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  static const routeName = '/categories';

  @override
  Widget build(BuildContext context) {
    return const LiquidGlassScaffold(body: CategoriesView());
  }
}

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              childAspectRatio: 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: directoryCategories.length,
            itemBuilder: (context, index) {
              final category = directoryCategories[index];
              return _CategoryCard(category: category, highlightIndex: index);
            },
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.highlightIndex});

  final String category;
  final int highlightIndex;

  @override
  Widget build(BuildContext context) {
    final glass = LiquidGlassTheme.of(context);
    final accent =
        highlightIndex.isEven ? glass.primaryAccent : glass.warningAccent;
    return LiquidGlass3DCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadii.card,
      blur: 10,
      semanticLabel: 'Open $category category',
      onTap: () {
        Navigator.of(context).pushNamed(
          SearchScreen.routeName,
          arguments: SearchScreenArgs(category: category),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    iconForCategory(category),
                    color: accent,
                    size: 29,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward, color: accent, size: 22),
              ],
            ),
            const Spacer(),
            Text(
              category,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
