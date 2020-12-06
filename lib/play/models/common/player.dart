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
        throw UnimplementedError("More than two players: add color()");
    }
  }

  String get colorWord {
    switch (this) {
      case Player.One:
        return "Blue";
      case Player.Two:
        return "Red";
      default:
        throw UnimplementedError("More than two players: add colorWord");
    }
  }

  String get playerWord {
    switch (this) {
      case Player.One:
        return "You";
      case Player.Two:
        return "Enemy";
      default:
        throw UnimplementedError("More than two players: add playerWord");
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
