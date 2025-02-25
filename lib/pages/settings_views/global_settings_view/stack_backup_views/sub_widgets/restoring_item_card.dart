import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class RestoringItemCard extends StatelessWidget {
  const RestoringItemCard({
    Key? key,
    required this.left,
    required this.right,
    required this.title,
    this.subTitle,
    this.leftSize = 32.0,
    this.button,
    this.onRightTapped,
  }) : super(key: key);

  final Widget left;
  final Widget right;
  final String title;
  final Text? subTitle;
  final double leftSize;
  final Widget? button;
  final VoidCallback? onRightTapped;

  @override
  Widget build(BuildContext context) {
    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(2),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: leftSize,
                  height: leftSize,
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: STextStyles.titleBold12,
                      ),
                      if (subTitle != null)
                        const SizedBox(
                          height: 2,
                        ),
                      if (subTitle != null) subTitle!,
                      if (button != null)
                        const SizedBox(
                          height: 2,
                        ),
                      if (button != null) button!,
                    ],
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                const SizedBox(
                  width: 20,
                  height: 20,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                left,
              ],
            ),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppBarIconButton(
                  size: 40,
                  color: Colors.transparent,
                  icon: right,
                  onPressed: onRightTapped,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
