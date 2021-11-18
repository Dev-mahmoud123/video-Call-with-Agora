import 'dart:developer';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/app_brain.dart';

class AudioCallScreen extends StatefulWidget {
  const AudioCallScreen({Key? key}) : super(key: key);

  @override
  _AudioCallScreenState createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  int? _remoteUid;
  late RtcEngine _engine;

  /// TODO : init agora
  Future<void> initAgora() async {
    // retrieve  Permission
    await [Permission.microphone, Permission.camera].request();
    // Create Engine
    _engine = await RtcEngine.create(AgoraManager.appId);
    await _engine.enableAudio();
    _engine.setEventHandler(
      RtcEngineEventHandler(
          joinChannelSuccess: (String channel, int uid, int elapsed) {
        log("local user $uid joined");
      }, userJoined: (int uid, int elapsed) {
        log("remote user $uid joined");
        setState(() {
          _remoteUid = uid;
        });
      }, userOffline: (int uid, UserOfflineReason reason) {
        log("remote user $uid left channel");
        setState(() {
          _remoteUid = null;
        });
        Navigator.of(context).pop(true);
      }),
    );
    await _engine.joinChannel(
        AgoraManager.token, AgoraManager.channelName, null, 0);
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

  /// TODO : Display Audio
  Widget _renderRemoteAudio() {
    if (_remoteUid != null) {
      return Text(
        "Calling with $_remoteUid",
        style: const TextStyle(color: Colors.white),
      );
    } else {
      return const Text(
        "Calling …",
        style: TextStyle(color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black87,
            child: Center(
              child: _renderRemoteAudio(),
            ),
          ),
          Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20.0),
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
              )),
        ],
      ),
    );
  }
}
