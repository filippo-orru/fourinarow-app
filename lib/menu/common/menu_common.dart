import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:four_in_a_row/providers/themes.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:four_in_a_row/play/models/online/game_state_manager.dart';
import 'package:four_in_a_row/util/constants.dart';

class MenuWrapper extends StatelessWidget {
  final Widget child;
  MenuWrapper({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgCol = context.watch<ThemesProvider>().selectedTheme.menuBackgroundColor;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Theme(
        data: ThemeData(
          backgroundColor: bgCol,
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            color: bgCol,
            child: Center(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class ArmsButton extends StatefulWidget {
  final String label;
  final void Function()? callback;

  ArmsButton(this.label, {Key? key, this.callback}) : super(key: key);

  @override
  _ArmsButtonState createState() => _ArmsButtonState();
}

class _ArmsButtonState extends State<ArmsButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 12),
      child: GestureDetector(
        onTap: widget.callback,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          decoration: BoxDecoration(
              // color: Colors.black,
              border: Border.all(
                color: Colors.black,
                width: 2,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              )),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              // color: Theme.of(context).backgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

PageRouteBuilder fadeRoute(Widget child, {int millDuration = 300}) {
  final opacityTween = Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.ease));
  // final sizeTween =
  //     Tween<double>(begin: 0.9, end: 1).chain(CurveTween(curve: Curves.ease));
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionDuration: Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation.drive(opacityTween),
        child: child,
      );
    },
  );
}

class FiarAppBar extends AppBar {
  final List<FiarThreeDotItem> threeDots;

  FiarAppBar({
    required String title,
    this.threeDots = const [],
    bool refreshing = false,
    Key? key,
  }) : super(
          key: key,
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,
          iconTheme: IconThemeData(color: Colors.black),
          title: Text(title,
              style: TextStyle(
                fontFamily: "RobotoSlab",
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
          actions: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: refreshing
                  ? Transform.scale(scale: 0.7, child: CircularProgressIndicator())
                  : SizedBox(),
            ),
            threeDots.isNotEmpty ? FiarPopupMenuButton(threeDots) : SizedBox(),
          ],
        );
}

class FiarThreeDotItem {
  final String label;
  final VoidCallback onTap;

  FiarThreeDotItem(this.label, {required this.onTap});
}

class FiarPopupMenuButton extends PopupMenuButton {
  final List<FiarThreeDotItem> threeDots;

  FiarPopupMenuButton(this.threeDots)
      : super(
            onSelected: (index) => threeDots[index as int].onTap(),
            itemBuilder: (_) => threeDots
                .asMap()
                .map((index, customDot) => MapEntry(
                    index,
                    PopupMenuItem(
                      value: index,
                      child: Text(customDot.label),
                      height: kToolbarHeight,
                    )))
                .values
                .toList());
}

void showFeedbackDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => FeedbackDialog(),
  );
}

class FeedbackDialog extends StatefulWidget {
  static Future<void> sendRequest(Map body) async {
    await http.post(Uri.parse(HTTP_URL + "/api/feedback"),
        body: jsonEncode(body), headers: {"Content-Type": "application/json"});
  }

  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> with SingleTickerProviderStateMixin {
  bool done = false;

  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();

    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      child: AnimatedSwitcher(
        key: ValueKey(done),
        duration: Duration(milliseconds: 100),
        child: done
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Thanks!", style: TextStyle(color: Colors.black)),
              )
            : SimpleDialog(
                title: Text(
                  'Feedback',
                  style: TextStyle(
                    fontFamily: 'RobotoSlab',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                contentPadding: EdgeInsets.all(16),
                children: [
                  Text(
                      "I'm very happy about any feedback! Tell me what you like or dislike about the game :)"),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(hintText: "Any feedback..."),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          primary: Colors.black87,
                        ),
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          primary: context.watch<ThemesProvider>().selectedTheme.accentColor,
                        ),
                        onPressed: () async {
                          Map<String, String> body = {
                            "content": controller.text,
                          };
                          var user = context.read<GameStateManager>().userInfo.user;
                          if (user != null) {
                            body["user_id"] = user.id;
                          }
                          await FeedbackDialog.sendRequest(body);
                          setState(() => done = true);

                          Future.delayed(Duration(milliseconds: 400), () {
                            if (mounted) Navigator.of(context).pop();
                          });
                        },
                        child: Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
