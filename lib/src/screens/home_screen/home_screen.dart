import 'package:smart_home/config/size_config.dart';
import 'package:smart_home/provider/base_view.dart';
import 'package:smart_home/src/screens/edit_profile/edit_profile.dart';
import 'package:smart_home/src/screens/favourites_screen/favourites_screen.dart';
import 'package:smart_home/src/widgets/custom_bottom_nav_bar.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'components/body.dart';
import 'package:smart_home/src/screens/menu_page/menu_screen.dart';

class HomeScreen extends StatelessWidget {
  static String routeName = '/home-screen';
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);

    return BaseView<HomeScreenViewModel>(
      onModelReady: (model) {
        model.generateRandomNumber();
      },
      builder: (context, model, child) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: getProportionateScreenHeight(60),
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: getProportionateScreenWidth(4)),
              child: Row(
                children: [
                  Text(
                    'Hi, Khoa',
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                  const Spacer(),
                  // Profile button
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xffdadada),
                      borderRadius: BorderRadius.all(Radius.elliptical(45, 45)),
                    ),
                    child: IconButton(
                      splashRadius: 25,
                      icon: const Icon(FontAwesomeIcons.solidUser, color: Colors.amber),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const EditProfile()),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(5)),
                  // Favourites button
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xffdadada),
                      borderRadius: BorderRadius.all(Radius.elliptical(45, 45)),
                    ),
                    child: IconButton(
                      splashRadius: 25,
                      icon: const Icon(CupertinoIcons.heart_fill, color: Colors.grey, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Favourites(model: model)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          drawer: SizedBox(
            width: getProportionateScreenWidth(270),
            child: const Menu(),
          ),

          // BODY sử dụng PageView để đồng bộ với BottomNavigationBar
          body: PageView(
            controller: model.pageController,
            onPageChanged: (index) {
              model.selectedIndex = index;
              model.notifyListeners();
            },
            children: <Widget>[
              Body(model: model),
              Center(
                child: Text(
                  'To be Built Soon',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              const Center(child: Text('under construction')),
            ],
          ),

          bottomNavigationBar: CustomBottomNavBar(model: model),
        );
      },
    );
  }
}
