import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:salat_janaza/layout/mypray.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../layout/home.dart';
import '../model/model.dart';
import 'state.dart';

class AppCubit extends Cubit<AppStates> {
  AppCubit() : super(AppInitialState());

  static AppCubit get(context) => BlocProvider.of(context);

  final dataBase = FirebaseDatabase.instance.ref();
  final fire = FirebaseFirestore.instance;
  final firestore = FirebaseFirestore.instance.collection('prayers');
  final FirebaseMessaging messaging = FirebaseMessaging.instance;


  var currentPosition;
  double? lati;
  double? longi;
  var mapController = MapController();

  void openMap({
    required double lat, required double long
  }) {
    mapController.move(
        LatLng(
            lat
            ,
            long
        ), 18.0
    );
    emit(AppOpenMapState());
  }


  void changeMarkeMap({required double lat, required double long}) {
    lati = lat;
    longi = long;

    emit(AppChangeMarkeMapState());
  }

  Future requestPermission() async {
    await Geolocator.requestPermission().then((value) {
      if (value == LocationPermission.deniedForever) {
        emit(AppLocationErrorState(
            'Location permissions are permanently denied, we cannot request permissions.'));
        Geolocator.openLocationSettings();
      } else if (value == LocationPermission.denied) {
        emit(AppLocationErrorState('Location permissions are denied'));
        Geolocator.openLocationSettings();
      } else {
        getCurrentPosition();

      }
    });
    emit(AppInitialState());
  }

