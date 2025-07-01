import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_model.dart';

class RoomsViewModel extends BaseModel {
  List<dynamic> _rooms = [];
  
  List<dynamic> get rooms => _rooms;
  
  int get totalActiveDevices {
    int count = 0;
    for (var room in _rooms) {
      for (var device in room.devices) {
        if (device.isOn) count++;
      }
    }
    return count;
  }
  
  double get totalEnergyUsage {
    double usage = 0;
    for (var room in _rooms) {
      for (var device in room.devices) {
        if (device.isOn) {
          usage += device.energyUsage ?? 0;
        }
      }
    }
    return double.parse(usage.toStringAsFixed(1));
  }

  void loadRooms() {
    // Simulate loading rooms data
    _rooms = [
      Room(
        id: '1',
        name: 'Living Room',
        type: 'Living Room',
        temperature: 22,
        devices: [
          Device(id: '1', name: 'Main Light', type: 'light', isOn: true, energyUsage: 0.8),
          Device(id: '2', name: 'TV', type: 'tv', isOn: false, energyUsage: 1.2),
          Device(id: '3', name: 'AC', type: 'ac', isOn: true, energyUsage: 2.5),
        ],
      ),
      Room(
        id: '2',
        name: 'Bedroom',
        type: 'Bedroom',
        temperature: 20,
        devices: [
          Device(id: '4', name: 'Ceiling Light', type: 'light', isOn: false, energyUsage: 0.6),
          Device(id: '5', name: 'Fan', type: 'fan', isOn: true, energyUsage: 0.9),
        ],
      ),
      Room(
        id: '3',
        name: 'Kitchen',
        type: 'Kitchen',
        temperature: 24,
        devices: [
          Device(id: '6', name: 'Under Cabinet Lights', type: 'light', isOn: true, energyUsage: 0.4),
          Device(id: '7', name: 'Exhaust Fan', type: 'fan', isOn: false, energyUsage: 0.7),
        ],
      ),
    ];
    notifyListeners();
  }

  void showAddRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Room Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Room Type',
                border: OutlineInputBorder(),
              ),
              items: ['Living Room', 'Bedroom', 'Kitchen', 'Bathroom', 'Office']
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Add room logic here
            },
            child: const Text('Add Room'),
          ),
        ],
      ),
    );
  }

  void toggleDevice(String roomId, String deviceId) {
    for (var room in _rooms) {
      if (room.id == roomId) {
        for (var device in room.devices) {
          if (device.id == deviceId) {
            device.isOn = !device.isOn;
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  void turnOnAllDevices(String roomId) {
    for (var room in _rooms) {
      if (room.id == roomId) {
        for (var device in room.devices) {
          device.isOn = true;
        }
        notifyListeners();
        return;
      }
    }
  }

  void turnOffAllDevices(String roomId) {
    for (var room in _rooms) {
      if (room.id == roomId) {
        for (var device in room.devices) {
          device.isOn = false;
        }
        notifyListeners();
        return;
      }
    }
  }

  void applyScene(String roomId, String sceneName) {
    // Apply scene logic here
    print('Applying $sceneName scene to room $roomId');
  }
}

class Room {
  final String id;
  final String name;
  final String type;
  final int temperature;
  final List<Device> devices;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.temperature,
    required this.devices,
  });
}

class Device {
  final String id;
  final String name;
  final String type;
  bool isOn;
  final double? energyUsage;

  Device({
    required this.id,
    required this.name,
    required this.type,
    required this.isOn,
    this.energyUsage,
  });
}
