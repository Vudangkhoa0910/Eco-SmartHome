import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';
import 'package:lottie/lottie.dart';
import 'custom_commands_manager.dart';
import 'dart:math' as math;

class Body extends StatefulWidget {
  final AIVoiceViewModel model;
  const Body({Key? key, required this.model}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  late AnimationController _textAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _textFadeAnimation;
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Pulse animation for mic button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Wave animation for voice visualization
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.linear),
    );

    // Glow animation
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Text animation for real-time feedback
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textAnimationController, curve: Curves.easeIn),
    );

    // Start animations based on model state
    widget.model.addListener(_onModelStateChanged);
  }

  void _onModelStateChanged() {
    if (widget.model.isListening) {
      _pulseController.repeat(reverse: true);
      _waveController.repeat();
      _glowController.repeat(reverse: true);
      _textAnimationController.forward();
    } else {
      _pulseController.stop();
      _waveController.stop();
      _glowController.stop();
      _textAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _glowController.dispose();
    _textAnimationController.dispose();
    _chatController.dispose();
    widget.model.removeListener(_onModelStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    const Color(0xFF1A1B3E),
                    const Color(0xFF2D2B69),
                    const Color(0xFF4A4A8A),
                  ]
                : [
                    const Color(0xFFF0F8FF), // Alice Blue - very light blue
                    const Color(0xFFE6F3FF), // Light blue
                    const Color(0xFFD6EAF8), // Soft blue
                    const Color(0xFFE8DAEF), // Light lavender
                    const Color(0xFFF8F9FA), // Almost white
                  ],
            stops: const [0.0, 0.3, 0.6, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Modern Header
              _buildModernHeader(context),
              
              // AI Status Card with Real-time Voice Display
              _buildStatusCard(context),
              
              // Main Content Area - Fixed layout
              Expanded(
                child: widget.model.showChatBox 
                    ? _buildChatInterface(context)
                    : _buildVoiceInterface(context),
              ),
              
              // Bottom Controls
              _buildBottomControls(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      child: Row(
        children: [
          // Back Button with Modern Design
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.black87,
                size: 20,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Title with Gradient Text Effect
          Column(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF4FC3F7)],
                ).createShader(bounds),
                child: Text(
                  'AI Voice Assistant',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: [
                      Shadow(
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.model.speechEnabled ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.model.speechEnabled ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          offset: const Offset(0.5, 0.5),
                          blurRadius: 1,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const Spacer(),
          
          // Settings Menu with Modern Design
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black87, size: 24),
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) {
                switch (value) {
                  case 'chat':
                    widget.model.toggleChatBox();
                    break;
                  case 'commands':
                    _showCustomCommandsManager(context);
                    break;
                  case 'settings':
                    widget.model.showSettings(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'chat',
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 24, color: Colors.blue[700]),
                      const SizedBox(width: 12),
                      Text('Chat Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'commands',
                  child: Row(
                    children: [
                      Icon(Icons.tune, size: 24, color: Colors.purple[700]),
                      const SizedBox(width: 12),
                      Text('Commands', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 24, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildStatusCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: 8,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status Icon with Animation
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _getStatusColor().withOpacity(_glowAnimation.value),
                          _getStatusColor().withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                  );
                },
              ),
              
              const SizedBox(width: 16),
              
              // Status Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0.5, 0.5),
                            blurRadius: 1,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _getStatusSubtitle(),
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.8),
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            offset: const Offset(0.5, 0.5),
                            blurRadius: 1,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Audio Level Indicator
              if (widget.model.isListening) _buildAudioLevelIndicator(),
            ],
          ),
          
          // Real-time Voice Recognition Display
          if (widget.model.isListening || widget.model.recognizedText.isNotEmpty)
            AnimatedBuilder(
              animation: _textFadeAnimation,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.hearing,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Nhận diện:',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              shadows: [
                                Shadow(
                                  offset: const Offset(0.5, 0.5),
                                  blurRadius: 1,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.model.recognizedText.isEmpty 
                            ? (widget.model.isListening ? 'Đang lắng nghe...' : 'Chưa có văn bản')
                            : widget.model.recognizedText,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: widget.model.recognizedText.isEmpty 
                              ? FontStyle.italic 
                              : FontStyle.normal,
                          shadows: [
                            Shadow(
                              offset: const Offset(0.5, 0.5),
                              blurRadius: 1,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          
          // AI Response Display
          if (widget.model.aiResponse.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00D4AA).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        color: const Color(0xFF00D4AA),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Phản hồi:',
                        style: TextStyle(
                          color: const Color(0xFF00D4AA),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.volume_up,
                        color: const Color(0xFF00D4AA),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.model.aiResponse,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          offset: Offset(0.5, 0.5),
                          blurRadius: 1,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioLevelIndicator() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Row(
          children: List.generate(4, (index) {
            final height = 20 + 15 * math.sin(_waveAnimation.value + index * 0.5);
            return Container(
              width: 3,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D4AA), Color(0xFF4FC3F7)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildVoiceInterface(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: 16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Voice Visualization Circle - Reduced size to prevent overflow
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.model.isListening ? _pulseAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: widget.model.toggleListening,
                  child: Container(
                    width: 180, // Increased from 160 for better visibility
                    height: 180, // Increased from 160 for better visibility
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          _getStatusColor().withOpacity(0.8),
                          _getStatusColor().withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: widget.model.isProcessing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Center(
                              child: Container(
                                width: 80, // Increased mic icon container size
                                height: 80,
                                decoration: BoxDecoration(
                                  color: widget.model.isListening 
                                      ? Colors.red.withOpacity(0.8)
                                      : Colors.red.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  widget.model.isListening ? Icons.mic : Icons.mic_none,
                                  color: Colors.white,
                                  size: 40, // Larger mic icon
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24), // Reduced from 40
          
          // Instruction Text with Auto-stop Timer Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  widget.model.isListening
                      ? 'Đang lắng nghe...\nHãy nói câu lệnh của bạn'
                      : widget.model.isProcessing
                          ? 'Đang xử lý...\nVui lòng đợi'
                          : widget.model.speechEnabled
                              ? 'Chạm vào mic để bắt đầu\nnói với trợ lý AI'
                              : 'Cần cấp quyền microphone\nđể sử dụng tính năng này',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        offset: const Offset(0.5, 0.5),
                        blurRadius: 1,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
                
                // Auto-stop progress indicator when listening
                if (widget.model.isListening && widget.model.recognizedText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tự động xử lý sau 1.5s...',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 16), // Reduced from 20
          
          // Mic Permission Button (if needed)
          if (!widget.model.speechEnabled)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await widget.model.requestMicrophonePermission();
                },
                icon: const Icon(Icons.mic, size: 20),
                label: const Text('Cấp quyền Microphone'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4AA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          
          // Quick Commands - More compact layout
          if (!widget.model.isListening && !widget.model.isProcessing)
            _buildQuickCommands(context),
        ],
      ),
    );
  }
  Widget _buildQuickCommands(BuildContext context) {
    final quickCommands = [
      {'text': 'Mở đèn cổng', 'icon': Icons.lightbulb_outline},
      {'text': 'Bật đèn hành lang', 'icon': Icons.light},
      {'text': 'Bật điều hòa phòng khách', 'icon': Icons.ac_unit},
      {'text': 'Mở cổng', 'icon': Icons.door_front_door},
      {'text': 'Chế độ về nhà', 'icon': Icons.home},
      {'text': 'Chế độ đi ngủ', 'icon': Icons.bedtime},
    ];

    return Column(
      children: [
        Text(
          'Lệnh nhanh',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: const Offset(0.5, 0.5),
                blurRadius: 1,
                color: Colors.white.withOpacity(0.8),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Use GridView instead of Wrap to prevent overflow
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.0,
          ),
          itemCount: quickCommands.length,
          itemBuilder: (context, index) {
            final cmd = quickCommands[index];
            return GestureDetector(
              onTap: () => widget.model.executeVoiceCommand(cmd['text'] as String),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      cmd['icon'] as IconData,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        cmd['text'] as String,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              offset: Offset(0.5, 0.5),
                              blurRadius: 1,
                              color: Colors.white,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildChatInterface(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: 8,
      ),
      height: MediaQuery.of(context).size.height * 0.6, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00D4AA).withOpacity(0.3),
                  const Color(0xFF4FC3F7).withOpacity(0.3),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chat với AI Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: widget.model.clearChatMessages,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          
          // Chat Messages
          Expanded(
            child: widget.model.chatMessages.isEmpty
                ? _buildEmptyChat()
                : _buildChatMessages(),
          ),
          
          // Chat Input
          _buildChatInput(context),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  offset: const Offset(0.5, 0.5),
                  blurRadius: 1,
                  color: Colors.white.withOpacity(0.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gửi tin nhắn hoặc sử dụng giọng nói\nđể điều khiển smart home',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black.withOpacity(0.8),
              fontSize: 14,
              shadows: [
                Shadow(
                  offset: const Offset(0.5, 0.5),
                  blurRadius: 1,
                  color: Colors.white.withOpacity(0.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: widget.model.chatMessages.length,
      itemBuilder: (context, index) {
        final message = widget.model.chatMessages[index];
        final isUser = message['isUser'] as bool;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D4AA), Color(0xFF4FC3F7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    message['message'] as String,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          offset: Offset(0.3, 0.3),
                          blurRadius: 0.5,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _buildChatInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _chatController,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 14, // Giảm kích thước chữ
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn hoặc câu lệnh...',
                  hintStyle: TextStyle(
                    color: Colors.black.withOpacity(0.5),
                    fontWeight: FontWeight.w400,
                    fontSize: 14, // Giảm kích thước hint text
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                  isDense: true, // Giảm chiều cao
                ),
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) {
                    widget.model.sendChatMessage(text.trim());
                    _chatController.clear();
                  }
                },
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D4AA), Color(0xFF4FC3F7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: () {
                final text = _chatController.text.trim();
                if (text.isNotEmpty) {
                  widget.model.sendChatMessage(text);
                  _chatController.clear();
                }
              },
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 22, // Tăng kích thước
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Voice Button
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.model.isListening 
                    ? [const Color(0xFFEF5350), const Color(0xFFD32F2F)] // Darker red when listening
                    : [const Color(0xFFE53935), const Color(0xFFB71C1C)], // Red when not listening
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              onPressed: widget.model.toggleListening,
              icon: Icon(
                widget.model.isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 24, // Larger icon in chat
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: widget.model.showChatBox ? Icons.mic : Icons.chat,
            label: widget.model.showChatBox ? 'Voice' : 'Chat',
            onTap: widget.model.toggleChatBox,
            isActive: false,
          ),
          _buildControlButton(
            icon: Icons.tune,
            label: 'Commands',
            onTap: () => _showCustomCommandsManager(context),
            isActive: false,
          ),
          _buildControlButton(
            icon: Icons.settings,
            label: 'Settings',
            onTap: () => widget.model.showSettings(context),
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? Colors.white.withOpacity(0.4)
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive 
                  ? Colors.blue[700] 
                  : Colors.black87, // Màu đen nổi bật thay vì trắng
              size: 26, // Tăng kích thước icon
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.black87, // Đổi từ black thành black87 cho đồng nhất
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    offset: const Offset(0.3, 0.3),
                    blurRadius: 0.5,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getStatusColor() {
    if (widget.model.isListening) return const Color(0xFF00D4AA);
    if (widget.model.isProcessing) return const Color(0xFFFFA726);
    if (widget.model.showChatBox) return const Color(0xFF4FC3F7);
    if (widget.model.speechEnabled) return const Color(0xFF66BB6A);
    return const Color(0xFFEF5350);
  }

  IconData _getStatusIcon() {
    if (widget.model.isListening) return Icons.mic;
    if (widget.model.isProcessing) return Icons.hourglass_empty;
    if (widget.model.showChatBox) return Icons.chat;
    if (widget.model.speechEnabled) return Icons.mic_none;
    return Icons.mic_off;
  }

  String _getStatusTitle() {
    if (widget.model.isListening) return 'Đang lắng nghe...';
    if (widget.model.isProcessing) return 'Đang xử lý...';
    if (widget.model.showChatBox) return 'Chế độ chat';
    if (widget.model.speechEnabled) return 'Sẵn sàng';
    return 'Không khả dụng';
  }

  String _getStatusSubtitle() {
    if (widget.model.isListening) return 'Hãy nói câu lệnh của bạn';
    if (widget.model.isProcessing) return 'Vui lòng đợi trong giây lát';
    if (widget.model.showChatBox) return 'Nhập tin nhắn hoặc dùng voice';
    if (widget.model.speechEnabled) return 'Chạm mic để bắt đầu';
    return 'Cần cấp quyền microphone';
  }

  void _showCustomCommandsManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomCommandsManager(model: widget.model),
    );
  }
}