  Future<void> getCurrentPosition() async {
    emit(AppLocationLoadingState());

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(AppLocationErrorState('Location services are disabled.'));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        emit(AppLocationErrorState('Location permissions are denied'));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      emit(AppLocationErrorState(
          'Location permissions are permanently denied, we cannot request permissions.'));
      return;
    }

    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      currentPosition = position;
      final address = await getAddressFromLatLng(position);
      emit(AppLocationSuccessState(position, address));
    }).catchError((e) {
      emit(AppLocationErrorState('Failed to get current location'));
    });
    return currentPosition;
  }

  Future<String> getAddressFromLatLng(Position position) async {
    final placemarks =
    await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      final place = placemarks[0];
      return '${place.street}, ${place.subLocality}, ${place
          .subAdministrativeArea}, ${place.postalCode}';
    }
    return '';
  }

  calculateDistanse(double lat1, double lon1, double lat2, double lon2) {

    emit(AppLocationLoadingState());
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  void registerNotification() async {
    // 3. On iOS, this helps to take the user permissions
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      // TODO: handle the received notifications
    } else {
      print('User declined or has not accepted permission');
    }
  }

  permissions() async {
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    final fcmToken = await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.instance.onTokenRefresh
        .listen((fcmToken) {
      // TODO: If necessary send token to application server.

      // Note: This callback is fired at each app startup and whenever a new
      // token is generated.
    })
        .onError((err) {
      // Error getting token.
    });
    await FirebaseMessaging.instance
        .requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    )
        .then((value) {
      if (value.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');
        emit(AppFirebaseNotificationSuccessState());
      } else if (value.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission');
        emit(AppFirebaseNotificationSuccessState());
      } else {
        print('User declined or has not accepted permission');
        emit(AppFirebaseNotificationErrorState(
            'User declined or has not accepted permission'));
      }
    });
  }


  Model? model;
  List<Model> deceaseds_posts = [];
  Map<dynamic, dynamic> deceaseds_posts_map = {};

  checkaddNewPost() {
    firestore.snapshots().listen((event) {
      event.docChanges.forEach((element) {
        if (element.type == DocumentChangeType.added) {
          if(deceaseds_posts.isNotEmpty){
            if(deceaseds_posts[deceaseds_posts.length-1].name!=element.doc['name']){
              showNotification(name: element.doc['name']);
            }
          }




        }
      });



      });


  }

  clearCollectionFirestore() {
    firestore.get().then((querySnapshot) {
      querySnapshot.docs.forEach((document) {
        document.reference.delete();
      });
    });
    emit(ClearDeceasedPostSuccessState());
  }

  void createPost({
    required String name,
    required String masged,
    required double latitude,
    required double longitude,
    required String location,
    required String date,
    required String time,

  }) {
    emit(CreatDeceasedPostLoadingState());
    String postId = firestore
        .doc()
        .id;
    Model model = Model(
      name: name,
      id: postId,
      masged: masged,
      latitude: latitude,
      longitude: longitude,
      date: date,
      time: time,
      location: location,
      createdAt: FieldValue.serverTimestamp(),
    );

    firestore.add(model.toJson()).then((value) async {
      deceaseds_posts_map.addAll({
        model.id: [model.time, model.date],



      });

      timeParse(model.time!, model.date!);

      scheduledNotification(
        name: model.name!,
        hour: timeParse(model.time!, model.date!).hour,
        minutes: timeParse(model.time!, model.date!).minute+15,
        day: timeParse(model.time!, model.date!).day,
        month: timeParse(model.time!, model.date!).month,
        year: timeParse(model.time!, model.date!).year,
        id: model.id!,
      );


      // body: 'تذكير بوفاة ${model.name} في ${model.location} في ${model.time} في ${model.date}',
      //showNotification(name: model.name!);
      emit(CreateDeceasedPostSuccessState());
    }).catchError((error) {
      emit(CreateDeceasedPostErrorState(error.toString()));
    });
  }
  timeParse(String time, String date) {
    DateTime dateTime = DateTime.parse(date + ' ' + time);

    return dateTime;
  }



  void getPosts() {
    deceaseds_posts.clear();
    markers = [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'open_street_map_search_and_pick',
        subdomains: ['a', 'b', 'c'],
      ),
    ];
    emit(GetDeceasedPostLoadingState());
    firestore
        .orderBy('time', descending: true)
        .snapshots()
        .listen((event) async {

      for (var element in event.docs) {
        if (calculateDistanse(
            element.data()['latitude'],
            element.data()['longitude'],
            currentPosition.latitude,
            currentPosition.longitude) <= 3000) {
          deceaseds_posts.add(Model.fromJson(element.data()));
          addMarker(element.data()['latitude'], element.data()['longitude']);

        }
      }
      for (var element in event.docChanges) {
        if (element.type == DocumentChangeType.added) {
          if(deceaseds_posts.isNotEmpty){
            if(deceaseds_posts[deceaseds_posts.length-1].name!=element.doc['name']){
              showNotification(name: element.doc['name']);
            }
            //showNotification(name: deceaseds_posts[deceaseds_posts.length-1].name!);
          }


        }

        break;
      }


      emit(GetDeceasedPostSuccessState(deceaseds_posts));
    });
  }

  void deletePost(String? postId) {
    firestore.doc(postId).delete().then((value) {
      getPosts();
      emit(DeleteDeceasesdPostSuccessState());
    });
  }

  var scaffoldkey = GlobalKey<ScaffoldState>();
  DateTime selectedDate = DateTime.now();
  var nameController = TextEditingController();
  var masgedController = TextEditingController();
  var dateController = TextEditingController();
  var timeController = TextEditingController();
  var locationController = TextEditingController();
  var placeController = TextEditingController();
  var longitudeController;
  var latitudeController;
  var dateTimeController = TextEditingController();
  var formKey = GlobalKey<FormState>();

  Future<void> selectDate(BuildContext context) async {
    emit(PikeDateLoadingState());
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 30)));
    if (picked != null && picked != selectedDate) {
      final DateFormat formatter = DateFormat('yyyy-MM-dd');
      final String formatted = formatter.format(picked);
      selectedDate = picked;
      dateController.text = formatted.toString();
      emit(PikeDateSuccessState());
    }
  }

  Future<void> selectTime(BuildContext context) async {
    emit(PikeTimeLoadingState());
    final TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) {
      timeController.text = picked.format(context).toString();

      emit(PikeTimeSuccessState());
    }
  }

  Future<void> selectDateTime(BuildContext context) async {
    emit(PikeDateTimeLoadingState());
    selectDate(context).then((date) {
      selectTime(context).then((time) {
        var dateString = (dateController.text).toString() +
            ' ' +
            timeController.text.toString();
        dateTimeController.text = DateTime.parse(dateString).toString();
        emit(PikeDateTimeSuccessState());
      }).catchError((error) {
        selectDateTime(context);
        emit(PikeDateTimeErrorState(error.toString()));
      });
    }).then((value) {
      emit(PikeDateTimeSuccessState());
    }).catchError((error) {
      selectDateTime(context);
      emit(PikeDateTimeErrorState(error.toString()));
    });
  }

  List<Widget> markers = [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'open_street_map_search_and_pick',
      subdomains: ['a', 'b', 'c'],
    ),
  ];
  var item;

  addMarker(dynamic latitude,
      dynamic longitude,) {
    for (item in deceaseds_posts) {
      markers.add(LocationMarkerLayer(
        position: LocationMarkerPosition(
            latitude: item.latitude, longitude: item.longitude, accuracy: 0),
        style: LocationMarkerStyle(
          showAccuracyCircle: false,
          showHeadingSector: false,
          marker: const DefaultLocationMarker(
            color: Colors.transparent,
            child: Image(
              image: AssetImage(
                'assets/images/location.png',
              ),
            ),
          ),
          markerSize: const Size(50, 50),
          markerDirection: MarkerDirection.heading,
        ),
      ));
    }
  }

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// Initialize notification
  initializeNotification() async {
    await init();

    _configureLocalTimeZone();
    // const IOSInitializationSettings initializationSettingsIOS = IOSInitializationSettings();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');


    InitializationSettings initializationSettings = InitializationSettings(


      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveLocalNotificationResponse,


    );
    emit(InitializeNotificationState());
  }

  /// Set right date and time for notifications
  tz.TZDateTime _convertTime(int hour, int minutes,int day, int month, int year) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduleDate = tz.TZDateTime(
      tz.local,
      year,
      month,
      day,
      hour,
      minutes,
    );
    if (scheduleDate.isBefore(now)) {
      scheduleDate = scheduleDate.add(const Duration(days: 1));
    }
    emit(SetTimeNotificationState());

    return scheduleDate;
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String timeZone = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone));
  }

  BigPictureStyleInformation? _buildBigPictureStyleInformation(String title,
      String body,
      String? picturePath,
      bool showBigPicture,) {
    if (picturePath == null) return null;
    final FilePathAndroidBitmap filePath = FilePathAndroidBitmap(picturePath);
    return BigPictureStyleInformation(
      showBigPicture ? filePath : const FilePathAndroidBitmap("empty"),
      largeIcon: filePath,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: body,
      htmlFormatSummaryText: true,
    );
  }


  /// Scheduled Notification
  scheduledNotification({
    required int hour,
    required int minutes,
    required int day,
    required int month,
    required int year,

    required int id,
    required String name,
    //required String sound,
  }) async {
    emit(ScheduledNotificationLoadingState());
    final bigPicture = await DownloadUtil.downloadAndSaveFile(
        "http://au-fas.net/UploadFiles/2023/Jan/04/ee442646-7319-46b1-b4d3-082c57f84cb2.jpg",
        "Picture");

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'إنّا لله وإنّا إليهِ رَاجعُون',
      '   اللهم ارحمه رحمةً  تسع  السماوات والارض و اجعل قبره في نور دائم لا ينقطع   ${name} توفى اليوم الي رحمة الله تعالى   ',
      _convertTime(hour, minutes, day, month, year),
      NotificationDetails(

        android: AndroidNotificationDetails(
          //'your channel id $sound',
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
          //sound: RawResourceAndroidNotificationSound(sound),
          icon: '@mipmap/ic_launcher',
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          styleInformation: BigPictureStyleInformation(
            FilePathAndroidBitmap(bigPicture),
            hideExpandedLargeIcon: false,
          ),
          color: const Color(0xff2196f3),


          playSound: true,
          enableVibration: true,


        ),
        //iOS: IOSNotificationDetails(sound: '$sound.mp3'),
      ),

      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation
          .absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'item x',

    ).then((value) {
      emit(ScheduledNotificationSuccessState());
      print('Notification scheduled');
    }).catchError((error) {
      emit(ScheduledNotificationErrorState(error.toString()));
      print('$error');
      print('Notification scheduled error');
    });
  }

  showNotification({


    required String name,

  }) async {
    emit(ShowNotificationLoadingState());


    final bigPicture = await DownloadUtil.downloadAndSaveFile(
        "http://au-fas.net/UploadFiles/2023/Jan/04/ee442646-7319-46b1-b4d3-082c57f84cb2.jpg",
        "Picture");
    final platformChannelSpecifics = NotificationDetails(

      android: AndroidNotificationDetails(
        //'your channel id $sound',
        'your channel id',
        'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high,
        //sound: RawResourceAndroidNotificationSound(sound),
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigPictureStyleInformation(
          FilePathAndroidBitmap(bigPicture),
          hideExpandedLargeIcon: false,
        ),
        color: const Color(0xff2196f3),


        playSound: true,
        enableVibration: true,


      ),
      //iOS: IOSNotificationDetails(sound: '$sound.mp3'),
    );
    await flutterLocalNotificationsPlugin.show(
      Random.secure().nextInt(1000),
      'إنّا لله وإنّا إليهِ رَاجعُون',
      '     اللهم ارحمه رحمةً  تسع  السماوات والارض و اجعل قبره في نور دائم لا ينقطع   ${ name }  توفى اليوم الي رحمة الله تعالى      ',
      platformChannelSpecifics,
      payload: 'item $name',
    ).then((value) {
      emit(ShowNotificationSuccessState());
      print('Notification scheduled');
    }).catchError((error) {
      emit(ShowNotificationErrorState(error.toString()));
      print('$error');
      print('Notification scheduled error');
    });
  }


  /// Request IOS permissions
  void requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    emit(RequestIOSPermissionState());
  }

  cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    emit(CancelAllNotificationState());
  }

  cancel(id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    emit(CancelNotificationState());
  }


  var hourController;
  var minuteController;

  var hour_reminder;
  var minute_reminder;

  Future onSelectNotification(String payload) async {
    print('Notification clicked');
    emit(OnSelectNotificationState());
    return Future.value(0);
  }

  void onDidReceiveLocalNotification(int id, String title, String body,
      String payload, BuildContext context) async {
    // display a dialog with the notification details, tap ok to go to another page
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            CupertinoAlertDialog(
              title: Text(title),
              content: Text(body),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('Ok'),
                  onPressed: () async {
                    Navigator.of(context, rootNavigator: true).pop();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HomePage()),

                    );
                  },
                )
              ],
            ));
    void removeReminder(int notificationId) {
      flutterLocalNotificationsPlugin.cancel(notificationId);
    }
  }


  void onDidReceiveLocalNotificationResponse(NotificationResponse details) {
    print('Notification clicked');
    emit(OnDidReceiveLocalNotificationResponseState());
  }

