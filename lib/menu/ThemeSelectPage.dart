import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/game_chip.dart';
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
  final ThemesProvider themes;

  const ThemeSelectPage({required this.themes, Key? key}) : super(key: key);

  @override
  _ThemeSelectPageState createState() => _ThemeSelectPageState();
}

class _ThemeSelectPageState extends State<ThemeSelectPage> {
  final PageController themePreviewPageController = PageController();

  String selectedThemeId = "default";
  int get selectedThemeIndex => widget.themes.allThemes.indexWhere((t) => t.id == selectedThemeId);

  @override
  void initState() {
    super.initState();

    selectedThemeId = widget.themes.selectedTheme.id;
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
          CurrentCoinCount(),
          Flexible(
            flex: 4,
            // child: AbsorbPointer(
            child: PageView(
              controller: themePreviewPageController,
              children: widget.themes.allThemes.map((theme) => ThemePreview(theme)).toList(),
            ),
            // ),
          ),
          Flexible(
            flex: 3,
            child: ThemesCarousel(allThemes: widget.themes.allThemes, selectedId: selectedThemeId),
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

class ThemesCarousel extends StatefulWidget {
  final List<FiarTheme> allThemes;
  final String selectedId;

  const ThemesCarousel({Key? key, required this.allThemes, required this.selectedId})
      : super(key: key);

  @override
  State<ThemesCarousel> createState() => _ThemesCarouselState();
}

class _ThemesCarouselState extends State<ThemesCarousel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: Offset(0, -1),
            spreadRadius: 1,
            color: Colors.black26,
          )
        ],
      ),
      child: Container(
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: widget.allThemes.map((theme) => ThemesCarouselItem(theme)).toList(),
        ),
      ),
    );
  }
}

class ThemesCarouselItem extends StatelessWidget {
  final FiarTheme theme;

  ThemesCarouselItem(this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      width: 64,
      child: Stack(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameChipStatic(theme.playerOneColor),
                    GameChipStatic(theme.playerTwoColor),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GameChipStatic(theme.playerTwoColor),
                    GameChipStatic(theme.playerOneColor),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Text(theme.name),
            ),
          )
        ],
      ),
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
