import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/rooms_view_model.dart';

class RoomDetailModal extends StatelessWidget {
  final dynamic room;
  final RoomsViewModel model;

  const RoomDetailModal({
    Key? key,
    required this.room,
    required this.model,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: getProportionateScreenHeight(10)),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(20)),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(getProportionateScreenWidth(12)),
                  decoration: BoxDecoration(
                    color: _getRoomColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    _getRoomIcon(),
                    color: _getRoomColor(),
                    size: 28,
                  ),
                ),
                SizedBox(width: getProportionateScreenWidth(15)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.name,
                        style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${room.devices.length} devices • ${room.temperature}°C',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Room Controls
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(context),
                  
                  SizedBox(height: getProportionateScreenHeight(25)),
                  
                  // Devices List
                  Text(
                    'Devices',
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  SizedBox(height: getProportionateScreenHeight(15)),
                  
                  ...room.devices.map<Widget>((device) => _buildDeviceCard(context, device)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(15)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(15)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                'All On',
                Icons.power_settings_new,
                () => model.turnOnAllDevices(room.id),
              ),
              _buildActionButton(
                context,
                'All Off',
                Icons.power_off,
                () => model.turnOffAllDevices(room.id),
              ),
              _buildActionButton(
                context,
                'Scene',
                Icons.wb_sunny,
                () => model.applyScene(room.id, 'evening'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenHeight(12),
          horizontal: getProportionateScreenWidth(20),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: _getRoomColor(), size: 24),
            SizedBox(height: getProportionateScreenHeight(5)),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, dynamic device) {
    return Container(
      margin: EdgeInsets.only(bottom: getProportionateScreenHeight(10)),
      padding: EdgeInsets.all(getProportionateScreenWidth(15)),
      decoration: BoxDecoration(
        color: device.isOn ? _getRoomColor().withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: device.isOn ? _getRoomColor().withOpacity(0.3) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(getProportionateScreenWidth(10)),
            decoration: BoxDecoration(
              color: device.isOn ? _getRoomColor() : Colors.grey[400],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDeviceIcon(device.type),
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: getProportionateScreenWidth(15)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  device.isOn ? 'On' : 'Off',
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: device.isOn ? _getRoomColor() : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: device.isOn,
            onChanged: (value) => model.toggleDevice(room.id, device.id),
            activeColor: Colors.white,
            activeTrackColor: _getRoomColor(),
          ),
        ],
      ),
    );
  }

  Color _getRoomColor() {
    switch (room.type.toLowerCase()) {
      case 'bedroom':
        return const Color(0xFF6B73FF);
      case 'living room':
        return const Color(0xFF9C88FF);
      case 'kitchen':
        return const Color(0xFFFF6B6B);
      case 'bathroom':
        return const Color(0xFF4ECDC4);
      case 'office':
        return const Color(0xFFFFD93D);
      default:
        return const Color(0xFF464646);
    }
  }

  IconData _getRoomIcon() {
    switch (room.type.toLowerCase()) {
      case 'bedroom':
        return Icons.bed;
      case 'living room':
        return Icons.weekend;
      case 'kitchen':
        return Icons.kitchen;
      case 'bathroom':
        return Icons.bathtub;
      case 'office':
        return Icons.work;
      default:
        return Icons.room;
    }
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'light':
        return Icons.lightbulb_outline;
      case 'ac':
        return Icons.ac_unit;
      case 'fan':
        return Icons.toys;
      case 'speaker':
        return Icons.speaker;
      case 'tv':
        return Icons.tv;
      default:
        return Icons.device_unknown;
    }
  }
}
