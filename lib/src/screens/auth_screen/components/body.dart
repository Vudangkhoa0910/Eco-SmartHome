import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/service/auth_service.dart';
import 'package:smart_home/src/widgets/custom_notification.dart';
import 'package:flutter/material.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = false; // Add remember me state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRememberMeState();
  }

  /// Load remember me state and stored email
  Future<void> _loadRememberMeState() async {
    try {
      final rememberMe = await _authService.isRememberMeEnabled();
      final storedEmail = await _authService.getStoredUserEmail();
      
      setState(() {
        _rememberMe = rememberMe;
        if (storedEmail != null && rememberMe) {
          emailController.text = storedEmail;
        }
      });
    } catch (e) {
      print('❌ Error loading remember me state: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    setState(() => isLoading = true);
    try {
      // Sign in with Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      // Handle successful login with remember me
      await _authService.handleSuccessfulLogin(
        emailController.text.trim(), 
        _rememberMe
      );
      
      Navigator.of(context).pushReplacementNamed('/device-connection-screen');
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập thất bại';
      if (e.code == 'user-not-found') {
        message = 'Tài khoản không tồn tại.';
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu không đúng.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      } else if (e.code == 'too-many-requests') {
        message = 'Quá nhiều lần thử. Vui lòng thử lại sau.';
      } else if (e.code == 'invalid-credential') {
        message = 'Thông tin đăng nhập không chính xác.';
      }
      _showMessage(message);
    } catch (e) {
      _showMessage('Đăng nhập thất bại: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> signUp() async {
    if (emailController.text.trim().isEmpty || 
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty ||
        nameController.text.trim().isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      _showMessage('Mật khẩu xác nhận không khớp');
      return;
    }

    if (passwordController.text.trim().length < 6) {
      _showMessage('Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }

    setState(() => isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(nameController.text.trim());
      
      // Handle successful registration with remember me (default to false for registration)
      await _authService.handleSuccessfulLogin(
        emailController.text.trim(), 
        false // Don't auto-enable remember me for new registrations
      );
      
      Navigator.of(context).pushReplacementNamed('/device-connection-screen');
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại';
      if (e.code == 'email-already-in-use') {
        message = 'Email đã được sử dụng.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu (ít nhất 6 ký tự).';
      }
      _showMessage(message);
    } catch (e) {
      _showMessage('Đăng ký thất bại: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showMessage(String message) {
    context.showInfoNotification(message);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E3440),
              Color(0xFF3B4252),
              Color(0xFF434C5E),
            ],
          ),
        ),      child: SafeArea(
        child: Column(
          children: [
            // Header with Smart Home branding - flexible height
            Container(
              height: MediaQuery.of(context).size.height * 0.25, // Fixed height for header
              padding: EdgeInsets.symmetric(
                horizontal: getProportionateScreenWidth(20),
                vertical: getProportionateScreenHeight(20),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(20)),
                  Text(
                    'SMART HOME',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                  ),
                  SizedBox(height: getProportionateScreenHeight(8)),
                  Text(
                    'Quản lý ngôi nhà thông minh của bạn',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),            // Tab container - flexible height
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    // Tab bar
                    Container(
                      margin: EdgeInsets.all(getProportionateScreenWidth(20)),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: const Color(0xFF464646),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.grey[600],
                        dividerColor: Colors.transparent,
                        labelPadding: EdgeInsets.symmetric(horizontal: 20),
                        tabs: const [
                          Tab(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text('Đăng nhập'),
                            ),
                          ),
                          Tab(
                            child: Align(
                              alignment: Alignment.center,
                              child: Text('Đăng ký'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLoginTab(),
                          _buildRegisterTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chào mừng trở lại!',
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E3440),
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(8)),
          Text(
            'Đăng nhập để tiếp tục quản lý ngôi nhà của bạn',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          SizedBox(height: getProportionateScreenHeight(30)),

          // Email field
          _buildTextField(
            controller: emailController,
            hintText: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: getProportionateScreenHeight(16)),

          // Password field
          _buildTextField(
            controller: passwordController,
            hintText: 'Mật khẩu',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),

          // Remember Me checkbox
          Row(
            children: [
              Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: const Color(0xFF464646),
                checkColor: Colors.white,
              ),
              Text(
                'Ghi nhớ đăng nhập',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Future: Add "Forgot Password?" here if needed
              GestureDetector(
                onTap: () {
                  // TODO: Implement forgot password
                  _showMessage('Tính năng quên mật khẩu sẽ sớm có');
                },
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    color: const Color(0xFF464646),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(20)),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF464646),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          // Add some bottom padding for keyboard
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(getProportionateScreenWidth(20)),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - getProportionateScreenHeight(40),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tạo tài khoản mới',
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E3440),
                      ),
                ),
                SizedBox(height: getProportionateScreenHeight(8)),
                Text(
                  'Đăng ký để bắt đầu trải nghiệm Smart Home',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                SizedBox(height: getProportionateScreenHeight(30)),

                // Name field
                _buildTextField(
                  controller: nameController,
                  hintText: 'Họ và tên',
                  icon: Icons.person_outline,
                ),
                SizedBox(height: getProportionateScreenHeight(16)),

                // Email field
                _buildTextField(
                  controller: emailController,
                  hintText: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: getProportionateScreenHeight(16)),

                // Password field
                _buildTextField(
                  controller: passwordController,
                  hintText: 'Mật khẩu',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),

          // Confirm password field
          _buildTextField(
            controller: confirmPasswordController,
            hintText: 'Xác nhận mật khẩu',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[600],
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(30)),

          // Register button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF464646),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Đăng ký',
                      style: TextStyle(
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
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        scrollPadding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
