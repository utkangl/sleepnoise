enum AppRoute {
  onboarding('/onboarding'),
  home('/home'),
  mixer('/mixer'),
  library('/library'),
  nowPlaying('/now-playing');

  const AppRoute(this.path);
  final String path;
}
