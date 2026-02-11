import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:football_predictions/core/presentation/widgets/app_network_image.dart';
import 'package:football_predictions/core/utils/web_heic_converter_stub.dart'
    if (dart.library.html) 'package:football_predictions/core/utils/web_heic_converter.dart';

class ImagePickerWidget extends StatelessWidget {
  final XFile? image;
  final ValueChanged<XFile> onImageSelected;
  final double radius;
  final String? initialUrl;

  const ImagePickerWidget({
    super.key,
    required this.image,
    required this.onImageSelected,
    this.radius = 40,
    this.initialUrl,
  });

  Future<void> _pickImage() async {
    if (kIsWeb) {
      await _pickWebImage();
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      XFile imageFile = pickedFile;

      // Verifica se a imagem é HEIC e converte para JPG
      // A conversão de arquivo físico só deve ocorrer em Mobile (Android/iOS)
      if (imageFile.path.toLowerCase().endsWith('.heic')) {
        File? convertedFile;
        if (Platform.isAndroid) {
          convertedFile = await _convertHeicToJpgAndorid(File(imageFile.path));
        } else {
          convertedFile = await _convertHeicToJpg(File(imageFile.path));
        }
        if (convertedFile != null) {
          imageFile = XFile(convertedFile.path);
        }
      }

      onImageSelected(imageFile);
    }
  }

  Future<void> _pickWebImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
      allowMultiple: false,
      withData: true, // Importante para Web ter acesso aos bytes
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        Uint8List imageBytes = file.bytes!;
        String fileName = file.name;

        // 1. Se for HEIC, converte para JPG usando a lib JS
        if (fileName.toLowerCase().endsWith('.heic')) {
          imageBytes = await convertHeicToJpgWeb(imageBytes);
          fileName = '${fileName.split('.').first}.jpg';
        }

        // 2. Comprime a imagem para evitar erro 413 (Payload Too Large)
        try {
          final compressedBytes = await FlutterImageCompress.compressWithList(
            imageBytes,
            minHeight: 1080, // Limita a resolução
            minWidth: 1080,
            quality: 85,     // Qualidade boa, mas com tamanho reduzido
            format: CompressFormat.jpeg,
          );
          imageBytes = compressedBytes;
          // Garante a extensão correta
          if (!fileName.toLowerCase().endsWith('.jpg')) {
            fileName = '${fileName.split('.').first}.jpg';
          }
        } catch (e) {
          debugPrint('Erro ao comprimir imagem na web: $e');
        }

        onImageSelected(XFile.fromData(imageBytes, name: fileName));
      }
    }
  }

  Future<File?> _convertHeicToJpgAndorid(File image) async {
    final targetPath = image.path.replaceAll(
      RegExp(r'\.heic$', caseSensitive: false),
      '.jpg',
    );
    final result = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      format: CompressFormat.jpeg,
      quality: 90,
    );
    return result != null ? File(result.path) : null;
  }

  Future<File?> _convertHeicToJpg(File image) async {
    final bytes = await image.readAsBytes();
    final jpgBytes = await HeicConverter.convertToJPG(heicData: bytes);

    final targetPath = image.path.replaceAll(
      RegExp(r'\.heic$', caseSensitive: false),
      '.jpg',
    );
    return File(targetPath).writeAsBytes(jpgBytes);
  }

  ImageProvider? _getBackgroundImage() {
    // 1. Se tem imagem nova selecionada (Mobile)
    if (!kIsWeb && image != null) return FileImage(File(image!.path));
    // 2. Se não tem imagem nova, mas tem URL inicial (Apenas Mobile)
    // Na Web, usamos AppNetworkImage no child para evitar problemas de CORS
    if (!kIsWeb && image == null && initialUrl != null) return NetworkImage(initialUrl!);
    // 3. Caso contrário (Web com imagem nova é tratado no child)
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade300,
        backgroundImage: _getBackgroundImage(),
        child: _buildChild(),
      ),
    );
  }

  Widget? _buildChild() {
    // Se não tem imagem nova nem URL inicial, mostra o ícone
    if (image == null && initialUrl == null) {
      return Icon(Icons.add_a_photo, size: radius * 0.75, color: Colors.grey);
    }

    // Se tem URL inicial e nenhuma imagem nova, não mostra nada no child (o backgroundImage cuida disso)
    if (image == null && initialUrl != null) {
      if (kIsWeb) {
        return ClipOval(
          child: AppNetworkImage(
            url: initialUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
          ),
        );
      }
      return null; // No mobile o backgroundImage cuida da exibição
    }

    // Na Web usamos Image.memory via FutureBuilder para ler os bytes
    if (kIsWeb) {
      return FutureBuilder<Uint8List>(
        future: image!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ClipOval(
              child: Image.memory(
                snapshot.data!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
              ),
            );
          }
          return const CircularProgressIndicator();
        },
      );
    }
    return null; // No mobile o backgroundImage cuida da exibição
  }
}