import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_view.dart';
import 'package:smart_home/view/rooms_view_model.dart';
import 'package:smart_home/view/home_screen_view_model.dart';
import 'package:smart_home/provider/getit.dart';
import 'package:provider/provider.dart';
import 'components/body.dart';

class RoomsScreen extends StatelessWidget {
  static String routeName = '/rooms-screen';
  const RoomsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseView<RoomsViewModel>(
      onModelReady: (model) => model.loadRooms(),
      builder: (context, model, child) {
        return ChangeNotifierProvider.value(
          value: getIt<HomeScreenViewModel>(),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Rooms',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.displayLarge!.color,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.add_home, 
                  color: Theme.of(context).iconTheme.color, 
                  size: 28),
                onPressed: () => model.showAddRoomDialog(context),
              ),
            ],
          ),
          body: Body(model: model),
        ),
      );
        },
    );
  }
}
