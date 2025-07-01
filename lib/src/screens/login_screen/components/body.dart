import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:flutter/material.dart';
import 'package:smart_home/src/screens/home_screen/home_screen.dart';

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> signIn() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập thất bại';
      if (e.code == 'user-not-found') {
        message = 'Tài khoản không tồn tại.';
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu không đúng.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng nhập thất bại: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> signUp() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.of(context).pushReplacementNamed(HomeScreen.routeName);
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại';
      if (e.code == 'email-already-in-use') {
        message = 'Email đã được sử dụng.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu (ít nhất 6 ký tự).';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đăng ký thất bại: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Image.asset(
              'assets/images/login.png',
              height: getProportionateScreenHeight(300),
              width: double.infinity,
              fit: BoxFit.fill,
            ),
            Positioned(
              bottom: getProportionateScreenHeight(20),
              left: getProportionateScreenWidth(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SMART',
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                          color: Colors.black,
                          fontSize: 33,
                        ),
                  ),
                  Text(
                    'HOME',
                    style: Theme.of(context).textTheme.displayLarge!.copyWith(
                          color: Colors.black,
                          fontSize: 64,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'sign into \nmange your device & accessory',
            style: TextStyle(fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: TextField(
            controller: emailController,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(left: 40.0, right: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(70.0),
              ),
              hintText: 'Email',
              suffixIcon: const Icon(Icons.email, color: Colors.black),
            ),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(20)),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0),
          child: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(left: 40.0, right: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(70.0),
              ),
              hintText: 'Password',
              suffixIcon: const Icon(Icons.lock, color: Colors.black),
            ),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(20)),
        Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 20),
          child: GestureDetector(
            onTap: isLoading ? null : signIn,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey : const Color(0xFF464646),
                borderRadius: BorderRadius.circular(70.0),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : const Text(
                      'Đăng nhập',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ),
        SizedBox(height: getProportionateScreenHeight(10)),
        Center(
          child: TextButton(
            onPressed: isLoading ? null : signUp,
            child: const Text('Chưa có tài khoản? Đăng ký'),
          ),
        ),
      ],
    );
  }
}