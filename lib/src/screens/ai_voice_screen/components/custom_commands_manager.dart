import 'package:flutter/material.dart';
import 'package:smart_home/view/ai_voice_view_model.dart';

class CustomCommandsManager extends StatefulWidget {
  final AIVoiceViewModel model;
  
  const CustomCommandsManager({Key? key, required this.model}) : super(key: key);

  @override
  State<CustomCommandsManager> createState() => _CustomCommandsManagerState();
}

class _CustomCommandsManagerState extends State<CustomCommandsManager> {
  final _commandController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _aliasesController = TextEditingController();
  
  String _selectedZone = 'living_room';
  String _selectedDeviceId = 'led_gate';
  String _selectedAction = 'on';
  
  final List<Map<String, String>> _zones = [
    {'id': 'living_room', 'name': 'Phòng khách'},
    {'id': 'bedroom', 'name': 'Phòng ngủ'},
    {'id': 'kitchen', 'name': 'Nhà bếp'},
    {'id': 'bathroom', 'name': 'Phòng tắm'},
    {'id': 'garden', 'name': 'Sân vườn'},
    {'id': 'gate', 'name': 'Cổng'},
  ];
  
  final List<Map<String, String>> _devices = [
    {'id': 'led_gate', 'name': 'Đèn cổng'},
    {'id': 'led_around', 'name': 'Đèn quanh nhà'},
    {'id': 'motor', 'name': 'Motor/Quạt'},
    {'id': 'air_conditioner', 'name': 'Điều hòa'},
    {'id': 'tv', 'name': 'TV'},
    {'id': 'camera', 'name': 'Camera'},
  ];
  
  final List<Map<String, String>> _actions = [
    {'id': 'on', 'name': 'Bật'},
    {'id': 'off', 'name': 'Tắt'},
    {'id': 'adjust', 'name': 'Điều chỉnh'},
    {'id': 'toggle', 'name': 'Đổi trạng thái'},
  ];

  @override
  void dispose() {
    _commandController.dispose();
    _descriptionController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF2E3440),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF3B4252),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quản lý lệnh tùy chỉnh',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Tab Bar
                  Container(
                    color: const Color(0xFF3B4252),
                    child: const TabBar(
                      indicatorColor: Colors.blue,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white54,
                      tabs: [
                        Tab(text: 'Danh sách lệnh'),
                        Tab(text: 'Thêm lệnh mới'),
                      ],
                    ),
                  ),
                  
                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCommandsList(),
                        _buildAddCommand(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandsList() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Search Bar
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm lệnh...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              // TODO: Implement search
            },
          ),
          
          const SizedBox(height: 16),
          
          // Commands List
          Expanded(
            child: widget.model.customCommands.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.voice_over_off,
                          size: 64,
                          color: Colors.white24,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có lệnh tùy chỉnh nào',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hãy thêm lệnh mới để điều khiển\nthiết bị theo cách riêng của bạn',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.model.customCommands.length,
                    itemBuilder: (context, index) {
                      final command = widget.model.customCommands[index];
                      return _buildCommandItem(command);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandItem(Map<String, dynamic> command) {
    final zoneName = _zones.firstWhere(
      (zone) => zone['id'] == command['zone'],
      orElse: () => {'id': '', 'name': command['zone']},
    )['name'];
    
    final deviceName = _devices.firstWhere(
      (device) => device['id'] == command['device_id'],
      orElse: () => {'id': '', 'name': command['device_id']},
    )['name'];
    
    final actionName = _actions.firstWhere(
      (action) => action['id'] == command['action'],
      orElse: () => {'id': '', 'name': command['action']},
    )['name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Command text
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  command['command_text'] ?? '',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white54),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text('Sửa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Text('Xóa'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditCommandDialog(command);
                  } else if (value == 'delete') {
                    _showDeleteConfirmDialog(command);
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Description
          if (command['description'] != null && command['description'].isNotEmpty)
            Text(
              command['description'],
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Device info
          Row(
            children: [
              _buildInfoChip(Icons.location_on, zoneName ?? '', Colors.green),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.device_hub, deviceName ?? '', Colors.orange),
              const SizedBox(width: 8),
              _buildInfoChip(Icons.play_arrow, actionName ?? '', Colors.purple),
            ],
          ),
          
          // Aliases
          if (command['aliases'] != null && command['aliases'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 4,
                children: (command['aliases'] as List).map((alias) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      alias,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCommand() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Command Text
            const Text(
              'Lệnh giọng nói',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commandController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ví dụ: "Mở đèn phòng ngủ"',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Zone Selection
            const Text(
              'Khu vực',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedZone,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF2E3440),
                style: const TextStyle(color: Colors.white),
                items: _zones.map((zone) {
                  return DropdownMenuItem(
                    value: zone['id'],
                    child: Text(zone['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedZone = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Device Selection
            const Text(
              'Thiết bị',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedDeviceId,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF2E3440),
                style: const TextStyle(color: Colors.white),
                items: _devices.map((device) {
                  return DropdownMenuItem(
                    value: device['id'],
                    child: Text(device['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDeviceId = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Selection
            const Text(
              'Hành động',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _selectedAction,
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF2E3440),
                style: const TextStyle(color: Colors.white),
                items: _actions.map((action) {
                  return DropdownMenuItem(
                    value: action['id'],
                    child: Text(action['name']!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAction = value!;
                  });
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            const Text(
              'Mô tả (tùy chọn)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Mô tả chi tiết lệnh này',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Aliases
            const Text(
              'Các cách nói khác (tùy chọn)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _aliasesController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cách nói khác, ngăn cách bằng dấu phẩy',
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Add Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addCommand,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Thêm lệnh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCommand() async {
    if (_commandController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập lệnh giọng nói')),
      );
      return;
    }

    final aliases = _aliasesController.text.trim().isNotEmpty
        ? _aliasesController.text.split(',').map((e) => e.trim()).toList()
        : null;

    await widget.model.addCustomCommand(
      commandText: _commandController.text.trim(),
      deviceId: _selectedDeviceId,
      action: _selectedAction,
      zone: _selectedZone,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      aliases: aliases,
    );

    // Clear form
    _commandController.clear();
    _descriptionController.clear();
    _aliasesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã thêm lệnh tùy chỉnh thành công!')),
    );
  }

  void _showEditCommandDialog(Map<String, dynamic> command) {
    // TODO: Implement edit command dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa lệnh'),
        content: const Text('Tính năng sửa lệnh đang được phát triển'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(Map<String, dynamic> command) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa lệnh'),
        content: Text('Bạn có chắc muốn xóa lệnh "${command['command_text']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.model.deleteCustomCommand(command['id']);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa lệnh thành công!')),
              );
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
