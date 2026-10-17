/// Validates one storage path component, never a relative or absolute path.
void validateStorageName(String value, {String label = 'name'}) {
  if (value.isEmpty ||
      value == '.' ||
      value == '..' ||
      value.contains(RegExp(r'[<>:"/\\|?*\x00-\x1f]')) ||
      value.trim() != value ||
      value.endsWith('.') ||
      RegExp(
        r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
        caseSensitive: false,
      ).hasMatch(value)) {
    throw ArgumentError.value(
      value,
      label,
      'Expected a single safe path component',
    );
  }
}
