import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';

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
          colors: Theme.of(context).brightness == Brightness.dark ? [
            const Color(0xFF2E3440),
            const Color(0xFF3B4252),
            const Color(0xFF434C5E),
          ] : [
            const Color(0xFFF7F9FC),
            const Color(0xFFE6F0FA),
            const Color(0xFFDDE7F5),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(20),
            vertical: getProportionateScreenHeight(20),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_ios, 
                      color: Theme.of(context).textTheme.bodyLarge!.color, 
                      size: 24),
                  ),
                  Column(
                    children: [
                      Text(
                        'Trợ lý AI',
                        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Smart Home Assistant',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).textTheme.bodySmall!.color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => model.showSettings(context),
                    icon: Icon(Icons.settings, 
                      color: Theme.of(context).textTheme.bodyMedium!.color, 
                      size: 24),
                  ),
                ],
              ),
              SizedBox(height: getProportionateScreenHeight(20)),
              // AI Status
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: model.isListening 
                      ? Colors.green.withOpacity(0.2)
                      : model.isProcessing 
                          ? Colors.orange.withOpacity(0.2)
                          : Theme.of(context).cardColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: model.isListening 
                        ? Colors.green
                        : model.isProcessing 
                            ? Colors.orange
                            : Colors.white30,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (model.isListening) ...[
                      const Icon(Icons.mic, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                    ] else if (model.isProcessing) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.orange,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(Icons.mic_none, color: Colors.grey, size: 16),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      model.isListening ? 'Đang nghe...' : 
                      model.isProcessing ? 'Đang xử lý...' : 'Chạm để nói',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: model.isListening 
                            ? Colors.green
                            : model.isProcessing 
                                ? Colors.orange
                                : Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: getProportionateScreenHeight(5)),
              // Voice Visualizer
              Expanded(
                flex: 2,
                child: Center(
                  child: GestureDetector(
                    onTap: model.toggleListening,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: getProportionateScreenWidth(220),
                      height: getProportionateScreenWidth(220),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: model.isListening ? [
                            const Color(0xFF00D4AA).withOpacity(0.8),
                            const Color(0xFF00D4AA).withOpacity(0.4),
                            const Color(0xFF00D4AA).withOpacity(0.1),
                            Colors.transparent,
                          ] : model.isProcessing ? [
                            const Color(0xFFFF6B6B).withOpacity(0.6),
                            const Color(0xFFFF6B6B).withOpacity(0.3),
                            const Color(0xFFFF6B6B).withOpacity(0.1),
                            Colors.transparent,
                          ] : [
                            Colors.white.withOpacity(0.2),
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: model.isListening 
                              ? const Color(0xFF00D4AA)
                              : model.isProcessing 
                                  ? const Color(0xFFFF6B6B)
                                  : Colors.white.withOpacity(0.3),
                          boxShadow: [
                            BoxShadow(
                              color: model.isListening 
                                  ? const Color(0xFF00D4AA).withOpacity(0.4)
                                  : model.isProcessing
                                      ? const Color(0xFFFF6B6B).withOpacity(0.4)
                                      : Colors.white.withOpacity(0.2),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            model.isListening 
                                ? Icons.mic 
                                : model.isProcessing
                                    ? Icons.auto_awesome
                                    : Icons.mic_none,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Command Recognition Display
              if (model.recognizedText.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(getProportionateScreenWidth(16)),
                  margin: EdgeInsets.symmetric(vertical: getProportionateScreenHeight(10)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.purple.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Bạn đã nói:',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getProportionateScreenHeight(8)),
                      Text(
                        model.recognizedText,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              // AI Response
              if (model.aiResponse.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(getProportionateScreenWidth(16)),
                  margin: EdgeInsets.only(bottom: getProportionateScreenHeight(20)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF00D4AA).withOpacity(0.15),
                        const Color(0xFF00D4AA).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D4AA),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trợ lý AI:',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: const Color(0xFF00D4AA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: getProportionateScreenHeight(12)),
                      Text(
                        model.aiResponse,
                        style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              // Quick Commands
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Lệnh nhanh:',
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: getProportionateScreenHeight(12)),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: getProportionateScreenWidth(10),
                        mainAxisSpacing: getProportionateScreenHeight(10),
                        children: [
                          _buildQuickCommand(context, 'Mở đèn phòng khách', Icons.lightbulb_outline, Colors.amber),
                          _buildQuickCommand(context, 'Bật quạt phòng ngủ', Icons.air, Colors.cyan),
                          _buildQuickCommand(context, 'Đặt điều hòa 25°C', Icons.ac_unit, Colors.blue),
                          _buildQuickCommand(context, 'Tắt tất cả đèn', Icons.lightbulb, Colors.orange),
                          _buildQuickCommand(context, 'Chế độ đi ngủ', Icons.bedtime, Colors.purple),
                          _buildQuickCommand(context, 'Chế độ về nhà', Icons.home, Colors.green),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Tip
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Thử nói: "Mở đèn cổng", "Tắt quạt phòng bếp", "Đặt nhiệt độ 24 độ"',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 11,
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

  Widget _buildQuickCommand(BuildContext context, String command, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => model.executeQuickCommand(command),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: getProportionateScreenWidth(10),
          vertical: getProportionateScreenHeight(8),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.15),
              color.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: getProportionateScreenHeight(6)),
            Expanded(
              child: Text(
                command,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  fontSize: 11,
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
