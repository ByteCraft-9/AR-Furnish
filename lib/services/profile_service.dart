import 'package:ar_furnish/models/user_profile.dart';
import 'package:ar_furnish/services/auth_service.dart';

class ProfileService {
  final AuthService _authService = AuthService();

  Future<UserProfile> getUserProfile() async {
    final userId = await _authService.getUserId();
    if (userId == null) throw Exception('User not authenticated');

    // TODO: Implement API call to fetch profile
    // This is dummy data for demonstration
    await Future.delayed(const Duration(seconds: 1));

    return UserProfile(
      id: userId,
      email: 'user@example.com',
      fullName: 'John Doe',
      phoneNumber: '+1234567890',
      addresses: ['123 Main St, City, Country'],
      savedPaymentMethods: ['**** **** **** 1234'],
    );
  }
}
