import 'package:smart_home/config/size_config.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class AddNewDevice extends StatelessWidget {
  const AddNewDevice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        print('Add device widget constraints: ${constraints.maxWidth}');
        
        return GestureDetector(
          onTap: () {
            print('Add device widget tapped');
            // Add functionality to add new device
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add new device functionality'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: getProportionateScreenHeight(70),
              maxHeight: getProportionateScreenHeight(90),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6B73FF).withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B73FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF6B73FF),
                    size: 24,
                  ),
                ),
                SizedBox(height: getProportionateScreenHeight(6)),
                Text(
                  'Add New Device',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B73FF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Tap to connect smart devices',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF9E9E9E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
