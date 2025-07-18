import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';
import 'package:lottie/lottie.dart';
import 'custom_commands_manager.dart';

class Body extends StatelessWidget {
  final AIVoiceViewModel model;
  const Body({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [
                  const Color(0xFF2E3440),
                  const Color(0xFF3B4252),
                  const Color(0xFF434C5E),
                ]
              : [
                  const Color(0xFFF7F9FC),
                  const Color(0xFFE6F0FA),
                  const Color(0xFFDDE7F5),
                ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(16),
            vertical: getProportionateScreenHeight(12),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                      size: 22,
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        'Trợ lý AI',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Smart Home Assistant',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall!.color,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => model.toggleChatBox(),
                        icon: Stack(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              color:
                                  Theme.of(context).textTheme.bodyMedium!.color,
                              size: 22,
                            ),
                            if (model.showChatBox)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showCustomCommandsManager(context),
                        icon: Icon(
                          Icons.tune,
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                          size: 22,
                        ),
                      ),
                      IconButton(
                        onPressed: () => model.showSettings(context),
                        icon: Icon(
                          Icons.settings,
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: getProportionateScreenHeight(10)),
              // AI Status
              Container(
                margin:
                    EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: model.isListening
                      ? Colors.green.withOpacity(0.2)
                      : model.isProcessing
                          ? Colors.orange.withOpacity(0.2)
                          : model.showChatBox
                              ? Colors.blue.withOpacity(0.2)
                              : model.speechEnabled
                                  ? Theme.of(context).cardColor.withOpacity(0.8)
                                  : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: model.isListening
                        ? Colors.green
                        : model.isProcessing
                            ? Colors.orange
                            : model.showChatBox
                                ? Colors.blue
                                : model.speechEnabled
                                    ? Colors.white30
                                    : Colors.red,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (model.isListening) ...[
                      const Icon(Icons.mic, color: Colors.green, size: 14),
                      const SizedBox(width: 6),
                    ] else if (model.isProcessing) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ] else if (model.showChatBox) ...[
                      const Icon(Icons.chat, color: Colors.blue, size: 14),
                      const SizedBox(width: 6),
                    ] else if (model.speechEnabled) ...[
                      const Icon(Icons.mic_none, color: Colors.grey, size: 14),
                      const SizedBox(width: 6),
                    ] else ...[
                      const Icon(Icons.mic_off, color: Colors.red, size: 14),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      model.isListening
                          ? 'Đang nghe...'
                          : model.isProcessing
                              ? 'Đang xử lý...'
                              : model.showChatBox
                                  ? 'Chế độ chat'
                                  : model.speechEnabled
                                      ? 'Chạm để nói'
                                      : 'Giọng nói không khả dụng',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: model.isListening
                                ? Colors.green
                                : model.isProcessing
                                    ? Colors.orange
                                    : model.showChatBox
                                        ? Colors.blue
                                        : model.speechEnabled
                                            ? Theme.of(context)
                                                .textTheme
                                                .bodyMedium!
                                                .color!
                                                .withOpacity(0.7)
                                            : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),

              // Voice Visualizer or Chat Box
              if (!model.showChatBox) ...[
                Flexible(
                  flex: 3,
                  child: Center(
                    child: GestureDetector(
                      onTap: model.toggleListening,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!model.speechEnabled)
                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.mic_off,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 4),
                                    Text(
                                      'Chạm để cấp quyền',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Center(
                            child: model.isProcessing
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 4,
                                  )
                                : Lottie.asset(
                                    'assets/Lottie/mic.json',
                                    width: 400, // Tăng từ 60 → 120
                                    height: 400, // Tăng từ 60 → 120
                                    animate: model
                                        .isListening, // Animate khi đang nghe
                                    repeat: model
                                        .isListening, // Lặp lại khi đang nghe
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Flexible(
                  flex: 3,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        vertical: getProportionateScreenHeight(5)),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Chat Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.chat,
                                  color: Theme.of(context).primaryColor,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Chat với AI',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: model.clearChatMessages,
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .color,
                                  size: 18,
                                ),
                                constraints: const BoxConstraints(
                                    minWidth: 32, minHeight: 32),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                        // Chat Messages
                        Expanded(
                          child: model.chatMessages.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color!
                                            .withOpacity(0.5),
                                        size: 40,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Chưa có tin nhắn nào\nBắt đầu trò chuyện với AI!',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .copyWith(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .color!
                                                  .withOpacity(0.5),
                                              fontSize: 12,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: model.chatMessages.length,
                                  itemBuilder: (context, index) {
                                    final message = model.chatMessages[index];
                                    final isUser = message['isUser'] as bool;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        mainAxisAlignment: isUser
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (!isUser) ...[
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF00D4AA),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: const Icon(
                                                Icons.smart_toy,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Flexible(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isUser
                                                    ? Theme.of(context)
                                                        .primaryColor
                                                    : Theme.of(context)
                                                        .cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: isUser
                                                    ? null
                                                    : Border.all(
                                                        color: Theme.of(context)
                                                            .dividerColor,
                                                      ),
                                              ),
                                              child: Text(
                                                message['message'] as String,
                                                style: TextStyle(
                                                  color: isUser
                                                      ? Colors.white
                                                      : Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium!
                                                          .color,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isUser) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Chat Input
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: model.chatController,
                                  style: const TextStyle(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Nhập tin nhắn...',
                                    hintStyle: const TextStyle(fontSize: 12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Theme.of(context).cardColor,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    isDense: true,
                                  ),
                                  onSubmitted: (text) {
                                    if (text.trim().isNotEmpty) {
                                      model.sendChatMessage(text);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 6),
                              FloatingActionButton(
                                onPressed: () {
                                  if (model.chatController.text
                                      .trim()
                                      .isNotEmpty) {
                                    model.sendChatMessage(
                                        model.chatController.text);
                                  }
                                },
                                backgroundColor: Theme.of(context).primaryColor,
                                mini: true,
                                child: const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // Command Recognition Display
              if (model.recognizedText.isNotEmpty && !model.showChatBox)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                  margin: EdgeInsets.symmetric(
                      vertical: getProportionateScreenHeight(4)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.purple.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over,
                              color: Colors.blue, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Bạn đã nói:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                      SizedBox(height: getProportionateScreenHeight(4)),
                      Text(
                        model.recognizedText,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 14,
                            ),
                      ),
                    ],
                  ),
                ),
              // AI Response
              if (model.aiResponse.isNotEmpty && !model.showChatBox)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                  margin:
                      EdgeInsets.only(bottom: getProportionateScreenHeight(8)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00D4AA).withOpacity(0.15),
                        const Color(0xFF00D4AA).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00D4AA).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4AA),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Trợ lý AI:',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: const Color(0xFF00D4AA),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                      SizedBox(height: getProportionateScreenHeight(6)),
                      Text(
                        model.aiResponse,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 13,
                              height: 1.3,
                            ),
                      ),
                    ],
                  ),
                ),
              // Quick Commands
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on,
                            color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Lệnh nhanh:',
                          style:
                              Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(8)),
                    Flexible(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: getProportionateScreenWidth(8),
                        mainAxisSpacing: getProportionateScreenHeight(8),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _buildQuickCommand(
                            context,
                            'Mở đèn phòng khách',
                            Icons.lightbulb_outline,
                            Colors.amber,
                          ),
                          _buildQuickCommand(
                            context,
                            'Bật quạt phòng ngủ',
                            Icons.air,
                            Colors.cyan,
                          ),
                          _buildQuickCommand(
                            context,
                            'Đặt điều hòa 25°C',
                            Icons.ac_unit,
                            Colors.blue,
                          ),
                          _buildQuickCommand(
                            context,
                            'Tắt tất cả đèn',
                            Icons.lightbulb,
                            Colors.orange,
                          ),
                          _buildQuickCommand(
                            context,
                            'Chế độ đi ngủ',
                            Icons.bedtime,
                            Colors.purple,
                          ),
                          _buildQuickCommand(
                            context,
                            'Chế độ về nhà',
                            Icons.home,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tip
              Container(
                padding: const EdgeInsets.all(10),
                margin: EdgeInsets.only(top: getProportionateScreenHeight(6)),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      model.speechEnabled
                          ? Icons.tips_and_updates
                          : Icons.warning,
                      color: model.speechEnabled ? Colors.amber : Colors.orange,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        model.speechEnabled
                            ? (model.showChatBox
                                ? 'Chế độ chat: Nhập tin nhắn hoặc chuyển sang chế độ giọng nói'
                                : 'Thử nói: "Mở đèn cổng", "Tắt quạt phòng bếp", "Đặt nhiệt độ 24 độ"')
                            : 'Nhận diện giọng nói chưa khả dụng. Hãy sử dụng chế độ chat.',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontSize: 10,
                              color: model.speechEnabled ? null : Colors.orange,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCustomCommandsManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomCommandsManager(model: model),
    );
  }

  Widget _buildQuickCommand(
    BuildContext context,
    String command,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => model.executeQuickCommand(command),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(8),
          vertical: getProportionateScreenHeight(6),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: getProportionateScreenHeight(4)),
            Flexible(
              child: Text(
                command,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
