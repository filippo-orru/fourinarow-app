import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/game_chip.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:provider/src/provider.dart';

class Board extends StatelessWidget {
  final Field field;
  final Function(int) _dropChip;

  Board(this.field, {Key? key, required Function(int) dropChip})
      : _dropChip = dropChip,
        super(key: key);

  // Function(Color color, AnimationController c) gameChipCurry =
  //     (Color col, AnimationController con) => GameChip(col, controller: con);

  @override
  Widget build(BuildContext context) {
    var _field = field;
    WinDetails? details;
    if (_field is FieldFinished) {
      details = _field.winDetails;
    } else if (_field is FieldPlaying) {
      details = _field.checkWin();
    }
    List<Point> winning = [];

    if (details != null) {
      if (details is WinDetailsWinner) {
        Point<int> pointer = details.start;
        for (int i = 0; i < Field.size; i++) {
          if (pointer.x < 0 ||
              pointer.x >= Field.size ||
              pointer.y < 0 ||
              pointer.y >= Field.size) {
            break;
          }
          if (field.array[pointer.x][pointer.y] == details.winner) {
            winning.add(pointer);
            pointer += details.delta;
          } else {
            break;
          }
        }
      }
    }

    return ConstrainedBox(
      // constraints: BoxConstraints.expand(),
      constraints: BoxConstraints.loose(Size(
        MediaQuery.of(context).size.width - 64,
        MediaQuery.of(context).size.width - 64,
      )),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          constraints: BoxConstraints.expand(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: field.array
                .asMap()
                .map((x, column) {
                  return MapEntry(
                    x,
                    _CreateRow(x,
                        dropChip: _dropChip,
                        winning: winning,
                        column: column,
                        lastPlacedChipY: _field is FieldPlaying
                            ? _field.lastPlacedChip?.x == x
                                ? _field.lastPlacedChip!.y
                                : null
                            : null),
                  );
                })
                .values
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _CreateRow extends StatelessWidget {
  const _CreateRow(
    this.x, {
    Key? key,
    required this.column,
    required Function(int) dropChip,
    required this.winning,
    required this.lastPlacedChipY,
  })  : _dropChip = dropChip,
        super(key: key);

  final int x;
  final List<Player?> column;
  final Function(int) _dropChip;
  final List<Point> winning;
  final int? lastPlacedChipY;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _dropChip(x),
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: column
                .asMap()
                .map((y, cell) {
                  return MapEntry(
                    y,
                    _CreateCell(
                      cell: cell,
                      winning: winning.contains(Point<int>(x, y)),
                      wasLastPlaced: lastPlacedChipY == y,
                    ),
                  );
                })
                .values
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _CreateCell extends StatelessWidget {
  _CreateCell({
    required this.cell,
    required this.winning,
    required this.wasLastPlaced,
    Key? key,
  }) : super(key: key);

  final Player? cell;
  // final WinDetails details;
  final bool winning;
  final bool wasLastPlaced;

  @override
  Widget build(BuildContext context) {
    Widget chip = SizedBox();
    FiarTheme theme = context.watch<ThemesProvider>().selectedTheme;

    if (cell != null) {
      chip = GameChip(cell!.color(theme));
      if (winning) {
        chip = WinningGameChip(cell!.color(theme));
      }
    }

    return Expanded(
      child: Stack(children: [
        GameChipStatic(Color(0xFFDEDEDE)),
        chip,
        wasLastPlaced
            ? Transform.scale(scale: 0.16, child: GameChip(Colors.white.withOpacity(0.6)))
            : SizedBox(),
      ]),
    );
  }
}
