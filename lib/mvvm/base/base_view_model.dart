import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_state.dart';

abstract class BaseViewModel<T extends BaseState> extends StateNotifier<T> {
  BaseViewModel(T initialState) : super(initialState);

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading) as T;
  }

  void setError(String? error) {
    state = state.copyWith(error: error) as T;
  }
}
