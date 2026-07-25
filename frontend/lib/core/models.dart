// The contract. Ported verbatim from the commit-1 brief's lib/types.ts.
// Every screen and the ApiClient speak these types so integrations can be swapped
// one at a time without touching the UI.

enum TaskType { photo, clip }

TaskType taskTypeFromString(String s) =>
    s == 'clip' ? TaskType.clip : TaskType.photo;

String taskTypeToJson(TaskType t) => t == TaskType.clip ? 'clip' : 'photo';

enum SessionStatus { brief, shooting, interview, rendering, done }

SessionStatus sessionStatusFromString(String s) =>
    SessionStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => SessionStatus.brief,
    );

class Task {
  final String id;
  final String title; // "📸 Entrance sign, low angle"
  final TaskType type;
  final String instruction; // one concrete framing instruction
  final String
      suggestedLine; // a line the Regisseur offers so nobody improvises
  final int order;

  const Task({
    required this.id,
    required this.title,
    required this.type,
    required this.instruction,
    required this.suggestedLine,
    required this.order,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        type: taskTypeFromString(j['type'] as String),
        instruction: j['instruction'] as String,
        suggestedLine: j['suggestedLine'] as String,
        order: j['order'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': taskTypeToJson(type),
        'instruction': instruction,
        'suggestedLine': suggestedLine,
        'order': order,
      };
}

class Capture {
  final String taskId;
  final String mediaUrl; // local file path in mock; fal storage URL later
  final TaskType kind;

  const Capture({
    required this.taskId,
    required this.mediaUrl,
    required this.kind,
  });

  factory Capture.fromJson(Map<String, dynamic> j) => Capture(
        taskId: j['taskId'] as String,
        mediaUrl: j['mediaUrl'] as String,
        kind: taskTypeFromString(j['kind'] as String),
      );

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'mediaUrl': mediaUrl,
        'kind': taskTypeToJson(kind),
      };
}

class Review {
  final String taskId;
  final String transcript; // what the creator said about this shot/place
  final String summary; // 1-sentence summary (agent-provided later)

  const Review({
    required this.taskId,
    required this.transcript,
    required this.summary,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        taskId: j['taskId'] as String,
        transcript: j['transcript'] as String,
        summary: j['summary'] as String,
      );

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'transcript': transcript,
        'summary': summary,
      };
}

class RenderResult {
  final String videoUrl;
  const RenderResult({required this.videoUrl});

  factory RenderResult.fromJson(Map<String, dynamic> j) =>
      RenderResult(videoUrl: j['videoUrl'] as String);
}

class PublishResult {
  final String postUrl;
  final String caption;
  final List<String> hashtags;

  const PublishResult({
    required this.postUrl,
    required this.caption,
    required this.hashtags,
  });

  factory PublishResult.fromJson(Map<String, dynamic> j) => PublishResult(
        postUrl: j['postUrl'] as String,
        caption: j['caption'] as String,
        hashtags:
            (j['hashtags'] as List<dynamic>).map((e) => e as String).toList(),
      );
}

class ShootSession {
  final SessionStatus status;
  final int currentTaskIndex; // 0..4
  final List<Task> tasks;
  final List<Capture> captures;
  final List<Review> reviews;
  final String? videoUrl;
  final String? postUrl;
  final String? caption;
  final List<String>? hashtags;

  const ShootSession({
    required this.status,
    required this.currentTaskIndex,
    required this.tasks,
    required this.captures,
    required this.reviews,
    this.videoUrl,
    this.postUrl,
    this.caption,
    this.hashtags,
  });

  factory ShootSession.empty() => const ShootSession(
        status: SessionStatus.brief,
        currentTaskIndex: 0,
        tasks: [],
        captures: [],
        reviews: [],
      );

  Task? get currentTask =>
      (currentTaskIndex >= 0 && currentTaskIndex < tasks.length)
          ? tasks[currentTaskIndex]
          : null;

  ShootSession copyWith({
    SessionStatus? status,
    int? currentTaskIndex,
    List<Task>? tasks,
    List<Capture>? captures,
    List<Review>? reviews,
    String? videoUrl,
    String? postUrl,
    String? caption,
    List<String>? hashtags,
  }) {
    return ShootSession(
      status: status ?? this.status,
      currentTaskIndex: currentTaskIndex ?? this.currentTaskIndex,
      tasks: tasks ?? this.tasks,
      captures: captures ?? this.captures,
      reviews: reviews ?? this.reviews,
      videoUrl: videoUrl ?? this.videoUrl,
      postUrl: postUrl ?? this.postUrl,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
    );
  }

  factory ShootSession.fromJson(Map<String, dynamic> j) => ShootSession(
        status: sessionStatusFromString(j['status'] as String),
        currentTaskIndex: j['currentTaskIndex'] as int,
        tasks: (j['tasks'] as List<dynamic>)
            .map((e) => Task.fromJson(e as Map<String, dynamic>))
            .toList(),
        captures: (j['captures'] as List<dynamic>)
            .map((e) => Capture.fromJson(e as Map<String, dynamic>))
            .toList(),
        reviews: (j['reviews'] as List<dynamic>)
            .map((e) => Review.fromJson(e as Map<String, dynamic>))
            .toList(),
        videoUrl: j['videoUrl'] as String?,
        postUrl: j['postUrl'] as String?,
        caption: j['caption'] as String?,
        hashtags:
            (j['hashtags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      );

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'currentTaskIndex': currentTaskIndex,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'captures': captures.map((c) => c.toJson()).toList(),
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'videoUrl': videoUrl,
        'postUrl': postUrl,
        'caption': caption,
        'hashtags': hashtags,
      };
}
