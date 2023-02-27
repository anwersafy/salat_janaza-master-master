import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../colors/colors.dart';
import '../main.dart';

class Setting extends StatefulWidget {

  @override
  State<Setting> createState() => _SettingState();

}

class _SettingState extends State<Setting> {


  @override
  void initState(){
    super.initState();
    getSelectedPref();
    setState(() {
    });
  }
  Widget build(BuildContext context) {
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
            Center(child:
            Lottie.asset('assets/images/coming-soon.json'))
          ],
        ),

      ),
    );
  }

  void getSelectedPref() {}
}
