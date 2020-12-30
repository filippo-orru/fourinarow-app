import 'dart:math';

import 'package:four_in_a_row/util/vibration.dart';

import 'player.dart';

abstract class Field {
  static const int size = 7;

  late List<List<Player?>> _array;

  Field({List<List<Player?>>? field}) {
    this._array = field ??
        List.generate(
            Field.size, (_) => List.filled(Field.size, null, growable: false),
            growable: false);
  }

  List<List<Player?>> get array {
    return _array;
  }
}

class FieldFinished extends Field {
  final WinDetails winDetails;
  bool waitingToPlayAgain = false;

  FieldFinished(this.winDetails, List<List<Player?>> field)
      : super(field: field);
}

class FieldPlaying extends Field {
  // int _chips = 0;
  Player turn = Player.One;
  List<int> lastChips = [];

  FieldPlaying() {
    this.reset();
  }

  void reset() {
    _array = List.generate(
        Field.size, (_) => List.filled(Field.size, null, growable: false),
        growable: false);
    turn = Player.One;
  }

  void vibrate() {
    Vibrations.turnChange();
  }

  void dropChip(int column) {
    dropChipNamed(column, turn);
  }

  void dropChipNamed(int column, Player p) {
    if (column < Field.size &&
        column >= 0 &&
        _array[column].any((c) => c == null)) {
      vibrate();
      int len = _array[column].length;
      for (var i = 0; i <= len; i++) {
        if (i == len || _array[column][i] != null) {
          _array[column][i - 1] = turn;
          break;
        }
      }
      lastChips.add(column);
      turn = turn.other;
    }
  }

  bool get isEmpty {
    for (List<Player?> column in _array) {
      if (column.any((c) => c != null)) {
        // print("field not empty");
        return false;
      }
    }
    // print("field  empty");
    return true;
  }

  // int get chips => _chips;

  // Player get turn => _turn;

  void undo() {
    if (lastChips.isNotEmpty) {
      int lastChip = lastChips.removeLast();
      for (int i = 0; i < Field.size; i++) {
        if (array[lastChip][i] != null) {
          array[lastChip][i] = null;
          return;
        }
      }
    }
  }

  WinDetails? checkWin() {
    const int range = Field.size - 4;
    for (int r = -range; r <= range; r++) {
      Player? lastPlayer;
      int combo = 0;
      for (int i = 0; i < Field.size; i++) {
        if (i + r < 0 || i + r >= Field.size) {
          continue;
        }
        final cellPlayer = _array[i + r][i];
        if (cellPlayer == null) {
          combo = 0;
          lastPlayer = null;
          continue;
        } else if (lastPlayer != cellPlayer) {
          combo = 0;
        }
        lastPlayer = cellPlayer;
        combo += 1;
        if (combo >= 4) {
          // print("won in first block");
          return WinDetailsWinner(
            lastPlayer,
            Point(i + r - (combo - 1), i - (combo - 1)),
            Point(1, 1),
          );
          // return WinDetails(
          //     lastPlayer, Point(i + r - range, i - range), Point(i + r, i));
        }
      }

      lastPlayer = null;
      combo = 0;

      for (int i = Field.size - 1; i >= 0; i--) {
        if (i + r < 0 || i + r >= Field.size) {
          continue;
        }
        int realY = Field.size - 1 - i;
        final cellPlayer = _array[i + r][realY];
        if (cellPlayer == null) {
          combo = 0;
          lastPlayer = null;
          continue;
        } else if (lastPlayer != cellPlayer) {
          combo = 0;
        }
        lastPlayer = cellPlayer;
        combo += 1;
        if (combo >= 4) {
          // print("won in second block");
          return WinDetailsWinner(
              lastPlayer,
              Point(i + r + (combo - 1), realY - (combo - 1)),
              Point(-1, 1)); //- (combo - 1)
          // return WinDetails(
          //     lastPlayer, Point(i + r + range, i + range), Point(i + r, i));
        }
      }
    }

    final List<int> xCombo = List.filled(Field.size, 0);
    final List<Player?> xPlayer = List.filled(Field.size, null);
    // List.generate(Field.size, (_) => List(), growable: false);
    for (int x = 0; x < Field.size; x++) {
      Player? lastPlayer;
      int combo = 0;
      for (int y = 0; y < Field.size; y++) {
        Player? cell = _array[x][y];
        if (cell == null) {
          combo = 0;
          lastPlayer = null;
          xCombo[y] = 0;
          xPlayer[y] = null;
          continue;
        } else if (cell != lastPlayer) {
          combo = 0;
        }
        combo += 1;
        lastPlayer = cell;
        if (combo >= 4) {
          // print("won in y block");
          return WinDetailsWinner(
              lastPlayer, Point(x, max(0, y - combo + 1)), Point(0, 1));
        }

        if (cell != xPlayer[y]) {
          xCombo[y] = 0;
        }
        xCombo[y] += 1;
        xPlayer[y] = lastPlayer;
        if (xCombo[y] >= 4) {
          // print("won in x block");
          return WinDetailsWinner(
              lastPlayer, Point(max(0, x - xCombo[y] + 1), y), Point(1, 0));
        }
      }
    }

    if (_array.every((column) => column.every((cell) => cell != null))) {
      // Field completely full but no winner -> draw
      return WinDetailsDraw();
    }

    return null;
  }
}

abstract class WinDetails {}

class WinDetailsWinner extends WinDetails {
  final bool me;
  final Player winner;
  final Point<int> start;
  final Point<int> delta;

  WinDetailsWinner(this.winner, this.start, this.delta)
      : this.me = winner == Player.One;

  @override
  String toString() {
    return "WinDetails: $winner (${me ? "Me" : "Opp."}). Start: $start, delta: $delta";
  }
}

class WinDetailsDraw extends WinDetails {
  @override
  String toString() {
    return "WinDetails: draw";
  }
}
