import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/view/rooms_view_model.dart';
import 'package:smart_home/domain/entities/house_structure.dart';
import 'package:smart_home/src/screens/house_floor/house_floor_screen.dart';
import 'package:smart_home/service/theme_service.dart';
import 'package:smart_home/src/widgets/theme_color_picker.dart';
import 'room_card.dart';

class Body extends StatefulWidget {
  final RoomsViewModel model;
  const Body({Key? key, required this.model}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  @override
  void initState() {
    super.initState();
    // Initialize theme service
    ThemeService.instance.initialize();
    
    // Listen to theme changes
    ThemeService.instance.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {
        // Rebuild when theme changes
      });
    }
  }

  void _showThemePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                child: ThemeColorPicker(
                  onThemeChanged: (theme) {
                    setState(() {
                      // Rebuild with new theme
                    });
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(15),
        vertical: getProportionateScreenHeight(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats
          Container(
            height: getProportionateScreenHeight(100),
            padding: EdgeInsets.all(getProportionateScreenWidth(15)),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(context, 'Tổng số phòng',
                    '${widget.model.rooms.length}', Icons.home),
                _buildDivider(context),
                _buildStatItem(context, 'Thiết bị hoạt động',
                    '${widget.model.totalActiveDevices}', Icons.power),
                _buildDivider(context),
                _buildStatItem(context, 'Năng lượng',
                    '${widget.model.totalEnergyUsage}kW', Icons.bolt),
              ],
            ),
          ),

          SizedBox(height: getProportionateScreenHeight(20)),

          // House Area Management - Đây là tính năng từ nút xanh được đưa ra trực tiếp  
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý khu vực nhà',
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              GestureDetector(
                onTap: _showThemePicker,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ThemeService.instance.currentPalette.gradientColors.take(2).toList(),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: ThemeService.instance.currentPalette.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.palette,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Theme',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: getProportionateScreenHeight(15)),

          _buildHouseAreaManagement(context),

          SizedBox(height: getProportionateScreenHeight(20)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String title, String value, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: Theme.of(context).iconTheme.color),
        SizedBox(height: getProportionateScreenHeight(5)),
        Text(
          value,
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontSize: 12,
              ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildHouseAreaManagement(BuildContext context) {
    final floors = HouseData.getHouseStructure();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children:
            floors.map((floor) => _buildFloorCard(context, floor)).toList(),
      ),
    );
  }

  Widget _buildFloorCard(BuildContext context, HouseFloor floor) {
    return Container(
      margin: EdgeInsets.all(getProportionateScreenWidth(10)),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HouseFloorScreen(floor: floor),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.all(getProportionateScreenWidth(15)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: ThemeService.instance.getFloorGradient(floor.name),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  floor.name.contains('Sân') 
                      ? Icons.grass 
                      : floor.name.contains('Tầng 1')
                          ? Icons.home
                          : floor.name.contains('Tầng 2')
                              ? Icons.home_work
                              : Icons.roofing,
                  color: ThemeService.instance.getFloorIconColor(floor.name),
                  size: 24,
                ),
              ),
              SizedBox(width: getProportionateScreenWidth(15)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      floor.name,
                      style: TextStyle(
                        color: ThemeService.instance.getFloorTextColor(floor.name),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      floor.description,
                      style: TextStyle(
                        color: ThemeService.instance.getFloorTextColor(floor.name).withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: getProportionateScreenHeight(8)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(8),
                            vertical: getProportionateScreenHeight(4),
                          ),
                          decoration: BoxDecoration(
                            color: ThemeService.instance.getFloorBadgeColor(floor.name),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${floor.rooms.length} khu vực',
                            style: TextStyle(
                              color: ThemeService.instance.getFloorTextColor(floor.name),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: getProportionateScreenWidth(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: getProportionateScreenWidth(8),
                            vertical: getProportionateScreenHeight(4),
                          ),
                          decoration: BoxDecoration(
                            color: ThemeService.instance.getFloorBadgeColor(floor.name),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${floor.totalDevices} thiết bị',
                            style: TextStyle(
                              color: ThemeService.instance.getFloorTextColor(floor.name),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: ThemeService.instance.getFloorTextColor(floor.name).withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
