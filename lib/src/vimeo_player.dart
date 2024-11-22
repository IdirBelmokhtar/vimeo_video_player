import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:vimeo_video_player/src/model/flick_portrait_with_settings_controls.dart';

import 'model/vimeo_video_config.dart';

class VimeoVideoPlayer extends StatefulWidget {
  /// vimeo video url
  final String url;

  /// hide/show device status-bar
  final List<SystemUiOverlay> systemUiOverlay;

  /// deviceOrientation of video view
  final List<DeviceOrientation> deviceOrientation;

  /// If this value is set, video will have initial position
  /// set to given minute/second.
  ///
  /// Incorrect values (exceeding the video duration) will be ignored.
  final Duration? startAt;

  /// If this function is provided, it will be called periodically with
  /// current video position (approximately every 500 ms).
  final void Function(Duration timePoint)? onProgress;

  /// If this function is provided, it will be called when video
  /// finishes playback.
  final VoidCallback? onFinished;

  /// to auto-play the video once initialized
  final bool autoPlay;

  /// Options to pass in Dio GET request
  /// Used in vimeo video public API call to get the video config
  final Options? dioOptionsForVimeoVideoConfig;

  /// you need to add your vimeo token
  final String token;

  /// start video muted
  final bool startMuted;

  const VimeoVideoPlayer({
    required this.url,
    this.systemUiOverlay = const [
      SystemUiOverlay.top,
      SystemUiOverlay.bottom,
    ],
    this.deviceOrientation = const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
    this.startAt,
    this.onProgress,
    this.onFinished,
    this.autoPlay = false,
    this.dioOptionsForVimeoVideoConfig,
    required this.token,
    required this.startMuted,
    super.key,
  });

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  /// video player controller
  VideoPlayerController? _videoPlayerController;

  final VideoPlayerController _emptyVideoPlayerController =
      VideoPlayerController.networkUrl(Uri.parse(''));

  /// flick manager to manage the flick player
  FlickManager? _flickManager;

  /// used to notify that video is loaded or not
  ValueNotifier<bool> isVimeoVideoLoaded = ValueNotifier(false);

  /// used to notify that video is is playing or not
  ValueNotifier<bool> isSettingsButtonVisible = ValueNotifier(true);

  /// used to notify quality files
  ValueNotifier<List<VimeoVideoFile>> files = ValueNotifier([]);

  /// the current link of the vedio
  String currentLink = '';
  void updateCurrentLink(String newValue) {
    setState(() {
      currentLink = newValue;
      // Reinitialize the video player with the new link
      _videoPlayer(currentLink, _videoPlayerController!.value.position);
      isVimeoVideoLoaded.value = !isVimeoVideoLoaded.value;
      // This will trigger the whole screen to refresh because it modifies the state
    });
  }

  /// Vimeo video regexp
  final RegExp _vimeoRegExp = RegExp(
    r'^(?:http|https)?:?/?/?(?:www\.)?(?:player\.)?vimeo\.com/(?:channels/(?:\w+/)?|groups/[^/]*/videos/|video/|)(\d+)(?:|/\?)?$',
    caseSensitive: false,
    multiLine: false,
  );

  /// used to check that the url format is valid vimeo video format
  bool get _isVimeoVideo {
    var regExp = _vimeoRegExp;
    final match = regExp.firstMatch(widget.url);
    if (match != null && match.groupCount >= 1) return true;
    return false;
  }

  /// used to check that the video is already seeked or not
  bool _isSeekedVideo = false;

  @override
  void initState() {
    super.initState();

    /// checking that vimeo url is valid or not
    if (_isVimeoVideo) {
      if (_videoId.isEmpty) {
        throw (Exception(
            'Unable extract video id from given vimeo video url: ${widget.url}'));
      }

      if (currentLink == '') _videoPlayer('', const Duration(seconds: 0));
    } else {
      throw (Exception('Invalid vimeo video url: ${widget.url}'));
    }
  }

