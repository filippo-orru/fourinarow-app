import 'package:flutter/material.dart';
import 'package:four_in_a_row/lottie/splash_screen.dart';
import 'package:four_in_a_row/util/fiar_shared_prefs.dart';
import 'package:four_in_a_row/util/logger.dart';

class AppStartup extends StatefulWidget {
  final VoidCallback onStartPreloading;
  final VoidCallback onCompleted;

  const AppStartup({
    Key? key,
    required this.onStartPreloading,
    required this.onCompleted,
  }) : super(key: key);

  @override
  State<AppStartup> createState() => _AppStartupState();
}

enum LoadState {
  Idle,
  LoadingDependencies,
  Done,

  Error,
  // Done doesn't exist because we call the onCompleted callback and this widget is hidden
}

class _AppStartupState extends State<AppStartup> {
  _AppStartupState() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (loadState == LoadState.Idle) {
        // Usually, initialize() is called by [initState] when the widget loads.
        // If it hasn't yet been called, call it here (screen may be off).
        Logger.d("Initializing app after waiting 500 ms");
        _initialize();
        _skipAnimation();
      }
    });
  }

  LoadState _loadState = LoadState.Idle;
  LoadState get loadState => _loadState;
  set loadState(state) {
    _loadState = state;
    _callCallbackIfCompleted();
  }

  SplashScreenState _animationState = SplashScreenState.Loading;
  SplashScreenState get animationState => _animationState;
  set animationState(state) {
    if (_animationState != SplashScreenState.Done) {
      _animationState = state;
      _callCallbackIfCompleted();
    }
  }

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (loadState == LoadState.LoadingDependencies) return; // already initialized
    loadState = LoadState.LoadingDependencies;
    setState(() {});

    _initializeNecessaryDependencies().then(
      (_) async {
        setState(() => loadState = LoadState.Done);
      },
      onError: ((error, stackTrace) {
        setState(() => loadState = LoadState.Error);
      }),
    );
  }

  Future<void> _initializeNecessaryDependencies() async {
    await FiarSharedPrefs.i.init();
    return;
  }

  void _callCallbackIfCompleted() {
    if (loadState == LoadState.Done) {
      if (animationState == SplashScreenState.LottieDone) {
        widget.onStartPreloading();
      }
      if (animationState == SplashScreenState.Done) {
        widget.onCompleted();
      }
    }
  }

  void _skipAnimation() {
    setState(() => animationState = SplashScreenState.Done);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () => _skipAnimation(),
      child: animationState != SplashScreenState.Done
          ? WidgetsApp(
              color: Colors.blue,
              debugShowCheckedModeBanner: false,
              builder: (ctx, __) {
                // if (loadState == LoadState.Idle) {
                //   return SizedBox();
                // } else {
                return SplashScreen(
                  onAnimationState: (state) => setState(() => animationState = state),
                );
                // }
              },
            )
          : SizedBox(),
    );
  }
}
