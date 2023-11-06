import 'dart:async';
import 'dart:io' as io;

import 'package:audioplayers/audioplayers.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder4/audio_format.dart';
import 'package:flutter_audio_recorder4/flutter_audio_recorder4.dart';
import 'package:flutter_audio_recorder4/recorder_state.dart';
import 'package:flutter_audio_recorder4/recording.dart';
import 'package:flutter_audio_recorder4_example/utils.dart';
import 'dart:developer' as developer;

import 'package:path_provider/path_provider.dart';

class RecorderExample extends StatefulWidget {

  final LocalFileSystem localFileSystem;

  const RecorderExample({super.key, localFileSystem}) : this.localFileSystem = localFileSystem ?? const LocalFileSystem();

  @override
  State<StatefulWidget> createState() => RecorderExampleState();
}

class RecorderExampleState extends State<RecorderExample> {

  FlutterAudioRecorder4? recorder;
  Recording? recording;
  RecorderState recorderState = RecorderState.UNSET;
  String platformVersion = "";
  String libraryVersion = "TODO";
  bool hasPermissions = false;

  @override
  void initState() {
    //TODO - OLD CODE - implement initState
    super.initState();
    init();
  }

  void init() async {
    try {
      if (await FlutterAudioRecorder4.hasPermissions ?? false) {
        await handleHasPermissions();
      } else {
        handleDoesNotHavePermissions();
      }
      updatePlatformVersion();
    } catch (exception) {
      developer.log("RecorderExample init exception:$exception");
    }
  }

  Future<void> updatePlatformVersion() async {
    var platformVersion = await recorder?.getPlatformVersion() ?? "Unknown platform version";
    setState((){
      this.platformVersion = platformVersion;
    });
  }

  Future<void> handleHasPermissions() async {
    String customPath = '/flutter_audio_recorder_';

    io.Directory? appDocDirectory = await getAppDocDirectory();
    if (appDocDirectory == null) throw const FileSystemException("Could not get app doc directory");

    // Can add extensions like ".mp4 ".wav" ".m4a" ".aac"
    customPath = appDocDirectory.path +
                 customPath +
                 DateTime.now().millisecondsSinceEpoch.toString();

    // .wav <---> AudioFormat.WAV
    // .mp4 .m4a .aac <---> AudioFormat.AAC
    // AudioFormat is optional, if given value, will overwrite path extension when there is conflicts.
    var recorder = FlutterAudioRecorder4(customPath, audioFormat: AudioFormat.AAC);

    try {
      await recorder.initialized;
      var recording = await recorder.current(channel: 0);
      developer.log("Recording:$recording");
    } catch(exception) {
      developer.log("Initialized exception:$exception");
    }

    // Recorder should now be INITIALIZED if everything is working
    setState(() {
      this.recorder = recorder;
      this.recording = recording;
      recorderState = recording?.recorderState ?? RecorderState.UNSET;
      hasPermissions = true;
      developer.log("RecorderState:$recorderState");
    });
  }

