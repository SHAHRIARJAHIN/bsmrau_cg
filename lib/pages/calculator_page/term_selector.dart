import 'package:bsmrau_cg/providers/calculator_provider.dart';
import 'package:bsmrau_cg/widgets/action_button.dart';
import 'package:bsmrau_cg/widgets/alert_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TermSelector extends StatelessWidget {
  const TermSelector({
    Key? key,
    required this.screenHeight,
    required this.screenWidth,
  }) : super(key: key);

  final double screenHeight;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final state = context.read<CalculatorState>();
    final termName =
        context.select<CalculatorState, String>((value) => value.termName);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ActionButton(
              icon: Icons.skip_previous,
              onPressed: state.showPrevButton ? () => state.prevTerm() : null),
          ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                  fixedSize: Size.fromWidth(screenWidth / 10 * 6),
                  elevation: 5.0),
              child: Text(termName)),
          ActionButton(
            icon: Icons.skip_next,
            onPressed: () => showDialog(
                context: context,
                builder: (_) => CustomAlertDialogue(
                      details: '',
                      onPressed: () {},
                    )),
            // onPressed: state.showNextButton ? () => state.nextTerm() : null,
          )
        ],
      ),
    );
  }
}
