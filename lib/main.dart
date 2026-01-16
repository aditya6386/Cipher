import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:youtube_messenger_app/config/theme/app_theme.dart';
import 'package:youtube_messenger_app/data/repositories/chat_repository.dart';
import 'package:youtube_messenger_app/data/services/service_locator.dart';
import 'package:youtube_messenger_app/logic/cubits/auth/auth_cubit.dart';
import 'package:youtube_messenger_app/logic/cubits/auth/auth_state.dart';
import 'package:youtube_messenger_app/logic/observer/app_life_cycle_observer.dart';
import 'package:youtube_messenger_app/presentation/home/home_screen.dart';
import 'package:youtube_messenger_app/presentation/screens/auth/login_screen.dart';
import 'package:youtube_messenger_app/router/app_router.dart';

void main() async {
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLifeCycleObserver? _lifeCycleObserver;

  @override
  void initState() {
    super.initState();
    getIt<AuthCubit>().stream.listen((state) {
      if (state.status == AuthStatus.authenticated && state.user != null) {
        // Remove old observer if exists
        if (_lifeCycleObserver != null) {
          WidgetsBinding.instance.removeObserver(_lifeCycleObserver!);
        }
        // Create and add new observer
        _lifeCycleObserver = AppLifeCycleObserver(
            userId: state.user!.uid, chatRepository: getIt<ChatRepository>());
        WidgetsBinding.instance.addObserver(_lifeCycleObserver!);
      } else {
        // Remove observer when user logs out
        if (_lifeCycleObserver != null) {
          WidgetsBinding.instance.removeObserver(_lifeCycleObserver!);
          _lifeCycleObserver = null;
        }
      }
    });
  }

  @override
  void dispose() {
    if (_lifeCycleObserver != null) {
      WidgetsBinding.instance.removeObserver(_lifeCycleObserver!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        title: 'Messenger App',
        navigatorKey: getIt<AppRouter>().navigatorKey,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: BlocBuilder<AuthCubit, AuthState>(
          bloc: getIt<AuthCubit>(),
          builder: (context, state) {
            if (state.status == AuthStatus.initial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.status == AuthStatus.authenticated) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
