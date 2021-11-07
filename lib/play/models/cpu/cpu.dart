import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';

enum CpuDifficulty { EASY, MEDIUM, HARD }

abstract class Cpu {
  final Player cpu = Player.Two;
  final Random _random = Random(DateTime.now().millisecond);

  static Cpu fromDifficulty(CpuDifficulty difficulty) {
    switch (difficulty) {
      case CpuDifficulty.EASY:
        return EasyCpu();
      case CpuDifficulty.MEDIUM:
        return MediumCpu();
      case CpuDifficulty.HARD:
        return HardCpu();
    }
  }

  String difficultyString();

  Future<int> chooseCol(Field field);
}

class EasyCpu extends Cpu {
  @override
  Future<int> chooseCol(Field field) async {
    await Future.delayed(Duration(seconds: 1 + _random.nextInt(2)));
    int col = 0;
    bool foundColumn = true;
    int tries = 0;
    do {
      col = _random.nextInt(Field.size);
      foundColumn = true;
      final fieldCopy = FieldPlaying.from(field.clone());
      fieldCopy.dropChipNamed(col, cpu, vibrate: false);
      var winDetails = fieldCopy.checkWin();
      if (winDetails != null && winDetails is WinDetailsWinner && winDetails.winner == cpu.other) {
        foundColumn = false;
      }
      tries += 1;
    } while (foundColumn && tries < Field.size);

    return col;
  }

  @override
  String toString() => 'DUMB CPU';

  @override
  String difficultyString() => "Stupid";
}

class MediumCpu extends Cpu {
  @override
  Future<int> chooseCol(Field field) async {
    final List<double> scores = List.filled(Field.size, 0);

    await Future.delayed(Duration(seconds: 2 + _random.nextInt(2)));

    return _compute(ComputeDetails(cpu, field, 0, 1, scores, _random));
  }

  @override
  String toString() => 'MEDIUM CPU';

  @override
  String difficultyString() => "Easy";
}

class HardCpu extends MediumCpu {
  @override
  Future<int> chooseCol(Field field) async {
    final List<double> scores = List.filled(Field.size, 0);

    //await Future.delayed(Duration(seconds: 2 + _random.nextInt(2)));
    return await compute(_compute, ComputeDetails(cpu, field, 0, 3, scores, _random));
  }

  @override
  String toString() => 'HARD CPU';

  @override
  String difficultyString() => "Medium";
}

class ComputeDetails {
  final Player cpuPlayer;
  final Field field;
  final int step;
  final int deepness;
  final List<double?> scores;
  final Random random;

  ComputeDetails(this.cpuPlayer, this.field, this.step, this.deepness, this.scores, this.random);
}

int _compute(ComputeDetails details) {
  for (var i = 0; i < Field.size; ++i) {
    final fieldCopy = FieldPlaying.from(details.field.clone());

    final target = fieldCopy.array[i].lastIndexOf(null);
    if (target == -1) {
      details.scores[i] = null;
      continue;
    }

    fieldCopy.dropChipNamed(i, details.cpuPlayer, vibrate: false);
    if (fieldCopy.checkWin() != null) {
      var score = details.scores[i];
      details.scores[i] = (score ?? 0) + details.deepness / (details.step + 1);
      continue;
    }

    for (var j = 0; j < Field.size; ++j) {
      final target = fieldCopy.array[i].lastIndexOf(null);
      if (target == -1) {
        continue;
      }

      fieldCopy.dropChipNamed(j, details.cpuPlayer, vibrate: false);
      if (fieldCopy.checkWin() != null) {
        var score = details.scores[i];
        details.scores[i] = (score ?? 0) - details.deepness / (details.step + 1);
        continue;
      }

      if (details.step + 1 < details.deepness) {
        ComputeDetails newDetails = ComputeDetails(details.cpuPlayer, details.field,
            details.step + 1, details.deepness, details.scores, details.random);
        _compute(newDetails);
      }
    }
  }

  return _getBestScoreIndex(details.scores, details.random);
}

int _getBestScoreIndex(List<double?> scores, Random random) {
  int bestScoreIndex = scores.indexWhere((s) => s != null);
  scores.asMap().forEach((index, score) {
    if (score != null &&
        (score > scores[bestScoreIndex]! ||
            (score == scores[bestScoreIndex] && random.nextBool()))) {
      bestScoreIndex = index;
    }
  });
  return bestScoreIndex;
}
