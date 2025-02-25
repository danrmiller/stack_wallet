import 'package:flutter/material.dart';
import 'package:stackwallet/utilities/cfcolors.dart';

class DraggableSwitchButton extends StatefulWidget {
  const DraggableSwitchButton({
    Key? key,
    this.onItem,
    this.offItem,
    this.onValueChanged,
    required this.isOn,
    this.enabled = true,
    this.controller,
  }) : super(key: key);

  final Widget? onItem;
  final Widget? offItem;
  final void Function(bool)? onValueChanged;
  final bool isOn;
  final bool enabled;
  final DSBController? controller;

  @override
  DraggableSwitchButtonState createState() => DraggableSwitchButtonState();
}

class DraggableSwitchButtonState extends State<DraggableSwitchButton> {
  late bool _isOn;
  bool get isOn => _isOn;

  late bool _enabled;

  late ValueNotifier<double> valueListener;

  final tapAnimationDuration = const Duration(milliseconds: 150);
  bool _isDragging = false;

  Color _colorBG(bool isOn, bool enabled, double alpha) {
    if (enabled) {
      return Color.alphaBlend(
        CFColors.primary.withOpacity(alpha),
        CFColors.primaryLight,
      );
    }
    return CFColors.neutral80;
  }

  Color _colorFG(bool isOn, bool enabled, double alpha) {
    if (enabled) {
      return Color.alphaBlend(
        CFColors.primaryLight.withOpacity(alpha),
        CFColors.white,
      );
    }
    return CFColors.white;
  }

  @override
  initState() {
    _isOn = widget.isOn;
    _enabled = widget.enabled;
    valueListener = _isOn ? ValueNotifier(1.0) : ValueNotifier(0.0);

    widget.controller?.activate = () {
      _isOn = !_isOn;
      // widget.onValueChanged?.call(_isOn);
      valueListener.value = _isOn ? 1.0 : 0.0;
    };
    super.initState();
  }

  @override
  void dispose() {
    valueListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return GestureDetector(
      onTap: () {
        _isOn = !_isOn;
        widget.onValueChanged?.call(_isOn);
        valueListener.value = _isOn ? 1.0 : 0.0;
      },
      child: LayoutBuilder(
        builder: (context, constraint) {
          return Stack(
            children: [
              AnimatedBuilder(
                animation: valueListener,
                builder: (context, child) {
                  return AnimatedContainer(
                    duration: tapAnimationDuration,
                    height: constraint.maxHeight,
                    width: constraint.maxWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        constraint.maxHeight / 2,
                      ),
                      color: _colorBG(_isOn, _enabled, valueListener.value),
                    ),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final handle = GestureDetector(
                    key: const Key("draggableSwitchButtonSwitch"),
                    onHorizontalDragStart: (_) => _isDragging = true,
                    onHorizontalDragUpdate: (details) {
                      valueListener.value = (valueListener.value +
                              details.delta.dx / constraint.maxWidth)
                          .clamp(0.0, 1.0);
                    },
                    onHorizontalDragEnd: (details) {
                      bool oldValue = _isOn;
                      if (valueListener.value > 0.5) {
                        valueListener.value = 1.0;
                        _isOn = true;
                      } else {
                        valueListener.value = 0.0;
                        _isOn = false;
                      }
                      if (_isOn != oldValue) {
                        widget.onValueChanged?.call(_isOn);
                      }
                      _isDragging = false;
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: AnimatedBuilder(
                        animation: valueListener,
                        builder: (context, child) {
                          return AnimatedContainer(
                            duration: tapAnimationDuration,
                            height: constraint.maxHeight - 4,
                            width: constraint.maxWidth / 2 - 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                constraint.maxHeight / 2,
                              ),
                              color: _colorFG(
                                  _isOn, _enabled, valueListener.value),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                  return AnimatedBuilder(
                    animation: valueListener,
                    builder: (context, child) {
                      return AnimatedAlign(
                        duration:
                            _isDragging ? Duration.zero : tapAnimationDuration,
                        alignment: Alignment(valueListener.value * 2 - 1, 0.5),
                        child: child,
                      );
                    },
                    child: handle,
                  );
                },
              ),
              IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: constraint.maxWidth / 2,
                      child: Center(
                        child: widget.onItem,
                      ),
                    ),
                    SizedBox(
                      width: constraint.maxWidth / 2,
                      child: Center(
                        child: widget.offItem,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DSBController {
  VoidCallback? activate;
}
