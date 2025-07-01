import 'package:flutter/material.dart';
import 'package:smart_home/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class SwitchTiles extends StatefulWidget {
  const SwitchTiles({Key? key}) : super(key: key);

  @override
  State<SwitchTiles> createState() => _SwitchTilesState();
}

class _SwitchTilesState extends State<SwitchTiles> {
  @override
  Widget build(BuildContext context) {
    
    const bool givenValue = false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 24.44, 19, 0),
      child: Container(
        height: 250, // Tăng height để chứa dark mode toggle
        width: 326,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Theme.of(context).cardColor,
        ),
        child: ListView(
          children: [
            // Dark Mode Toggle
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return SwitchListTile(
                  activeTrackColor: const Color.fromRGBO(61, 213, 152, 1),
                  inactiveTrackColor: Theme.of(context).brightness == Brightness.dark 
                      ? const Color.fromRGBO(120, 120, 120, 1)
                      : const Color.fromRGBO(210, 210, 210, 1),
                  activeColor: Theme.of(context).brightness == Brightness.dark 
                      ? const Color.fromRGBO(200, 200, 200, 1)
                      : const Color.fromRGBO(70, 70, 70, 1),
                  inactiveThumbColor: Theme.of(context).brightness == Brightness.dark 
                      ? const Color.fromRGBO(200, 200, 200, 1)
                      : const Color.fromRGBO(70, 70, 70, 1),
                  value: themeProvider.isDarkMode,
                  secondary: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  title: Text("Chế độ tối", style: TextStyle(
                    fontFamily: 'Abeezee',
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  )),
                  subtitle: Text(
                    themeProvider.isDarkMode ? "Đang bật" : "Đang tắt",
                    style: TextStyle(
                      fontFamily: 'Abeezee',
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                      fontSize: 12,
                    ),
                  ),
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                );
              },
            ),
            SwitchListTile(
              activeTrackColor: const Color.fromRGBO(61, 213, 152, 1),
              inactiveTrackColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(120, 120, 120, 1)
                  : const Color.fromRGBO(210, 210, 210, 1),
              activeColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(200, 200, 200, 1)
                  : const Color.fromRGBO(70, 70, 70, 1),
              inactiveThumbColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(200, 200, 200, 1)
                  : const Color.fromRGBO(70, 70, 70, 1),
              value: givenValue,
              secondary: Image.asset('assets/images/settings/star.png'),
              title: Text("Option 1", style: TextStyle(
                fontFamily: 'Abeezee',
                color: Theme.of(context).textTheme.bodyLarge!.color,
              )),
              onChanged: (givenValue) {
                setState(() {
                  givenValue = true;
                });
              },
            ),
            SwitchListTile(
              selected: true,
              activeTrackColor: const Color.fromRGBO(61, 213, 152, 1),
              inactiveTrackColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(120, 120, 120, 1)
                  : const Color.fromRGBO(210, 210, 210, 1),
              activeColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(200, 200, 200, 1)
                  : const Color.fromRGBO(70, 70, 70, 1),
              inactiveThumbColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(200, 200, 200, 1)
                  : const Color.fromRGBO(70, 70, 70, 1),
              value: givenValue,
              secondary: Image.asset('assets/images/settings/chat.png'),
              title: Text("Option 2", style: TextStyle(
                fontFamily: 'Abeezee',
                color: Theme.of(context).textTheme.bodyLarge!.color,
              )),
              onChanged: (givenValue) {
                setState(() {
                  givenValue = true;
                });
              },
            ),
            SwitchListTile(
              activeTrackColor: const Color.fromRGBO(61, 213, 152, 1),
              inactiveTrackColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(120, 120, 120, 1)
                  : const Color.fromRGBO(210, 210, 210, 1),
              activeColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(200, 200, 200, 1)
                  : const Color.fromRGBO(70, 70, 70, 1),
              inactiveThumbColor: Theme.of(context).brightness == Brightness.dark 
                  ? const Color.fromRGBO(200, 200, 200, 1)
                  : const Color.fromRGBO(70, 70, 70, 1),
              value: givenValue,
              secondary: Image.asset('assets/images/settings/bell.png'),
              title: Text("Option 3", style: TextStyle(
                fontFamily: 'Abeezee',
                color: Theme.of(context).textTheme.bodyLarge!.color,
              )),
              onChanged: (givenValue) {
                setState(() {
                  givenValue = true;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  const SettingTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 19, 0),
      child: Container(
        height: 182.56,
        width: 326,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Theme.of(context).cardColor,
        ),
        child: ListView(
          children: [
            InkWell(
              onTap: () {},
              child: ListTile(
                  leading: Image.asset('assets/images/settings/heart.png'),
                  title: Text(
                    "Option 1",
                    style: TextStyle(
                      fontFamily: 'Abeezee',
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  trailing: Icon(
                    Icons.navigate_next,
                    color: Theme.of(context).iconTheme.color,
                  )),
            ),
            InkWell(
              onTap: () {},
              child: ListTile(
                  leading: Image.asset('assets/images/settings/bookmark.png'),
                  title: Text(
                    "Option 2", 
                    style: TextStyle(
                      fontFamily: 'Abeezee',
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    )
                  ),
                  trailing: Icon(
                    Icons.navigate_next,
                    color: Theme.of(context).iconTheme.color,
                  )),
            ),
            InkWell(
              onTap: () {},
              child: ListTile(
                  leading: Image.asset('assets/images/settings/home.png'),
                  title: Text(
                    "Option 3", 
                    style: TextStyle(
                      fontFamily: 'Abeezee',
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    )
                  ),
                  trailing: Icon(
                    Icons.navigate_next,
                    color: Theme.of(context).iconTheme.color,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
