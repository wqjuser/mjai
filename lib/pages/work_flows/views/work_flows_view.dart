import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/change_settings.dart';
import '../view_models/script_workflow_view_model.dart';
import '../view_models/image_reimagination_view_model.dart';
import '../view_models/reverse_engineering_view_model.dart';
import 'script_workflow_view.dart';
import 'image_reimagination_view.dart';
import 'reverse_engineering_view.dart';

class WorkFlowsView extends StatelessWidget {
  const WorkFlowsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScriptWorkflowViewModel()),
        ChangeNotifierProvider(create: (_) => ImageReimaginationViewModel()),
        ChangeNotifierProvider(create: (_) => ReverseEngineeringViewModel()),
      ],
      child: Container(
        decoration: BoxDecoration(
          color: settings.getBackgroundColor(),
        ),
        child: const SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScriptWorkflowView(),
                SizedBox(height: 20),
                ImageReimaginationView(),
                SizedBox(height: 16),
                ReverseEngineeringView(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}