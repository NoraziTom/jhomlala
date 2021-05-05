// Dart imports:
import 'dart:convert';
import 'dart:io';

// External Package imports:
import 'package:better_player/src/hls/hls_parser/mime_types.dart';
import 'package:xml/xml.dart';

// Package imports:
import 'package:better_player/src/core/better_player_utils.dart';
import 'package:better_player/src/dash/better_player_dash_audio_track.dart';

// Project imports:
import 'package:better_player/src/dash/better_player_dash_subtitle.dart';
import 'package:better_player/src/dash/better_player_dash_track.dart';

import 'better_player_dash_video.dart';

class DashObject {
  List<BetterPlayerDashVideo>? videos;
  List<BetterPlayerDashSubtitle>? subtitles;
  List<BetterPlayerDashAudioTrack>? audios;

  DashObject({this.videos, this.subtitles, this.audios});
}

///DASH helper class
class BetterPlayerDashUtils {
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);

  static Future<DashObject> parse(
      String data, String masterPlaylistUrl) async {
    final document = XmlDocument.parse(data);
    final adaptationSets = document.findAllElements('AdaptationSet');
    List<BetterPlayerDashVideo> videos = [];
    List<BetterPlayerDashAudioTrack> audios = [];
    List<BetterPlayerDashSubtitle> subtitles = [];
    int audiosCount = 0;
    adaptationSets.forEach((node) {
      final mimeType = node.getAttribute('mimeType');
      if (mimeType != null) {
        if (MimeTypes.isVideo(mimeType)) {
          videos.add(parseVideo(node));
        } else if (MimeTypes.isAudio(mimeType)) {
          audios.add(parseAudio(node, audiosCount));
          audiosCount += 1;
        } else if (MimeTypes.isText(mimeType)) {
          subtitles.add(parseSubtitle(node));
        }
      }
    });
    return DashObject(videos: videos, audios: audios, subtitles: subtitles);
  }

  static BetterPlayerDashVideo parseVideo(XmlElement node) {
    String segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    List<BetterPlayerDashTrack> tracks = [];
    String? mimeType = null;

    final representations = node.findAllElements('Representation');

    representations.forEach((representation) {
      final String? id = representation.getAttribute('id');
      final int width = int.parse(representation.getAttribute('width') ?? '0');
      final int height = int.parse(representation.getAttribute('height') ?? '0');
      final int bitrate = int.parse(representation.getAttribute('bandwidth') ?? '0');
      final int frameRate = int.parse(representation.getAttribute('frameRate') ?? '0');
      final String? codecs = representation.getAttribute('codecs');
      mimeType = MimeTypes.getCustomMimeTypeForCodec(codecs ?? '');
      tracks.add(BetterPlayerDashTrack(id, width, height, bitrate, frameRate, codecs));
    });

    return BetterPlayerDashVideo(
      tracks: tracks,
      mimeType: mimeType,
      segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true'
    );
  }

  static BetterPlayerDashAudioTrack parseAudio(XmlElement node, int index) {
    String segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    String? label = node.getAttribute('label');
    String? language = node.getAttribute('lang');
    String? mimeType = node.getAttribute('mimeType');

    return BetterPlayerDashAudioTrack(
      id: index,
      segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
      label: label,
      language: language,
      mimeType: mimeType
    );
  }

  static BetterPlayerDashSubtitle parseSubtitle(XmlElement node) {
    String segmentAlignmentStr = node.getAttribute('segmentAlignment') ?? '';
    String? language = node.getAttribute('lang');
    String? mimeType = node.getAttribute('mimeType');
    String? url = node.getElement('Representation')?.getElement('BaseURL')?.text;
    if (url != null && url.startsWith('//')) {
      url = 'https:' + url;
    }

    return BetterPlayerDashSubtitle(
      language: language,
      mimeType: mimeType,
      segmentAlignment: segmentAlignmentStr.toLowerCase() == 'true',
      url: url
    );
  }

  static Future<String?> getDataFromUrl(String url,
      [Map<String, String?>? headers]) async {
    try {
      final request = await _httpClient.getUrl(Uri.parse(url));
      if (headers != null) {
        headers.forEach((name, value) => request.headers.add(name, value!));
      }

      final response = await request.close();
      var data = "";
      await response.transform(const Utf8Decoder()).listen((content) {
        data += content.toString();
      }).asFuture<String?>();

      return data;
    } catch (exception) {
      BetterPlayerUtils.log("GetDataFromUrl failed: $exception");
      return null;
    }
  }

}
