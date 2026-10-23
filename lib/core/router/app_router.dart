import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import features using absolute paths for stability
import 'package:unani_academy/features/splash/splash_screen.dart';
import 'package:unani_academy/features/auth/login_screen.dart';
import 'package:unani_academy/features/auth/signup_screen.dart';
import 'package:unani_academy/features/auth/forgot_password_screen.dart';
import 'package:unani_academy/features/admin/admin_panel.dart';
import 'package:unani_academy/features/main/main_screen.dart';
import 'package:unani_academy/features/courses/course_detail_screen.dart';
import 'package:unani_academy/features/courses/presentation/subject_materials_screen.dart';
import 'package:unani_academy/features/courses/file_viewer_screen.dart';
import 'package:unani_academy/features/courses/data/material_model.dart';
import 'package:unani_academy/features/profile/downloads_screen.dart';
import 'package:unani_academy/features/profile/purchase_history_screen.dart';
import 'package:unani_academy/features/profile/privacy_policy_screen.dart';
import 'package:unani_academy/features/main/nav_provider.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot_password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          // Set index to 3 (Profile)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(mainNavigationProvider.notifier).state = 3;
          });
          return const MainScreen();
        },
      ),
      GoRoute(
        path: '/course_detail/:id',
        name: 'course_detail',
        builder: (context, state) {
          final courseData = state.extra as Map<String, dynamic>? ?? {};
          return CourseDetailScreen(course: courseData);
        },
      ),
      GoRoute(
        path: '/file_viewer',
        name: 'file_viewer',
        builder: (context, state) {
          final extra = state.extra;

          // Case 1: already a MaterialModel (from subject_materials_screen)
          if (extra is MaterialModel) {
            return FileViewerScreen(material: extra);
          }

          // Case 2: raw Map passed (from downloads section or course_detail_screen)
          if (extra is Map<String, dynamic>) {
            final material = MaterialModel(
              id: extra['id'] as String? ?? '',
              year: extra['year'] as String? ?? '',
              subject: extra['subject'] as String? ?? '',
              fileName: extra['title'] as String? ?? 
                        extra['file_name'] as String? ?? 'document',
              fileUrl: extra['url'] as String? ?? 
                       extra['file_url'] as String? ?? '',
              storagePath: extra['storage_path'] as String? ?? '',
              mediaType: extra['media_type'] as String? ?? 'pdf',
              title: extra['title'] as String? ?? extra['file_name'] as String?,
              imagePath: null,
              videoPath: null,
              createdAt: DateTime.now(),
            );
            return FileViewerScreen(material: material);
          }

          // Fallback — should never happen
          return const Scaffold(
            body: Center(child: Text('Error: Invalid file data')),
          );
        },
      ),
      GoRoute(
        path: '/admin_dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminPanel(),
      ),
      GoRoute(
        path: '/subject_materials',
        name: 'subject_materials',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return SubjectMaterialsScreen(
            year: data['year'] ?? '',
            subject: data['subject'] ?? '',
            subjectId: data['subject_id'], // Pass subjectId
          );
        },
      ),

      GoRoute(
        path: '/downloads',
        name: 'downloads',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DownloadsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/purchase_history',
        name: 'purchase_history',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PurchaseHistoryScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return SlideTransition(
               position: animation.drive(Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.ease))),
               child: child,
             );
          },
        ),
      ),
      GoRoute(
        path: '/privacy_policy',
        name: 'privacy_policy',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PrivacyPolicyScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
             return SlideTransition(
               position: animation.drive(Tween(begin: const Offset(0.0, 1.0), end: Offset.zero).chain(CurveTween(curve: Curves.ease))),
               child: child,
             );
          },
        ),
      ),
    ],
  );
});
