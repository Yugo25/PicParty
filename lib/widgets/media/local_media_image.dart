import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Shows a locally picked photo. On web, image_picker returns a blob URL instead of a file path.
class LocalMediaImage extends StatelessWidget {
  final String path;
  final bool video;
  final double? height;
  final BoxFit fit;
  const LocalMediaImage({super.key, required this.path, this.video = false, this.height, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext c) {
    if (video) return Container(height: height ?? 260, width: double.infinity, color: Colors.black12, child: const Icon(Icons.videocam, size: 56));
    return kIsWeb
        ? Image.network(path, height: height, width: double.infinity, fit: fit)
        : Image.file(File(path), height: height, width: double.infinity, fit: fit);
  }
}
