import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ui/theme.dart';
import '../data/country_repository.dart';

/// Opens the country popup anchored to the widget carrying [anchorKey]
/// (the "Country" row), as in the wireframe. Resolves to the chosen country,
/// or null if dismissed.
Future<Country?> showCountryPicker(
    BuildContext context, {
      required GlobalKey anchorKey,
      String? selectedCode,
      String? selectedName,
    }) {
  final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.attached) return Future.value(null);
  final anchor = box.localToGlobal(Offset.zero) & box.size;

  return showDialog<Country>(
    context: context,
    barrierColor: Colors.black26,
    useSafeArea: false,
    builder: (_) => _PickerHost(
      anchor: anchor,
      selectedCode: selectedCode,
      selectedName: selectedName,
    ),
  );
}

/// Places the panel above the anchor when there is room, otherwise below.
class _PickerHost extends StatelessWidget {
  const _PickerHost({
    required this.anchor,
    required this.selectedCode,
    required this.selectedName,
  });

  final Rect anchor;
  final String? selectedCode;
  final String? selectedName;

  static const double _gap = 8;
  static const double _maxHeight = 360;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final top = mq.padding.top + _gap;
    final bottom = mq.size.height - mq.viewInsets.bottom - _gap;

    final spaceAbove = anchor.top - _gap - top;
    final spaceBelow = bottom - (anchor.bottom + _gap);
    final above = spaceAbove >= 240 || spaceAbove >= spaceBelow;
    final available = above ? spaceAbove : spaceBelow;
    final height = math.min(_maxHeight, math.max(140.0, available));

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            left: anchor.left,
            width: anchor.width,
            top: above ? anchor.top - _gap - height : anchor.bottom + _gap,
            height: height,
            child: _CountryPanel(
              selectedCode: selectedCode,
              selectedName: selectedName,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryPanel extends StatefulWidget {
  const _CountryPanel({
    required this.selectedCode,
    required this.selectedName,
  });

  final String? selectedCode;
  final String? selectedName;

  @override
  State<_CountryPanel> createState() => _CountryPanelState();
}

class _CountryPanelState extends State<_CountryPanel> {
  final _search = TextEditingController();
  late Future<List<Country>> _future = CountryRepository.shared.fetch();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = CountryRepository.shared.fetch(forceRefresh: true);
    });
  }

  bool _isSelected(Country c) =>
      (widget.selectedCode != null &&
          widget.selectedCode!.isNotEmpty &&
          c.code == widget.selectedCode) ||
          c.name == widget.selectedName;

  /// Popular countries first when not searching, then A–Z.
  List<Country> _visible(List<Country> all) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      return all.where((c) => c.name.toLowerCase().contains(q)).toList();
    }
    final popular = <Country>[
      for (final code in CountryRepository.popularCodes)
        ...all.where((c) => c.code == code),
    ];
    final rest = all.where((c) => !popular.contains(c));
    return [...popular, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      elevation: 10,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(AppRadius.chip + 4),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm + 4),
        child: Column(
          children: [
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search country',
                isDense: true,
                prefixIcon: Icon(Icons.search_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  tooltip: 'Clear',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.transparent,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: FutureBuilder<List<Country>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _retry,
                    );
                  }

                  final items = _visible(snapshot.data ?? const []);
                  if (items.isEmpty) {
                    return Center(
                      child: Text('No countries found.',
                          style: theme.textTheme.bodyMedium),
                    );
                  }

                  final list = ListView.builder(
                    itemCount: items.length,
                    itemExtent: 46,
                    itemBuilder: (context, i) => _CountryTile(
                      country: items[i],
                      selected: _isSelected(items[i]),
                      onTap: () => Navigator.of(context).pop(items[i]),
                    ),
                  );

                  // The live list couldn't be loaded; say so and offer a retry.
                  if (!CountryRepository.shared.usedFallback) return list;
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Showing offline list.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            onPressed: _retry,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 28),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xs),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                      Expanded(child: list),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.selected,
    required this.onTap,
  });

  final Country country;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: selected ? primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.chip),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    country.name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded,
              color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}