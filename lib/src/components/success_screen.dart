import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onContinue;
  
  const SuccessScreen({
    Key? key,
    required this.title,
    required this.message,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(getProportionateScreenWidth(20)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success animation
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 80,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(40)),
                
                // Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: getProportionateScreenHeight(16)),
                
                // Message
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: getProportionateScreenHeight(60)),
                
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF464646),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Tiếp tục',
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
        ),
      ),
    );
  }
}
