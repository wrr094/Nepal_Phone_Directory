import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/categories.dart';
import '../../../core/location/location_resolver.dart';
import '../../../core/location/location_selection.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../../../features/contacts/data/contact_query.dart';
import '../../../features/contacts/data/contact_repository.dart';
import '../../../features/contacts/domain/contact.dart';
import '../../../features/settings/data/user_preferences.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/contact_list_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/liquid_glass.dart';

class SearchScreenArgs {
  const SearchScreenArgs({this.searchTerm, this.category});

  final String? searchTerm;
  final String? category;
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  static const routeName = '/search';

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _controlsToggleScrollThreshold = 72.0;
  static const Object _keepFilter = Object();

  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<Contact>>? _results;
  bool _argsApplied = false;
  bool _initialized = false;
  bool _filtersExpanded = true;
  bool _controlsVisible = true;
  double _controlsScrollAccumulator = 0;
  bool _gpsLoading = false;

  String? _province;
  String? _district;
  String? _palika;
  String? _category;
  String? _verificationStatus;
  bool _emergencyOnly = false;
  bool _open247Only = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SearchScreenArgs) {
      _controller.text = args.searchTerm ?? '';
      _category = args.category;
    }
    _argsApplied = true;
    if (!_initialized) {
      _initialized = true;
      Future.microtask(_applyDefaultLocationAndSearch);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final repository = await ref.read(contactRepositoryProvider.future);
    if (!mounted) return;
    final location = LocationSelection(
      province: _province ?? '',
      district: _district ?? '',
      palika: _palika ?? '',
    );
    setState(() {
      _results = repository.search(
        ContactQuery(
          searchTerm: _controller.text,
          province: _province,
          district: _district,
          palika: _palika,
          category: _category,
          verificationStatus: _verificationStatus,
          emergencyOnly: _emergencyOnly,
          open247Only: _open247Only,
          limit: 100,
        ),
      );
    });
    if (location.isNotEmpty) {
      unawaited(
        ref
            .read(userPreferencesProvider.notifier)
            .setLastSearchedLocation(location),
      );
    }
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _search);
  }

  Future<void> _applyDefaultLocationAndSearch() async {
    final preferences = await ref.read(userPreferencesProvider.future);
    final repository = await ref.read(contactRepositoryProvider.future);
    LocationSelection location = preferences.selectedStoredLocation;

    if (preferences.defaultAddressMode == DefaultAddressMode.gps) {
      try {
        location = await resolveCurrentDirectoryLocation(repository);
      } catch (_) {
        location = const LocationSelection();
      }
    }

    if (mounted && location.isNotEmpty) {
      _applyLocationSelection(location, search: false);
    }
    await _search();
  }

  void _applyLocationSelection(
    LocationSelection location, {
    bool search = true,
  }) {
    setState(() {
      _province = location.province.isEmpty ? null : location.province;
      _district = location.district.isEmpty ? null : location.district;
      _palika = location.palika.isEmpty ? null : location.palika;
      _filtersExpanded = false;
      _controlsVisible = true;
    });
    if (search) _search();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsLoading = true);
    try {
      final repository = await ref.read(contactRepositoryProvider.future);
      final location = await resolveCurrentDirectoryLocation(repository);
      if (!mounted) return;
      _applyLocationSelection(location, search: false);
      await _search();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search filters autofilled from GPS.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not use GPS location: $error')),
      );
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  bool _handleResultsScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollStartNotification) {
      _controlsScrollAccumulator = 0;
      return false;
    }
    if (notification is! ScrollUpdateNotification) return false;

    final delta = notification.scrollDelta ?? 0;
    if (delta.abs() < 0.5) return false;

    final changedDirection =
        (_controlsScrollAccumulator > 0 && delta < 0) ||
        (_controlsScrollAccumulator < 0 && delta > 0);
    _controlsScrollAccumulator =
        changedDirection ? delta : _controlsScrollAccumulator + delta;

    if (_controlsVisible &&
        _controlsScrollAccumulator >= _controlsToggleScrollThreshold) {
      setState(() => _controlsVisible = false);
      _controlsScrollAccumulator = 0;
    } else if (!_controlsVisible &&
        _controlsScrollAccumulator <= -_controlsToggleScrollThreshold) {
      setState(() => _controlsVisible = true);
      _controlsScrollAccumulator = 0;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final repositoryValue = ref.watch(contactRepositoryProvider);

    return LiquidGlassScaffold(
      body: repositoryValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (repository) {
          return SafeArea(
            child: Column(
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child:
                      _controlsVisible
                          ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  6,
                                  8,
                                  16,
                                  10,
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Back',
                                      onPressed:
                                          () =>
                                              Navigator.of(context).maybePop(),
                                      icon: const Icon(Icons.arrow_back),
                                    ),
                                    IconButton.filledTonal(
                                      tooltip: 'Use GPS location',
                                      onPressed:
                                          _gpsLoading
                                              ? null
                                              : _useCurrentLocation,
                                      icon:
                                          _gpsLoading
                                              ? const SizedBox.square(
                                                dimension: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                    ),
                                              )
                                              : const Icon(Icons.my_location),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GlassSearchBar(
                                        controller: _controller,
                                        hintText:
                                            'Search organisation, location, phone, keyword',
                                        onChanged: (_) => _scheduleSearch(),
                                        onSubmitted: (_) => _search(),
                                        onClear: () {
                                          _controller.clear();
                                          _search();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              LiquidGlassCard(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                borderRadius: AppRadii.panel,
                                blur: 10,
                                strong: true,
                                opacity: 0.98,
                                shadow: true,
                                child: Column(
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.card,
                                      ),
                                      onTap:
                                          () => setState(
                                            () =>
                                                _filtersExpanded =
                                                    !_filtersExpanded,
                                          ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.tune_outlined),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                _filterSummary,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style:
                                                    Theme.of(
                                                      context,
                                                    ).textTheme.titleSmall,
                                              ),
                                            ),
                                            IconButton(
                                              tooltip:
                                                  _filtersExpanded
                                                      ? 'Collapse filters'
                                                      : 'Expand filters',
                                              onPressed:
                                                  () => setState(
                                                    () =>
                                                        _filtersExpanded =
                                                            !_filtersExpanded,
                                                  ),
                                              icon: AnimatedRotation(
                                                turns:
                                                    _filtersExpanded ? 0.5 : 0,
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                child: const Icon(
                                                  Icons.keyboard_arrow_down,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AnimatedCrossFade(
                                      firstChild: const SizedBox(
                                        width: double.infinity,
                                      ),
                                      secondChild: Column(
                                        children: [
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _CountedDropdown(
                                                  label: 'Province',
                                                  value: _province,
                                                  dataFuture: _countedValues(
                                                    repository,
                                                    valuesFuture: repository
                                                        .distinctValues(
                                                          'province',
                                                        ),
                                                    queryForValue:
                                                        (value) =>
                                                            _countQueryFor(
                                                              province: value,
                                                              district: null,
                                                              palika: null,
                                                            ),
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _province = value;
                                                      _district = null;
                                                      _palika = null;
                                                    });
                                                    _search();
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _CountedDropdown(
                                                  label: 'District',
                                                  value: _district,
                                                  dataFuture: _countedValues(
                                                    repository,
                                                    valuesFuture: repository
                                                        .distinctValues(
                                                          'district',
                                                          filters: {
                                                            'province':
                                                                _province ?? '',
                                                          },
                                                        ),
                                                    queryForValue:
                                                        (value) =>
                                                            _countQueryFor(
                                                              district: value,
                                                              palika: null,
                                                            ),
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      _district = value;
                                                      _palika = null;
                                                    });
                                                    _search();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _CountedDropdown(
                                                  label: 'Palika',
                                                  value: _palika,
                                                  dataFuture: _countedValues(
                                                    repository,
                                                    valuesFuture: repository
                                                        .distinctValues(
                                                          'palika',
                                                          filters: {
                                                            'province':
                                                                _province ?? '',
                                                            'district':
                                                                _district ?? '',
                                                          },
                                                        ),
                                                    queryForValue:
                                                        (value) =>
                                                            _countQueryFor(
                                                              palika: value,
                                                            ),
                                                  ),
                                                  onChanged: (value) {
                                                    setState(
                                                      () => _palika = value,
                                                    );
                                                    _search();
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: _CountedDropdown(
                                                  label: 'Category',
                                                  value: _category,
                                                  dataFuture: _countedValues(
                                                    repository,
                                                    values: directoryCategories,
                                                    queryForValue:
                                                        (value) =>
                                                            _countQueryFor(
                                                              category: value,
                                                            ),
                                                  ),
                                                  onChanged: (value) {
                                                    setState(
                                                      () => _category = value,
                                                    );
                                                    _search();
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          _CountedDropdown(
                                            label: 'Verification',
                                            value: _verificationStatus,
                                            dataFuture: _countedValues(
                                              repository,
                                              values: const [
                                                'Verified',
                                                'Needs Review',
                                                'Unverified',
                                              ],
                                              queryForValue:
                                                  (value) => _countQueryFor(
                                                    verificationStatus: value,
                                                  ),
                                            ),
                                            onChanged: (value) {
                                              setState(
                                                () =>
                                                    _verificationStatus = value,
                                              );
                                              _search();
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 8,
                                              children: [
                                                FilterChip(
                                                  label: const Text(
                                                    'Emergency only',
                                                  ),
                                                  selected: _emergencyOnly,
                                                  onSelected: (value) {
                                                    setState(
                                                      () =>
                                                          _emergencyOnly =
                                                              value,
                                                    );
                                                    _search();
                                                  },
                                                ),
                                                FilterChip(
                                                  label: const Text(
                                                    '24/7 only',
                                                  ),
                                                  selected: _open247Only,
                                                  onSelected: (value) {
                                                    setState(
                                                      () =>
                                                          _open247Only = value,
                                                    );
                                                    _search();
                                                  },
                                                ),
                                                if (_activeFilters.isNotEmpty)
                                                  ActionChip(
                                                    avatar: const Icon(
                                                      Icons.clear_all,
                                                    ),
                                                    label: const Text('Clear'),
                                                    onPressed: _clearFilters,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      crossFadeState:
                                          _filtersExpanded
                                              ? CrossFadeState.showSecond
                                              : CrossFadeState.showFirst,
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                          : const SizedBox(width: double.infinity),
                ),
                Expanded(
                  child: FutureBuilder<List<Contact>>(
                    future: _results,
                    builder: (context, snapshot) {
                      if (_results == null ||
                          snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final contacts = snapshot.data ?? const <Contact>[];
                      return Column(
                        children: [
                          _ResultCount(count: contacts.length),
                          Expanded(
                            child:
                                contacts.isEmpty
                                    ? const EmptyState(
                                      icon: Icons.search_off,
                                      title: 'No contacts found',
                                      message:
                                          'Try fewer filters or a different search term.',
                                    )
                                    : NotificationListener<ScrollNotification>(
                                      onNotification: _handleResultsScroll,
                                      child: ListView.builder(
                                        itemCount: contacts.length,
                                        itemBuilder: (context, index) {
                                          return ContactListTile(
                                            contact: contacts[index],
                                          );
                                        },
                                      ),
                                    ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<String> get _activeFilters {
    return [
      if (_province?.isNotEmpty ?? false) _province!,
      if (_district?.isNotEmpty ?? false) _district!,
      if (_palika?.isNotEmpty ?? false) _palika!,
      if (_category?.isNotEmpty ?? false) _category!,
      if (_verificationStatus?.isNotEmpty ?? false) _verificationStatus!,
      if (_emergencyOnly) 'Emergency only',
      if (_open247Only) '24/7 only',
    ];
  }

  String get _filterSummary {
    final active = _activeFilters;
    if (active.isEmpty) return 'Filters';
    return active.join(' / ');
  }

  ContactQuery _countQueryFor({
    Object? province = _keepFilter,
    Object? district = _keepFilter,
    Object? palika = _keepFilter,
    Object? category = _keepFilter,
    Object? verificationStatus = _keepFilter,
  }) {
    return ContactQuery(
      searchTerm: _controller.text,
      province: province == _keepFilter ? _province : province as String?,
      district: district == _keepFilter ? _district : district as String?,
      palika: palika == _keepFilter ? _palika : palika as String?,
      category: category == _keepFilter ? _category : category as String?,
      verificationStatus:
          verificationStatus == _keepFilter
              ? _verificationStatus
              : verificationStatus as String?,
      emergencyOnly: _emergencyOnly,
      open247Only: _open247Only,
      limit: 1,
    );
  }

  Future<_CountedDropdownData> _countedValues(
    ContactRepository repository, {
    Future<List<String>>? valuesFuture,
    List<String>? values,
    required ContactQuery Function(String? value) queryForValue,
  }) async {
    final resolvedValues =
        values ??
        (valuesFuture == null ? const <String>[] : await valuesFuture);
    final uniqueValues = resolvedValues.toSet().toList()..sort();
    final counts = <String?, int>{};
    counts[null] = await repository.count(queryForValue(null));
    await Future.wait(
      uniqueValues.map((value) async {
        counts[value] = await repository.count(queryForValue(value));
      }),
    );
    return _CountedDropdownData(values: uniqueValues, counts: counts);
  }

  void _clearFilters() {
    setState(() {
      _province = null;
      _district = null;
      _palika = null;
      _category = null;
      _verificationStatus = null;
      _emergencyOnly = false;
      _open247Only = false;
    });
    _search();
  }
}

class _ResultCount extends StatelessWidget {
  const _ResultCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count == 1 ? 'Showing 1 result' : 'Showing $count results';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(label, style: Theme.of(context).textTheme.labelMedium),
      ),
    );
  }
}

class _CountedDropdownData {
  const _CountedDropdownData({required this.values, required this.counts});

  final List<String> values;
  final Map<String?, int> counts;
}

class _CountedDropdown extends StatelessWidget {
  const _CountedDropdown({
    required this.label,
    required this.value,
    required this.dataFuture,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Future<_CountedDropdownData> dataFuture;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CountedDropdownData>(
      future: dataFuture,
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? const _CountedDropdownData(values: [], counts: {});
        return _CountedStaticDropdown(
          label: label,
          value: value,
          values: data.values,
          counts: data.counts,
          onChanged: onChanged,
        );
      },
    );
  }
}

class _CountedStaticDropdown extends StatelessWidget {
  const _CountedStaticDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.counts,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final Map<String?, int> counts;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = values.contains(value) ? value : null;
    final glass = LiquidGlassTheme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final fieldFill = Color.alphaBlend(
      glass.glassSurfaceStrong.withValues(alpha: 0.84),
      colorScheme.surface,
    );
    final menuColor = Color.alphaBlend(
      glass.glassSurfaceStrong.withValues(alpha: 0.96),
      colorScheme.surface,
    );
    return DropdownButtonFormField<String?>(
      isExpanded: true,
      initialValue: selected,
      dropdownColor: menuColor,
      menuMaxHeight: 360,
      borderRadius: BorderRadius.circular(AppRadii.card),
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: glass.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fieldFill,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(_optionLabel('Any', counts[null])),
        ),
        for (final item in values)
          DropdownMenuItem<String?>(
            value: item,
            child: Text(
              _optionLabel(item, counts[item]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

String _optionLabel(String label, int? count) {
  return count == null ? label : '$label ($count)';
}
