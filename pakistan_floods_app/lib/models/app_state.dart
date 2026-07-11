/// Singleton app-wide shared state
class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  // Server config – hidden from the citizen user
  String serverIp = 'https://mbh7788899.pythonanywhere.com';

  // Logged-in user info
  bool isLoggedIn = false;
  bool isGovernmentUser = false;
  String userName = '';
  String userPhone = '';
  String userProvince = 'Sindh';
  String userCity = '';
  List<Map<String, String>> emergencyContacts = [];

  // Officer Profile Credentials
  String officerEmail = 'eoc.officer@ndma.gov.pk';
  String officerBatchId = 'EOC-2026-X';
  String officerStation = 'National EOC Headquarters';
}
