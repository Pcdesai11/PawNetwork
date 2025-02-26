class Pet {
  final String id; // Add this field
  final String name;
  final String breed;
  final int age;
  final String imageUrl;
  final String description;

  Pet({
    required this.id, // Add this parameter
    required this.name,
    required this.breed,
    required this.age,
    required this.imageUrl,
    required this.description,
  });

  factory Pet.fromMap(Map<String, dynamic> map, {required String id}) {
    return Pet(
      id: id, // Ensure the ID is always provided
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}