library flow.render.animation;

import 'dart:async';

import 'package:stagexl/stagexl.dart' as xl;

import 'package:flow/src/render/item_renderer.dart';

class Animation {

  Stream<AnimationInfo> get animation$ => _animation$ctrl.stream;
  double currentValue;
  bool isComplete = false, isStopped = false;
  xl.Translation translation;

  final xl.Juggler juggler;
  final double startValue, targetValue, time;
  final xl.TransitionFunction transitionFunction;
  final AnimationType type;

  final StreamController<AnimationInfo> _animation$ctrl = new StreamController<AnimationInfo>();

  Animation(this.juggler, this.type, this.startValue, this.targetValue, this.time, this.transitionFunction) {
    currentValue = startValue;
  }

  void start() {
    translation = juggler.addTranslation(startValue, targetValue, time, transitionFunction, (num value) {
      if (!isStopped) {
        currentValue = value;

        _animation$ctrl.add(new AnimationInfo(type, AnimationPosition.UPDATE, value.toDouble()));
      }
    })
      ..onStart = () {
        if (!isStopped) {
          currentValue = startValue;

          _animation$ctrl.add(new AnimationInfo(type, AnimationPosition.START, startValue));
        }
      }
      ..onComplete = () {
        if (!isStopped) {
          currentValue = targetValue;
          isComplete = true;

          _animation$ctrl.add(new AnimationInfo(type, AnimationPosition.COMPLETE, targetValue));
        }
      };
  }

  void stop() {
    isStopped = true;

    juggler.remove(translation);
  }

}