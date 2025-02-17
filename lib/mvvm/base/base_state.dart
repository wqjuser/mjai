abstract class BaseState {
  final bool isLoading;
  final String? error;

  const BaseState({
    this.isLoading = false,
    this.error,
  });

  BaseState copyWith({
    bool? isLoading,
    String? error,
  });
}
