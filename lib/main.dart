import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:psitta/ui/app/psitta_app.dart';

void main() {
  JustAudioMediaKit.ensureInitialized();
  runApp(const PsittaApp());
}
