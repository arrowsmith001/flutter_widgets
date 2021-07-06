import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Extend this class to provide your own desired notification information.
class Notif {
  Notif([this.message]);

  /// A message you may want to show to the user in your notification.
  ///
  /// There's nothing special about this field, other than it's use in the
  /// default notification builder implementation.
  final String? message;
}

/// A widget which takes a Notif stream and displays each new
/// [Notif] as a widget.
///
/// Each notification widget has a lifespan, and can be provided an entry and/or
/// exit animation. By default, each widget is displayed in a list until its
/// life is over.
class NotifCentre<T extends Notif> extends StatefulWidget {

  NotifCentre(
      {required this.notifStream,
        this.notifWidgetBuilder,
        this.notifLifespan = const Duration(seconds: 3),
        this.animatedEntryBuilder,
        this.animatedEntryDuration = const Duration(seconds: 1),
        this.animatedExitBuilder,
        this.animatedExitDuration = const Duration(seconds: 1)});


  /// A [Notif] stream. Should be provided by a [StreamController] in the
  /// client-side code, through which [Notif] instances are added.
  final Stream<T> notifStream;

  /// Builder which transforms each [Notif] into a [Widget]. Implement this to
  /// decide exactly how your notification will look. See [_defaultNotifBuilder]
  /// for an example implementation.
  final Widget Function(T)? notifWidgetBuilder;

  /// The time in which the notification will be displayed between the entrance
  /// and exit animation. This is added to the [animatedEntryDuration] and
  /// [animatedExitDuration] to calculate the total lifespan of the
  /// notification.
  final Duration notifLifespan;

  /// Builder which is called during the entrance animation. Implement this to
  /// transform the (already built) notification widget according to the
  /// animation value. See [_defaultEntranceAnimation] for an example
  /// implementation.
  final Widget Function(Widget, Animation<double>)? animatedEntryBuilder;

  /// The time in which the entrance animation will last. This is added to the
  /// [notifLifespan] and [animatedExitDuration] to calculate the total lifespan
  /// of the notification.
  final Duration animatedEntryDuration;

  /// Builder which is called during the exit animation. Implement this to
  /// transform the (already built) notification widget according to the
  /// animation value. See [_defaultExitAnimation] for an example
  /// implementation.
  final Widget Function(Widget, Animation<double>)? animatedExitBuilder;

  /// The time in which the exit animation will last. This is added to the
  /// [notifLifespan] and [animatedEntryDuration] to calculate the total lifespan
  /// of the notification.
  final Duration animatedExitDuration;

  /// Basic implementation of [notifWidgetBuilder]. Takes a [Notif] as input,
  /// outputs a [Widget].
  final Widget Function(T notif) _defaultNotifBuilder =
      (notif) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Container(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(notif.message ?? 'This is a notification.', style: TextStyle(fontSize: 16))),
        height: 50,
        decoration: BoxDecoration(
            boxShadow: [BoxShadow(color: Colors.black, blurRadius: 5, spreadRadius: 1)],
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.all(Radius.circular(12)) )),
  );

  /// Basic implementation of [animatedEntryBuilder]. Takes a [Widget] and
  /// [Animation] as input, outputs the animation-transformed [Widget].
  final Widget Function(Widget widget, Animation<double> animation) _defaultEntranceAnimation =
      (widget, animation) => Transform.scale(child: widget,
          scale: animation.drive(new CurveTween(curve: Curves.elasticOut)).value);

  /// Basic implementation of [animatedExitBuilder]. Takes a [Widget] and
  /// [Animation] as input, outputs the animation-transformed [Widget].
  final Widget Function(Widget widget, Animation<double> animation) _defaultExitAnimation =
      (widget, animation) => Opacity(child: widget, opacity: 1 - animation.value);

  @override
  _NotifCentreState<T> createState() => _NotifCentreState<T>();
}

class _NotifCentreState<T extends Notif> extends State<NotifCentre<T>> with TickerProviderStateMixin {

  List<T> notifs = [];
  Map<T, AnimationController> notifControllers = {};

