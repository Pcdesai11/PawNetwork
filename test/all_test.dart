import 'package:flutter_test/flutter_test.dart';

// Import all your test files
import 'home_screen_test.dart' as home_screen_test;
import 'auth service test.dart' as auth_service_test;

import 'widget_test.dart' as widget_test;
// Import any other test files here

void main() {
  // Run all tests
  home_screen_test.main();
  auth_service_test.main();
  home_screen_test.main();
  widget_test.main();
  // Add other test main() functions
}