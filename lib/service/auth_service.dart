import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle authentication state persistence
class AuthService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUserEmail = 'user_email';
  static const String _keyAutoLoginEnabled = 'auto_login_enabled';
  
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Check if user has enabled "Remember Me" feature
  Future<bool> isRememberMeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyRememberMe) ?? false;
    } catch (e) {
      print('❌ Error checking remember me status: $e');
      return false;
    }
  }

  /// Enable or disable "Remember Me" feature
  Future<void> setRememberMe(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, enabled);
      
      if (!enabled) {
        // If disabling remember me, also clear stored credentials
        await clearStoredCredentials();
      }
    } catch (e) {
      print('❌ Error setting remember me: $e');
    }
  }

  /// Save user credentials for auto-login
  Future<void> saveUserCredentials(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUserEmail, email);
      await prefs.setBool(_keyAutoLoginEnabled, true);
      print('✅ User credentials saved for auto-login');
    } catch (e) {
      print('❌ Error saving user credentials: $e');
    }
  }

  /// Get stored user email
  Future<String?> getStoredUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      print('❌ Error getting stored user email: $e');
      return null;
    }
  }

  /// Check if auto-login is enabled
  Future<bool> isAutoLoginEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_keyAutoLoginEnabled) ?? false;
      final rememberMe = await isRememberMeEnabled();
      return isEnabled && rememberMe;
    } catch (e) {
      print('❌ Error checking auto-login status: $e');
      return false;
    }
  }

  /// Clear stored credentials
  Future<void> clearStoredCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyUserEmail);
      await prefs.setBool(_keyAutoLoginEnabled, false);
      print('✅ Stored credentials cleared');
    } catch (e) {
      print('❌ Error clearing stored credentials: $e');
    }
  }

  /// Check if user should be auto-logged in
  Future<bool> shouldAutoLogin() async {
    try {
      // Check if user is already signed in with Firebase
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return false;
      }

      // Check if auto-login is enabled
      final autoLoginEnabled = await isAutoLoginEnabled();
      if (!autoLoginEnabled) {
        return false;
      }

      // Check if stored email matches current user
      final storedEmail = await getStoredUserEmail();
      if (storedEmail == null || storedEmail != currentUser.email) {
        return false;
      }

      return true;
    } catch (e) {
      print('❌ Error checking auto-login: $e');
      return false;
    }
  }

  /// Handle successful login
  Future<void> handleSuccessfulLogin(String email, bool rememberMe) async {
    try {
      await setRememberMe(rememberMe);
      
      if (rememberMe) {
        await saveUserCredentials(email);
      } else {
        await clearStoredCredentials();
      }
    } catch (e) {
      print('❌ Error handling successful login: $e');
    }
  }

  /// Handle logout
  Future<void> handleLogout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear stored credentials if remember me is disabled
      final rememberMe = await isRememberMeEnabled();
      if (!rememberMe) {
        await clearStoredCredentials();
      }
      
      print('✅ User logged out successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
      throw e;
    }
  }

  /// Get current user login status
  Future<Map<String, dynamic>> getLoginStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final rememberMe = await isRememberMeEnabled();
      final autoLogin = await isAutoLoginEnabled();
      final storedEmail = await getStoredUserEmail();

      return {
        'isLoggedIn': currentUser != null,
        'userEmail': currentUser?.email,
        'rememberMe': rememberMe,
        'autoLogin': autoLogin,
        'storedEmail': storedEmail,
        'shouldAutoLogin': await shouldAutoLogin(),
      };
    } catch (e) {
      print('❌ Error getting login status: $e');
      return {
        'isLoggedIn': false,
        'userEmail': null,
        'rememberMe': false,
        'autoLogin': false,
        'storedEmail': null,
        'shouldAutoLogin': false,
      };
    }
  }

  /// Reset all authentication data (for debugging or user preference reset)
  Future<void> resetAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRememberMe);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyAutoLoginEnabled);
      print('✅ All authentication data reset');
    } catch (e) {
      print('❌ Error resetting auth data: $e');
    }
  }
}
