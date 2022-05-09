import 'dart:math';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/play/models/common/field.dart';
import 'package:four_in_a_row/play/models/common/player.dart';
import 'package:four_in_a_row/play/models/online/game_states/playing.dart';
import 'package:four_in_a_row/play/widgets/online/viewer.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:four_in_a_row/providers/user.dart';
import 'package:four_in_a_row/util/extensions.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:provider/provider.dart';

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

  late int selectedThemeIndex;

  @override
  void initState() {
    super.initState();

    selectedThemeIndex = widget.themes.allThemes.indexWhere((t) => t.id == "default");
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
        mainAxisSize: MainAxisSize.max,
        children: [
          CurrentCoinCount(),
          Expanded(
            // child: AbsorbPointer(
            child: PageView(
              controller: themePreviewPageController,
              children: widget.themes.allThemes.map((theme) => ThemePreview(theme)).toList(),
            ),
          ),
          // ),
          // Flexible(
          //   flex: 3,
          // child:

          ThemesCarousel(
            allThemes: widget.themes.allThemes,
            selectedIndex: selectedThemeIndex,
            onThemeSelected: (selectedThemeIndex) {
              themePreviewPageController.animateToPage(
                selectedThemeIndex,
                curve: Curves.easeInOut,
                duration: Duration(milliseconds: 220),
              );
              setState(() => this.selectedThemeIndex = selectedThemeIndex);
            },
          ),
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
      decoration: BoxDecoration(
          // TODO
          ),
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text('200 ©'),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text('Get more!'),
              ),
            ],
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
  Map<FiarThemeCategory, List<FiarTheme>> get categorizedThemes =>
      allThemes.groupBy((t) => t.category);
  final int selectedIndex;
  final void Function(int) onThemeSelected;

  ThemesCarousel({
    Key? key,
    required this.allThemes,
    required this.selectedIndex,
    required this.onThemeSelected,
  }) : super(key: key);

  @override
  State<ThemesCarousel> createState() => _ThemesCarouselState();
}

class _ThemesCarouselState extends State<ThemesCarousel> {
  late final LinkedScrollControllerGroup _controllers;
  late final ScrollController _categories;
  late final ScrollController _themes;
  final double themesCarouselItemWidth = 96 + 24.0;

  double offset = 0;
  Map<int, double> categoriesMaxWidths = {};

  @override
  void initState() {
    super.initState();
    _controllers = LinkedScrollControllerGroup()
      ..addOffsetChangedListener(() {
        setState(() => offset = _controllers.offset);
      });
    _categories = _controllers.addAndGet();
    _themes = _controllers.addAndGet();
  }

  @override
  void didUpdateWidget(ThemesCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      double screenWidth = MediaQuery.of(context).size.width;

      _controllers.animateTo(
        max(
            0,
            widget.selectedIndex * themesCarouselItemWidth -
                (screenWidth / 2) +
                (themesCarouselItemWidth / 2)),
        curve: Curves.easeInOut,
        duration: Duration(milliseconds: 220),
      );
    }
  }

  @override
  void dispose() {
    _categories.dispose();
    _themes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 128,
      // height: double.infinity,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: ListView.builder(
                controller: _categories,
                scrollDirection: Axis.horizontal,
                itemCount: widget.categorizedThemes.keys.length,
                itemBuilder: (_, index) {
                  FiarThemeCategory category = widget.categorizedThemes.keys.toList()[index];
                  double relativeOffset = offset -
                      widget.allThemes.takeWhile((theme) => theme.category != category).length *
                          themesCarouselItemWidth;
                  double boxWidth =
                      widget.categorizedThemes[category]!.length * themesCarouselItemWidth;
                  return Container(
                    padding: const EdgeInsets.only(top: 8, bottom: 5),
                    width: boxWidth,
                    child: Stack(
                      children: [
                        Opacity(
                          opacity: 0.00001, // Don't skip laying out the widget
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: LayoutBuilder(
                                  builder: (_, constraints) {
                                    categoriesMaxWidths[index] =
                                        constraints.maxWidth - 24; // padding
                                    return SizedBox();
                                  },
                                ),
                              ),
                              CategoryTitle(category: category),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            SizedBox(
                                width: max(
                                    0,
                                    min(relativeOffset,
                                        categoriesMaxWidths.getOrNull(index) ?? 0))),
                            CategoryTitle(category: category),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 96,
              child: ListView.builder(
                controller: _themes,
                scrollDirection: Axis.horizontal,
                itemCount: widget.allThemes.length,
                itemBuilder: (_, index) {
                  var theme = widget.allThemes[index];
                  return ThemesCarouselItem(
                    theme,
                    onClick: () {
                      widget.onThemeSelected(index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTitle extends StatelessWidget {
  const CategoryTitle({
    Key? key,
    required this.category,
  }) : super(key: key);

  final FiarThemeCategory category;

  @override
  Widget build(BuildContext context) {
    return Text(
      category.name,
      style: TextStyle(
        fontFamily: 'RobotoSlab',
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class ThemesCarouselItem extends StatelessWidget {
  final FiarTheme theme;
  final void Function() onClick;

  ThemesCarouselItem(this.theme, {required this.onClick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 24),
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: onClick,
          child: Container(
            width: 96,

            color: theme.category == FiarThemeCategory.FREE ? Colors.green : Colors.red,
            // child:
            //     Stack(
            //       children: [GridView(
            //     // mainAxisSize: MainAxisSize.min,
            //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            //       crossAxisCount: 2,
            //     ),
            //     children: [
            //       GameChipStatic(Colors.lightBlue),
            //       GameChipStatic(Colors.lightBlue),
            //       GameChipStatic(Colors.lightBlue),
            //       GameChipStatic(Colors.lightBlue),
            //       // GameChipStatic(theme.playerOneColor),
            //       // GameChipStatic(theme.playerTwoColor),
            //       // GameChipStatic(theme.playerTwoColor),
            //       // GameChipStatic(theme.playerOneColor),
            //     ],
            //   ),
            // ),
            // Positioned(
            //   bottom: 0,
            //   left: 0,
            //   right: 0,
            //   child: Center(
            //     child: Text(
            //       theme.name,
            //       style: TextStyle(
            //         // fontSize: 16,
            //         fontFamily: "RobotoSlab",
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //   ),
            // ),
            //   ],
            // ),
          ),
        ),
      ),
    );
  }
}
