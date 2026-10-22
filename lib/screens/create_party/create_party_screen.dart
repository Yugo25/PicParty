import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/time_format.dart';
import '../../models/countdown.dart';
import '../../models/feed/party_options.dart';
import '../../services/feed/feed_repository.dart';
import '../../theme/tokens.dart';
import '../../widgets/common/filters.dart';
import '../../widgets/common/form_parts.dart';
import '../../widgets/common/underline_tabs.dart';
import '../../widgets/countdown/clock_builder.dart';
import '../../widgets/countdown/countdown_style.dart';
import '../../widgets/countdown/timer_face.dart';
import '../../widgets/feed/feed_media_view.dart';
import '../../widgets/media/local_media_image.dart';
import '../../widgets/party/party_grid_card.dart';
import '../../l10n/l10n.dart';

enum _Step { details, timing }

enum _StartMode { now, schedule }

enum _Preset {
  h1(Duration(hours: 1)),
  h6(Duration(hours: 6)),
  h24(Duration(hours: 24)),
  custom(null);

  final Duration? duration;
  const _Preset(this.duration);

  String get label => duration == null ? L10n.current.custom : L10n.current.unitHours(duration!.inHours);
}

/// Create a Party in two steps — Details, then Time & style. Everything typed
/// is kept when moving between steps, and after a failed submit.
class CreatePartyScreen extends StatefulWidget {
  const CreatePartyScreen({super.key});

  @override
  State<CreatePartyScreen> createState() => _CreatePartyScreenState();
}

class _CreatePartyScreenState extends State<CreatePartyScreen> {
  _Step _step = _Step.details;

  // Step 1 — details.
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _titleFocus = FocusNode();
  String _category = 'photography';
  PartyPrivacy _privacy = PartyPrivacy.public;
  XFile? _cover;
  String? _coverPath;

  // Step 2 — time & style.
  _StartMode _startMode = _StartMode.now;
  DateTime? _scheduledStart;
  _Preset _preset = _Preset.h6;
  final _days = TextEditingController(text: '0');
  final _hours = TextEditingController(text: '6');
  final _minutes = TextEditingController(text: '0');
  TimerStyle _timerStyle = TimerStyle.digital;

