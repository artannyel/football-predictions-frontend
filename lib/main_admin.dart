import 'package:flutter/material.dart';
import 'package:football_predictions/admin_app.dart';
import 'package:football_predictions/core/providers/theme_provider.dart';
import 'package:football_predictions/features/admin/data/repositories/admin_repository.dart';
import 'package:football_predictions/dio_client.dart';
import 'package:provider/provider.dart';

void main() async {
  runApp(MultiProvider(
      providers: [
        Provider(create: (_) => DioClient()),
        ProxyProvider<DioClient, AdminRepository>(
          update: (_, dioClient, __) => AdminRepository(dioClient: dioClient),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const AdminApp(),
    ),);
}