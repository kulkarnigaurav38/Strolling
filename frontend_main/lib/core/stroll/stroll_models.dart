import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/map_business.dart';
import '../theme.dart';
import '../../features/map/data/sample_businesses.dart';

/// Draft captures for one stop. Persisted so a stroll survives restarts.
class StopDraft {
  final int businessId;
  final String? photoBase64;
  final String? videoName;
  final int? voiceSeconds;
  final String? note;
  final DateTime? savedAt;
  final bool posted;
  final String? postedPlatform;

  const StopDraft({
    required this.businessId,
    this.photoBase64,
    this.videoName,
    this.voiceSeconds,
    this.note,
    this.savedAt,
    this.posted = false,
    this.postedPlatform,
  });

  bool get hasPhoto => photoBase64 != null;
  bool get hasVideo => videoName != null;
  bool get hasVoice => voiceSeconds != null;
  bool get hasNote => note != null && note!.trim().isNotEmpty;
  bool get hasAnyCapture => hasPhoto || hasVideo || hasVoice || hasNote;

  bool has(CaptureAction action) => switch (action) {
        CaptureAction.photo => hasPhoto,
        CaptureAction.video => hasVideo,
        CaptureAction.voice => hasVoice,
        CaptureAction.text => hasNote,
      };

  StopDraft copyWith({
    String? photoBase64,
    String? videoName,
    int? voiceSeconds,
    String? note,
    DateTime? savedAt,
    bool? posted,
    String? postedPlatform,
    bool clearPhoto = false,
    bool clearVideo = false,
    bool clearVoice = false,
    bool clearNote = false,
  }) {
    return StopDraft(
      businessId: businessId,
      photoBase64: clearPhoto ? null : (photoBase64 ?? this.photoBase64),
      videoName: clearVideo ? null : (videoName ?? this.videoName),
      voiceSeconds: clearVoice ? null : (voiceSeconds ?? this.voiceSeconds),
      note: clearNote ? null : (note ?? this.note),
      savedAt: savedAt ?? this.savedAt,
      posted: posted ?? this.posted,
      postedPlatform: postedPlatform ?? this.postedPlatform,
    );
  }

  factory StopDraft.fromJson(Map<String, dynamic> j) => StopDraft(
        businessId: j['businessId'] as int,
        photoBase64: j['photoBase64'] as String?,
        videoName: j['videoName'] as String?,
        voiceSeconds: j['voiceSeconds'] as int?,
        note: j['note'] as String?,
        savedAt: j['savedAt'] != null
            ? DateTime.tryParse(j['savedAt'] as String)
            : null,
        posted: j['posted'] as bool? ?? false,
        postedPlatform: j['postedPlatform'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'photoBase64': photoBase64,
        'videoName': videoName,
        'voiceSeconds': voiceSeconds,
        'note': note,
        'savedAt': savedAt?.toIso8601String(),
        'posted': posted,
        'postedPlatform': postedPlatform,
      };
}

enum CaptureAction { photo, video, voice, text }

CaptureAction captureActionFromString(String s) => CaptureAction.values
    .firstWhere((a) => a.name == s, orElse: () => CaptureAction.photo);

class ScriptAction {
  final CaptureAction kind;
  final String prompt;
  final bool required;

  const ScriptAction(this.kind, this.prompt, {this.required = false});

  factory ScriptAction.fromJson(Map<String, dynamic> j) => ScriptAction(
        captureActionFromString(j['kind'] as String),
        j['prompt'] as String,
        required: j['required'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'kind': kind.name, 'prompt': prompt, 'required': required};
}

/// One beat in the scene script: prose or an inline capture prompt.
class SceneBlock {
  final String? narrative;
  final String? captureTitle;
  final String? capturePrompt;
  final CaptureAction? captureKind;

  const SceneBlock.narrative(this.narrative)
      : captureTitle = null,
        capturePrompt = null,
        captureKind = null;

  const SceneBlock.capture({
    required this.captureTitle,
    required this.capturePrompt,
    required this.captureKind,
  }) : narrative = null;

  bool get isCapture => captureKind != null;

  String get ctaLabel => switch (captureKind) {
        CaptureAction.video => 'Open camera — video',
        CaptureAction.photo => 'Open camera — photo',
        CaptureAction.voice => 'Record voice note',
        CaptureAction.text => 'Write a note',
        null => 'Capture',
      };

  factory SceneBlock.fromJson(Map<String, dynamic> j) {
    if (j['kind'] == 'capture') {
      return SceneBlock.capture(
        captureTitle: j['captureTitle'] as String,
        capturePrompt: j['capturePrompt'] as String,
        captureKind: captureActionFromString(j['captureKind'] as String),
      );
    }
    return SceneBlock.narrative(j['narrative'] as String);
  }

  Map<String, dynamic> toJson() => isCapture
      ? {
          'kind': 'capture',
          'captureTitle': captureTitle,
          'capturePrompt': capturePrompt,
          'captureKind': captureKind!.name,
        }
      : {'kind': 'narrative', 'narrative': narrative};
}

class ScriptStep {
  final int businessId;
  final String sceneTitle;
  final String direction;
  final String line;
  final String? perkCallout;
  final List<ScriptAction> actions;
  final String? locationTitle;
  final String? locationBody;
  final List<SceneBlock> blocks;

