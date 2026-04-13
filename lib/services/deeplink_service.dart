import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'firestore_service.dart';

class DeepLinkService {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> navigatorKey;

  DeepLinkService(this.navigatorKey) {
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    // Check initial link if app was closed
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to parse initial deep link: $e");
    }

    // Subscribe to links when app is in background
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    // We look for logic like: myapp://join?gameId=XYZ or https://nextdink.com/join?gameId=XYZ
    if (uri.pathSegments.contains('join') || uri.host == 'join') {
      final gameId = uri.queryParameters['gameId'];
      if (gameId != null && navigatorKey.currentContext != null) {
        final context = navigatorKey.currentContext!;
        
        // Show loading indicator wrapper
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joining game from link...⏱️')),
        );

        final result = await FirestoreService().joinGame(gameId);
        
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(result)),
           );
        }
      }
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
