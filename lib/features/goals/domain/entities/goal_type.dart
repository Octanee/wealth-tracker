enum GoalType {
  portfolio,
  asset;

  String get displayName {
    switch (this) {
      case GoalType.portfolio:
        return 'Portfel';
      case GoalType.asset:
        return 'Aktywo';
    }
  }
}
