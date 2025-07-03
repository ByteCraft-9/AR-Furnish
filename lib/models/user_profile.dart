class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final List<String> addresses;
  final List<String> savedPaymentMethods;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.addresses,
    required this.savedPaymentMethods,
  });
}