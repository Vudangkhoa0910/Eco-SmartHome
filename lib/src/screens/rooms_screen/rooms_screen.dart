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
            body: Body(model: model),
          ),
        );
      },
    );
  }
}
