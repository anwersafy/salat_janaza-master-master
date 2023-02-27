import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:salat_janaza/layout/tt.dart';

class HowToUse extends StatelessWidget {
   HowToUse({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(

        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                  height: 750,
                  child: Image.asset('assets/images/howtouse.jpg')),
              SizedBox(height: 20,),

              Container(
                width: double.infinity,
                  height: 750,
                  child: Image.asset('assets/images/howtouse2.jpg')),
              SizedBox(height: 20,),

              Container(
                width: double.infinity,
                  height: 750,
                  child: Image.asset('assets/images/howtouse3.jpg')),
              SizedBox(height: 20,),
              Container(
                width: double.infinity,
                  height: 750,
                  child: Image.asset('assets/images/howtouse4.jpg')),

            ],
          ),
        )

      ),
    );


  }
}
