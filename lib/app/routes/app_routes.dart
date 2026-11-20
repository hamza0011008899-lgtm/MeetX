part of 'app_pages.dart';

/// App Route Names
abstract class Routes {
  Routes._();
  static const INITIAL = _Paths.SPLASH;
  static const SPLASH = _Paths.SPLASH;
  static const AUTH = _Paths.AUTH;
  static const HOME = _Paths.HOME;
  static const CHAT = _Paths.CHAT;
  static const PROFILE = _Paths.PROFILE;
  static const CALL = _Paths.CALL;
}

abstract class _Paths {
  _Paths._();
  static const INITIAL = '/';
  static const SPLASH = '/splash';
  static const AUTH = '/auth';
  static const HOME = '/home';
  static const CHAT = '/chat';
  static const PROFILE = '/profile';
  static const CALL = '/call';
}
