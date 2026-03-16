/// Environment configuration for the Divvy app
///
/// Update the API base URLs below to match your backend deployment:
/// - Development: Local backend (default: http://127.0.0.1:8000)
/// - Staging: Staging server URL
/// - Production: Production server URL
enum Environment { development, staging, production }

class EnvironmentConfig {
  static Environment _currentEnvironment = Environment.development;

  static Environment get currentEnvironment => _currentEnvironment;

  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }

  /// API Base URL configuration
  /// Update these URLs to match your backend deployment
  static String get apiBaseUrl {
    switch (_currentEnvironment) {
      case Environment.development:
        // Local development - update if your backend runs on a different port
        return 'http://127.0.0.1:8000';
      case Environment.staging:
        // Staging server - update with your staging URL
        return 'https://staging-api.divvy.com';
      case Environment.production:
        // Production server - update with your production URL
        return 'https://api.divvy.com';
    }
  }

  static bool get isProduction => _currentEnvironment == Environment.production;
  static bool get isDevelopment =>
      _currentEnvironment == Environment.development;
  static bool get isStaging => _currentEnvironment == Environment.staging;

  static String get environmentName {
    switch (_currentEnvironment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }

  // Feature flags
  static bool get enableLogging => !isProduction;
  static bool get enableDebugBanner => isDevelopment;
  static bool get enablePerformanceOverlay => isDevelopment;

  // API Configuration
  static Duration get apiTimeout => const Duration(seconds: 30);
  static Duration get apiLongTimeout => const Duration(seconds: 60);
  static int get maxRetries => 3;

  // Cache Configuration
  static Duration get cacheExpiration => const Duration(hours: 24);
  static int get maxCacheSize => 100; // MB

  // Sync Configuration
  static Duration get syncInterval => const Duration(minutes: 15);
  static int get maxSyncRetries => 5;
  static Duration get syncRetryDelay => const Duration(seconds: 30);
}
