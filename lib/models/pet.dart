
class Pet {
  final String name;
  final String breed;
  final int age;
  final String imageUrl;
  final String description;

  Pet({
    required this.name,
    required this.breed,
    required this.age,
    required this.imageUrl,
    required this.description,
  });


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'age': age,
      'imageUrl': imageUrl,
      'description': description,
    };
  }


  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      name: map['name'] ?? '',
      breed: map['breed'] ?? '',
      age: map['age']?.toInt() ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
    );
  }
}