  void handleDoesNotHavePermissions() {
    setState(() {
      hasPermissions = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You must accept all permissions"))
    );
  }

  void start() async {
    try {
      await recorder?.start();

      await updateRecording();

      const tick = Duration(milliseconds: 50);
      Timer.periodic(tick, (Timer timer) async {
        if (recorderState == RecorderState.STOPPED) {
          timer.cancel();
        }

        await updateRecording();
        updateRecorderState();
      });

    } catch(exception) {
      developer.log("RecorderExample start exception:$exception");
    }
  }

  void resume() async {
    await recorder?.resume();
    triggerStateRefresh();
  }

  void pause() async {
    await recorder?.pause();
    triggerStateRefresh();
  }

  void stop() async {
    var result = await recorder?.stop();
    var filepath = result?.filepath;
    var duration = result?.duration;

    developer.log("Stop recording: path:$filepath");
    developer.log("Stop recording: duration:$duration");

    if (filepath == null) {
      developer.log("Stop recording and filepath is null");
    } else {
      File file = widget.localFileSystem.file(filepath);
      var fileLength = await file.length();
      developer.log("Stop recording and file length is $fileLength");
    }

    setState((){
      recording = result;
      recorderState = result?.recorderState ?? RecorderState.UNSET;//TODO - CHRIS - it's probably worth having an error state vs unset
    });
  }

  Future updateRecording() async {
    var recording = await recorder?.current(channel: 0);
    setState((){
      this.recording = recording;
    });
  }

  void updateRecorderState() {
    setState((){
      recorderState = recording?.recorderState ?? RecorderState.UNSET;
    });
  }

  void triggerStateRefresh() => setState((){});

  void onPlayAudio() async {
    var filepath = recording?.filepath;
    if (filepath == null) {
      developer.log("OnPlayAudio filepath is null");
    } else {
      await AudioPlayer().play(DeviceFileSource(filepath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: buildEdgeInsets(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            buildHasPermissionsRow(),
            buildVersionsRow(),
            buildRecorderRow(),
            buildRecorderStateRow(),
            buildAveragePowerRow(),
            buildPeakPowerRow(),
            buildFilepathRow(),
            buildAudioFormatRow(),
            buildMeteringEnabledRow(),
            buildExtensionRow(),
            buildDurationRow()
          ]
        )
      )
    );
  }

  Widget buildHasPermissionsRow() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      buildGetPermissionsButton(),
      Text("Has permissions:$hasPermissions"),
    ]
  );

  Widget buildVersionsRow() => Text('Library version $libraryVersion running on platform version $platformVersion');

  Widget buildRecorderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        buildNextRecorderStateButton(),
        buildStopButton(),
        buildPlayButton()
      ]
    );
  }

  EdgeInsets buildEdgeInsets() => const EdgeInsets.all(8.0);

  Widget buildVerticalSpacer() => const SizedBox(width: 8);

  Widget buildStopButton() => TextButton(
      onPressed: recorderState != RecorderState.UNSET ? stop : null,
      style: buildButtonStyle(),
      child: Text("Stop", style: buildButtonTextStyle())
  );

  Widget buildGetPermissionsButton() => TextButton(
    onPressed: () async {
      bool? hasPermissions = await FlutterAudioRecorder4.hasPermissions ?? this.hasPermissions;
      setState(() {
        this.hasPermissions = hasPermissions;
      });
    },
    style: buildButtonStyle(),
    child: Text("Request Permissions", style: buildButtonTextStyle())
  );

  Widget buildPlayButton() => TextButton(
    onPressed: onPlayAudio,
    style: buildButtonStyle(),
    child: Text("Play", style: buildButtonTextStyle())
  );

  Widget buildNextRecorderStateButton() {
    return Padding(
      padding: buildEdgeInsets(),
      child: TextButton(
        onPressed: (){
          switch(recorderState) {
            case RecorderState.INITIALIZED: start();
            case RecorderState.RECORDING: pause();
            case RecorderState.PAUSED: resume();
            case RecorderState.STOPPED: init();
            default: break;
          }
        },
        style: buildButtonStyle(),
        child: Text(recorderState.nexStateDisplayText, style: buildButtonTextStyle())
      )
    );
  }

  ButtonStyle buildButtonStyle() => ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(
        Colors.blueAccent.withOpacity(0.5),
      )
  );

  TextStyle buildButtonTextStyle() => const TextStyle(color: Colors.white);

  Widget buildFilepathRow() => Text("Filepath:${recording?.filepath}");
  Widget buildExtensionRow() => Text("Extension:${recording?.extension}");
  Widget buildDurationRow() => Text("Duration:${recording?.duration}");
  Widget buildAudioFormatRow() => Text("Audio Format:${recording?.audioFormat}");
  Widget buildRecorderStateRow() => Text("Recorder State:$recorderState");
  Widget buildPeakPowerRow() => Text("Peak Power:${recording?.audioMetering?.peakPower}");
  Widget buildAveragePowerRow() => Text("Average Power:${recording?.audioMetering?.averagePower}");
  Widget buildMeteringEnabledRow() => Text("Metering Enabled:${recording?.audioMetering?.meteringEnabled}");
}