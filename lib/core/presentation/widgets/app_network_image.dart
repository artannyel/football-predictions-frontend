import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'web_image_renderer.dart'
    if (dart.library.html) 'web_image_renderer_web.dart';

class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return renderWebImage(url, width, height, fit);
    }

    if (url.toLowerCase().endsWith('.svg')) {
      // Usa o Cache Manager para baixar e cachear o arquivo SVG
      return FutureBuilder<File>(
        future: DefaultCacheManager().getSingleFile(url),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              width: width,
              height: height,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return errorWidget ??
                SizedBox(
                  width: width,
                  height: height,
                  child: const Icon(Icons.broken_image, size: 20),
                );
          }
          return SvgPicture.file(
            snapshot.data! as dynamic,
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    }

    // Usa CachedNetworkImage para imagens raster (JPG, PNG, etc.)
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          const Icon(Icons.broken_image, size: 20),
    );
  }
}
