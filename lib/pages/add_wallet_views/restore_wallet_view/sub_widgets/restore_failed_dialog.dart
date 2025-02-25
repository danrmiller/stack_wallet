import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class RestoreFailedDialog extends ConsumerStatefulWidget {
  const RestoreFailedDialog({
    Key? key,
    required this.errorMessage,
    required this.walletName,
    required this.walletId,
  }) : super(key: key);

  final String errorMessage;
  final String walletName;
  final String walletId;

  @override
  ConsumerState<RestoreFailedDialog> createState() =>
      _RestoreFailedDialogState();
}

class _RestoreFailedDialogState extends ConsumerState<RestoreFailedDialog> {
  late final String errorMessage;
  late final String walletName;
  late final String walletId;

  @override
  void initState() {
    errorMessage = widget.errorMessage;
    walletName = widget.walletName;
    walletId = widget.walletId;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: StackDialog(
        title: "Restore failed",
        message: errorMessage,
        rightButton: TextButton(
          style: Theme.of(context).textButtonTheme.style?.copyWith(
                backgroundColor: MaterialStateProperty.all<Color>(
                  CFColors.buttonGray,
                ),
              ),
          child: Text(
            "Ok",
            style: STextStyles.itemSubtitle12,
          ),
          onPressed: () async {
            ref
                .read(walletsChangeNotifierProvider.notifier)
                .removeWallet(walletId: walletId);

            await ref.read(walletsServiceChangeNotifierProvider).deleteWallet(
                  walletName,
                  false,
                );
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
    );
  }
}
