import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_view.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'components/body.dart';

class AIVoiceScreen extends StatelessWidget {
  static String routeName = '/ai-voice-screen';
  const AIVoiceScreen({Key? key}) : super(key: key);

  Future<void> _checkPermissions(BuildContext context) async {
    // Kiểm tra quyền microphone
    final micStatus = await Permission.microphone.status;
    final speechStatus = await Permission.speech.status;
    
    // Hiển thị dialog nếu quyền chưa được cấp
    if (micStatus.isDenied || speechStatus.isDenied) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cấp quyền cho trợ lý giọng nói'),
          content: const Text(
            'Để sử dụng trợ lý giọng nói, ứng dụng cần quyền truy cập vào microphone và nhận dạng giọng nói. '
            'Vui lòng cấp quyền để tiếp tục.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Để sau'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                
                // Yêu cầu quyền
                await Permission.microphone.request();
                await Permission.speech.request();
              },
              child: const Text('Cấp quyền'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseView<AIVoiceViewModel>(
      onModelReady: (model) {
        model.initialize();
        _checkPermissions(context);
      },
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: Body(model: model),
        );
      },
    );
  }
}
