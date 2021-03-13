// ignore: import_of_legacy_library_into_null_safe
import 'package:android_intent/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:platform/platform.dart';

class OutDatedDialog extends StatelessWidget {
  final isAndroid = LocalPlatform().isAndroid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100]!,
      body: Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: 64,
                color: Colors.black12,
              ),
              BoxShadow(
                blurRadius: 16,
                color: Colors.black26,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🎉 Great news! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'There\'s a new version of the game out now with new features!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 48),
              Text(
                'To play online, please update the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700]!,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 18),
              isAndroid
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueAccent,
                        padding:
                            EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                      ),
                      onPressed: () async {
                        AndroidIntent intent = AndroidIntent(
                          action: 'action_view',
                          data: 'https://play.google.com/store/apps/details?'
                              'id=ml.fourinarow',
                        );
                        await intent.launch();
                      },
                      child: Text('Update',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          )),
                    )
                  : Text('[ Please update the app manually ]'),
            ],
          ),
        ),
      ),
    );
  }
}
