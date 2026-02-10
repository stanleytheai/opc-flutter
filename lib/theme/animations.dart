import 'package:flutter/material.dart';

class Anim {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 400);
  static const slow = Duration(milliseconds: 600);

  static const snappy = Curves.easeOutCubic;
  static const smooth = Curves.easeInOutCubic;
  static const bounce = Curves.elasticOut;

  /// Returns a staggered delay for item at [index].
  static Duration staggerDelay(int index, {Duration interval = const Duration(milliseconds: 50)}) {
    return Duration(milliseconds: interval.inMilliseconds * index);
  }
}
