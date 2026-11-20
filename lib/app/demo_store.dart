import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoPost {
  const DemoPost({
    required this.id,
    required this.author,
    required this.handle,
    required this.caption,
    required this.createdAt,
    this.photoBase64,
    this.likes = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.comments = const [],
    this.teamId,
    this.artwork,
  });

  final String id;
  final String author;
  final String handle;
  final String caption;
  final DateTime createdAt;
  final String? photoBase64;
  final int likes;
  final bool isLiked;
  final bool isSaved;
  final List<String> comments;
  final String? teamId;
  final String? artwork;

  DemoPost copyWith({
    int? likes,
    bool? isLiked,
    bool? isSaved,
    List<String>? comments,
  }) =>
      DemoPost(
        id: id,
        author: author,
        handle: handle,
        caption: caption,
        createdAt: createdAt,
        photoBase64: photoBase64,
        likes: likes ?? this.likes,
        isLiked: isLiked ?? this.isLiked,
        isSaved: isSaved ?? this.isSaved,
        comments: comments ?? this.comments,
        teamId: teamId,
        artwork: artwork,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'author': author,
        'handle': handle,
        'caption': caption,
        'createdAt': createdAt.toIso8601String(),
        'photoBase64': photoBase64,
        'likes': likes,
        'isLiked': isLiked,
        'isSaved': isSaved,
        'comments': comments,
        'teamId': teamId,
        'artwork': artwork,
      };

  factory DemoPost.fromJson(Map<String, dynamic> json) => DemoPost(
        id: json['id'] as String,
        author: json['author'] as String? ?? 'Jugador',
        handle: json['handle'] as String? ?? '@jugador',
        caption: json['caption'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        photoBase64: json['photoBase64'] as String?,
        likes: json['likes'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        isSaved: json['isSaved'] as bool? ?? false,
        comments: (json['comments'] as List<dynamic>? ?? const [])
            .map((comment) => comment as String)
            .toList(),
        teamId: json['teamId'] as String?,
        artwork: json['artwork'] as String?,
      );
}

class DemoTeam {
  const DemoTeam({
    required this.id,
    required this.name,
    required this.description,
    required this.courtSize,
    required this.zone,
    required this.captain,
    required this.memberCount,
    required this.isMine,
    this.requested = false,
    this.lookingForPlayers = false,
    this.positionNeeded = '',
  });

  final String id;
  final String name;
  final String description;
  final int courtSize;
  final String zone;
  final String captain;
  final int memberCount;
  final bool isMine;
  final bool requested;
  final bool lookingForPlayers;
  final String positionNeeded;

  DemoTeam copyWith({
    int? memberCount,
    bool? isMine,
    bool? requested,
    bool? lookingForPlayers,
    String? positionNeeded,
  }) =>
      DemoTeam(
        id: id,
        name: name,
        description: description,
        courtSize: courtSize,
        zone: zone,
        captain: captain,
        memberCount: memberCount ?? this.memberCount,
        isMine: isMine ?? this.isMine,
        requested: requested ?? this.requested,
        lookingForPlayers: lookingForPlayers ?? this.lookingForPlayers,
        positionNeeded: positionNeeded ?? this.positionNeeded,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'courtSize': courtSize,
        'zone': zone,
        'captain': captain,
        'memberCount': memberCount,
        'isMine': isMine,
        'requested': requested,
        'lookingForPlayers': lookingForPlayers,
        'positionNeeded': positionNeeded,
      };

  factory DemoTeam.fromJson(Map<String, dynamic> json) => DemoTeam(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Equipo',
        description: json['description'] as String? ?? '',
        courtSize: json['courtSize'] as int? ?? 5,
        zone: json['zone'] as String? ?? 'Buenos Aires',
        captain: json['captain'] as String? ?? 'Jugador',
        memberCount: json['memberCount'] as int? ?? 1,
        isMine: json['isMine'] as bool? ?? false,
        requested: json['requested'] as bool? ?? false,
        lookingForPlayers: json['lookingForPlayers'] as bool? ?? false,
        positionNeeded: json['positionNeeded'] as String? ?? '',
      );
}

class DemoTournament {
  const DemoTournament({
    required this.id,
    required this.name,
    required this.zone,
    required this.courtSize,
    required this.startDate,
    required this.teamLimit,
    this.registeredTeams = 1,
  });

  final String id;
  final String name;
  final String zone;
  final int courtSize;
  final DateTime startDate;
  final int teamLimit;
  final int registeredTeams;

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'zone': zone,
        'courtSize': courtSize,
        'startDate': startDate.toIso8601String(),
        'teamLimit': teamLimit,
        'registeredTeams': registeredTeams,
      };

  factory DemoTournament.fromJson(Map<String, dynamic> json) => DemoTournament(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Torneo',
        zone: json['zone'] as String? ?? 'A coordinar',
        courtSize: json['courtSize'] as int? ?? 5,
        startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 14)),
        teamLimit: json['teamLimit'] as int? ?? 8,
        registeredTeams: json['registeredTeams'] as int? ?? 1,
      );
}

