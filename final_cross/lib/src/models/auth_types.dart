class LoginResponse {
  final String msg;
  final String? token;
  final String? error;

  LoginResponse({
    required this.msg,
    this.token,
    this.error,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      msg: json['msg'] as String,
      token: json['token'] as String?,
      error: json['error'] as String?,
    );
  }
}

class User {
  final String email;
  final String id;

  User({
    required this.email,
    required this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      email: json['email'] as String,
      id: json['id'] as String,
    );
  }
}