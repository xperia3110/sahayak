class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? phoneNumber;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    this.phoneNumber,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Check if the response is nested under 'user' key (like in login/register response)
    // or flat (like in stored session or direct user fetch)
    Map<String, dynamic> userData = json;
    String? token;

    if (json.containsKey('user')) {
      userData = json['user'];
      token = json['token'];
    } else if (json.containsKey('token')) {
      token = json['token'];
    }

    return User(
      id: userData['id'] ?? userData['user_id'] ?? 0,
      username: userData['username'] ?? '',
      email: userData['email'] ?? '',
      firstName: userData['first_name'] ?? '',
      lastName: userData['last_name'] ?? '',
      middleName: userData['middle_name'],
      phoneNumber: userData['phone_number'],
      token: token ?? json['token'], // Fallback for token
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'phone_number': phoneNumber,
      'token': token,
    };
  }
}
