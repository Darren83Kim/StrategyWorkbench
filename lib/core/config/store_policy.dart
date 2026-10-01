class StorePolicy {
  static const variant = String.fromEnvironment(
    'STORE_VARIANT',
    defaultValue: 'full',
  );

  static const bool isPersonalMode = variant == 'personal';
  static const bool showPortfolioFeatures = !isPersonalMode;
  static const bool enablePortfolioAlerts = !isPersonalMode;
}
