import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import 'package:tuitu/json_models/kb_file_list_data.dart';

class KbFileItem extends StatefulWidget {
  final KBFileListData fileListData;
  final int index;
  final void Function(int) onDelete;

  const KbFileItem({super.key, required this.fileListData, required this.index, required this.onDelete});

  @override
  State<KbFileItem> createState() => _KbFileItemState();
}

class _KbFileItemState extends State<KbFileItem> {
  var deleteSize = 175;
  late KBFileListData fileListData;

  @override
  void initState() {
    super.initState();
    fileListData = widget.fileListData;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SizedBox(
      height: 40,
      width: MediaQuery.of(context).size.width,
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints.expand(), // 设置内容限制为填充父布局
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                color: settings.getForegroundColor(), // 边框颜色
                width: 1.0, // 边框宽度
              )),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(
                      fileListData.id,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                  child: Center(
                    child: Text(
                      fileListData.title,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                  child: Center(
                    child: Text(
                      fileListData.status == '0'
                          ? '解析中'
                          : fileListData.status == '1'
                              ? '解析成功'
                              : fileListData.status == '2'
                                  ? '解析失败'
                                  : fileListData.status == '3'
                                      ? '文件大小超过限制'
                                      : '',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                  child: Center(
                    child: Text(
                      fileListData.fileSize,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: (MediaQuery.of(context).size.width - deleteSize) / 5,
                  child: Center(
                    child: Text(
                      fileListData.createTime,
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                SizedBox(
                  width: 100,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onDelete(widget.index);
                      },
                      style: ButtonStyle(backgroundColor: WidgetStateProperty.all(settings.getSelectedBgColor())),
                      child: Text(
                        '删除',
                        style: TextStyle(
                          color: settings.getCardTextColor(),
                          shadows: [
                            Shadow(
                              color: Colors.grey.withAlpha(128),
                              offset: const Offset(0, 2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.0, // 设置线的宽度
                  height: 40.0, // 设置线的高度
                  color: settings.getForegroundColor(), // 设置线的颜色
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '',
                      style: TextStyle(
                        color: settings.getForegroundColor(),
                        shadows: [
                          Shadow(
                            color: Colors.grey.withAlpha(128),
                            offset: const Offset(0, 2),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
