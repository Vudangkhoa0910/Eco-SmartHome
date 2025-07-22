import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/src/widgets/custom_notification.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String displayName = 'Đang tải...';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          usernameController.text = userDoc['email'] ?? user.email ?? '';
          displayName = userDoc['displayName'] ??
              user.displayName ??
              userDoc['name'] ??
              'Người dùng';
          displayNameController.text = displayName;
        });
      } else {
        setState(() {
          usernameController.text = user.email ?? '';
          displayName = user.displayName ?? 'Người dùng';
          displayNameController.text = displayName;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor,
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
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
                  Text(
                    'Chỉnh sửa hồ sơ',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              SizedBox(height: getProportionateScreenHeight(30)),

              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Avatar
                        Container(
                          width: 100,
                          height: 100,
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
                            size: 50,
                          ),
                        ),
                        SizedBox(height: getProportionateScreenHeight(10)),
                        Text(
                          displayName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),

                        SizedBox(height: getProportionateScreenHeight(30)),

                        // Account Section
                        _buildSectionTitle('Thông tin tài khoản'),
                        SizedBox(height: getProportionateScreenHeight(15)),
                        _buildTextField(
                          controller: displayNameController,
                          label: 'Tên người dùng',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Tên người dùng không được để trống';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: getProportionateScreenHeight(15)),

                        _buildTextField(
                          controller: usernameController,
                          label: 'Tên đăng nhập / Email',
                          icon: Icons.account_circle_outlined,
                          enabled: false,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Tên đăng nhập không được để trống';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: getProportionateScreenHeight(25)),

                        // Password Section
                        _buildSectionTitle('Đổi mật khẩu'),
                        SizedBox(height: getProportionateScreenHeight(15)),

                        _buildPasswordField(
                          controller: oldPasswordController,
                          label: 'Mật khẩu hiện tại',
                          icon: Icons.lock_outline,
                          isVisible: _isOldPasswordVisible,
                          onVisibilityToggle: () {
                            setState(() {
                              _isOldPasswordVisible = !_isOldPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value!.isEmpty &&
                                (newPasswordController.text.isNotEmpty ||
                                    confirmPasswordController
                                        .text.isNotEmpty)) {
                              return 'Vui lòng nhập mật khẩu hiện tại';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: getProportionateScreenHeight(15)),

                        _buildPasswordField(
                          controller: newPasswordController,
                          label: 'Mật khẩu mới',
                          icon: Icons.lock_outline,
                          isVisible: _isNewPasswordVisible,
                          onVisibilityToggle: () {
                            setState(() {
                              _isNewPasswordVisible = !_isNewPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value!.isEmpty &&
                                confirmPasswordController.text.isNotEmpty) {
                              return 'Vui lòng nhập mật khẩu mới';
                            }
                            if (value.isNotEmpty && value.length < 6) {
                              return 'Mật khẩu phải có ít nhất 6 ký tự';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: getProportionateScreenHeight(15)),

                        _buildPasswordField(
                          controller: confirmPasswordController,
                          label: 'Xác nhận mật khẩu mới',
                          icon: Icons.lock_outline,
                          isVisible: _isConfirmPasswordVisible,
                          onVisibilityToggle: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                          validator: (value) {
                            if (value!.isEmpty &&
                                newPasswordController.text.isNotEmpty) {
                              return 'Vui lòng xác nhận mật khẩu mới';
                            }
                            if (value.isNotEmpty &&
                                value != newPasswordController.text) {
                              return 'Mật khẩu xác nhận không khớp';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: getProportionateScreenHeight(40)),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: getProportionateScreenHeight(50),
                          child: ElevatedButton(
                            onPressed: _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Lưu thay đổi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: getProportionateScreenHeight(20)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        validator: validator,
        style: TextStyle(
          color: Theme.of(context).primaryColor, // ✅ Màu chữ ở đây
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? Theme.of(context).primaryColor : Colors.grey,
            size: 20,
          ),
          filled: true,
          fillColor: enabled
              ? Theme.of(context).cardColor
              : Colors.grey.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isVisible,
    required VoidCallback onVisibilityToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            onPressed: onVisibilityToggle,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        bool hasChanges = false;
        String? errorMessage;

        // Check for display name update
        if (displayNameController.text != displayName) {
          try {
            await user.updateDisplayName(displayNameController.text);
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .set({
              'displayName': displayNameController.text,
              'email': user.email,
            }, SetOptions(merge: true));
            hasChanges = true;
          } catch (e) {
            errorMessage = 'Lỗi khi cập nhật tên người dùng: ${e.toString()}';
          }
        }

        // Check for password update
        if (oldPasswordController.text.isNotEmpty &&
            newPasswordController.text.isNotEmpty &&
            confirmPasswordController.text.isNotEmpty) {
          try {
            // Re-authenticate user before updating password
            AuthCredential credential = EmailAuthProvider.credential(
              email: user.email!,
              password: oldPasswordController.text,
            );
            await user.reauthenticateWithCredential(credential);
            await user.updatePassword(newPasswordController.text);
            hasChanges = true;
          } catch (e) {
            errorMessage = 'Lỗi khi cập nhật mật khẩu: ${e.toString()}';
          }
        }

        if (hasChanges) {
          _showSuccessDialog();
        } else if (errorMessage != null) {
          context.showErrorNotification(errorMessage);
        } else {
          context.showWarningNotification(
              'Vui lòng nhập thông tin để thay đổi tên người dùng hoặc mật khẩu');
        }
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành công'),
        content: const Text('Thông tin đã được cập nhật thành công!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
