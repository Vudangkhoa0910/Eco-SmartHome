import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_view.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';
import 'components/body.dart';

class AIVoiceScreen extends StatelessWidget {
  static String routeName = '/ai-voice-screen';
  const AIVoiceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseView<AIVoiceViewModel>(
      onModelReady: (model) => model.initialize(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Body(model: model),
        );
      },
    );
  }
}
