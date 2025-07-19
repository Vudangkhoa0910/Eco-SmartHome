import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/src/screens/auth_screen/auth_screen.dart';
import 'package:smart_home/service/auth_service.dart';
import 'package:flutter/material.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final AuthService _authService = AuthService();
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Wait a bit for splash screen effect
      await Future.delayed(const Duration(seconds: 2));

      // Check if user should be auto-logged in
      final shouldAutoLogin = await _authService.shouldAutoLogin();
      
      if (shouldAutoLogin) {
        // Auto-login successful, navigate to device connection screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/device-connection-screen');
        }
      } else {
        // No auto-login, navigate to auth screen
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
        }
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      // On error, navigate to auth screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  void _navigateToAuth() {
    Navigator.of(context).pushReplacementNamed(AuthScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF464646),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            height: getProportionateScreenHeight(20),
          ),
          Material(
            child: Image.asset('assets/images/splash_img.png'),
            color: Colors.transparent,
          ),
          Text(
            'Sweet & Smart Home',
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  color: Colors.white,
                ),
          ),
          Text(
            'Smart Home can change\nway you live in the future',
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: const Color(0xFFBDBDBD),
                ),
          ),
          
          // Show loading or button based on auth checking status
          _isCheckingAuth 
            ? Column(
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: getProportionateScreenHeight(16)),
                  Text(
                    'Checking login status...',
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: const Color(0xFFBDBDBD),
                        ),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _navigateToAuth,
                child: Text(
                  'Get Started',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: getProportionateScreenWidth(70),
                    vertical: getProportionateScreenHeight(15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
