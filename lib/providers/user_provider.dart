import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  final String name;
  final String email;
  final String role;
  final String avatarUrl;

  const UserProfile({
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
  });
}

class UserNotifier extends Notifier<UserProfile> {
  @override
  UserProfile build() {
    return const UserProfile(
      name: 'Piyush Sahu',
      email: 'piyush.sahu@ordersync.app',
      role: 'Lead Logistics Manager',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    );
  }

  void updateName(String newName) {
    state = UserProfile(
      name: newName,
      email: state.email,
      role: state.role,
      avatarUrl: state.avatarUrl,
    );
  }
}

final userProvider = NotifierProvider<UserNotifier, UserProfile>(
  UserNotifier.new,
);
