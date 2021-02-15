import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MenuWrapper extends StatelessWidget {
  final Widget child;
  MenuWrapper({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color bgCol = Color(0xFFFDFDFD);

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
  final opacityTween =
      Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.ease));
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

class CustomAppBar extends AppBar {
  final List<CustomThreeDot> threeDots;

  CustomAppBar({
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
                  ? Transform.scale(
                      scale: 0.7, child: CircularProgressIndicator())
                  : SizedBox(),
            ),
            threeDots.isNotEmpty
                ? PopupMenuButton(
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
                        .toList())
                : SizedBox(),
          ],
        );
}

class CustomThreeDot {
  final String label;
  final VoidCallback onTap;

  CustomThreeDot(this.label, {required this.onTap});
}

void showFeedbackDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => FeedbackDialog(),
  );
}

class FeedbackDialog extends StatefulWidget {
  @override
  _FeedbackDialogState createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog>
    with SingleTickerProviderStateMixin {
  bool done = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      vsync: this,
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
                        child: Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      ElevatedButton(
                        child: Text('Send'),
                        onPressed: () {
                          setState(() => done = true);
                          // TODO send feedback
                          Future.delayed(Duration(milliseconds: 800), () {
                            Navigator.of(context).pop();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
