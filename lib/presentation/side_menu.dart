import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFFFDFBE8),
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: UserAccountsDrawerHeader (
              decoration: BoxDecoration(color: Color(0xFF438589)),
              accountName: const Text('Вася',
                  style: TextStyle(color: Color(0xFFFDFBE8), fontSize: 16)),
              accountEmail: const Text("home@dartflutter.ru",
                  style: TextStyle(color: Color(0xFFFDFBE8))),
              currentAccountPicture: Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      image : DecorationImage(
                        image: AssetImage('assets/images/avataaar.jpg'),
                        fit: BoxFit.fill,
                      )
                  )
              ),
            ),
          ),
          ListTile(
              title: const Text("О себе"),
              leading: const Icon(Icons.account_box),
              onTap: (){}
          ),
          ListTile(
              title: const Text("Настройки"),
              leading: const Icon(Icons.settings),
              onTap: (){}
          )
        ],
      ),
    );
  }
}