class AppRoutes {
  const AppRoutes._();

  static const homeName = 'home';
  static const catalogueName = 'catalogue';
  static const artistDetailName = 'artist-detail';
  static const scanName = 'scan';

  static const homePath = '/';
  static const cataloguePath = '/catalogue';
  static const artistDetailPath = '/artist/:mbid';
  static const scanPath = '/scan';

  static String artistDetailLocation(String mbid) => '/artist/$mbid';
}
