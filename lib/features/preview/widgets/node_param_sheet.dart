import 'package:flutter/material.dart';

import '../../../core/catalog/node_catalog.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/models/workflow_node.dart';

/// Bir düğüme dokunulduğunda parametrelerini düzenlemeyi sağlayan bottom sheet (FR-11, SDD 6.1).
class NodeParamSheet extends StatefulWidget {
  const NodeParamSheet({
    super.key,
    required this.node,
    required this.lang,
    required this.onSave,
  });

  final WorkflowNode node;
  final AppLang lang;
  final ValueChanged<Map<String, dynamic>> onSave;

  @override
  State<NodeParamSheet> createState() => _NodeParamSheetState();
}

class _NodeParamSheetState extends State<NodeParamSheet> {
  late final List<String> _requiredKeys;
  late final Map<String, TextEditingController> _controllers;
  final TextEditingController _newKeyController = TextEditingController();
  final TextEditingController _newValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final template = NodeCatalog.byKey(widget.node.templateKey);
    _requiredKeys = List<String>.from(template?.requiredParameters ?? const []);

    final orderedKeys = <String>[
      ..._requiredKeys,
      ...widget.node.parameters.keys.where((k) => !_requiredKeys.contains(k)),
    ];

    _controllers = {
      for (final key in orderedKeys)
        key: TextEditingController(
          text: widget.node.parameters[key]?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _newKeyController.dispose();
    _newValueController.dispose();
    super.dispose();
  }

  void _addCustomParameter() {
    final key = _newKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() {
      final existing = _controllers[key];
      if (existing != null) {
        existing.text = _newValueController.text.trim();
      } else {
        _controllers[key] = TextEditingController(
          text: _newValueController.text.trim(),
        );
      }
      _newKeyController.clear();
      _newValueController.clear();
    });
  }

  void _handleSave() {
    final updated = <String, dynamic>{
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };
    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.node.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.node.templateKey,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.lookup('common.close', lang),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_controllers.isEmpty)
              Container(
                key: const Key('empty_params_info'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppStrings.lookup('params.emptyInfo', lang),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final entry in _controllers.entries) ...[
                TextField(
                  key: Key('param_field_${entry.key}'),
                  controller: entry.value,
                  decoration: InputDecoration(
                    labelText: _requiredKeys.contains(entry.key)
                        ? '${entry.key} *'
                        : entry.key,
                    helperText: _requiredKeys.contains(entry.key)
                        ? AppStrings.lookup('params.requiredHelper', lang)
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 8),
            Text(
              AppStrings.lookup('params.addCustomTitle', lang),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('custom_param_key_field'),
                    controller: _newKeyController,
                    decoration: InputDecoration(
                      labelText: AppStrings.lookup('params.keyLabel', lang),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const Key('custom_param_value_field'),
                    controller: _newValueController,
                    decoration: InputDecoration(
                      labelText: AppStrings.lookup('params.valueLabel', lang),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  key: const Key('add_custom_param_button'),
                  tooltip: AppStrings.lookup('params.addTooltip', lang),
                  icon: const Icon(Icons.add_rounded),
                  onPressed: _addCustomParameter,
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('save_node_params_button'),
              onPressed: _handleSave,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(AppStrings.lookup('params.saveButton', lang)),
            ),
          ],
        ),
      ),
    );
  }
}
