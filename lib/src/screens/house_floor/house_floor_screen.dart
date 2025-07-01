import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/src/screens/room_detail/room_detail_screen.dart';

class HouseFloorScreen extends StatelessWidget {
  final HouseFloor floor;
  
  const HouseFloorScreen({
    Key? key,
    required this.floor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(floor.name),
        backgroundColor: floor.color.withOpacity(0.1),
        foregroundColor: floor.color,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(getProportionateScreenWidth(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(getProportionateScreenWidth(20)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    floor.color.withOpacity(0.2),
                    floor.color.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(getProportionateScreenWidth(15)),
                    decoration: BoxDecoration(
                      color: floor.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      floor.icon,
                      color: floor.color,
                      size: 40,
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(15)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          floor.name,
                          style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: floor.color,
                          ),
                        ),
                        Text(
                          floor.description,
                          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${floor.rooms.length} khu vực • ${_getTotalDevices()} thiết bị',
                          style: Theme.of(context).textTheme.titleSmall!.copyWith(
                            color: floor.color.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(30)),
            
            Text(
              'Các khu vực',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(15)),
            
            // Rooms Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: getProportionateScreenWidth(15),
                  mainAxisSpacing: getProportionateScreenHeight(15),
                  childAspectRatio: 0.85,
                ),
                itemCount: floor.rooms.length,
                itemBuilder: (context, index) {
                  final room = floor.rooms[index];
                  return _buildRoomCard(context, room);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(BuildContext context, HouseRoom room) {
    final activeDevices = room.devices.where((device) => device.isOn).length;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomDetailScreen(room: room),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(15)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: room.color.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: room.color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Icon
            Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(12)),
              decoration: BoxDecoration(
                color: room.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                room.icon,
                color: room.color,
                size: 30,
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(15)),
            
            // Room Name
            Text(
              room.name,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: getProportionateScreenHeight(5)),
            
            // Room Description
            Text(
              room.description,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            const Spacer(),
            
            // Devices Status
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(8),
                    vertical: getProportionateScreenHeight(4),
                  ),
                  decoration: BoxDecoration(
                    color: activeDevices > 0 ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$activeDevices/${room.devices.length}',
                    style: TextStyle(
                      color: activeDevices > 0 ? Colors.green : Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: room.color,
                  size: 16,
                ),
              ],
            ),
            
            SizedBox(height: getProportionateScreenHeight(10)),
            
            // Quick Device Icons
            SizedBox(
              height: getProportionateScreenHeight(25),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: room.devices.take(4).length,
                itemBuilder: (context, deviceIndex) {
                  final device = room.devices[deviceIndex];
                  return Container(
                    margin: EdgeInsets.only(right: getProportionateScreenWidth(5)),
                    padding: EdgeInsets.all(getProportionateScreenWidth(4)),
                    decoration: BoxDecoration(
                      color: device.isOn 
                          ? device.color.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      device.icon,
                      size: 14,
                      color: device.isOn ? device.color : Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getTotalDevices() {
    return floor.rooms.fold(0, (total, room) => total + room.devices.length);
  }
}