var messageBody={
  "message": {
    "topic": "all",
    "notification": {
      "title": 'إنّا لله وإنّا إليهِ رَاجعُون',
      "body": "     اللهم ارحمه رحمةً  تسع  السماوات والارض و اجعل قبره في نور دائم لا ينقطع   ",
      "image": "http://au-fas.net/UploadFiles/2023/Jan/04/ee442646-7319-46b1-b4d3-082c57f84cb2.jpg"
    },


  }
};
  String serverKey = "AAAAlJ7cgpo:APA91bGPQG7Jl4CkGxzB-RnH9n-kuvwf-KJHO9zaZDBanO6pnFeVy-fbYxiQaMVfAmJShsRavYqyxNSxXCVtEH17WCb5ED66DeKe4ixwbpA62LIgP9TV0V0PrGiM3LtR_sXUxSjOFxn0";
  String fcmUrl = "https://fcm.googleapis.com/fcm/send";

  sendFirebaseNotification({
    required String name,
  }) async {
     final bigPicture = await DownloadUtil.downloadAndSaveFile(
         "http://au-fas.net/UploadFiles/2023/Jan/04/ee442646-7319-46b1-b4d3-082c57f84cb2.jpg",
         "Picture");
emit(SendFirebaseNotificationLoadingState());
    var response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $serverKey",
        },
        body: jsonEncode(

          {
            "message": {
              'image': 'http://au-fas.net/UploadFiles/2023/Jan/04/ee442646-7319-46b1-b4d3-082c57f84cb2.jpg',
              "topic": "all",
              'sound': 'default',
              'priority': 'high',
              'content_available': true,
              'mutable_content': true,

              "notification": {
                "title": 'إنّا لله وإنّا إليهِ رَاجعُون',
                "body": "     اللهم ارحمه رحمةً  تسع  السماوات والارض و اجعل قبره في نور دائم لا ينقطع   ${ name }  توفى اليوم الي رحمة الله تعالى      ",

              },},
          },
        )
    ).then((value) {
      emit(SendFirebaseNotificationSuccessState());
      print('Notification sent');
    }).catchError((error) {
      emit(SendFirebaseNotificationErrorState(error.toString()));
      print('$error');
      print('Notification sent error');
    });
    emit(SendFirebaseNotificationState());
    print(response);
    print('Notification sent');
  }


  init() async {
    // add firebase notification permission
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    if (await Permission.notification.request().isGranted) {
      try {
        // Either the permission was already granted before or the user just granted it.
        FirebaseMessaging.onBackgroundMessage(_messageHandler);
        _firebaseMessagingListener();
        String? deviceToken = await FirebaseMessaging.instance.getToken();
        print(deviceToken);
      } catch (e) {
        print(e);
        emit(PermissionNotGrantedState());
      }
    }
  }

  /// must call it from view after getContext is initialized to show dialog message
  checkAndroid() async {
    if (!(await Permission.notification.request().isGranted) && Platform.isAndroid) {
      print('Permission not granted');
      openAppSettings();
      emit(PermissionNotGrantedState());
    } else {
      print('Permission granted');
      emit(PermissionGrantedState());
    }

  }

// execute if app in background
  Future<void> _messageHandler(RemoteMessage message) async {
    // Data notificationMessage = Data.fromJson(message.data);
    print('notification from background : ${message.toMap()}');
    print('notification from background : ${message.data}');
    emit(OnDidReceiveLocalNotificationResponseState());
  }

// execute if app in foreground
  void _firebaseMessagingListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {

        // that means new message

        try {
          // snackbar(message.notification!.title.toString(), message.notification!.body.toString(),
          //     duration: Duration(seconds: 6),
          //     //backgroundColor: Theme.of(Get.context!).cardColor,
          //     barBlur: 10,
          //     margin: EdgeInsets.all(10),
          //     padding: EdgeInsets.all(8));
        } catch (e) {

        }
      }
    });
  }

}
class DownloadUtil {
  static Future<String> downloadAndSaveFile(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await Dio().get(url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          },
        ));
    File file = File(filePath);
    var raf = file.openSync(mode: FileMode.write);
    raf.writeFromSync(response.data);
    await raf.close();
    return filePath;
  }
}





