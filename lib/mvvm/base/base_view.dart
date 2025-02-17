import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'base_view_model.dart';
import 'base_state.dart';

abstract class BaseView<VM extends BaseViewModel<S>, S extends BaseState> extends ConsumerWidget {
  const BaseView({super.key});

  Widget buildView(BuildContext context, WidgetRef ref, S state);

  void onInit(WidgetRef ref) {}

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(viewModelProvider);

    onInit(ref);

    return Scaffold(
      body: Stack(
        children: [
          buildView(context, ref, state),
          if (state.isLoading) const Center(child: CircularProgressIndicator()),
          if (state.error != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Material(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.red,
                  child: Text(
                    state.error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  StateNotifierProvider<VM, S> get viewModelProvider;
}
