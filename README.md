# flutter_widgets

My library of widgets for Flutter, at varying stages of development. Constantly expanding.


## Noteworthy content

[<b>NotifCentre:</b>](https://github.com/arrowsmith001/flutter_widgets/blob/master/lib/src/notif_centre.dart) A widget that, given a Stream, builds a ListView of (local) notifications that appear in sequence and disappear after a short amount of time. Highly customizable including notification design, entry & exit animations and lifetime. 

Example implementation: (see a fuller example [here](https://github.com/arrowsmith001/flutter_widgets/blob/master/lib/examples/notif_centre_example.dart))
```
_notifStreamController = new StreamController<Notif>.broadcast();

...
  
 SafeArea(
  child: NotifCentre<Notif>(

    notifStream: _notifStreamController.stream,

    // Optional!
    notifWidgetBuilder: (notif) => Text('My notif says this: ${notif.message!}')
  ),
),

...

_notifStreamController.add(new Notif('Here is my message'));
```
Simply extend the Notif class to include as much data as you'd like to pass to the notifWidgetBuilder.
