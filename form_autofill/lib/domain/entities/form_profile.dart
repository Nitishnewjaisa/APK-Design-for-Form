class FormProfile {
  final String id;
  final String name;
  final Map<String, String> fields;
  final DateTime updatedAt;

  const FormProfile({
    required this.id,
    required this.name,
    required this.fields,
    required this.updatedAt,
  });

  FormProfile copyWith({
    String? id,
    String? name,
    Map<String, String>? fields,
    DateTime? updatedAt,
  }) {
    return FormProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      fields: fields ?? Map<String, String>.from(this.fields),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
