import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:openai_realtime_dart/openai_realtime_dart.dart';
import 'package:record/record.dart';
import 'package:tuitu/utils/common_methods.dart';
import 'dart:async';

import '../json_models/chat_message_voice.dart';

class ChatProvider extends ChangeNotifier {
  RealtimeClient? _client;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isConnected = false;
  bool isUserSpeaking = false;
  bool isAIResponding = false;
  bool isRecording = false;
  bool _shouldRestartRecording = true;
  String? currentResponseId;
  List<ChatMessage> messages = [];
  Stream<Uint8List>? audioStream;
  Timer? _silenceTimer;
  StreamSubscription? _amplitudeSubscription;
  double volume = 1.0;
  bool _isDisposed = false;

  static const double SPEECH_THRESHOLD = 0.5;
  static const Duration SILENCE_DURATION = Duration(milliseconds: 1000);

  ChatProvider() {
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    // _audioPlayer.playbackEventStream.listen((state) {
    //   switch (state) {
    //     case :
    //       isAIResponding = true;
    //       notifyListeners();
    //       break;
    //     case PlayerState.stopped:
    //     case PlayerState.completed:
    //       isAIResponding = false;
    //       notifyListeners();
    //       break;
    //     default:
    //       break;
    //   }
    // });
    //
    // _audioPlayer.playbackEventStream.listen((_) {
    //   isAIResponding = false;
    //   notifyListeners();
    // });
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  Future<void> initialize() async {
    if (_client != null) return;

    _client = RealtimeClient(
      apiKey: '',
    );

    _client!.updateSession(
      instructions: 'You are a helpful assistant.',
      voice: Voice.alloy,
      turnDetection: const TurnDetection(
        type: TurnDetectionType.serverVad,
      ),
      inputAudioTranscription: const InputAudioTranscriptionConfig(
        model: 'whisper-1',
      ),
    );

    _setupEventHandlers();
    await _connect();
    await startContinuousListening();
    isRecording = true;
    notifyListeners();
  }

  void _setupEventHandlers() {
    _client?.on(RealtimeEventType.conversationUpdated, (event) async {
      final result = (event as RealtimeEventConversationUpdated).result;
      final item = result.item;
      // you can fetch a full list of items at any time
      _client!.conversation.getItems();
      // ignore: unused_local_variable
      if (item?.item case final ItemMessage message) {
        // system, user, or assistant message (message.role)

      }
    });

    _client?.on(RealtimeEventType.conversationItemCompleted, (event) {

    });
  }

  Future<void> _connect() async {
    try {
      var connected = await _client?.connect();
      isConnected = connected ?? false;
      notifyListeners();
    } catch (e) {
      commonPrint('Connection error: $e');
    }
  }


  Future<void> startContinuousListening() async {
    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }

    try {
      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 24000,
        numChannels: 1,
      );

      audioStream = await _recorder.startStream(config);

      audioStream?.listen((data) {
        if (_client != null && _shouldRestartRecording && isConnected) {
          _client!.appendInputAudio(data);
        }
      });

      _startAmplitudeMonitoring();
    } catch (e) {
      commonPrint('Error starting continuous recording: $e');
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = Stream.periodic(
      const Duration(milliseconds: 100),
    ).asyncMap((_) => _recorder.getAmplitude()).listen((amp) {
      _handleAmplitude(amp);
    });
  }

  void _handleAmplitude(Amplitude amplitude) {
    if (!_shouldRestartRecording) return;

    bool isSpeakingNow = amplitude.current > SPEECH_THRESHOLD;

    if (isSpeakingNow && !isUserSpeaking) {
      _silenceTimer?.cancel();
      isUserSpeaking = true;

      if (isAIResponding && currentResponseId != null) {
        _audioPlayer.stop();
        _client?.cancelResponse(currentResponseId!, 0);
      }

      notifyListeners();
    } else if (!isSpeakingNow && isUserSpeaking) {
      _silenceTimer?.cancel();
      _silenceTimer = Timer(SILENCE_DURATION, () {
        if (_shouldRestartRecording) {
          isUserSpeaking = false;
          _client?.createResponse();
          notifyListeners();
        }
      });
    }
  }

  Future<void> stopRecording() async {
    _shouldRestartRecording = false;
    isRecording = false;
    _silenceTimer?.cancel();
    _amplitudeSubscription?.cancel();

    if (isUserSpeaking) {
      isUserSpeaking = false;
      _client?.createResponse();
    }

    notifyListeners();
  }

  Future<void> resumeRecording() async {
    if (!isRecording) {
      _shouldRestartRecording = true;
      isRecording = true;
      await startContinuousListening();
      notifyListeners();
    }
  }

  void sendTextMessage(String text) {
    _client?.sendUserMessageContent([
       ContentPart.inputText(text: text),
    ]);
    _addMessage(ChatMessage(isUser: true, content: text));
  }

  Future<void> setVolume(double newVolume) async {
    volume = newVolume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    volume = volume > 0 ? 0.0 : 1.0;
    await _audioPlayer.setVolume(volume);
    notifyListeners();
  }

  void _addMessage(ChatMessage message) {
    messages.add(message);
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _shouldRestartRecording = false;
    _silenceTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _client?.disconnect();

    super.dispose();
  }
}
