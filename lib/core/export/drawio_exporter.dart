import 'package:xml/xml.dart';

import '../catalog/node_catalog.dart';
import '../catalog/node_category.dart';
import '../models/workflow_model.dart';
import '../models/workflow_node.dart';
import 'node_name_deduplicator.dart';

/// [WorkflowModel] nesnesini sıkıştırılmamış `.drawio` XML formatına çevirir (SDD 5.4).
class DrawioExporter {
  const DrawioExporter();

  static const String _defaultVertexStyle =
      'rounded=1;whiteSpace=wrap;html=1;fillColor=#f5f5f5;strokeColor=#666666;';
  static const String _edgeStyle =
      'edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;';

  static const int _standardWidth = 160;
  static const int _standardHeight = 60;
  static const int _logicWidth = 120;
  static const int _logicHeight = 80;

  /// Modeli geçerli, sıkıştırılmamış `.drawio` XML metnine dönüştürür.
  ///
  /// - Yapı: `mxfile > diagram > mxGraphModel > root > mxCell`
  /// - `<root>` altında zorunlu `<mxCell id="0"/>` ve `<mxCell id="1" parent="0"/>`
  ///   kök hücreleri her zaman bulunur.
  /// - Kategori stilleri katalogdan alınır; IF çıkış kenarları `"true"` / `"false"`
  ///   olarak etiketlenir.
  /// - `& < > "` karakterleri `xml` paketi tarafından otomatik escape edilir.
  String export(WorkflowModel model) {
    final uniqueNames = resolveUniqueNames(model);
    final nodeById = <String, WorkflowNode>{
      for (final node in model.nodes) node.id: node,
    };

    final builder = XmlBuilder();
    builder.element(
      'mxfile',
      attributes: {
        'host': 'app.diagrams.net',
        'agent': 'FlowForge',
      },
      nest: () {
        builder.element(
          'diagram',
          attributes: {
            'id': 'flowforge-diagram',
            'name': model.name,
          },
          nest: () {
            builder.element(
              'mxGraphModel',
              attributes: {
                'dx': '1000',
                'dy': '1000',
                'grid': '1',
                'gridSize': '10',
                'guides': '1',
                'tooltips': '1',
                'connect': '1',
                'arrows': '1',
                'fold': '1',
                'page': '1',
                'pageScale': '1',
                'pageWidth': '850',
                'pageHeight': '1100',
                'math': '0',
                'shadow': '0',
              },
              nest: () {
                builder.element(
                  'root',
                  nest: () {
                    // Zorunlu draw.io kök hücreleri
                    builder.element('mxCell', attributes: {'id': '0'});
                    builder.element(
                      'mxCell',
                      attributes: {'id': '1', 'parent': '0'},
                    );

                    // Vertex (Node) hücreleri
                    for (final node in model.nodes) {
                      final template = NodeCatalog.byKey(node.templateKey);
                      final isLogic = template?.category == NodeCategory.logic;
                      final width = isLogic ? _logicWidth : _standardWidth;
                      final height = isLogic ? _logicHeight : _standardHeight;

                      builder.element(
                        'mxCell',
                        attributes: {
                          'id': 'node_${node.id}',
                          'value': uniqueNames[node.id] ?? node.name,
                          'style': template?.drawioStyle ?? _defaultVertexStyle,
                          'vertex': '1',
                          'parent': '1',
                        },
                        nest: () {
                          builder.element(
                            'mxGeometry',
                            attributes: {
                              'x': '${node.position.dx.round()}',
                              'y': '${node.position.dy.round()}',
                              'width': '$width',
                              'height': '$height',
                              'as': 'geometry',
                            },
                          );
                        },
                      );
                    }

                    // Edge (Bağlantı) hücreleri
                    for (var i = 0; i < model.edges.length; i++) {
                      final edge = model.edges[i];
                      final sourceNode = nodeById[edge.fromId];
                      if (sourceNode == null ||
                          !nodeById.containsKey(edge.toId)) {
                        continue;
                      }

                      var edgeLabel = '';
                      if (sourceNode.templateKey == 'if') {
                        if (edge.outputIndex == 0) {
                          edgeLabel = 'true';
                        } else if (edge.outputIndex == 1) {
                          edgeLabel = 'false';
                        }
                      }

                      builder.element(
                        'mxCell',
                        attributes: {
                          'id': 'edge_$i',
                          'value': edgeLabel,
                          'style': _edgeStyle,
                          'edge': '1',
                          'parent': '1',
                          'source': 'node_${edge.fromId}',
                          'target': 'node_${edge.toId}',
                        },
                        nest: () {
                          builder.element(
                            'mxGeometry',
                            attributes: {
                              'relative': '1',
                              'as': 'geometry',
                            },
                          );
                        },
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
  }
}
