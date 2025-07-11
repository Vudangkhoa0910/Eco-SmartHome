import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/provider/theme_provider.dart';
import 'package:smart_home/view/profile_view_model.dart';

class Body extends StatelessWidget {
  final ProfileViewModel model;
  const Body({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(15),
        vertical: getProportionateScreenHeight(10),
      ),
      child: Column(
        children: [
          // Profile Header
          _buildProfileHeader(context),

          SizedBox(height: getProportionateScreenHeight(30)),

          // Quick Stats
          _buildQuickStats(context),

          SizedBox(height: getProportionateScreenHeight(25)),

          // Account Settings
          _buildSection(context, 'Tài khoản', [
            _buildSettingItem(
              context,
              'Thông tin cá nhân',
              'Cập nhật chi tiết hồ sơ của bạn',
              Icons.person_outline,
              () => model.editProfile(context),
            ),
          ]),

          SizedBox(height: getProportionateScreenHeight(20)),

          // Smart Home Settings
          _buildSection(context, 'Nhà thông minh', [
            _buildSettingItem(
              context,
              'Quản lý thiết bị',
              'Thêm hoặc xóa thiết bị',
              Icons.devices,
              () => model.openDeviceManagement(context),
            ),
            _buildSettingItem(
              context,
              'Quy tắc tự động',
              'Thiết lập tự động hóa thông minh',
              Icons.auto_awesome,
              () => model.openAutomation(context),
            ),
            _buildSettingItem(
              context,
              'Cài đặt năng lượng',
              'Cấu hình giám sát năng lượng',
              Icons.bolt,
              () => model.openEnergySettings(context),
            ),
          ]),

          SizedBox(height: getProportionateScreenHeight(20)),

          // App Settings
          _buildSection(context, 'Cài đặt ứng dụng', [
            _buildSettingToggle(
              context,
              'Chế độ tối',
              'Chuyển sang giao diện tối',
              Icons.dark_mode,
              Provider.of<ThemeProvider>(context).isDarkMode,
              (value) => model.toggleDarkMode(value, context),
            ),
            _buildSettingItem(
              context,
              'Ngôn ngữ',
              'Tiếng Việt',
              Icons.language,
              () => model.changeLanguage(context),
            ),
          ]),

          SizedBox(height: getProportionateScreenHeight(20)),

          // Support & About
          _buildSection(context, 'Hỗ trợ & Thông tin', [
            _buildSettingItem(
              context,
              'Trợ giúp & Hỗ trợ',
              'Nhận trợ giúp và liên hệ hỗ trợ',
              Icons.help_outline,
              () => model.openSupport(context),
            ),
            _buildSettingItem(
              context,
              'Về Smart Home',
              'Phiên bản 1.0.1 (beta)',
              Icons.info_outline,
              () => model.openAbout(context),
            ),
          ]),

          SizedBox(height: getProportionateScreenHeight(30)),

          // Logout Button
          _buildLogoutButton(context),

          SizedBox(height: getProportionateScreenHeight(30)),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6B73FF),
                  const Color(0xFF9C88FF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(15)),
          Text(
            model.userName,
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(5)),
          Text(
            model.userEmail,
            style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                  fontSize: 14,
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(15)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: getProportionateScreenWidth(15),
              vertical: getProportionateScreenHeight(8),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF6B73FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Thành viên VIP',
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: const Color(0xFF6B73FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
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
          _buildStatItem(
              context, 'Thiết bị', '${model.totalDevices}', Icons.devices),
          _buildDivider(context),
          _buildStatItem(context, 'Phòng', '${model.totalRooms}', Icons.home),
          _buildDivider(context),
          _buildStatItem(
              context, 'Tiết kiệm', '${model.totalSavings}k VNĐ', Icons.eco),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).iconTheme.color),
        SizedBox(height: getProportionateScreenHeight(8)),
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

  Widget _buildSection(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(5)),
          child: Text(
            title,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(10)),
        Container(
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
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(8)),
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontSize: 12,
            ),
      ),
      trailing: Icon(Icons.arrow_forward_ios,
          size: 16, color: Theme.of(context).iconTheme.color),
      onTap: onTap,
    );
  }

  Widget _buildSettingToggle(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(getProportionateScreenWidth(8)),
        decoration: BoxDecoration(
          color: Theme.of(context).iconTheme.color!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.displayMedium!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              fontSize: 12,
            ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF6B73FF),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: getProportionateScreenWidth(20),
      ),
      child: ElevatedButton(
        onPressed: () {
          model.logout(context);
          Navigator.of(context).pushReplacementNamed(
              '/auth-screen'); // Chuyển về màn hình auth mới
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red,
          padding: EdgeInsets.symmetric(
            vertical: getProportionateScreenHeight(15),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, size: 20),
            SizedBox(width: getProportionateScreenWidth(10)),
            Text(
              'Đăng xuất',
              style: Theme.of(context).textTheme.displayMedium!.copyWith(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