  @override
  void deactivate() {
    _videoPlayerController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    /// disposing the controllers
    _flickManager = null;
    _flickManager?.dispose();
    _videoPlayerController = null;
    _videoPlayerController?.dispose();
    _emptyVideoPlayerController.dispose();
    isVimeoVideoLoaded.dispose();
    isSettingsButtonVisible.dispose();
    files.dispose();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    ); // to re-show bars
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      child: ValueListenableBuilder(
        valueListenable: isVimeoVideoLoaded,
        builder: (context, bool isVideo, child) => Container(
          child: isVideo
              ? FlickVideoPlayer(
                  key: ObjectKey(_flickManager),
                  flickManager: _flickManager ??
                      FlickManager(
                        videoPlayerController: _emptyVideoPlayerController,
                      ),
                  systemUIOverlay: widget.systemUiOverlay,
                  preferredDeviceOrientation: widget.deviceOrientation,
                  flickVideoWithControls: FlickVideoWithControls(
                    videoFit: BoxFit.fitWidth,
                    controls: FlickPortraitWithSettingsControls(
                      flickManager: _flickManager!,
                      isSettingsButtonVisible: isSettingsButtonVisible,
                      files: files,
                      onUpdate: updateCurrentLink,
                    ),
                  ),
                  flickVideoWithControlsFullscreen:
                      const FlickVideoWithControls(
                    controls: FlickLandscapeControls(),
                  ),
                )
              : const Center(
                  child: CircularProgressIndicator(
                    color: Colors.grey,
                    backgroundColor: Colors.white,
                  ),
                ),
        ),
      ),
      onPopInvoked: (didPop) {
        /// Pausing the video before the navigator pop
        _videoPlayerController?.pause();
      },
    );
  }

  void _setVideoInitialPosition(Duration goTo) {
    Duration? startAt = widget.startAt;

    if (goTo != const Duration(seconds: 0)) {
      startAt = goTo;
    }

    if (startAt != null && _videoPlayerController != null) {
      _videoPlayerController!.addListener(() {
        final VideoPlayerValue videoData = _videoPlayerController!.value;
        if (videoData.isInitialized &&
            videoData.duration > startAt! &&
            !_isSeekedVideo) {
          _videoPlayerController!.seekTo(startAt);
          _isSeekedVideo = true;
        } // else ignore, incorrect value
      });
    }
  }

  void _setVideoListeners() {
    final onProgressCallback = widget.onProgress;
    final onFinishCallback = widget.onFinished;

    if (_videoPlayerController != null &&
        (onProgressCallback != null || onFinishCallback != null)) {
      _videoPlayerController!.addListener(() {
        final VideoPlayerValue videoData = _videoPlayerController!.value;
        if (videoData.isInitialized) {
          if (videoData.isPlaying) {
            if (onProgressCallback != null) {
              onProgressCallback.call(videoData.position);
            }
          } else if (videoData.duration == videoData.position) {
            if (onFinishCallback != null) {
              onFinishCallback.call();
            }
          }
        }
      });
    }
    _checkPlayingStatus();
  }

  void _checkPlayingStatus() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_videoPlayerController != null &&
          _videoPlayerController!.value.isInitialized) {
        VideoPlayerValue videoData = _videoPlayerController!.value;

        // Update the visibility of the settings button based on playing status
        if (videoData.isPlaying) {
          isSettingsButtonVisible.value = false;
        } else {
          isSettingsButtonVisible.value = true;
        }
      }

      // Continue checking the status recursively every second
      _checkPlayingStatus();
    });
  }

  void _videoPlayer(String link, Duration duration) {
    //! the response of vimeo api was changed
    /// getting the vimeo video configuration from api and setting managers
    _getVimeoVideoConfigFromUrl(widget.url).then((value) async {
      final progressiveList = value?.files;

      List<VimeoVideoFile>? files = progressiveList;

      var vimeoMp4Video = '';

      if (files != null && files.isNotEmpty) {
        this.files.value = files;

        // Filter valid links and convert to a list
        var validLinks = files
            .where(
                (element) => element.link != null && element.link!.isNotEmpty)
            .map((element) => element.link!)
            .toList();

        // Check if there are at least 2 valid links
        if (link == '') {
          if (validLinks.isNotEmpty) {
            currentLink = validLinks[0]; // Get the first valid link
          } else {
            showAlertDialog(context);
            return;
          }
        } else {
          currentLink = link;
        }
        vimeoMp4Video = currentLink;

        if (vimeoMp4Video.isEmpty || vimeoMp4Video == '') {
          showAlertDialog(context);
        }
      }

      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(vimeoMp4Video));

      _setVideoInitialPosition(duration);
      _setVideoListeners();

      _flickManager = FlickManager(
        videoPlayerController:
            _videoPlayerController ?? _emptyVideoPlayerController,
        autoPlay: widget.autoPlay,
        // ignore: use_build_context_synchronously
      )..registerContext(context);

      if (widget.startMuted) _flickManager?.flickControlManager?.mute();

      isVimeoVideoLoaded.value = !isVimeoVideoLoaded.value;
    });
  }

  /// used to get valid vimeo video configuration
  Future<VimeoVideoConfig?> _getVimeoVideoConfigFromUrl(
    String url, {
    bool trimWhitespaces = true,
  }) async {
    if (trimWhitespaces) url = url.trim();

    final response = await _getVimeoVideoConfig(vimeoVideoId: _videoId);
    return (response != null) ? response : null;
  }

  /// give vimeo video configuration from api
  Future<VimeoVideoConfig?> _getVimeoVideoConfig({
    required String vimeoVideoId,
  }) async {
    try {
      Options dioOptions = Options(
        headers: {
          'Authorization': 'Bearer ${widget.token}',
        },
      );

      Response responseData = await Dio().get(
        'https://api.vimeo.com/videos/$vimeoVideoId',
        options: dioOptions,
        // options: widget.dioOptionsForVimeoVideoConfig,
      );
      var vimeoVideo = VimeoVideoConfig.fromJson(responseData.data);
      return vimeoVideo;
    } on DioException catch (e) {
      log('Dio Error : ', name: e.error.toString());
      return null;
    } on Exception catch (e) {
      log('Error : ', name: e.toString());
      return null;
    }
  }
}

// ignore: library_private_types_in_public_api
extension ShowAlertDialog on _VimeoVideoPlayerState {
  showAlertDialog(BuildContext context) {
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Alert"),
      content: const Text("Some thing wrong with this url"),
      actions: [
        TextButton(
          child: const Text("OK"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  String get _videoId {
    RegExpMatch? match = _vimeoRegExp.firstMatch(widget.url);
    return match?.group(1) ?? '';
  }
}
