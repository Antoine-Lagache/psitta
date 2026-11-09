import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const SettingsSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class NumericSliderSetting extends StatefulWidget {
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final int sliderMax;
  final bool enabled;
  final bool allowNegative;
  final String helperText;
  final ValueChanged<int> onChanged;

  const NumericSliderSetting({
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.sliderMax,
    required this.enabled,
    required this.allowNegative,
    required this.helperText,
    required this.onChanged,
  });

  @override
  State<NumericSliderSetting> createState() => NumericSliderSettingState();
}

class NumericSliderSettingState extends State<NumericSliderSetting> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;
  late int _displayValue;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _displayValue = widget.value;
    _textController = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant NumericSliderSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focusNode.hasFocus) {
      _displayValue = widget.value;
      _textController.text = '${widget.value}';
      _errorText = null;
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) _commit();
  }

  void _commit() {
    final parsed = int.tryParse(_textController.text);
    if (parsed == null || parsed < widget.minValue || parsed > widget.maxValue) {
      setState(() {
        _errorText =
            'Enter a whole number from ${widget.minValue} to ${widget.maxValue}.';
        _textController.text = '${widget.value}';
      });
      return;
    }
    setState(() {
      _errorText = null;
      _displayValue = parsed;
      _textController.text = '$parsed';
    });
    if (parsed != widget.value) widget.onChanged(parsed);
  }

  void _setFromSlider(double value) {
    final next = value.round();
    setState(() {
      _displayValue = next;
      _textController.text = '$next';
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sliderValue = _displayValue < 0
        ? widget.sliderMax.toDouble()
        : _displayValue.clamp(0, widget.sliderMax).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.label)),
              const SizedBox(width: 16),
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.numberWithOptions(
                    signed: widget.allowNegative,
                  ),
                  textInputAction: TextInputAction.done,
                  inputFormatters: widget.allowNegative
                      ? [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return RegExp(r'^-?[0-9]*$').hasMatch(newValue.text)
                                ? newValue
                                : oldValue;
                          }),
                        ]
                      : [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _commit(),
                ),
              ),
            ],
          ),
          Slider(
            value: sliderValue,
            min: 0,
            max: widget.sliderMax.toDouble(),
            divisions: widget.sliderMax,
            label: _displayValue < 0 ? 'No limit' : '$_displayValue',
            onChanged: widget.enabled ? _setFromSlider : null,
            onChangeEnd: widget.enabled
                ? (value) => widget.onChanged(value.round())
                : null,
          ),
          Text(
            _errorText ?? widget.helperText,
            style: _errorText == null
                ? Theme.of(context).textTheme.bodySmall
                : Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
          ),
        ],
      ),
    );
  }
}
