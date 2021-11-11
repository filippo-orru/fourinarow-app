import 'package:flutter/material.dart';
import 'package:four_in_a_row/providers/themes.dart';

enum Player { One, Two }

extension PlayerExtension on Player {
  Color color(FiarTheme theme) {
    switch (this) {
      case Player.One:
        return theme.playerOneColor; // TODO theming how??
      case Player.Two:
        return theme.playerTwoColor;
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
