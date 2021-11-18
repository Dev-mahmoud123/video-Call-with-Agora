import 'dart:developer';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_video_call/utils/app_brain.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({Key? key}) : super(key: key);

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late int _remoteUid = 0;
  late RtcEngine _engine;
  bool _localUserJoin = false;
  bool muted = false;

  /// TODO : init agora
  Future<void> initAgora() async {
    // retrieve  Permission
    await [Permission.microphone, Permission.camera].request();
    // Create Engine
    _engine = await RtcEngine.create(AgoraManager.appId);
    await _engine.enableVideo();
    _engine.setEventHandler(
      RtcEngineEventHandler(
          joinChannelSuccess: (String channel, int uid, int elapsed) {
        log("local user $uid joined");
        setState(() {
          _localUserJoin = true;
        });
      }, userJoined: (int uid, int elapsed) {
        log("remote user $uid joined");
        setState(() {
          _remoteUid = uid;
        });
      }, userOffline: (int uid, UserOfflineReason reason) {
        log("remote user $uid left channel");
        setState(() {
          _remoteUid = 0;
        });
        Navigator.of(context).pop(true);
      }),
    );
    await _engine.joinChannel(
        AgoraManager.token, AgoraManager.channelName, null, 0);
  }

  /// TODO: Display remote user's video
  Widget _remoteVideo() {
    if (_remoteUid != 0) {
      return RtcRemoteView.SurfaceView(uid: _remoteUid);
    } else {
      return const Text(
        "Calling... ",
        style: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  /// TODO : Display current user View
  Widget _renderLocalPreview() {
    return _localUserJoin
        ? RtcLocalView.SurfaceView()
        : const Center(child: CircularProgressIndicator());
  }

  /// TODO : Mute Sound
  void onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  /// TODO :  Switch Camera
  void onSwitchCamera() {
    _engine.switchCamera();
  }

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  @override
  void dispose() {
    super.dispose();
    _engine.leaveChannel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: SizedBox(
                    width: 150.0,
                    height: 200.0,
                    child: _renderLocalPreview(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      onPressed: onToggleMute,
                      icon: muted
                          ? const Icon(Icons.mic_off)
                          : const Icon(Icons.mic),
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.call,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: IconButton(
                      onPressed: onSwitchCamera,
                      icon: const Icon(Icons.switch_camera),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
