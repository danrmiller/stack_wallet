import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

class AddressBookIcon extends StatelessWidget {
  const AddressBookIcon({
    Key? key,
    this.width = 16,
    this.height = 16,
    this.color = CFColors.neutral50,
  }) : super(key: key);

  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      Assets.svg.addressBook,
      width: width,
      height: height,
      color: color,
    );
  }
}
