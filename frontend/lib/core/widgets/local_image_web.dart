import 'package:flutter/widgets.dart';

// On web a captured XFile.path is a blob: URL that NetworkImage can load.
ImageProvider localImageProvider(String path) => NetworkImage(path);
