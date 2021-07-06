import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets.dart';

main(){
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      home: NotifCentreExamplePage(),
    );
  }

}

/// Our custom extension of the [Notif] class which will contain the information
/// we want to show.
class ExampleCustomNotif extends Notif {
  ExampleCustomNotif(this.buttonColor, this.notifNumber) : super(_message(buttonColor, notifNumber));

  static _message(String buttonColor, int notifNumber)
    => 'This is a $buttonColor notification (number: ${notifNumber.toString()})';

  /// A example of some custom information you may want to show the user
  /// in your notification.
  ///
  /// This String will tell us some information about which button that sent
  /// this notification was pressed.
  final String buttonColor;

  /// Another example of some custom information you may want to show the user in
  /// your notification.
  ///
  /// This number will track how many notifications have been sent through the
  /// stream in total. Each notification will then display their "number".
  final int notifNumber;
}


class NotifCentreExamplePage extends StatefulWidget {

  @override
  _NotifCentreExamplePageState createState() => _NotifCentreExamplePageState();
}

class _NotifCentreExamplePageState extends State<NotifCentreExamplePage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _notifStreamController.stream.listen((notif) => print('New notification: ' + notif.message!));
  }

  /// This [StreamController] will be used to send [Notif] instances to the
  /// [NotifCentre]. Be sure to initialize it with ".broadcast()", pass it to the
  /// [NotifCentre] as an argument, and dispose of it appropriately.
  var _notifStreamController = new StreamController<ExampleCustomNotif>.broadcast();


  /// Here is some extra information that the notifications will convey. It is
  /// the total number of notifications sent.
  int totalNumberOfNotificationsSent = 0;


  void _onButtonPressed(String buttonColor) => _addNewNotification(buttonColor);

  void _addNewNotification(buttonColor){

    totalNumberOfNotificationsSent++;

    var notif = new ExampleCustomNotif(buttonColor, totalNumberOfNotificationsSent);
    _notifStreamController.add(notif);
  }

  // This custom builder implementation will illustrate how our custom
  // notifications are turned into a widget.
  Widget _myNotifWidgetBuilder(ExampleCustomNotif notif){

      Color? widgetColor;
      switch(notif.buttonColor)
      {
        case 'red':
          widgetColor = Colors.red;
          break;
        case 'blue':
          widgetColor = Colors.blue;
          break;
        case 'green':
          widgetColor = Colors.green;
          break;
      }

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(notif.message!, style: TextStyle(color: Colors.white, fontSize: 20),),
          ),
          decoration: BoxDecoration(color: widgetColor!)),
      );
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [

        // Main body of the app page
        Scaffold(
          body: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.red)),
                    onPressed: () => _onButtonPressed('red'),
                    child: Text('Send Red Notif'),
                  ),

                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.blue)),
                    onPressed: () => _onButtonPressed('blue'),
                    child: Text('Send Blue Notif'),
                  ),

                  ElevatedButton(
                    style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.green)),
                    onPressed: () => _onButtonPressed('green'),
                    child: Text('Send Green Notif'),
                  )

                ],
              ),
            ),
          ),
        ),

        // Overlayed notifications.
        SafeArea(

          // The type argument is set to ExampleCustomNotif because we want it
          // to build and display notifications of this type.
          child: NotifCentre<ExampleCustomNotif>(

            // This is the only required argument.
            notifStream: _notifStreamController.stream,

            notifWidgetBuilder: _myNotifWidgetBuilder, // Comment out this line to
            // observe that the default builder still gives a detailed notification
            // thanks to our call to 'super' in the ExampleCustomNotif class.

          ),
        ),

      ],
    );
  }
}
