import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/play/models/online/game_states/playing.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:provider/provider.dart';
import 'package:provider/src/provider.dart';

import 'common/menu_common.dart';
import 'main_menu.dart';

class ThemeSelectPage extends StatefulWidget {
  const ThemeSelectPage({Key? key}) : super(key: key);

  @override
  _ThemeSelectPageState createState() => _ThemeSelectPageState();
}

class _ThemeSelectPageState extends State<ThemeSelectPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: FiarAppBar(
        title: "Themes",
        threeDots: [
          FiarThreeDotItem(
            'Feedback',
            onTap: () {
              showFeedbackDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Flexible(
            flex: 3,
            // child: AbsorbPointer(
            child: PageView(
              children: context
                  .watch<ThemesProvider>()
                  .allThemes
                  .map((theme) => ThemePreview(theme))
                  .toList(),
            ),
            // ),
          ),
          Flexible(
            flex: 1,
            child: Column(
              children: [
                ThemePrice(),
                ThemesCarousel(),
                Divider(),
                CurrentCoinCount(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ThemePreview extends StatelessWidget {
  final FiarTheme theme;

  const ThemePreview(this.theme, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: ChangeNotifierProvider.value(
          value: ThemesProvider(overrideTheme: theme),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FittedBox(
                      child: SizedBox(
                        height: deviceSize.height * 0.95,
                        width: deviceSize.width * 1.05,
                        child: MainPagePreview(),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: FittedBox(
                      child: SizedBox(
                        height: deviceSize.height * 0.95,
                        width: deviceSize.width * 1.05,
                        child: PlayingPreview(),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MainPagePreview extends StatelessWidget {
  const MainPagePreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: MainMenu(),
    );
  }
}

class PlayingPreview extends StatefulWidget {
  PlayingPreview({Key? key}) : super(key: key);

  @override
  State<PlayingPreview> createState() => _PlayingPreviewState();
}

class _PlayingPreviewState extends State<PlayingPreview> {
  final FieldPlaying field = FieldPlaying();

  late PlayingStateIntermediate playingState;

  void addChipsLoop() async {
    Random random = new Random();
    field // Initialize
      ..dropChip(0)
      ..dropChip(1)
      ..dropChip(2)
      ..dropChip(6);
    while (true) {
      for (int i = 0; i < 20; i++) {
        int column = random.nextInt(7);
        await Future.delayed(Duration(milliseconds: 1000));
        if (!mounted) return;
        setState(() => field.dropChip(column));
        if (field.checkWin() != null) {
          Future.delayed(Duration(milliseconds: 2000));
          break;
        }
      }
      await Future.delayed(Duration(seconds: 3));
      if (!mounted) return;
      setState(() => field.reset());
    }
  }

  @override
  void initState() {
    super.initState();
    playingState = PlayingStateIntermediate(
      getShowRatingDialog: () => false,
      setShowRatingDialog: (x) {},
      toastState: null,
      field: field,
      me: Player.One,
      dropChip: (x) {},
      opponentInfo: OpponentInfo()
        ..user = PublicUser("", "opponent", GameInfo(1275, 1), FriendState.None),
      connectionLost: false,
      setOpponentUser: (x) {},
      setMuteState: (x) {},
      playAgain: () {},
    );

    addChipsLoop();
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: PlayingViewer(playingState),
    );
  }
}

class ThemePrice extends StatelessWidget {
  const ThemePrice({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('theme price'),
    );
  }
}

class ThemesCarousel extends StatelessWidget {
  const ThemesCarousel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Theme carousel'),
    );
  }
}

class CurrentCoinCount extends StatelessWidget {
  const CurrentCoinCount({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Coin count'),
    );
  }
}