  const ScriptStep({
    required this.businessId,
    required this.sceneTitle,
    required this.direction,
    required this.line,
    required this.actions,
    this.perkCallout,
    this.locationTitle,
    this.locationBody,
    this.blocks = const [],
  });

  List<ScriptAction> get requiredActions =>
      actions.where((a) => a.required).toList();

  bool satisfiedBy(StopDraft draft) =>
      requiredActions.every((a) => draft.has(a.kind));

  factory ScriptStep.fromJson(Map<String, dynamic> j) => ScriptStep(
        businessId: j['businessId'] as int,
        sceneTitle: j['sceneTitle'] as String,
        direction: j['direction'] as String,
        line: j['line'] as String,
        perkCallout: j['perkCallout'] as String?,
        actions: (j['actions'] as List<dynamic>)
            .map((e) => ScriptAction.fromJson(e as Map<String, dynamic>))
            .toList(),
        locationTitle: j['locationTitle'] as String?,
        locationBody: j['locationBody'] as String?,
        blocks: (j['blocks'] as List<dynamic>?)
                ?.map((e) => SceneBlock.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'sceneTitle': sceneTitle,
        'direction': direction,
        'line': line,
        'perkCallout': perkCallout,
        'actions': actions.map((a) => a.toJson()).toList(),
        'locationTitle': locationTitle,
        'locationBody': locationBody,
        'blocks': blocks.map((b) => b.toJson()).toList(),
      };
}

extension CaptureActionX on CaptureAction {
  IconData get icon => switch (this) {
        CaptureAction.photo => CupertinoIcons.camera_fill,
        CaptureAction.video => CupertinoIcons.videocam_fill,
        CaptureAction.voice => CupertinoIcons.mic_fill,
        CaptureAction.text => CupertinoIcons.pencil,
      };

  String get label => switch (this) {
        CaptureAction.photo => 'Photo',
        CaptureAction.video => 'Video',
        CaptureAction.voice => 'Voice note',
        CaptureAction.text => 'Write',
      };
}

class StrollState {
  final List<int> stopIds;
  final Map<int, StopDraft> drafts;
  final String templateId;

  const StrollState({
    this.stopIds = const [],
    this.drafts = const {},
    this.templateId = 'doku',
  });

  bool get active => stopIds.isNotEmpty;

  StopDraft draftFor(int businessId) =>
      drafts[businessId] ?? StopDraft(businessId: businessId);

  int get completedCount =>
      stopIds.where((id) => drafts[id]?.posted ?? false).length;

  bool get allDone => active && completedCount == stopIds.length;

  int get totalPerkValue => stopIds
      .map(businessById)
      .where((b) => b.hasPerk)
      .fold(0, (sum, b) => sum + b.perkValueEuros);

  int get totalWalkMinutes =>
      stopIds.map(businessById).fold(0, (sum, b) => sum + b.walkMin);

  StrollState copyWith({
    List<int>? stopIds,
    Map<int, StopDraft>? drafts,
    String? templateId,
  }) =>
      StrollState(
        stopIds: stopIds ?? this.stopIds,
        drafts: drafts ?? this.drafts,
        templateId: templateId ?? this.templateId,
      );

  factory StrollState.fromJson(Map<String, dynamic> j) => StrollState(
        stopIds: (j['stopIds'] as List<dynamic>).cast<int>(),
        drafts: (j['drafts'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(
            int.parse(k),
            StopDraft.fromJson(v as Map<String, dynamic>),
          ),
        ),
        templateId: j['templateId'] as String? ?? 'doku',
      );

  Map<String, dynamic> toJson() => {
        'stopIds': stopIds,
        'drafts': drafts.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'templateId': templateId,
      };
}

MapBusiness businessById(int id) => kSampleBusinesses.firstWhere(
      (b) => b.id == id,
      orElse: () => kSampleBusinesses.first,
    );

extension MapBusinessStrollX on MapBusiness {
  int get perkValueEuros {
    final digits = (perkVal ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  IconData get categoryIcon => switch (filterKey ?? category) {
        'Café' => Icons.local_cafe_rounded,
        'Food' => Icons.restaurant_rounded,
        'Drinks' => Icons.sports_bar_rounded,
        'Culture' => Icons.park_rounded,
        'Market' => Icons.storefront_rounded,
        _ => Icons.place_rounded,
      };

  Color get categoryColor => switch (filterKey ?? category) {
        'Café' => const Color(0xFFF5A623),
        'Food' => StrollingColors.primary,
        'Drinks' => const Color(0xFF6C63FF),
        'Culture' => const Color(0xFF2DCE89),
        'Market' => StrollingColors.success,
        _ => StrollingColors.muted,
      };
}

String draftCaption(MapBusiness b) => switch (b.filterKey ?? b.category) {
      'Café' =>
        'Morning stop at ${b.name}. ${b.desc.split('.').first}. #strolling',
      'Food' =>
        'Ate well at ${b.name}. Swabian done right. #stuttgart #strolling',
      'Drinks' =>
        'Golden hour at ${b.name}. Local pours, good company. #strolling',
      'Market' =>
        'Market run at ${b.name}. Fresh finds, better light. #strolling',
      _ => 'Passing through ${b.name}. Worth the detour. #strolling',
    };
