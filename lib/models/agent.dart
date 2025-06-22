class Agent {
  final String id;
  final String name;
  final String email;
  final String password;
  final String mobile;
  final String? profilePicture;
  final bool isAdmin;
  final bool isFrozen;

  Agent({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.mobile,
    this.profilePicture,
    required this.isAdmin,
    required this.isFrozen,
  });

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      mobile: map['mobile'],
      profilePicture: map['profilePicture'],
      isAdmin: map['isAdmin'] == 1,
      isFrozen: map['isFrozen'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'mobile': mobile,
      'profilePicture': profilePicture,
      'isAdmin': isAdmin ? 1 : 0,
      'isFrozen': isFrozen ? 1 : 0,
    };
  }
}