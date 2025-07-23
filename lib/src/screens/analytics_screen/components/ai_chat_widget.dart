import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/gemini_service.dart';

class AIChatWidget extends StatefulWidget {
  final Map<String, dynamic> currentData;
  
  const AIChatWidget({
    Key? key,
    required this.currentData,
  }) : super(key: key);

  @override
  State<AIChatWidget> createState() => _AIChatWidgetState();
}

class _AIChatWidgetState extends State<AIChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final currentPower = widget.currentData['currentPower'] ?? 0.0;
    final dailyEnergy = widget.currentData['dailyEnergy'] ?? 0.0;
    final monthlyEnergy = widget.currentData['monthlyEnergy'] ?? 0.0;
    
    String welcomeText = '''
🤖 Xin chào! Tôi là AI Assistant cho hệ thống Smart Home của bạn.

📊 **Tình hình hiện tại:**
• Công suất: ${currentPower.toStringAsFixed(1)}W
• Tiêu thụ hôm nay: ${dailyEnergy.toStringAsFixed(2)} kWh
• Tiêu thụ tháng: ${monthlyEnergy.toStringAsFixed(2)} kWh

💡 **Tôi có thể giúp bạn:**
• Phân tích tiêu thụ năng lượng
• Đưa ra gợi ý tiết kiệm điện
• Dự đoán chi phí hàng tháng
• Tối ưu hóa thiết bị
• Trả lời câu hỏi về smart home

Hãy hỏi tôi bất cứ điều gì! 😊
''';

    setState(() {
      _messages.add(ChatMessage(
        text: welcomeText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      // Enhanced prompt with current smart home data
      final enhancedPrompt = _buildSmartHomePrompt(userMessage);
      final response = await GeminiService.generateResponse(enhancedPrompt);

      setState(() {
        _messages.add(ChatMessage(
          text: response,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Xin lỗi, tôi gặp lỗi khi xử lý câu hỏi của bạn. Vui lòng thử lại.',
          isUser: false,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  String _buildSmartHomePrompt(String userMessage) {
    final currentData = widget.currentData;
    
    return '''
Bạn là AI Assistant chuyên về Smart Home và quản lý năng lượng. Hãy trả lời câu hỏi sau dựa trên dữ liệu thực tế của hệ thống:

**DỮ LIỆU HỆ THỐNG HIỆN TẠI:**
- Công suất hiện tại: ${currentData['currentPower'] ?? 0.0}W
- Tiêu thụ hôm nay: ${currentData['dailyEnergy'] ?? 0.0} kWh
- Tiêu thụ tháng này: ${currentData['monthlyEnergy'] ?? 0.0} kWh
- Chi phí tháng: ${(currentData['monthlyEnergy'] ?? 0.0) * 2927} VND
- Số thiết bị: ${currentData['deviceCount'] ?? 0}

**THIẾT BỊ TRONG NHÀ:**
- Đèn LED (phòng khách, bếp, phòng ngủ)
- Điều hòa (phòng khách, phòng ngủ)
- Quạt trần, tivi, tủ lạnh
- Các thiết bị thông minh khác

**CÂUHỎI CỦA NGƯỜI DÙNG:** $userMessage

Hãy trả lời một cách:
- Thân thiện và dễ hiểu
- Dựa trên dữ liệu thực tế
- Đưa ra gợi ý cụ thể và thực tế
- Sử dụng emoji phù hợp
- Giải thích rõ ràng nếu liên quan đến kỹ thuật

Nếu câu hỏi không liên quan đến smart home, hãy nhẹ nhàng chuyển hướng về chủ đề năng lượng và smart home.
''';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Home AI Assistant',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      Text(
                        _isTyping ? 'Đang suy nghĩ...' : 'Sẵn sàng trợ giúp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isTyping)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[100],
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Hỏi về tiêu thụ năng lượng, thiết bị...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _isTyping ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: message.isError 
                    ? Colors.red.withOpacity(0.2)
                    : Theme.of(context).primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                message.isError ? Icons.error : Icons.smart_toy,
                color: message.isError 
                    ? Colors.red 
                    : Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? Theme.of(context).primaryColor
                    : message.isError
                        ? Colors.red.withOpacity(0.1)
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[700]
                            : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : message.isError
                              ? Colors.red[700]
                              : Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: (message.isUser
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color)
                          ?.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.person,
                color: Colors.green,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
