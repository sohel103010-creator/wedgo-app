import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config.dart';
import 'screens/splash.dart';
import 'screens/setup.dart';
import 'screens/landing.dart';
import 'screens/register.dart';
import 'screens/login.dart';
import 'screens/forgot_password.dart';
import 'screens/admin_login.dart';
import 'screens/dashboard.dart';
import 'screens/find_partner.dart';
import 'screens/profile_detail.dart';
import 'screens/chat_list.dart';
import 'screens/chat_room.dart';
import 'screens/call_screen.dart';
import 'screens/wallet.dart';
import 'screens/subscribe.dart';
import 'screens/payment_submit.dart';
import 'screens/withdraw.dart';
import 'screens/verification.dart';
import 'screens/notifications.dart';
import 'screens/settings.dart';

class WedGoApp extends ConsumerWidget {
  const WedGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1E2D), // deep maroon + gold accents
        ),
        fontFamily: 'NotoSansBengali',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1E2D),
          brightness: Brightness.dark,
        ),
        fontFamily: 'NotoSansBengali',
      ),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/setup':
            page = const SetupScreen();
            break;
          case '/landing':
            page = const LandingScreen();
            break;
          case '/register':
            page = const RegisterScreen();
            break;
          case '/login':
            page = const LoginScreen();
            break;
          case '/forgot':
            page = const ForgotPasswordScreen();
            break;
          case '/admin-login':
            page = const AdminLoginScreen();
            break;
          case '/dashboard':
            page = const DashboardScreen();
            break;
          case '/find':
            page = const FindPartnerScreen();
            break;
          case '/profile':
            page = ProfileDetailScreen(
                userId: settings.arguments as String);
            break;
          case '/chats':
            page = const ChatListScreen();
            break;
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            page = ChatRoomScreen(
              conversationId: args['conversationId'] as String,
              otherName: args['otherName'] as String? ?? '',
              otherUserId: args['otherUserId'] as String? ?? '',
            );
            break;
          case '/call':
            final args = settings.arguments as Map<String, dynamic>;
            page = CallScreen(
              otherUserId: args['otherUserId'] as String,
              otherName: args['otherName'] as String? ?? '',
              callType: args['callType'] as String? ?? 'audio',
              incomingCallId: args['incomingCallId'] as String?,
            );
            break;
          case '/wallet':
            page = const WalletScreen();
            break;
          case '/subscribe':
            page = const SubscribeScreen();
            break;
          case '/pay':
            page = PaymentSubmitScreen(
                packageId: settings.arguments as String?);
            break;
          case '/withdraw':
            page = const WithdrawScreen();
            break;
          case '/verification':
            page = const VerificationScreen();
            break;
          case '/notifications':
            page = const NotificationsScreen();
            break;
          case '/settings':
            page = const SettingsScreen();
            break;
          default:
            page = const SplashScreen();
        }
        return MaterialPageRoute(
            builder: (_) => page, settings: settings);
      },
    );
  }
}
