import 'package:flutter/widgets.dart';

// Resolves a captured media path to an ImageProvider without importing dart:io
// into web builds. On mobile the path is a file path; on web it's a blob URL.
import 'local_image_io.dart' if (dart.library.html) 'local_image_web.dart'
    as impl;

ImageProvider localImageProvider(String path) => impl.localImageProvider(path);
