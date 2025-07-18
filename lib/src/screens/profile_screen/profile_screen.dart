import 'package:flutter/material.dart';
import 'package:smart_home/provider/base_view.dart';
import 'package:smart_home/view/profile_view_model.dart';
import 'components/body.dart';

class ProfileScreen extends StatelessWidget {
  static String routeName = '/profile-screen';
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BaseView<ProfileViewModel>(
      onModelReady: (model) => model.loadProfile(),
      builder: (context, model, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: Icon(Icons.edit,
                    color: Theme.of(context).iconTheme.color, size: 28),
                onPressed: () => model.editProfile(context),
              ),
            ],
          ),
          body: Body(model: model),
        );
      },
    );
  }
}
