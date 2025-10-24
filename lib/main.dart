import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/milestone_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_page.dart';
import 'package:intl/date_symbol_data_local.dart';
void main() {
  initializeDateFormatting('vi_VN', null).then((_) {
    runApp(const MyApp());
  });
  // -----------------------------------------------------------------
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // ProjectProvider cần được định nghĩa TRƯỚC TaskProvider
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => MilestoneProvider()), // Milestone có thể độc lập

        // --- THAY ĐỔI QUAN TRỌNG Ở ĐÂY ---
        ChangeNotifierProxyProvider<ProjectProvider, TaskProvider>(
          // `create` chỉ được gọi một lần để tạo instance ban đầu
          create: (context) => TaskProvider(),
          // `update` được gọi mỗi khi ProjectProvider thay đổi (notifyListeners)
          update: (context, projectProvider, previousTaskProvider) {
            // Cập nhật danh sách project cho TaskProvider
            previousTaskProvider?.updateProjects(projectProvider.projects);
            return previousTaskProvider!;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProv, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Manager',
          theme: themeProv.isDark ? ThemeData.dark() : ThemeData(primarySwatch: Colors.blue),
          home: const RootRouter(),
        ),
      ),
    );
  }
}

class RootRouter extends StatelessWidget {
  const RootRouter({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return auth.isAuthenticated ? const HomePage() : const LoginScreen();
  }
}