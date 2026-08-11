import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/sticker.dart';
import '../models/sticker_kind.dart';
import '../platform/sticker_storage.dart';
import 'local_image.dart';

/// Renders PNG/JPG/WebP, GIF, Lottie, or unicode emoji stickers.
class StickerRenderer extends StatelessWidget {
  const StickerRenderer({
    super.key,
    required this.sticker,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final Sticker sticker;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (sticker.kind == StickerKind.unicode && sticker.unicode != null) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            sticker.unicode!,
            style: TextStyle(fontSize: (width ?? height ?? 40) * 0.72),
          ),
        ),
      );
    }

    if (sticker.kind == StickerKind.lottie) {
      return _buildLottie();
    }

    return _buildImage();
  }

  Widget _buildImage() {
    final w = width;
    final h = height;
    if (sticker.localPath != null) {
      return LocalImage(
        ref: sticker.localPath!,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    if (sticker.assetPath != null) {
      return Image.asset(
        sticker.assetPath!,
        package: 'emoji_weixin',
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    if (sticker.networkUrl != null) {
      return Image.network(
        sticker.networkUrl!,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    return _placeholder();
  }

  Widget _buildLottie() {
    final w = width;
    final h = height;
    if (sticker.localPath != null) {
      final local = sticker.localPath!;
      return FutureBuilder<Uint8List?>(
        future: StickerStorage.readBytes(local),
        builder: (context, snap) {
          final bytes = snap.data;
          if (bytes == null) {
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                width: w,
                height: h,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            return _placeholder();
          }
          final lower = local.toLowerCase();
          final isZipLottie =
              lower.endsWith('.lottie') || lower.contains('.lottie');
          return Lottie.memory(
            bytes,
            width: w,
            height: h,
            fit: fit,
            decoder: isZipLottie ? LottieComposition.decodeZip : null,
            errorBuilder: _error,
          );
        },
      );
    }
    if (sticker.assetPath != null) {
      return Lottie.asset(
        sticker.assetPath!,
        package: 'emoji_weixin',
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    if (sticker.networkUrl != null) {
      return Lottie.network(
        sticker.networkUrl!,
        width: w,
        height: h,
        fit: fit,
        errorBuilder: _error,
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return SizedBox(
      width: width,
      height: height,
      child: const ColoredBox(
        color: Color(0xFFEDEDED),
        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  Widget _error(BuildContext context, Object error, StackTrace? stackTrace) {
    return _placeholder();
  }
}
