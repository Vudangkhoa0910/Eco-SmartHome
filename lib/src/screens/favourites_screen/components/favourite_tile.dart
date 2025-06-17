import 'package:smart_home/config/size_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FavouriteTile extends StatelessWidget {
  final String iconAsset;
  final VoidCallback onTap;
  final String device;
  final String deviceCount;
  final bool itsOn;
  final VoidCallback switchButton;
  final bool isFav;
  final VoidCallback switchFav;
  const FavouriteTile({
    Key? key,
    required this.iconAsset,
    required this.onTap,
    required this.device,
    required this.deviceCount,
    required this.itsOn,
    required this.switchButton,
    required this.isFav,
    required this.switchFav,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 15,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: Container(
        padding: const EdgeInsets.only(top: 20),
        width: 200,
        height: MediaQuery.of(context).size.height / 5,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xffededed),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: getProportionateScreenWidth(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xffdadada),
                      borderRadius: BorderRadius.all(Radius.elliptical(45, 45)),
                    ),
                    child: SvgPicture.asset(
                      iconAsset,
                      color: const Color(0xFF808080),
                    ),
                  ),
                  SizedBox(
                    width: getProportionateScreenWidth(10),
                  ),
                  Expanded(
                    child: Text(
                      device,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: getProportionateScreenWidth(10),
                  ),
                  GestureDetector(
                    onTap: switchButton,
                    child: Container(
                      width: 48,
                      height: 25.6,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.grey,
                        border: Border.all(
                          color: Colors.grey,
                          width: itsOn ? 2 : 0,
                        ),
                      ),
                      child: Row(
                        children: [
                          itsOn ? const Spacer() : const SizedBox(),
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 15,)
                ],
              ),
              const SizedBox(height: 15),
              Text(
                deviceCount,
                textAlign: TextAlign.left,
                style: const TextStyle(
                    color: Color.fromRGBO(166, 166, 166, 1),
                    fontSize: 13,
                    letterSpacing: 0,
                    fontWeight: FontWeight.normal,
                    height: 1.6),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    itsOn ? 'On' : 'Off',
                    textAlign: TextAlign.left,
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(
                    width: getProportionateScreenWidth(160),
                  ),
                  Container(
                    padding: const EdgeInsets.all(2),
                    height: 25,
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Kitchen",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
