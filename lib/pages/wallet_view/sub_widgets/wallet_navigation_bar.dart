import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class WalletNavigationBar extends StatelessWidget {
  const WalletNavigationBar({
    Key? key,
    required this.onReceivePressed,
    required this.onSendPressed,
    required this.onExchangePressed,
    required this.onBuyPressed,
    required this.height,
    required this.enableExchange,
  }) : super(key: key);

  final VoidCallback onReceivePressed;
  final VoidCallback onSendPressed;
  final VoidCallback onExchangePressed;
  final VoidCallback onBuyPressed;
  final double height;
  final bool enableExchange;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: CFColors.white,
        boxShadow: const [CFColors.standardBoxShadow],
        borderRadius: BorderRadius.circular(
          height / 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(
              width: 12,
            ),
            RawMaterialButton(
              constraints: const BoxConstraints(
                minWidth: 66,
              ),
              onPressed: onReceivePressed,
              splashColor: CFColors.splashLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  height / 2.0,
                ),
              ),
              child: Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: CFColors.stackAccent.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(
                            24,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: SvgPicture.asset(
                            Assets.svg.arrowDownLeft,
                            width: 12,
                            height: 12,
                            color: CFColors.stackAccent,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "Receive",
                        style: STextStyles.buttonSmall,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            RawMaterialButton(
              constraints: const BoxConstraints(
                minWidth: 66,
              ),
              onPressed: onSendPressed,
              splashColor: CFColors.splashLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  height / 2.0,
                ),
              ),
              child: Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: CFColors.stackAccent.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(
                            24,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: SvgPicture.asset(
                            Assets.svg.arrowUpRight,
                            width: 12,
                            height: 12,
                            color: CFColors.stackAccent,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        "Send",
                        style: STextStyles.buttonSmall,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            if (enableExchange)
              RawMaterialButton(
                constraints: const BoxConstraints(
                  minWidth: 66,
                ),
                onPressed: onExchangePressed,
                splashColor: CFColors.splashLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    height / 2.0,
                  ),
                ),
                child: Container(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(),
                        SvgPicture.asset(
                          Assets.svg.exchange,
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          "Exchange",
                          style: STextStyles.buttonSmall,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(
              width: 12,
            ),
            // TODO: Do not delete this code.
            // only temporarily disabled
            // Spacer(
            //   flex: 2,
            // ),
            // GestureDetector(
            //   onTap: onBuyPressed,
            //   child: Container(
            //     color: Colors.transparent,
            //     child: Padding(
            //       padding: const EdgeInsets.symmetric(vertical: 2.0),
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.center,
            //         children: [
            //           Spacer(),
            //           SvgPicture.asset(
            //             Assets.svg.buy,
            //             width: 24,
            //             height: 24,
            //           ),
            //           SizedBox(
            //             height: 4,
            //           ),
            //           Text(
            //             "Buy",
            //             style: STextStyles.buttonSmall,
            //           ),
            //           Spacer(),
            //         ],
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
//
// class BarButton extends StatelessWidget {
//   const BarButton(
//       {Key? key, required this.icon, required this.text, this.onPressed})
//       : super(key: key);
//
//   final Widget icon;
//   final String text;
//   final VoidCallback? onPressed;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       child: MaterialButton(
//         splashColor: CFColors.splashLight,
//         padding: const EdgeInsets.all(0),
//         minWidth: 45,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(
//             Constants.size.circularBorderRadius,
//           ),
//         ),
//         materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//         onPressed: onPressed,
//         child: Padding(
//           padding: const EdgeInsets.all(4.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               icon,
//               SizedBox(
//                 height: 4,
//               ),
//               Text(
//                 text,
//                 style: STextStyles.itemSubtitle12.copyWith(
//                   fontSize: 10,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
