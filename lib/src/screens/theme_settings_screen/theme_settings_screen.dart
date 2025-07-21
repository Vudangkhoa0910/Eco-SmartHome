import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/theme_service.dart';
import 'package:smart_home/src/widgets/theme_color_picker.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
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
                    setState(() {});
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
    final currentPalette = ThemeService.instance.currentPalette;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài Đặt Theme'),
        backgroundColor: currentPalette.primaryColor.withOpacity(0.1),
        foregroundColor: currentPalette.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(getProportionateScreenWidth(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Theme Preview
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(getProportionateScreenWidth(20)),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: currentPalette.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          currentPalette.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme Hiện Tại',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              currentPalette.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    currentPalette.description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Color preview row
                  Row(
                    children: [
                      Text(
                        'Bảng màu: ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      ...currentPalette.gradientColors.map((color) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(30)),
            
            // Change Theme Button
            Container(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showThemePicker,
                icon: Icon(Icons.palette),
                label: Text('Thay Đổi Theme Màu Sắc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: currentPalette.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ),
            
            SizedBox(height: getProportionateScreenHeight(20)),
            
            // Theme info cards
            Text(
              'Tính Năng Theme',
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            
            SizedBox(height: 12),
            
            _buildInfoCard(
              icon: Icons.save,
              title: 'Lưu Tự Động',
              description: 'Theme được lưu và khôi phục khi mở app',
              color: currentPalette.primaryColor,
            ),
            
            SizedBox(height: 12),
            
            _buildInfoCard(
              icon: Icons.refresh,
              title: 'Thay Đổi Tức Thì',
              description: 'Giao diện cập nhật ngay lập tức khi thay theme',
              color: currentPalette.secondaryColor,
            ),
            
            SizedBox(height: 12),
            
            _buildInfoCard(
              icon: Icons.color_lens,
              title: 'Nhiều Lựa Chọn',
              description: '6 theme màu sắc đẹp và hiện đại',
              color: currentPalette.primaryColor.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