enum DemoMatchStatus { proposed, accepted, declined }

class DemoMatch {
  const DemoMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.courtSize,
    required this.zone,
    required this.scheduledAt,
    required this.status,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final int courtSize;
  final String zone;
  final DateTime scheduledAt;
  final DemoMatchStatus status;

  DemoMatch copyWith({DemoMatchStatus? status}) => DemoMatch(
        id: id,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        courtSize: courtSize,
        zone: zone,
        scheduledAt: scheduledAt,
        status: status ?? this.status,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'homeTeam': homeTeam,
        'awayTeam': awayTeam,
        'courtSize': courtSize,
        'zone': zone,
        'scheduledAt': scheduledAt.toIso8601String(),
        'status': status.name,
      };

  factory DemoMatch.fromJson(Map<String, dynamic> json) => DemoMatch(
        id: json['id'] as String,
        homeTeam: json['homeTeam'] as String? ?? 'Tu equipo',
        awayTeam: json['awayTeam'] as String? ?? 'Rival',
        courtSize: json['courtSize'] as int? ?? 5,
        zone: json['zone'] as String? ?? 'A coordinar',
        scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? '') ??
            DateTime.now().add(const Duration(days: 1)),
        status: DemoMatchStatus.values.firstWhere(
          (status) => status.name == json['status'],
          orElse: () => DemoMatchStatus.proposed,
        ),
      );
}

class DemoMessage {
  const DemoMessage({
    required this.author,
    required this.text,
    required this.createdAt,
    required this.isMine,
    this.attachmentType,
    this.attachmentBase64,
    this.mimeType,
    this.durationMs,
  });

  final String author;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final String? attachmentType;
  final String? attachmentBase64;
  final String? mimeType;
  final int? durationMs;

  Map<String, Object?> toJson() => {
        'author': author,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'isMine': isMine,
        'attachmentType': attachmentType,
        'attachmentBase64': attachmentBase64,
        'mimeType': mimeType,
        'durationMs': durationMs,
      };

  factory DemoMessage.fromJson(Map<String, dynamic> json) => DemoMessage(
        author: json['author'] as String? ?? 'Jugador',
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isMine: json['isMine'] as bool? ?? false,
        attachmentType: json['attachmentType'] as String?,
        attachmentBase64: json['attachmentBase64'] as String?,
        mimeType: json['mimeType'] as String?,
        durationMs: json['durationMs'] as int?,
      );
}

class DemoConversation {
  const DemoConversation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.updatedAt,
    required this.messages,
    this.unread = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime updatedAt;
  final List<DemoMessage> messages;
  final int unread;

  DemoConversation copyWith({
    DateTime? updatedAt,
    List<DemoMessage>? messages,
    int? unread,
  }) =>
      DemoConversation(
        id: id,
        title: title,
        subtitle: subtitle,
        updatedAt: updatedAt ?? this.updatedAt,
        messages: messages ?? this.messages,
        unread: unread ?? this.unread,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'updatedAt': updatedAt.toIso8601String(),
        'messages': messages.map((message) => message.toJson()).toList(),
        'unread': unread,
      };

