import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/categories.dart';
import '../../../core/location/location_resolver.dart';
import '../../../core/location/location_selection.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/contacts/data/contact_query.dart';
import '../../../features/contacts/domain/contact.dart';
import '../../../features/settings/data/user_preferences.dart';
import '../../../shared/providers.dart';
import '../../../shared/widgets/contact_list_tile.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/liquid_glass.dart';

class LocationBrowserScreen extends StatelessWidget {
  const LocationBrowserScreen({super.key});

  static const routeName = '/location-browser';

  @override
  Widget build(BuildContext context) {
    return const LiquidGlassScaffold(body: LocationBrowserView());
  }
}

class LocationBrowserView extends ConsumerStatefulWidget {
  const LocationBrowserView({super.key});

  @override
  ConsumerState<LocationBrowserView> createState() =>
      _LocationBrowserViewState();
}

class _LocationBrowserViewState extends ConsumerState<LocationBrowserView> {
  static const _controlsToggleScrollThreshold = 72.0;

  final _placeSearchController = TextEditingController();

  Future<List<Contact>>? _results;
  String? _province;
  String? _district;
  String? _palika;
  String? _category;
  bool _filtersExpanded = true;
  bool _controlsVisible = true;
  double _controlsScrollAccumulator = 0;
  bool _gpsLoading = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_applyDefaultLocationAndRefresh);
  }

  Future<void> _applyDefaultLocationAndRefresh() async {
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
      _applyLocationSelection(location, refresh: false);
    }
    await _refreshResults();
  }

  Future<void> _refreshResults({bool saveLastSearched = true}) async {
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
          searchTerm: _placeSearchController.text,
          province: _province,
          district: _district,
          palika: _palika,
          category: _category,
          limit: 100,
        ),
      );
    });
    if (saveLastSearched && location.isNotEmpty) {
      unawaited(
        ref
            .read(userPreferencesProvider.notifier)
            .setLastSearchedLocation(location),
      );
    }
  }

  Future<List<Contact>> _placeSuggestions() async {
    final term = _placeSearchController.text.trim();
    if (term.isEmpty) return const <Contact>[];
    final repository = await ref.read(contactRepositoryProvider.future);
    return repository.search(ContactQuery(searchTerm: term, limit: 8));
  }

  @override
  void dispose() {
    _placeSearchController.dispose();
    super.dispose();
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
    return repositoryValue.when(
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
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                              child: Row(
                                children: [
                                  IconButton.filledTonal(
                                    tooltip: 'Use GPS location',
                                    onPressed:
                                        _gpsLoading
                                            ? null
                                            : _useCurrentLocation,
                                    icon:
                                        _gpsLoading
                                            ? const SizedBox.square(
                                              dimension: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                              ),
                                            )
                                            : const Icon(Icons.my_location),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GlassSearchBar(
                                      controller: _placeSearchController,
                                      hintText:
                                          'Search place, district, palika, service',
                                      onChanged: (_) {
                                        setState(() {});
                                        _refreshResults();
                                      },
                                      onSubmitted: (_) => _refreshResults(),
                                      onClear: () {
                                        _placeSearchController.clear();
                                        setState(() {});
                                        _refreshResults();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_placeSearchController.text.trim().isNotEmpty)
                              FutureBuilder<List<Contact>>(
                                future: _placeSuggestions(),
                                builder: (context, snapshot) {
                                  final contacts =
                                      snapshot.data ?? const <Contact>[];
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                  if (contacts.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return LiquidGlassCard(
                                    margin: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      8,
                                    ),
                                    padding: EdgeInsets.zero,
                                    borderRadius: AppRadii.card,
                                    blur: 8,
                                    shadow: false,
                                    child: Column(
                                      children: [
                                        for (final contact in contacts)
                                          ListTile(
                                            dense: true,
                                            leading: const Icon(
                                              Icons.place_outlined,
                                            ),
                                            title: Text(
                                              _placeLabel(contact),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              contact.organisationName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            onTap:
                                                () => _applyContactLocation(
                                                  contact,
                                                ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            LiquidGlassCard(
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              padding: const EdgeInsets.all(AppSpacing.md),
                              borderRadius: AppRadii.panel,
                              blur: 10,
                              strong: true,
                              child: Column(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap:
                                        () => setState(
                                          () =>
                                              _filtersExpanded =
                                                  !_filtersExpanded,
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
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
                                              turns: _filtersExpanded ? 0.5 : 0,
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
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _AsyncDropdown(
                                                label: 'Province',
                                                value: _province,
                                                valuesFuture: repository
                                                    .distinctValues('province'),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _province = value;
                                                    _district = null;
                                                    _palika = null;
                                                  });
                                                  _refreshResults();
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _AsyncDropdown(
                                                label: 'District',
                                                value: _district,
                                                valuesFuture: repository
                                                    .distinctValues(
                                                      'district',
                                                      filters: {
                                                        'province':
                                                            _province ?? '',
                                                      },
                                                    ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _district = value;
                                                    _palika = null;
                                                  });
                                                  _refreshResults();
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _AsyncDropdown(
                                          label: 'Palika',
                                          value: _palika,
                                          valuesFuture: repository
                                              .distinctValues(
                                                'palika',
                                                filters: {
                                                  'province': _province ?? '',
                                                  'district': _district ?? '',
                                                },
                                              ),
                                          onChanged: (value) {
                                            setState(() => _palika = value);
                                            _refreshResults();
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        _StaticDropdown(
                                          label: 'Category',
                                          value: _category,
                                          values: directoryCategories,
                                          onChanged: (value) {
                                            setState(() => _category = value);
                                            _refreshResults();
                                          },
                                        ),
                                      ],
                                    ),
                                    crossFadeState:
                                        _filtersExpanded
                                            ? CrossFadeState.showSecond
                                            : CrossFadeState.showFirst,
                                    duration: const Duration(milliseconds: 180),
                                  ),
                                ],
                              ),
                            ),
                            if (!_filtersExpanded && _activeFilters.isNotEmpty)
                              SizedBox(
                                height: 48,
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    return Chip(
                                      visualDensity: VisualDensity.compact,
                                      label: Text(_activeFilters[index]),
                                    );
                                  },
                                  separatorBuilder:
                                      (_, _) => const SizedBox(width: 6),
                                  itemCount: _activeFilters.length,
                                ),
                              ),
                            if (_filtersExpanded)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    4,
                                    16,
                                    0,
                                  ),
                                  child: TextButton.icon(
                                    onPressed:
                                        _activeFilters.isEmpty
                                            ? null
                                            : () {
                                              setState(() {
                                                _province = null;
                                                _district = null;
                                                _palika = null;
                                                _category = null;
                                              });
                                              _refreshResults();
                                            },
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Clear filters'),
                                  ),
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
                        _LocationResultCount(count: contacts.length),
                        Expanded(
                          child:
                              contacts.isEmpty
                                  ? const EmptyState(
                                    icon: Icons.location_off_outlined,
                                    title: 'No location results',
                                    message:
                                        'Choose fewer location filters or another category.',
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
    );
  }

  List<String> get _activeFilters {
    return [
      if (_province?.isNotEmpty ?? false) _province!,
      if (_district?.isNotEmpty ?? false) _district!,
      if (_palika?.isNotEmpty ?? false) _palika!,
      if (_category?.isNotEmpty ?? false) _category!,
    ];
  }

  String get _filterSummary {
    final active = _activeFilters;
    if (active.isEmpty) return 'Province / District / Palika / Category';
    return active.join(' / ');
  }

  void _applyContactLocation(Contact contact) {
    _applyLocationSelection(
      LocationSelection(
        province: contact.province,
        district: contact.district,
        palika: contact.palika,
      ),
    );
  }

  void _applyLocationSelection(
    LocationSelection location, {
    bool refresh = true,
  }) {
    setState(() {
      _province = location.province.isEmpty ? null : location.province;
      _district = location.district.isEmpty ? null : location.district;
      _palika = location.palika.isEmpty ? null : location.palika;
      _placeSearchController.clear();
      _filtersExpanded = false;
      _controlsVisible = true;
    });
    if (refresh) {
      _refreshResults();
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gpsLoading = true);
    try {
      final repository = await ref.read(contactRepositoryProvider.future);
      final location = await resolveCurrentDirectoryLocation(repository);
      if (!mounted) return;
      _applyLocationSelection(location, refresh: false);
      await _refreshResults();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location filters autofilled from GPS.')),
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
}

String _placeLabel(Contact contact) {
  final parts =
      [
        contact.province,
        contact.district,
        contact.palika,
        if (contact.ward.isNotEmpty) 'Ward ${contact.ward}',
      ].where((value) => value.trim().isNotEmpty).toList();
  if (parts.isEmpty) return contact.organisationName;
  return parts.join(' / ');
}

class _LocationResultCount extends StatelessWidget {
  const _LocationResultCount({required this.count});

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

class _AsyncDropdown extends StatelessWidget {
  const _AsyncDropdown({
    required this.label,
    required this.value,
    required this.valuesFuture,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final Future<List<String>> valuesFuture;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: valuesFuture,
      builder: (context, snapshot) {
        return _StaticDropdown(
          label: label,
          value: value,
          values: snapshot.data ?? const [],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _StaticDropdown extends StatelessWidget {
  const _StaticDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final uniqueValues = values.toSet().toList()..sort();
    final selected = uniqueValues.contains(value) ? value : null;
    return DropdownButtonFormField<String?>(
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('Any')),
        for (final item in uniqueValues)
          DropdownMenuItem<String?>(
            value: item,
            child: Text(item, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
