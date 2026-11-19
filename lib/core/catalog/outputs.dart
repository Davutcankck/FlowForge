import 'node_category.dart';
import 'node_template.dart';

const String _outputStyle =
    'rounded=1;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;';

const List<NodeTemplate> outputTemplates = [
  NodeTemplate(
    key: 'respondToWebhook',
    displayName: 'Respond to Webhook',
    category: NodeCategory.output,
    n8nType: 'n8n-nodes-base.respondToWebhook',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 1,
    drawioStyle: _outputStyle,
  ),
];
