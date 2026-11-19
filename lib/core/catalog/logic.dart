import 'node_category.dart';
import 'node_template.dart';

const String _logicStyle =
    'rhombus;whiteSpace=wrap;html=1;fillColor=#fff2cc;strokeColor=#d6b656;';

const List<NodeTemplate> logicTemplates = [
  NodeTemplate(
    key: 'if',
    displayName: 'IF',
    category: NodeCategory.logic,
    n8nType: 'n8n-nodes-base.if',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 2,
    drawioStyle: _logicStyle,
  ),
  NodeTemplate(
    key: 'set',
    displayName: 'Edit Fields (Set)',
    category: NodeCategory.logic,
    n8nType: 'n8n-nodes-base.set',
    typeVersion: 1, // TODO(verify-n8n)
    defaultParameters: {},
    outputs: 1,
    drawioStyle: _logicStyle,
  ),
];
