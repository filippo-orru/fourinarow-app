import 'package:flutter/material.dart';

enum Player { One, Two }

extension PlayerExtension on Player {
  Color color() {
    switch (this) {
      case Player.One:
        return Colors.red;
      case Player.Two:
        return Colors.blue;
      default:
        return null;
    }
  }

  String get word {
    switch (this) {
      case Player.One:
        return "Red";
      case Player.Two:
        return "Blue";
      default:
        return null;
    }
  }

  Player get other {
    if (this == Player.One) {
      return Player.Two;
    } else {
      return Player.One;
    }
  }
}
