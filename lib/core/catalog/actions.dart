import 'node_category.dart';
import 'node_template.dart';

const String _actionStyle =
    'rounded=1;whiteSpace=wrap;html=1;fillColor=#dae8fc;strokeColor=#6c8ebf;';

const List<NodeTemplate> actionTemplates = [
  NodeTemplate(
    key: 'httpRequest',
    displayName: 'HTTP Request',
    category: NodeCategory.action,
    n8nType: 'n8n-nodes-base.httpRequest',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {'url': '', 'method': 'GET'},
    requiredParameters: ['url'],
    outputs: 1,
    drawioStyle: _actionStyle,
  ),
  NodeTemplate(
    key: 'gmail',
    displayName: 'Gmail',
    category: NodeCategory.action,
    n8nType: 'n8n-nodes-base.gmail',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 1,
    drawioStyle: _actionStyle,
  ),
  NodeTemplate(
    key: 'googleSheets',
    displayName: 'Google Sheets',
    category: NodeCategory.action,
    n8nType: 'n8n-nodes-base.googleSheets',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 1,
    drawioStyle: _actionStyle,
  ),
  NodeTemplate(
    key: 'telegram',
    displayName: 'Telegram',
    category: NodeCategory.action,
    n8nType: 'n8n-nodes-base.telegram',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 1,
    drawioStyle: _actionStyle,
  ),
];
