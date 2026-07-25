import 'dart:io';

import 'package:flutter/widgets.dart';

ImageProvider localImageProvider(String path) => FileImage(File(path));
