import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart'as intl;
import '../colors/colors.dart';
import '../cubit/cubit.dart';
import '../cubit/state.dart';
import 'add_location.dart';

class MyPray extends StatelessWidget {
  const MyPray({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return

        BlocConsumer<AppCubit,AppStates>(
            listener: (context,state) {},
            builder: (context,state) {
              var cubit = AppCubit.get(context);
              return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text('صلواتي',
                      ),

                    ),

                    body: cubit.deceaseds_posts.length == 0 ? Center(child: Text('لا يوجد صلاة جنازة',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white
                        )
                    ),) : ListView.separated(
                      itemBuilder: (context,index) => InkWell(
                        onTap:(){
                          cubit.openMap(
                              lat: cubit.deceaseds_posts[index].latitude!, long: cubit.deceaseds_posts[index].longitude!
                          );

                          Navigator.pop(context);
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(cubit.deceaseds_posts[index].name!),
                            subtitle: Text(" مسجد ${cubit.deceaseds_posts[index].masged!}  "),
                            trailing: Column(
                              children: [
                                Text(cubit.deceaseds_posts[index].time!),
                                SizedBox(height: 9,),
                              ],
                            ),
                          ),
                        ),
                      ),
                      separatorBuilder: (context,index) => SizedBox(height: 10,),
                      itemCount: cubit.deceaseds_posts.length,

                    ),


                  )

              );
            }
        );


  }
}
