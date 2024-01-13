import 'package:flutter/material.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';

class ConfirmAgeDialog extends StatefulWidget {
  @override
  _ConfirmAgeDialogState createState() => _ConfirmAgeDialogState();
}

class _ConfirmAgeDialogState extends State<ConfirmAgeDialog> {
  DateTime? dateOfBirth;
  bool get oldEnough =>
      dateOfBirth != null && DateTime.now().difference(dateOfBirth!).inDays > 13 * 365;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(
        'Confirm your age',
        style: TextStyle(
          fontFamily: 'RobotoSlab',
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      contentPadding: EdgeInsets.all(16),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parts of the app allow anonymous posting of short messages that can be read by anyone currently '
                'online and will be deleted once you close the app.\n'
                'Online interaction can be dangerous. Do not share personal information and never meet up '
                'with someone you\'ve met online without a parent or guardian present.',
              ),
              SizedBox(height: 16),
              Text(
                'Please enter your date of birth.',
                style: TextStyle(
                  fontFamily: 'RobotoSlab',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Center(
                child: Container(
                  width: 400,
                  child: CalendarDatePicker(
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    onDateChanged: (date) => setState(() => dateOfBirth = date),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (dateOfBirth != null) ...[
                    Text(
                        "You are ${DateTime.now().difference(dateOfBirth!).inDays ~/ 365} years old. "),
                    SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: dateOfBirth != null
                        ? () {
                            FiarSharedPrefs.socialFeatures
                                .set(oldEnough ? SocialFeatures.Allow : SocialFeatures.DontAllow);
                          }
                        : null,
                    child: Text('Continue'),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }
}
