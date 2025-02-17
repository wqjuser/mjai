import 'package:get/get.dart';

class ChatSetController extends GetxController {
  var enableNet = true.obs;
  changeEnableNet(bool value) => enableNet.value = value;
}
