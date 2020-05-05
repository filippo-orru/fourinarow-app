import 'package:flutter/material.dart';

enum Player { One, Two }

extension PlayerExtension on Player {
  Color color() {
    switch (this) {
      case Player.One:
        return Colors.blue;
      case Player.Two:
        return Colors.red;
      default:
        return null;
    }
  }

  String get colorWord {
    switch (this) {
      case Player.One:
        return "Blue";
      case Player.Two:
        return "Red";
      default:
        return null;
    }
  }

  String get playerWord {
    switch (this) {
      case Player.One:
        return "You";
      case Player.Two:
        return "Enemy";
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