  // Validation and submit state.
  String? _titleError, _scheduleError, _submitError;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_title, _description, _days, _hours, _minutes]) {
      c.dispose();
    }
    _titleFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Values and validation

  Duration? get _duration {
    if (_preset.duration != null) return _preset.duration;
    int? read(TextEditingController c) => c.text.trim().isEmpty ? 0 : int.tryParse(c.text.trim());
    final d = read(_days), h = read(_hours), m = read(_minutes);
    if (d == null || h == null || m == null) return null;
    return Duration(days: d, hours: h, minutes: m);
  }

  /// Shown under the duration fields as soon as the value is out of range.
  String? get _durationError {
    final d = _duration;
    if (d == null) return context.l10n.durationWholeNumbers;
    if (d < PartyLimits.minDuration) return context.l10n.durationTooShort;
    if (d > PartyLimits.maxDuration) return context.l10n.durationTooLong;
    return null;
  }

  String? _validateTitle() {
    final t = _title.text.trim();
    if (t.isEmpty) return context.l10n.titleRequired;
    if (t.length > PartyLimits.titleMax) return context.l10n.titleTooLong(PartyLimits.titleMax);
    return null;
  }

  String? _validateSchedule(DateTime now) {
    if (_startMode == _StartMode.now) return null;
    final s = _scheduledStart;
    if (s == null) return context.l10n.startRequired;
    if (!s.isAfter(now)) return context.l10n.startInPast;
    if (s.isAfter(now.add(PartyLimits.maxScheduleAhead))) return context.l10n.startTooFar;
    return null;
  }

  DateTime _startFor(DateTime now) => _startMode == _StartMode.now ? now : (_scheduledStart ?? now);

  // ---------------------------------------------------------------------------
  // Actions

  void _goToTiming() {
    final error = _validateTitle();
    setState(() => _titleError = error);
    if (error != null) {
      _titleFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _step = _Step.timing);
  }

  void _back() {
    if (_step == _Step.timing) {
      setState(() => _step = _Step.details);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  Future<void> _pickCover() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2400, imageQuality: 90);
      if (x != null && mounted) {
        setState(() {
          _cover = x;
          _coverPath = x.path;
        });
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.photosOpenFailed)));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _scheduledStart ?? _defaultScheduledStart(now);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(PartyLimits.maxScheduleAhead),
    );
    if (date == null || !mounted) return;
    _setSchedule(DateTime(date.year, date.month, date.day, initial.hour, initial.minute));
  }

  Future<void> _pickTime() async {
    final initial = _scheduledStart ?? _defaultScheduledStart(DateTime.now());
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    _setSchedule(DateTime(initial.year, initial.month, initial.day, time.hour, time.minute));
  }

  void _setSchedule(DateTime start) => setState(() {
        _scheduledStart = start;
        _scheduleError = _validateSchedule(DateTime.now());
      });

  /// The next full hour, at least 30 minutes away.
  static DateTime _defaultScheduledStart(DateTime now) {
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    return next.difference(now) < const Duration(minutes: 30) ? next.add(const Duration(hours: 1)) : next;
  }

  void _setStartMode(_StartMode mode) => setState(() {
        _startMode = mode;
        if (mode == _StartMode.schedule) _scheduledStart ??= _defaultScheduledStart(DateTime.now());
        _scheduleError = null;
      });

  void _setPreset(_Preset p) => setState(() {
        if (p == _Preset.custom && _preset.duration != null) {
          // Start the custom fields from the preset that was selected.
          final d = _preset.duration!;
          _days.text = '${d.inDays}';
          _hours.text = '${d.inHours % 24}';
          _minutes.text = '${d.inMinutes % 60}';
        }
        _preset = p;
      });

  Future<void> _create() async {
    if (_submitting) return; // no double creation
    final now = DateTime.now();
    final titleError = _validateTitle();
    final scheduleError = _validateSchedule(now);
    setState(() {
      _titleError = titleError;
      _scheduleError = scheduleError;
      _submitError = null;
    });
    if (titleError != null) {
      setState(() => _step = _Step.details);
      _titleFocus.requestFocus();
      return;
    }
    if (scheduleError != null || _durationError != null) return;

    setState(() => _submitting = true);
    try {
      final created = await FeedRepository.instance.createParty(
        title: _title.text.trim(),
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        category: _category,
        privacy: _privacy,
        timerStyle: _timerStyle,
        startAt: _startFor(DateTime.now()),
        duration: _duration!,
        cover: _cover,
      );
      if (!mounted) return;
      context.pushReplacement('/p/${created.id}');
    } catch (_) {
      if (mounted) setState(() => _submitError = context.l10n.createFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ---------------------------------------------------------------------------
  // UI

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: _step == _Step.details && !_submitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == _Step.timing && !_submitting) setState(() => _step = _Step.details);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), tooltip: context.l10n.back, onPressed: _submitting ? null : _back),
          centerTitle: true,
          title: Text(context.l10n.createParty, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Tokens.gutter),
              child: Center(
                child: Text(context.l10n.stepOf(_step.index + 1, 2),
                    semanticsLabel: context.l10n.stepOfSemantics(_step.index + 1, 2), style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant)),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            UnderlineTabs<_Step>(
              values: _Step.values,
              selected: _step,
              labelOf: (s) => s == _Step.details ? context.l10n.stepDetails : context.l10n.stepTimeStyle,
              onSelected: (s) => s == _Step.details ? setState(() => _step = _Step.details) : _goToTiming(),
              indicatorInset: 28,
            ),
            Expanded(
              child: IndexedStack(
                index: _step.index,
                children: [_details(context), _timing(context)],
              ),
            ),
            BottomActionBar(
              above: _step == _Step.timing && _submitError != null
                  ? Padding(padding: const EdgeInsets.only(bottom: 8), child: FieldError(_submitError))
                  : null,
              child: _step == _Step.details
                  ? FilledButton(
                      onPressed: _goToTiming,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(context.l10n.continueAction),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ]),
                    )
                  : FilledButton.icon(
                      onPressed: _submitting ? null : _create,
                      icon: _submitting
                          ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onSurfaceVariant))
                          : const Icon(Icons.celebration_outlined),
                      label: Text(_submitting ? context.l10n.creating : context.l10n.createParty),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _details(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      key: const PageStorageKey('details'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.gutter, Tokens.gutter, 24),
      children: [
        _CoverPicker(path: _coverPath, onPick: _pickCover),
        const SizedBox(height: 18),
        FieldLabel(context.l10n.fieldTitle),
        TextField(
          controller: _title,
          focusNode: _titleFocus,
          maxLength: PartyLimits.titleMax,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16),
          onChanged: (_) {
            if (_titleError != null) setState(() => _titleError = _validateTitle());
          },
          decoration: InputDecoration(hintText: context.l10n.titleHint, errorText: _titleError),
        ),
        const SizedBox(height: 6),
        FieldLabel(context.l10n.fieldDescription, trailing: context.l10n.optional),
        TextField(
          controller: _description,
          maxLength: PartyLimits.descriptionMax,
          minLines: 3,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(hintText: context.l10n.descriptionHint),
        ),
        const SizedBox(height: 6),
        FieldLabel(context.l10n.fieldCategory),
        DropdownButtonFormField<String>(
          initialValue: _category,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: TextStyle(fontSize: 16, color: scheme.onSurface),
          borderRadius: BorderRadius.circular(Tokens.radius),
          items: [for (final c in PartyCategories.ids) DropdownMenuItem(value: c, child: Text(PartyCategories.label(c)))],
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
        const SizedBox(height: 18),
        FieldLabel(context.l10n.fieldPrivacy),
        _PrivacyGroup(value: _privacy, onChanged: (p) => setState(() => _privacy = p)),
      ],
    );
  }

  Widget _timing(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: theme.colorScheme.onSurfaceVariant);
    final duration = _duration;
    final durationError = _durationError;
    final sample = durationError == null ? duration! : const Duration(hours: 6);
    return ListView(
      key: const PageStorageKey('timing'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(Tokens.gutter, Tokens.gutter, Tokens.gutter, 24),
      children: [
        _TimerPreview(coverPath: _coverPath, duration: durationError == null ? duration! : Duration.zero, timerStyle: _timerStyle),
        const SizedBox(height: 18),
        FieldLabel(context.l10n.fieldStarts),
        SegmentedChoice<_StartMode>(
          values: _StartMode.values,
          selected: _startMode,
          labelOf: (m) => m == _StartMode.now ? context.l10n.startNow : context.l10n.startSchedule,
          onSelected: _setStartMode,
        ),
        if (_startMode == _StartMode.schedule) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: _PickerTile(
                label: context.l10n.date,
                value: _scheduledStart == null ? context.l10n.choose : DateFormat.MMMEd(L10n.dateLocale).format(_scheduledStart!),
                icon: Icons.calendar_today_outlined,
                onTap: _pickDate,
                error: _scheduleError != null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PickerTile(
                label: context.l10n.time,
                value: _scheduledStart == null ? context.l10n.choose : DateFormat('HH:mm').format(_scheduledStart!),
                icon: Icons.schedule,
                onTap: _pickTime,
                error: _scheduleError != null,
              ),
            ),
          ]),
          FieldError(_scheduleError),
        ],
        const SizedBox(height: 18),
        FieldLabel(context.l10n.fieldDuration),
        SegmentedChoice<_Preset>(values: _Preset.values, selected: _preset, labelOf: (p) => p.label, onSelected: _setPreset, separated: true),
        const SizedBox(height: 6),
        Text(context.l10n.durationRange, style: muted),
        if (_preset == _Preset.custom) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _NumberField(label: context.l10n.days, controller: _days, onChanged: () => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: context.l10n.hours, controller: _hours, onChanged: () => setState(() {}))),
            const SizedBox(width: 8),
            Expanded(child: _NumberField(label: context.l10n.minutes, controller: _minutes, onChanged: () => setState(() {}))),
          ]),
          FieldError(durationError),
        ],
        const SizedBox(height: 12),
        _EndSummary(
          startFor: _startFor,
          duration: durationError == null ? duration : null,
          scheduled: _startMode == _StartMode.schedule,
        ),
        const SizedBox(height: 20),
        FieldLabel(context.l10n.fieldTimerStyle),
        Row(children: [
          for (final s in TimerStyle.values) ...[
            if (s != TimerStyle.values.first) const SizedBox(width: 8),
            Expanded(child: _StyleTile(style: s, sample: sample, selected: s == _timerStyle, onTap: () => setState(() => _timerStyle = s))),
          ],
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(child: Text(context.l10n.coverNote, style: muted)),
        ]),
      ],
    );
  }
}

