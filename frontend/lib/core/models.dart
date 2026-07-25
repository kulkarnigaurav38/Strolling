// The contract for the Strolling app (Figma Make "CursorStutt" v5).
// Businesses offer perks for posting; a stroll is an ordered cart of stops;
// each stop collects up to three captures and can publish one post.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'theme.dart';

enum BusinessCategory { cafe, food, drinks, culture, market }

extension BusinessCategoryX on BusinessCategory {
  String get label => switch (this) {
        BusinessCategory.cafe => 'Café',
        BusinessCategory.food => 'Food',
        BusinessCategory.drinks => 'Drinks',
        BusinessCategory.culture => 'Culture',
        BusinessCategory.market => 'Market',
      };

  IconData get icon => switch (this) {
        BusinessCategory.cafe => Icons.local_cafe_rounded,
        BusinessCategory.food => Icons.restaurant_rounded,
        BusinessCategory.drinks => Icons.sports_bar_rounded,
        BusinessCategory.culture => Icons.park_rounded,
        BusinessCategory.market => Icons.storefront_rounded,
      };

  Color get color => switch (this) {
        BusinessCategory.cafe => AppColors.amber,
        BusinessCategory.food => AppColors.coral,
        BusinessCategory.drinks => AppColors.indigo,
        BusinessCategory.culture => AppColors.leaf,
        BusinessCategory.market => AppColors.green,
      };
}

class Business {
  final String id;
  final String name;
  final BusinessCategory category;
  final String description;
  final int walkMinutes;
  final double rating;
  // Real-world position (WGS84).
  final double lat;
  final double lng;
  // Perk — null means a roam-only place (grey pin, no obligations).
  final String? perkTitle; // "2 free coffees"
  final int? perkValue; // € 7
  final String? deliverable; // "1 photo + 1 story post"
  final String narration; // script snippet read at this stop

  const Business({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.walkMinutes,
    required this.rating,
    required this.lat,
    required this.lng,
    required this.narration,
    this.perkTitle,
    this.perkValue,
    this.deliverable,
  });

  bool get hasPerk => perkTitle != null;
}

/// Draft captures for one stop — all three are independent (v5: "you can fill
/// all three, any two, or just one"). Persisted so a stroll survives restarts.
class StopDraft {
  final String businessId;
  final String? photoBase64; // captured photo, inline for simple persistence
  final String? videoName; // captured clip (name only — no bytes persisted)
  final int? voiceSeconds; // length of the (mock) voice note
  final String? note;
  final DateTime? savedAt;
  final bool posted;
  final String? postedPlatform; // instagram | tiktok | facebook

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
        businessId: j['businessId'] as String,
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

/// The four ways a script task can end. Each maps to a capture card on the
/// step screen — the script tells the influencer which one to open.
enum CaptureAction { photo, video, voice, text }

CaptureAction captureActionFromString(String s) => CaptureAction.values
    .firstWhere((a) => a.name == s, orElse: () => CaptureAction.photo);

/// One task inside a scene. [required] means the perk deliverable needs it —
/// the stop can't be posted until every required action is captured.
class ScriptAction {
  final CaptureAction kind;
  final String prompt; // "Facade dead-center. Nothing may lean."
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

class ScriptStep {
  final String businessId;
  final String sceneTitle; // "SCENE 2 · THE ARCADES, SYMMETRICAL"
  final String direction; // themed staging instruction
  final String line; // line to deliver (voice/caption seed)
  final String? perkCallout; // "Deliver 1 photo + 1 story → 2 free coffees (€7)"
  final List<ScriptAction> actions;

  const ScriptStep({
    required this.businessId,
    required this.sceneTitle,
    required this.direction,
    required this.line,
    required this.actions,
    this.perkCallout,
  });

  List<ScriptAction> get requiredActions =>
      actions.where((a) => a.required).toList();

  /// Every required capture present in [draft]?
  bool satisfiedBy(StopDraft draft) =>
      requiredActions.every((a) => draft.has(a.kind));

  factory ScriptStep.fromJson(Map<String, dynamic> j) => ScriptStep(
        businessId: j['businessId'] as String,
        sceneTitle: j['sceneTitle'] as String,
        direction: j['direction'] as String,
        line: j['line'] as String,
        perkCallout: j['perkCallout'] as String?,
        actions: (j['actions'] as List<dynamic>)
            .map((e) => ScriptAction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'sceneTitle': sceneTitle,
        'direction': direction,
        'line': line,
        'perkCallout': perkCallout,
        'actions': actions.map((a) => a.toJson()).toList(),
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

enum PerkStatus { pending, approved, redeemed }

extension PerkStatusX on PerkStatus {
  String get label => switch (this) {
        PerkStatus.pending => 'Pending',
        PerkStatus.approved => 'Approved',
        PerkStatus.redeemed => 'Redeemed',
      };

  Color get color => switch (this) {
        PerkStatus.pending => AppColors.amber,
        PerkStatus.approved => AppColors.green,
        PerkStatus.redeemed => AppColors.muted,
      };
}

class Perk {
  final String businessId;
  final PerkStatus status;
  final DateTime earnedAt;

  const Perk({
    required this.businessId,
    required this.status,
    required this.earnedAt,
  });

  Perk copyWith({PerkStatus? status}) => Perk(
        businessId: businessId,
        status: status ?? this.status,
        earnedAt: earnedAt,
      );

  factory Perk.fromJson(Map<String, dynamic> j) => Perk(
        businessId: j['businessId'] as String,
        status: PerkStatus.values.firstWhere(
          (s) => s.name == j['status'],
          orElse: () => PerkStatus.pending,
        ),
        earnedAt:
            DateTime.tryParse(j['earnedAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'status': status.name,
        'earnedAt': earnedAt.toIso8601String(),
      };
}

enum StrollMode { roam, earn }

enum ScriptStyle { cityStory, perStop }
