import 'package:flutter/material.dart';
import 'package:vimeo_video_player/vimeo_video_player.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  /// also support url like this: 'www.vimeo.com/70591644', 'vimeo.com/70591644'
  // final String _vimeoVideoUrl = 'https://vimeo.com/70591644';
  final String _vimeoVideoUrl = 'https://player.vimeo.com/video/670821472'; //! The video must have mp4 files with quality (SD, HD, 360, 720, ...).
  final String _vimeoToken = ''; //! Vimeo have policy settings for developer API, you need to generate your token to access to your vedio.

      // Create Dio options with the headers
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: VimeoVideoPlayer(
          url: _vimeoVideoUrl,
          autoPlay: true,
          token: _vimeoToken,
        ),
      ),
    );
  }
}
