import 'node_category.dart';
import 'node_template.dart';

const String _triggerStyle =
    'rounded=1;whiteSpace=wrap;html=1;fillColor=#d5e8d4;strokeColor=#82b366;';

const List<NodeTemplate> triggerTemplates = [
  NodeTemplate(
    key: 'webhook',
    displayName: 'Webhook',
    category: NodeCategory.trigger,
    n8nType: 'n8n-nodes-base.webhook',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {'path': 'my-hook', 'httpMethod': 'POST'},
    outputs: 1,
    drawioStyle: _triggerStyle,
  ),
  NodeTemplate(
    key: 'schedule',
    displayName: 'Schedule Trigger',
    category: NodeCategory.trigger,
    n8nType: 'n8n-nodes-base.scheduleTrigger',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 1,
    drawioStyle: _triggerStyle,
  ),
  NodeTemplate(
    key: 'telegramTrigger',
    displayName: 'Telegram Trigger',
    category: NodeCategory.trigger,
    n8nType: 'n8n-nodes-base.telegramTrigger',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 1,
    drawioStyle: _triggerStyle,
  ),
];
