import 'package:flutter/material.dart';
import 'package:smart_home/config/size_config.dart';
import 'package:flutter_svg/svg.dart';

class MenuListItems extends StatelessWidget {
  final String iconPath;
  final String itemName;
  final VoidCallback function;
  const MenuListItems({
    Key? key,
    required this.iconPath,
    required this.itemName,
    required this.function,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: function,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1)
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              child: SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white70 
                      : Colors.black54, 
                  BlendMode.srcIn
                ),
              ),
            ),
            SizedBox(width: getProportionateScreenWidth(16)),
            Expanded(
              child: Text(
                itemName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
