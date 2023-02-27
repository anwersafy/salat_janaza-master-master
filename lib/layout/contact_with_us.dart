import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../colors/colors.dart';

class ContactWithUs extends StatelessWidget {
  const ContactWithUs({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Uri facebook =Uri.parse('https://www.facebook.com/profile.php?id=100090376186396&mibextid=ZbWKwL');
    final Uri gmail = Uri.parse('https://salat.aljanazaa@gmail.com');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: canvasColor,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(
              flex: 1,
            ),
            GestureDetector(
              onTap: (){
                launchUrl(facebook);
              },

                child: Center(child: Image.asset('assets/images/face.png'))),
            Spacer(
              flex: 1,
            ),
            GestureDetector(
              onTap: (){
                launchUrl(gmail);
              },
              child: Center(
                  child: Image.asset(
                'assets/images/icons8-gmail-480.png',
                width: 200,
                height: 200,
              )),
            ),
            Spacer(
              flex: 1,
            ),
          ],
        ),
      ),
    );
  }
}