  late StreamSubscription<T> sub;

  @override
  initState(){
    super.initState();
    sub = widget.notifStream.listen((notif) {
      _onNewNotif(notif);
    });
  }

  void removeNotif(final T notif){
    notifs.remove(notif);
    notifControllers[notif]!.dispose();
    notifControllers.remove(notif);
  }

  @override
  void dispose() {
    sub.cancel();
    for(var controller in notifControllers.values) controller.dispose();
    super.dispose();
  }

  Duration get _totalNotifLifespan => widget.animatedEntryDuration + widget.notifLifespan + widget.animatedExitDuration;

  void _onNewNotif(final T notif) async {

    AnimationController _animController = new AnimationController(vsync: this, duration: _totalNotifLifespan);
    _animController.addListener(() {setState(() {});});
    _animController.addStatusListener((status) {
      if(status == AnimationStatus.completed){
        _onAnimationCompleted(notif);
      }
    });
    _animController.forward(from: 0);

    notifs.add(notif);
    notifControllers.addAll({notif: _animController});
  }

  void _onAnimationCompleted(T notif){
    removeNotif(notif);
  }

  Widget _buildNotif(final int i) {
    final T notif = notifs[i];
    final AnimationController controller = notifControllers[notif]!;

    return _NotifWidget(
        notif, controller,
        notifWidgetBuilder: widget.notifWidgetBuilder ?? widget._defaultNotifBuilder,
        notifLifespan: widget.notifLifespan,
        animatedEntryBuilder: widget.animatedEntryBuilder ?? widget._defaultEntranceAnimation,
        animatedEntryDuration: widget.animatedEntryDuration,
        animatedExitBuilder: widget.animatedExitBuilder ?? widget._defaultExitAnimation,
        animatedExitDuration: widget.animatedExitDuration);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
        stream: widget.notifStream,
        builder: (context, snap)
        {
          if(!snap.hasData || snap.data == null) return SizedBox.shrink();
          return Container(
            child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: notifs.length,
                itemBuilder: (context, i) {

                  return _buildNotif(i);

                  return Dismissible(
                      key: UniqueKey(),
                      onDismissed: (direction) => removeNotif(notifs[i]),
                      child: _buildNotif(i)
                  );
                }
            ),
          );
        });
  }
}

class _NotifWidget<T extends Notif> extends StatelessWidget {

  _NotifWidget(this.notif, this.controller,
      {
        required this.notifWidgetBuilder,required this.notifLifespan,
        required this.animatedEntryBuilder,required this.animatedEntryDuration,
        required this.animatedExitBuilder, required this.animatedExitDuration
      });

  final T notif;
  final AnimationController controller;
  final Widget Function(T) notifWidgetBuilder;
  final Duration notifLifespan;
  final Widget Function(Widget, Animation<double>) animatedEntryBuilder;
  final Duration animatedEntryDuration;
  final Widget Function(Widget, Animation<double>) animatedExitBuilder;
  final Duration animatedExitDuration;

  double _proportionOfLifespan(Duration duration) => duration.inMicroseconds / _totalNotifLifespan.inMicroseconds;
  Duration get _totalNotifLifespan => animatedEntryDuration + notifLifespan + animatedExitDuration;

  late Animation<double> entryAnimation = new CurvedAnimation(parent: controller,
      curve: Interval(0.0, _proportionOfLifespan(animatedEntryDuration)));
  late Animation<double> exitAnimation = new CurvedAnimation(parent: controller,
      curve: Interval(_proportionOfLifespan(animatedEntryDuration + notifLifespan), 1.0));

  @override
  Widget build(BuildContext context) {
    Widget notifWidget = notifWidgetBuilder(notif);

    if(entryAnimation.status == AnimationStatus.forward) notifWidget = animatedEntryBuilder(notifWidget, entryAnimation);
    if(exitAnimation.status == AnimationStatus.forward) notifWidget = animatedExitBuilder(notifWidget, exitAnimation);

    return notifWidget;
  }
}