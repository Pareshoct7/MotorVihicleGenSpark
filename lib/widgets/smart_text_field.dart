import 'package:flutter/material.dart';
import '../services/ai_learning_service.dart';

/// Smart TextField with AI-powered auto-complete
/// 
/// This widget learns from user inputs and provides intelligent suggestions
class SmartTextField extends StatefulWidget {
  final String fieldName;
  final String labelText;
  final String? hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enableSuggestions;
  final TextInputType? keyboardType;
  final int? maxLines;
  final Widget? prefixIcon;
  
  const SmartTextField({
    super.key,
    required this.fieldName,
    required this.labelText,
    required this.controller,
    this.hintText,
    this.validator,
    this.enableSuggestions = true,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixIcon,
  });

  @override
  State<SmartTextField> createState() => _SmartTextFieldState();
}

class _SmartTextFieldState extends State<SmartTextField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }
  
  void _onTextChanged() {
    if (!widget.enableSuggestions) return;
    
    final text = widget.controller.text;
    if (text.isEmpty) {
      _suggestions = AILearningService.getTopValues(widget.fieldName);
    } else {
      _suggestions = AILearningService.getSuggestions(widget.fieldName, text);
    }
    
    if (_focusNode.hasFocus) {
      _showSuggestions();
    }
  }
  
  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _onTextChanged();
    } else {
      _hideSuggestions();
      // Record input when field loses focus
      if (widget.controller.text.trim().isNotEmpty) {
        AILearningService.recordInput(widget.fieldName, widget.controller.text.trim());
      }
    }
  }
  
  void _showSuggestions() {
    _hideSuggestions();
    
    if (_suggestions.isEmpty) return;
    
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }
  
  void _hideSuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
  
  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 5.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  final usageCount = AILearningService.getUsageCount(
                    widget.fieldName,
                    suggestion,
                  );
                  
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.history,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(suggestion),
                    trailing: usageCount > 1
                        ? Chip(
                            label: Text(
                              '$usageCount×',
                              style: const TextStyle(fontSize: 10),
                            ),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                          )
                        : null,
                    onTap: () {
                      widget.controller.text = suggestion;
                      _focusNode.unfocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          border: const OutlineInputBorder(),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.enableSuggestions
              ? Tooltip(
                  message: 'AI-powered suggestions',
                  child: Icon(
                    Icons.auto_awesome,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                )
              : null,
        ),
        validator: widget.validator,
      ),
    );
  }
  
  @override
  void dispose() {
    _hideSuggestions();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }
}
