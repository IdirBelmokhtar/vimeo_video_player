class VimeoVideoConfig {
  VimeoVideoConfig({
    this.uri,
    this.name,
    this.description,
    this.type,
    this.link,
    this.playerEmbedUrl,
    this.duration,
    this.width,
    this.language,
    this.height,
    this.files,
  });

  factory VimeoVideoConfig.fromJson(Map<String, dynamic> json) => VimeoVideoConfig(
        uri: json['uri'],
        name: json['name'],
        description: json['description'],
        type: json['type'],
        link: json['link'],
        playerEmbedUrl: json['player_embed_url'],
        duration: json['duration'],
        width: json['width'],
        language: json['language'],
        height: json['height'],
        files: (json['files'] as List<dynamic>)
            .map((fileJson) => VimeoVideoFile.fromJson(fileJson))
            .toList(),
      );

  String? uri;
  String? name;
  String? description;
  String? type;
  String? link;
  String? playerEmbedUrl;
  int? duration;
  int? width;
  String? language;
  int? height;
  List<VimeoVideoFile>? files;

  Map<String, dynamic> toJson() => {
        'uri': uri,
        'name': name,
        'description': description,
        'type': type,
        'link': link,
        'player_embed_url': playerEmbedUrl,
        'duration': duration,
        'width': width,
        'language': language,
        'height': height,
        'files': files?.map((file) => file.toJson()).toList(),
      };
}

class VimeoVideoFile {
  VimeoVideoFile({
    this.quality,
    this.rendition,
    this.type,
    this.width,
    this.height,
    this.link,
    this.createdTime,
    this.fps,
    this.size,
    this.md5,
    this.publicName,
    this.sizeShort,
  });

  factory VimeoVideoFile.fromJson(Map<String, dynamic> json) => VimeoVideoFile(
        quality: json['quality'],
        rendition: json['rendition'],
        type: json['type'],
        width: json['width'],
        height: json['height'],
        link: json['link'],
        createdTime: json['created_time'],
        fps: json['fps'],
        size: json['size'],
        md5: json['md5'],
        publicName: json['public_name'],
        sizeShort: json['size_short'],
      );

  String? quality;
  String? rendition;
  String? type;
  int? width;
  int? height;
  String? link;
  String? createdTime;
  int? fps;
  int? size;
  String? md5;
  String? publicName;
  String? sizeShort;

  Map<String, dynamic> toJson() => {
        'quality': quality,
        'rendition': rendition,
        'type': type,
        'width': width,
        'height': height,
        'link': link,
        'created_time': createdTime,
        'fps': fps,
        'size': size,
        'md5': md5,
        'public_name': publicName,
        'size_short': sizeShort,
      };
}