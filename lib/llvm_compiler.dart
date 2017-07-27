import 'dart:async';
import 'dart:io' as io;
import 'package:analyzer/file_system/file_system.dart' hide File;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'src/context.dart';
export 'src/compiler.dart';

Future<CompilerContext> buildContext(io.File file) async {
  var resourceProvider = PhysicalResourceProvider.INSTANCE;
  var dartExecutable = new io.File(io.Platform.resolvedExecutable);
  var dartBinDir = dartExecutable.parent;
  var dartSdkDir = dartBinDir.parent;
  var sdk = new FolderBasedDartSdk(
      resourceProvider, resourceProvider.getFolder(dartSdkDir.absolute.path));

  var resolvers = [
    new DartUriResolver(sdk),
    new ResourceUriResolver(resourceProvider)
  ];

  var builder = new ContextBuilder(resourceProvider, null, null);
  String pubCachePath;

  if (io.Platform.isWindows) {
    var appDataDir = new io.Directory(io.Platform.environment['APPDATA']);
    pubCachePath = appDataDir.uri.resolve('Pub/Cache').toFilePath();
  } else {
    var homeDir = new io.Directory(io.Platform.environment['HOME']);
    pubCachePath = homeDir.uri.resolve('.pub-cache').toFilePath();
  }

  var packageMap =
      builder.convertPackagesToMap(builder.createPackageMap(pubCachePath));

  var packageResolver = new PackageMapUriResolver(resourceProvider, packageMap);
  resolvers.add(packageResolver);
  var sourceFactory = new SourceFactory(resolvers);
  var analysisContext = AnalysisEngine.instance.createAnalysisContext();
  analysisContext.sourceFactory = sourceFactory;
  var source = new FileSource(resourceProvider.getFile(file.absolute.path));
  var changeSet = new ChangeSet()..addedSource(source);
  analysisContext.applyChanges(changeSet);

  var libraryElement = analysisContext.computeLibraryElement(source);
  var compilationUnit =
      analysisContext.resolveCompilationUnit(source, libraryElement);

  var ctx = new CompilerContext();
  ctx.analysisContext = analysisContext;
  ctx.compilationUnit = compilationUnit;
  return ctx;
}
