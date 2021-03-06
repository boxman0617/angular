library angular2.transform.directive_metadata_extractor.transformer;

import 'dart:async';
import 'dart:convert';

import 'package:angular2/src/render/dom/convert.dart';
import 'package:angular2/src/transform/common/asset_reader.dart';
import 'package:angular2/src/transform/common/logging.dart' as log;
import 'package:angular2/src/transform/common/names.dart';
import 'package:barback/barback.dart';

import 'extractor.dart';

/// Transformer responsible for processing .ng_deps.dart files created by
/// {@link DirectiveProcessor} and creating associated `.ng_meta.dart` files.
/// These files contain commented Json-formatted representations of all
/// `Directive`s in the associated file.
class DirectiveMetadataExtractor extends Transformer {
  final _encoder = const JsonEncoder.withIndent('  ');

  DirectiveMetadataExtractor();

  @override
  bool isPrimary(AssetId id) => id.path.endsWith(DEPS_EXTENSION);

  @override
  Future apply(Transform transform) async {
    log.init(transform);

    try {
      var reader = new AssetReader.fromTransform(transform);
      var fromAssetId = transform.primaryInput.id;

      var metadataMap = await extractDirectiveMetadata(reader, fromAssetId);
      if (metadataMap != null) {
        var jsonMap = <String, Map>{};
        metadataMap.forEach((k, v) {
          jsonMap[k] = directiveMetadataToMap(v);
        });
        transform.addOutput(new Asset.fromString(
            _outputAssetId(fromAssetId), _encoder.convert(jsonMap)));
      }
    } catch (ex, stackTrace) {
      log.logger.error('Extracting ng metadata failed.\n'
          'Exception: $ex\n'
          'Stack Trace: $stackTrace');
    }
    return null;
  }
}

AssetId _outputAssetId(AssetId inputAssetId) {
  assert(inputAssetId.path.endsWith(DEPS_EXTENSION));
  return new AssetId(inputAssetId.package, toMetaExtension(inputAssetId.path));
}