/// Cover preview with an "Add cover" / "Change cover" button.
class _CoverPicker extends StatelessWidget {
  final String? path;
  final VoidCallback onPick;
  const _CoverPicker({required this.path, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius),
        child: Stack(fit: StackFit.expand, children: [
          path == null ? const MediaPlaceholder() : LocalMediaImage(path: path!),
          if (path == null)
            Center(child: _CoverButton(label: context.l10n.addCover, icon: Icons.add_photo_alternate_outlined, onTap: onPick))
          else
            Positioned(right: 10, bottom: 10, child: _CoverButton(label: context.l10n.changeCover, icon: Icons.photo_camera_outlined, onTap: onPick)),
        ]),
      ),
    );
  }
}

class _CoverButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _CoverButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xA6000000),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tokens.radius)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Tokens.radius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      );
}

class _PrivacyGroup extends StatelessWidget {
  final PartyPrivacy value;
  final ValueChanged<PartyPrivacy> onChanged;
  const _PrivacyGroup({required this.value, required this.onChanged});

  static const _icons = {
    PartyPrivacy.public: Icons.public,
    PartyPrivacy.unlisted: Icons.link,
    PartyPrivacy.private: Icons.lock_outline,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outline.withValues(alpha: 0.45);
    return DecoratedBox(
      decoration: BoxDecoration(border: Border.all(color: border), borderRadius: BorderRadius.circular(Tokens.radius)),
      child: Column(children: [
        for (final p in PartyPrivacy.values) ...[
          if (p != PartyPrivacy.values.first) Divider(height: 0.5, color: border),
          Semantics(
            inMutuallyExclusiveGroup: true,
            checked: p == value,
            button: true,
            label: '${p.label}. ${p.description}',
            child: ExcludeSemantics(
              child: InkWell(
                onTap: () => onChanged(p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Icon(_icons[p], size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 1),
                        Text(p.description, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                      ]),
                    ),
                    Icon(p == value ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: p == value ? scheme.onSurface : scheme.outline),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// The cover with the timer as it will look at the very start of the Party.
class _TimerPreview extends StatelessWidget {
  final String? coverPath;
  final Duration duration;
  final TimerStyle timerStyle;
  const _TimerPreview({required this.coverPath, required this.duration, required this.timerStyle});

  @override
  Widget build(BuildContext context) {
    final start = DateTime(2000);
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tokens.radius),
        child: Stack(fit: StackFit.expand, children: [
          coverPath == null ? const MediaPlaceholder() : LocalMediaImage(path: coverPath!),
          const IgnorePointer(child: photoScrim),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TimerFace(
                  snapshot: CountdownSnapshot.at(start: start, end: start.add(duration), now: start),
                  timerStyle: timerStyle,
                  style: CountdownStyle.compact,
                  fractionLeft: 1,
                  caption: context.l10n.preview,
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A labelled button that looks like an input, for date and time pickers.
class _PickerTile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final VoidCallback onTap;
  final bool error;
  const _PickerTile({required this.label, required this.value, required this.icon, required this.onTap, this.error = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$label, $value',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Tokens.radius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: error ? scheme.error : scheme.outline.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(Tokens.radius),
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ]),
              ),
              Icon(icon, size: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _NumberField({required this.label, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        FieldLabel(label),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
          onChanged: (_) => onChanged(),
          style: const TextStyle(fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
        ),
      ]);
}

/// "Ends today at 18:38 · 6 hours from now", kept current while the screen is open.
class _EndSummary extends StatelessWidget {
  final DateTime Function(DateTime now) startFor;
  final Duration? duration;
  final bool scheduled;
  const _EndSummary({required this.startFor, required this.duration, required this.scheduled});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(Tokens.radius)),
      child: Row(children: [
        const Icon(Icons.schedule, size: 26),
        const SizedBox(width: 14),
        Expanded(
          child: ClockBuilder(builder: (context, now) {
            final d = duration;
            if (d == null) {
              return Text(context.l10n.durationInvalidHint, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant));
            }
            final start = startFor(now);
            final end = start.add(d);
            final ends = TimeFormat.dayAndTime(end, now);
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.l10n.endsAt(ends), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                scheduled ? context.l10n.startsAndRuns(TimeFormat.dayAndTime(start, now), TimeFormat.duration(d)) : context.l10n.durationFromNow(TimeFormat.duration(d)),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
              ),
            ]);
          }),
        ),
      ]),
    );
  }
}

class _StyleTile extends StatelessWidget {
  final TimerStyle style;
  final Duration sample;
  final bool selected;
  final VoidCallback onTap;
  const _StyleTile({required this.style, required this.sample, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const digits = TextStyle(fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]);
    final face = switch (style) {
      TimerStyle.digital => Text(CountdownSnapshot.formatRemaining(sample), style: digits.copyWith(fontSize: 22)),
      TimerStyle.minimal => Text(CountdownSnapshot.formatMinimal(sample), style: digits.copyWith(fontSize: 26)),
      TimerStyle.ring => TimerRing(
          fraction: 1,
          size: 58,
          strokeWidth: 4,
          color: scheme.onSurface,
          child: Text(CountdownSnapshot.formatMinimal(sample), style: digits.copyWith(fontSize: 15)),
        ),
    };
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: context.l10n.timerStyleSemantics(style.label),
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Tokens.radius),
          child: Column(children: [
            AspectRatio(
              aspectRatio: 1.15,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Tokens.radius),
                  border: Border.all(color: selected ? scheme.onSurface : scheme.outline.withValues(alpha: 0.35), width: selected ? 2 : 1),
                ),
                padding: const EdgeInsets.all(8),
                child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: face)),
              ),
            ),
            const SizedBox(height: 6),
            Text(style.label, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }
}
