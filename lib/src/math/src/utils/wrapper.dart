class Wrapper<T> {
  final T value;

  const Wrapper(
    this.value,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Wrapper<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Wrapper($value)';
}
