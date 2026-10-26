import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sheetal_icecream/core/theme/app_theme.dart';
import 'package:sheetal_icecream/data/catalog/catalog_repository.dart';
import 'package:sheetal_icecream/features/cart/cubit/cart_cubit.dart';
import 'package:sheetal_icecream/features/cart/cubit/orders_cubit.dart';
import 'package:sheetal_icecream/features/catalog/cubit/catalog_cubit.dart';
import 'package:sheetal_icecream/features/shell/cubit/shell_cubit.dart';
import 'package:sheetal_icecream/features/shell/presentation/app_shell.dart';
import 'package:sheetal_icecream/features/splash/presentation/splash_screen.dart';

class SheetalApp extends StatefulWidget {
  const SheetalApp({super.key, this.showSplash = true});

  final bool showSplash;

  @override
  State<SheetalApp> createState() => _SheetalAppState();
}

class _SheetalAppState extends State<SheetalApp> {
  final CatalogRepository _catalog = SupabaseCatalogRepository();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CatalogCubit(_catalog)),
        BlocProvider(create: (_) => CartCubit(_catalog)),
        BlocProvider(create: (_) => OrdersCubit()),
        BlocProvider(create: (_) => ShellCubit()),
      ],
      child: MaterialApp(
        title: 'Sheetal',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        builder: (context, child) => _MobilePrototypeWrapper(child: child!),
        home: widget.showSplash ? const SplashScreen() : const AppShell(),
      ),
    );
  }
}

class _MobilePrototypeWrapper extends StatelessWidget {
  const _MobilePrototypeWrapper({required this.child});

  final Widget child;

  static const double mobileWidth = 390.0;
  static const double mobileHeight = 844.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 500) {
          return child;
        }
        final availableHeight = constraints.maxHeight;
        final scale = availableHeight > 0 && availableHeight < (mobileHeight + 60)
            ? ((availableHeight - 60) / mobileHeight).clamp(0.65, 1.0)
            : 1.0;

        return Scaffold(
          backgroundColor: const Color(0xFF140A12),
          body: Stack(
            children: [
              Center(
                child: Container(
                  width: mobileWidth + 140,
                  height: mobileHeight + 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEC5BB0).withValues(alpha: 0.18),
                        blurRadius: 130,
                        spreadRadius: 30,
                      ),
                      BoxShadow(
                        color: const Color(0xFF7FB942).withValues(alpha: 0.12),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Centered Mobile Prototype Frame
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: mobileWidth,
                    height: mobileHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(46),
                      border: Border.all(
                        color: const Color(0xFF2B1A27),
                        width: 9,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 40,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: const Color(0xFFEC5BB0).withValues(alpha: 0.15),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        size: const Size(mobileWidth, mobileHeight),
                        padding: const EdgeInsets.only(top: 44, bottom: 20),
                        viewPadding: const EdgeInsets.only(top: 44, bottom: 20),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(child: child),

                          // Dynamic Island / Camera Notch
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                width: 105,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),

                          // Home Bar Indicator
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                width: 130,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Top device info badge
              Positioned(
                top: 14,
                left: 18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('📱', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 6),
                      Text(
                        'Mobile Prototype (390 × 844)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
