import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

class CommonDropdownWidget extends StatefulWidget {
  final List<String> dropdownData;
  final String selectedValue;
  final Function(String) onChangeValue;

  const CommonDropdownWidget({
    super.key,
    required this.dropdownData,
    required this.selectedValue,
    required this.onChangeValue,
  });

  @override
  State<CommonDropdownWidget> createState() => _CommonDropdownWidgetState();
}

class _CommonDropdownWidgetState extends State<CommonDropdownWidget> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(CommonDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValue != widget.selectedValue) {
      _selectedValue = widget.selectedValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return DropdownButtonHideUnderline(
      child: Obx(() => DropdownButton2<String>(
            isExpanded: true,
            hint: const Row(
              children: [
                Icon(
                  Icons.list,
                  size: 16,
                  color: Colors.yellow,
                ),
                SizedBox(
                  width: 4,
                ),
                Expanded(
                  child: Text(
                    'Select Item',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            items: widget.dropdownData.obs
                .map((String item) => DropdownMenuItem<String>(
                    value: item,
                    child: Center(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )))
                .toList(),
            value: _selectedValue,
            onChanged: (value) {
              if (value == '自定义') {
              } else {
                setState(() {
                  _selectedValue = value!;
                });
                widget.onChangeValue(value!);
              }
            },
            buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.only(left: 14, right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black26,
                ),
                color: settings.getSelectedBgColor(),
              ),
              elevation: 2,
            ),
            iconStyleData: const IconStyleData(
              icon: Icon(
                Icons.arrow_forward_ios_outlined,
              ),
              iconSize: 14,
              iconEnabledColor: Colors.yellow,
              iconDisabledColor: Colors.grey,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              padding: const EdgeInsets.only(left: 18, right: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: settings.getSelectedBgColor(),
              ),
              scrollbarTheme: ScrollbarThemeData(
                radius: const Radius.circular(40),
                thickness: WidgetStateProperty.all(6),
                thumbColor: WidgetStateProperty.resolveWith<Color?>(
                  (Set<WidgetState> states) {
                    if (states.contains(WidgetState.pressed)) {
                      return Colors.red.withAlpha(128); // 当按钮被按下时的颜色
                    }
                    return Colors.white; // 默认颜色
                  },
                ),
                thumbVisibility: WidgetStateProperty.all(false),
              ),
            ),
            menuItemStyleData: MenuItemStyleData(
              height: 40,
              padding: const EdgeInsets.only(left: 14, right: 14),
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.pressed)) {
                    return Colors.red.withAlpha(128); // 按下时的颜色和透明度
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.blue.withAlpha(128); // 鼠标悬停时的颜色和透明度
                  }
                  if (states.contains(WidgetState.focused)) {
                    return Colors.yellowAccent.withAlpha(128); // 获取焦点时的颜色和透明度
                  }
                  return null; // 其他状态的默认颜色
                },
              ),
              selectedMenuItemBuilder: (ctx, child) {
                return Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.yellowAccent.withAlpha(128),
                      borderRadius: BorderRadius.circular(8), // 设置圆角
                    ),
                    child: child,
                  ),
                );
              },
            ),
          )),
    );
  }
}