  factory DemoConversation.fromJson(Map<String, dynamic> json) =>
      DemoConversation(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Chat',
        subtitle: json['subtitle'] as String? ?? 'Conversación de demo',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
        messages: (json['messages'] as List<dynamic>? ?? const [])
            .map((item) =>
                DemoMessage.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList(),
        unread: json['unread'] as int? ?? 0,
      );
}

class DemoPlayer {
  const DemoPlayer({
    required this.id,
    required this.name,
    required this.position,
    required this.zone,
    required this.team,
    required this.rating,
    required this.available,
  });

  final String id;
  final String name;
  final String position;
  final String zone;
  final String team;
  final double rating;
  final bool available;
}

class DemoStory {
  const DemoStory({
    required this.id,
    required this.author,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String author;
  final String caption;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'author': author,
        'caption': caption,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DemoStory.fromJson(Map<String, dynamic> json) => DemoStory(
        id: json['id'] as String,
        author: json['author'] as String? ?? 'Jugador',
        caption: json['caption'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class DemoStore extends ChangeNotifier {
  DemoStore();

  static const _prefix = 'hay_equipo_rebuild_v1';
  AudioPlayer? _ambientPlayer;
  SharedPreferences? _preferences;

  bool _ready = false;
  bool ambientEnabled = false;
  ThemeMode themeMode = ThemeMode.dark;
  String playerName = 'Alex Fernández';
  String playerBio = 'Volante · zurdo · siempre hay partido.';
  String? playerPhotoBase64;
  List<DemoPost> posts = const [];
  List<DemoTeam> teams = const [];
  List<DemoMatch> matches = const [];
  List<DemoTournament> tournaments = const [];
  List<DemoConversation> conversations = const [];
  List<DemoStory> stories = const [];
  List<String> reports = const [];

  static const players = <DemoPlayer>[
    DemoPlayer(
      id: 'player-sofi',
      name: 'Sofía Martínez',
      position: 'Arquera',
      zone: 'Palermo',
      team: 'Las del Parque',
      rating: 4.9,
      available: true,
    ),
    DemoPlayer(
      id: 'player-tomi',
      name: 'Tomás Rojas',
      position: 'Delantero',
      zone: 'Villa Crespo',
      team: 'Fieras FC',
      rating: 4.8,
      available: true,
    ),
    DemoPlayer(
      id: 'player-luli',
      name: 'Lucía Benítez',
      position: 'Defensora',
      zone: 'Caballito',
      team: 'La Banda',
      rating: 4.7,
      available: false,
    ),
    DemoPlayer(
      id: 'player-nico',
      name: 'Nicolás Acosta',
      position: 'Mediocampista',
      zone: 'Almagro',
      team: 'Los del Sur',
      rating: 4.9,
      available: true,
    ),
    DemoPlayer(
      id: 'player-maru',
      name: 'Maru Gómez',
      position: 'Delantera',
      zone: 'Boedo',
      team: 'Sin equipo',
      rating: 4.6,
      available: true,
    ),
  ];

  Future<void> initialize() async {
    if (_ready) return;
    _preferences = await SharedPreferences.getInstance();
    playerName = _preferences!.getString('${_prefix}_name') ?? playerName;
    playerBio = _preferences!.getString('${_prefix}_bio') ?? playerBio;
    playerPhotoBase64 = _preferences!.getString('${_prefix}_photo');
    ambientEnabled = _preferences!.getBool('${_prefix}_ambient') ?? false;
    themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == _preferences!.getString('${_prefix}_theme'),
      orElse: () => ThemeMode.dark,
    );
    posts = _readCollection(
      'posts',
      _seedPosts(),
      DemoPost.fromJson,
    );
    teams = _readCollection(
      'teams',
      _seedTeams(),
      DemoTeam.fromJson,
    );
    matches = _readCollection(
      'matches',
      const <DemoMatch>[],
      DemoMatch.fromJson,
    );
    tournaments = _readCollection(
      'tournaments',
      _seedTournaments(),
      DemoTournament.fromJson,
    );
    conversations = _readCollection(
      'chats',
      _seedConversations(),
      DemoConversation.fromJson,
    );
    stories = _readCollection(
      'stories',
      _seedStories(),
      DemoStory.fromJson,
    );
    reports = _preferences!.getStringList('${_prefix}_reports') ?? const [];
    _ready = true;
    if (ambientEnabled) await _startAmbient();
    notifyListeners();
  }

  List<T> _readCollection<T>(
    String key,
    List<T> seed,
    T Function(Map<String, dynamic>) decode,
  ) {
    final saved = _preferences!.getString('${_prefix}_$key');
    if (saved == null) return seed;
    final decoded = jsonDecode(saved) as List<dynamic>;
    return decoded
        .map((item) => decode(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  List<DemoPost> _seedPosts() {
    final now = DateTime.now();
    return [
      DemoPost(
        id: 'post-warmup',
        author: 'Tomi Rojas',
        handle: '@tomi.rojas',
        caption:
            'Domingo de fútbol 5 con esta banda. El tercer tiempo estuvo a la altura ⚽',
        createdAt: now.subtract(const Duration(minutes: 24)),
        likes: 18,
        comments: const ['La próxima revancha es nuestra', 'Qué lindo domingo'],
        artwork: 'match',
      ),
      DemoPost(
        id: 'post-team',
        author: 'Sofía Martínez',
        handle: '@sofi.martinez',
        caption:
            'Nos falta una defensora para el jueves en Palermo. ¿Quién se suma?',
        createdAt: now.subtract(const Duration(hours: 2)),
        likes: 11,
        comments: const ['Me sumo, ¿a qué hora?'],
        artwork: 'recruitment',
        teamId: 'team-parque',
      ),
      DemoPost(
        id: 'post-night',
        author: 'Nico Acosta',
        handle: '@nico.acosta',
        caption: 'Luces prendidas, equipo completo. No se negocia el jueves.',
        createdAt: now.subtract(const Duration(hours: 6)),
        likes: 7,
        artwork: 'night',
      ),
    ];
  }

  List<DemoTeam> _seedTeams() => [
        const DemoTeam(
          id: 'team-own',
          name: 'Los del Sur',
          description: 'Un equipo, muchas historias.',
          courtSize: 5,
          zone: 'Boedo',
          captain: 'Alex Fernández',
          memberCount: 8,
          isMine: true,
        ),
        const DemoTeam(
          id: 'team-fieras',
          name: 'Fieras FC',
          description: 'Buscamos jugar lindo y volver enteros.',
          courtSize: 5,
          zone: 'Villa Crespo',
          captain: 'Tomás Rojas',
          memberCount: 9,
          isMine: false,
        ),
        const DemoTeam(
          id: 'team-parque',
          name: 'Las del Parque',
          description: 'Fútbol 7 mixto, nivel recreativo.',
          courtSize: 7,
          zone: 'Palermo',
          captain: 'Sofía Martínez',
          memberCount: 11,
          isMine: false,
          lookingForPlayers: true,
          positionNeeded: 'Arquera',
        ),
        const DemoTeam(
          id: 'team-banda',
          name: 'La Banda',
          description: 'Cancha 5, jueves por la noche.',
          courtSize: 5,
          zone: 'Caballito',
          captain: 'Lucía Benítez',
          memberCount: 7,
          isMine: false,
        ),
      ];

  List<DemoTournament> _seedTournaments() => [
        DemoTournament(
          id: 'tournament-copa-barrial',
          name: 'Copa Barrial de Palermo',
          zone: 'Palermo',
          courtSize: 5,
          startDate: DateTime.now().add(const Duration(days: 14)),
          teamLimit: 8,
          registeredTeams: 5,
        ),
      ];

  List<DemoConversation> _seedConversations() {
    final now = DateTime.now();
    return [
      DemoConversation(
        id: 'chat-tomi',
        title: 'Tomás Rojas',
        subtitle: 'Jugador · Fieras FC',
        updatedAt: now.subtract(const Duration(minutes: 8)),
        unread: 1,
        messages: [
          DemoMessage(
            author: 'Tomás',
            text: '¿Sale un fútbol 5 esta semana?',
            createdAt: now.subtract(const Duration(minutes: 8)),
            isMine: false,
          ),
        ],
      ),
      DemoConversation(
        id: 'chat-own-team',
        title: 'Los del Sur',
        subtitle: 'Equipo · Cancha 5',
        updatedAt: now.subtract(const Duration(hours: 1)),
        messages: [
          DemoMessage(
            author: 'Alex',
            text: 'Confirmado el jueves a las 21.',
            createdAt: now.subtract(const Duration(hours: 1)),
            isMine: true,
          ),
        ],
      ),
      DemoConversation(
        id: 'chat-match',
        title: 'Partido vs. La Banda',
        subtitle: 'Partido · Palermo',
        updatedAt: now.subtract(const Duration(days: 1)),
        messages: [
          DemoMessage(
            author: 'Lucía',
            text: 'Les paso la dirección de la cancha.',
            createdAt: now.subtract(const Duration(days: 1)),
            isMine: false,
          ),
        ],
      ),
    ];
  }

  List<DemoStory> _seedStories() {
    final now = DateTime.now();
    return [
      DemoStory(
        id: 'story-tomi',
        author: 'Tomi',
        caption: 'Jueves 21 h. Cancha lista.',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
      DemoStory(
        id: 'story-sofi',
        author: 'Sofía',
        caption: 'Buscamos arquera para el sábado.',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      DemoStory(
        id: 'story-nico',
        author: 'Nico',
        caption: 'Tercer tiempo confirmado.',
        createdAt: now.subtract(const Duration(hours: 7)),
      ),
    ];
  }

  Future<void> addPost({required String caption, String? photoBase64}) async {
    final cleanCaption = caption.trim();
    if (cleanCaption.isEmpty && (photoBase64 == null || photoBase64.isEmpty)) {
      throw ArgumentError('Agregá un texto o una foto para compartir.');
    }
    posts = [
      DemoPost(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        author: playerName,
        handle: '@${_handleFromName(playerName)}',
        caption: cleanCaption,
        createdAt: DateTime.now(),
        photoBase64: photoBase64,
      ),
      ...posts,
    ];
    await _saveCollection('posts', posts, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> toggleLike(String postId) async {
    posts = posts
        .map((post) => post.id != postId
            ? post
            : post.copyWith(
                isLiked: !post.isLiked,
                likes: post.likes + (post.isLiked ? -1 : 1),
              ))
        .toList();
    await _saveCollection('posts', posts, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> toggleSaved(String postId) async {
    posts = posts
        .map((post) =>
            post.id == postId ? post.copyWith(isSaved: !post.isSaved) : post)
        .toList();
    await _saveCollection('posts', posts, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> addComment(String postId, String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) throw ArgumentError('Escribí un comentario.');
    if (cleanText.length > 280) {
      throw ArgumentError('El comentario no puede superar los 280 caracteres.');
    }
    posts = posts
        .map((post) => post.id == postId
            ? post.copyWith(comments: [...post.comments, cleanText])
            : post)
        .toList();
    await _saveCollection('posts', posts, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> addStory(String caption) async {
    final cleanCaption = caption.trim();
    if (cleanCaption.isEmpty) {
      throw ArgumentError('Escribí algo para compartir en tu historia.');
    }
    stories = [
      DemoStory(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        author: playerName,
        caption: cleanCaption,
        createdAt: DateTime.now(),
      ),
      ...stories,
    ];
    await _saveCollection('stories', stories, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> createTeam({
    required String name,
    required String description,
    required int courtSize,
    required String zone,
    bool lookingForPlayers = false,
    String positionNeeded = '',
  }) async {
    final cleanName = name.trim();
    if (cleanName.length < 3) {
      throw ArgumentError('El nombre del equipo necesita al menos 3 letras.');
    }
    if (teams
        .any((team) => team.name.toLowerCase() == cleanName.toLowerCase())) {
      throw ArgumentError('Ya existe un equipo con ese nombre en la demo.');
    }
    final teamId = DateTime.now().microsecondsSinceEpoch.toString();
    final team = DemoTeam(
      id: teamId,
      name: cleanName,
      description: description.trim(),
      courtSize: courtSize,
      zone: zone,
      captain: playerName,
      memberCount: 1,
      isMine: true,
      lookingForPlayers: lookingForPlayers,
      positionNeeded: positionNeeded.trim(),
    );
    teams = [
      team,
      ...teams,
    ];
    if (lookingForPlayers) posts = [_recruitmentPost(team), ...posts];
    await _saveCollection('teams', teams, (item) => item.toJson());
    if (lookingForPlayers) {
      await _saveCollection('posts', posts, (item) => item.toJson());
    }
    notifyListeners();
  }

  Future<void> setTeamRecruiting({
    required String teamId,
    required bool lookingForPlayers,
    String positionNeeded = '',
  }) async {
    final matchingTeams = teams.where((team) => team.id == teamId);
    if (matchingTeams.isEmpty || !matchingTeams.first.isMine) {
      throw ArgumentError('Solo el capitán puede publicar una búsqueda.');
    }
    final updatedTeam = matchingTeams.first.copyWith(
      lookingForPlayers: lookingForPlayers,
      positionNeeded: positionNeeded.trim(),
    );
    teams =
        teams.map((team) => team.id == teamId ? updatedTeam : team).toList();
    posts = posts.where((post) => post.teamId != teamId).toList();
    if (lookingForPlayers) posts = [_recruitmentPost(updatedTeam), ...posts];
    await _saveCollection('teams', teams, (item) => item.toJson());
    await _saveCollection('posts', posts, (item) => item.toJson());
    notifyListeners();
  }

  DemoPost _recruitmentPost(DemoTeam team) => DemoPost(
        id: 'recruitment-${team.id}',
        author: team.name,
        handle: '@${_handleFromName(team.name)}',
        caption:
            'Buscamos ${team.positionNeeded.isEmpty ? 'jugador/a' : team.positionNeeded} para fútbol ${team.courtSize} en ${team.zone}. ¿Te sumás?',
        createdAt: DateTime.now(),
        artwork: 'recruitment',
        teamId: team.id,
      );

  Future<void> requestToJoin(String teamId) async {
    teams = teams
        .map(
            (team) => team.id == teamId ? team.copyWith(requested: true) : team)
        .toList();
    await _saveCollection('teams', teams, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> cancelJoinRequest(String teamId) async {
    teams = teams
        .map((team) =>
            team.id == teamId ? team.copyWith(requested: false) : team)
        .toList();
    await _saveCollection('teams', teams, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> createMatch({
    required String homeTeam,
    required String awayTeam,
    required int courtSize,
    required String zone,
    required DateTime scheduledAt,
  }) async {
    if (homeTeam == awayTeam) {
      throw ArgumentError('Elegí dos equipos distintos.');
    }
    if (scheduledAt.isBefore(DateTime.now())) {
      throw ArgumentError('La fecha del partido tiene que ser futura.');
    }
    matches = [
      DemoMatch(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        courtSize: courtSize,
        zone: zone,
        scheduledAt: scheduledAt,
        status: DemoMatchStatus.proposed,
      ),
      ...matches,
    ];
    await _saveCollection('matches', matches, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> createTournament({
    required String name,
    required String zone,
    required int courtSize,
    required DateTime startDate,
    required int teamLimit,
  }) async {
    final cleanName = name.trim();
    if (cleanName.length < 4) {
      throw ArgumentError('El torneo necesita un nombre de al menos 4 letras.');
    }
    if (zone.trim().isEmpty) throw ArgumentError('Indicá la zona del torneo.');
    if (startDate.isBefore(DateTime.now())) {
      throw ArgumentError('La fecha del torneo tiene que ser futura.');
    }
    if (teamLimit < 4 || teamLimit > 32) {
      throw ArgumentError('Elegí un cupo de entre 4 y 32 equipos.');
    }
    tournaments = [
      DemoTournament(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: cleanName,
        zone: zone.trim(),
        courtSize: courtSize,
        startDate: startDate,
        teamLimit: teamLimit,
      ),
      ...tournaments,
    ];
    await _saveCollection('tournaments', tournaments, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> respondToMatch(
    String matchId,
    DemoMatchStatus status,
  ) async {
    matches = matches
        .map((match) =>
            match.id == matchId ? match.copyWith(status: status) : match)
        .toList();
    await _saveCollection('matches', matches, (item) => item.toJson());
    notifyListeners();
  }

  Future<String> openConversation(String title, String subtitle) async {
    final existing = conversations.where((chat) => chat.title == title);
    if (existing.isNotEmpty) return existing.first.id;
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    conversations = [
      DemoConversation(
        id: id,
        title: title,
        subtitle: subtitle,
        updatedAt: DateTime.now(),
        messages: const [],
      ),
      ...conversations,
    ];
    await _saveCollection('chats', conversations, (item) => item.toJson());
    notifyListeners();
    return id;
  }

  Future<void> sendMessage(
    String chatId,
    String text, {
    String? attachmentType,
    String? attachmentBase64,
    String? mimeType,
    int? durationMs,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty && attachmentBase64 == null) return;
    conversations = conversations.map((chat) {
      if (chat.id != chatId) return chat;
      return chat.copyWith(
        updatedAt: DateTime.now(),
        unread: 0,
        messages: [
          ...chat.messages,
          DemoMessage(
            author: playerName,
            text: cleanText,
            createdAt: DateTime.now(),
            isMine: true,
            attachmentType: attachmentType,
            attachmentBase64: attachmentBase64,
            mimeType: mimeType,
            durationMs: durationMs,
          ),
        ],
      );
    }).toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    await _saveCollection('chats', conversations, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> markConversationRead(String chatId) async {
    conversations = conversations
        .map((chat) => chat.id == chatId ? chat.copyWith(unread: 0) : chat)
        .toList();
    await _saveCollection('chats', conversations, (item) => item.toJson());
    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    String? photoBase64,
  }) async {
    final cleanName = name.trim();
    if (cleanName.length < 2) {
      throw ArgumentError('Escribí un nombre de al menos 2 caracteres.');
    }
    playerName = cleanName;
    playerBio = bio.trim();
    if (photoBase64 != null) playerPhotoBase64 = photoBase64;
    await Future.wait([
      _preferences!.setString('${_prefix}_name', playerName),
      _preferences!.setString('${_prefix}_bio', playerBio),
      if (playerPhotoBase64 != null)
        _preferences!.setString('${_prefix}_photo', playerPhotoBase64!),
    ]);
    notifyListeners();
  }

  Future<void> addReport(String playerName, String reason) async {
    reports = ['$playerName · $reason', ...reports];
    await _preferences!.setStringList('${_prefix}_reports', reports);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _preferences!.setString('${_prefix}_theme', mode.name);
    notifyListeners();
  }

  Future<void> setAmbientEnabled(bool enabled) async {
    if (enabled) {
      await _startAmbient();
    } else if (_ambientPlayer != null) {
      await _ambientPlayer!.pause();
    }
    ambientEnabled = enabled;
    await _preferences!.setBool('${_prefix}_ambient', enabled);
    notifyListeners();
  }

  Future<void> _startAmbient() async {
    final player = _ambientPlayer ??= AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(0.055);
    await player.play(AssetSource('audio/ambient_loop.wav'));
  }

  Future<void> _saveCollection<T>(
    String key,
    List<T> collection,
    Map<String, Object?> Function(T) encode,
  ) async {
    await _preferences!.setString(
      '${_prefix}_$key',
      jsonEncode(collection.map(encode).toList()),
    );
  }

  String _handleFromName(String name) => name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
      .replaceAll(RegExp(r'(^\.|\.$)'), '');

  @override
  void dispose() {
    _ambientPlayer?.dispose();
    super.dispose();
  }
}
