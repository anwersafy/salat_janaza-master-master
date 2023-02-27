import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:salat_janaza/layout/tt.dart';

import '../colors/colors.dart';

class About extends StatelessWidget {
  const About({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(

          backgroundColor: canvasColor,
        ),
        body: Background(
          child: Center(
            child: Column(
              children: [
                //Lottie.asset('assets/images/splash.json',width: 200,height: 200),

                Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10)

                  ),
                  child: Text('  هل عرَفْتَ الأجرَ المترتب على الصلاة على الجِنازة وتشييعها؟ قال رسول الله ﷺ: «من شهد الجنازة حتى يصلى عليها فله قيراط ومن شهدها حتى تدفن فله قيراطان، قيل: يا رسول الله، وما القيراطان؟ قال: مثل الجبلين العظيمين»'

                  ,style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Colors.white
                  ),),
                ),
                Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10)

                  ),
                  child: Text(' وعن ابن عباسٍ رضي الله عنهما قال: سمعتُ النبيَّ ﷺ يقول: ما من رجلٍ مسلمٍ يموت, فيقوم على جنازته أربعون رجلًا لا يُشركون بالله شيئًا؛ إلا شفَّعهم الله فيه. رواه مسلم.'

                    ,style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: Colors.white
                    ),),
                ),
                Container(
                  height: 130,
                  width: double.infinity,
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(10)
                  ),
                  child: Column(

                    children: [
                      Center(
                        child: Text('قال رسول الله صلى الله عليه وسلم:',
                          style: TextStyle(
                            fontFamily: 'ShantellSans',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black
                        ),),
                      ),

                      Text('من صلى على الجنازة فله قيراط، ومن تبعها حتى تدفن فله قيراط. رواه البخاري',


                          style: TextStyle(
                            fontFamily: 'ShantellSans',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red
                          ))
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10)

                  ),
                  child: Text('تطبيق صلاة الجنازة طريقك إلى الجنة'

                    ,style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 19,
                        color: Colors.white
                    ),),
                ),


              ],
            ),
          ),
        ),

      ),
    );
  }
}
