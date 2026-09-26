/// The user's gender identity, used to tailor tracking features.
///
/// Period tracking is offered only when the user selects [female].
enum Gender {
  female(label: 'Female'),
  male(label: 'Male'),
  nonBinary(label: 'Non-binary'),
  preferNotToSay(label: 'Prefer not to say'),
  ;

  const Gender({required this.label});

  final String label;

  static Gender? fromName(String? name) {
    for (final gender in Gender.values) {
      if (gender.name == name) return gender;
    }
    return null;
  }
}