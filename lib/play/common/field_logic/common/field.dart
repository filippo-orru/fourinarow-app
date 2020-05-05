import 'dart:math';

import 'package:four_in_a_row/util/vibration.dart';

import 'player.dart';

class Field {
  static const int fieldSize = 7;
  List<List<Player>> _array;
  int _chips = 0;
  Player turn = Player.One;

  Field() {
    this.reset();
  }

  void vibrate() {
    Vibrations.turnChange();
  }

  dropChip(int column) {
    dropChipNamed(column, turn);
  }

  dropChipNamed(int column, Player p) {
    vibrate();
    int len = _array[column].length;
    for (var i = 0; i <= len; i++) {
      if (i == len || _array[column][i] != null) {
        _array[column][i - 1] = turn;
        break;
      }
    }
    turn = turn.other;
  }

  List<List<Player>> get array {
    return _array;
  }

  bool get isEmpty {
    for (List<Player> column in _array) {
      if (column.any((c) => c != null)) {
        // print("field not empty");
        return false;
      }
    }
    // print("field  empty");
    return true;
  }

  int get chips => _chips;

  // Player get turn => _turn;

  reset() {
    _array = List.generate(
        fieldSize, (_) => List.filled(fieldSize, null, growable: false),
        growable: false);
    turn = Player.One;
  }

  WinDetails checkWin() {
    const int range = fieldSize - 4;
    for (int r = -range; r <= range; r++) {
      Player lastPlayer;
      int combo = 0;
      for (int i = 0; i < fieldSize; i++) {
        if (i + r < 0 || i + r >= fieldSize) {
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
        if (combo == 4) {
          // print("won in first block");
          return WinDetails(lastPlayer, Point(i + r, i), Point(-1, -1));
          // return WinDetails(
          //     lastPlayer, Point(i + r - range, i - range), Point(i + r, i));
        }
      }

      lastPlayer = null;
      combo = 0;

      for (int i = fieldSize - 1; i >= 0; i--) {
        if (i + r < 0 || i + r >= fieldSize) {
          continue;
        }
        int realY = fieldSize - 1 - i;
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
        if (combo == 4) {
          // print("won in second block");
          return WinDetails(lastPlayer, Point(i + r, i), Point(1, 1));
          // return WinDetails(
          //     lastPlayer, Point(i + r + range, i + range), Point(i + r, i));
        }
      }
    }

    final List<int> xCombo = List(fieldSize);
    final List<Player> xPlayer = List(fieldSize);
    Player lastPlayer;
    int combo = 0;
    // List.generate(fieldSize, (_) => List(), growable: false);
    for (int x = 0; x < fieldSize; x++) {
      for (int y = 0; y < fieldSize; y++) {
        Player cell = _array[x][y];
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
          return WinDetails(lastPlayer, Point(x, y), Point(0, -1));
        }

        if (cell != xPlayer[y]) {
          xCombo[y] = 0;
        }
        xCombo[y] += 1;
        xPlayer[y] = lastPlayer;
        if (xCombo[y] >= 4) {
          // print("won in x block");
          return WinDetails(lastPlayer, Point(x, y), Point(-1, 0));
        }
      }
    }

    return null;
  }
}

class WinDetails {
  final bool me;
  final Player player;
  final Point<int> start;
  final Point<int> delta;

  WinDetails(this.player, this.start, this.delta)
      : this.me = player == Player.One;

  @override
  String toString() {
    return "WinDetails: $player (${me ? "Me" : "Opp."}). Start: $start, delta: $delta";
  }
}
