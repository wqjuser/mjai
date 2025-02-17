import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';
import '../json_models/uploading_file.dart';
import '../utils/common_methods.dart';

class FileDisplayWidget extends StatelessWidget {
  final UploadingFile file; // 接收一个 UploadingFile 对象

  // 构造函数
  const FileDisplayWidget({
    Key? key,
    required this.file,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return Container(
      width: 220,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          SizedBox(
            width: 220,
            height: 60,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center, // 子项垂直居中
              children: [
                const SizedBox(width: 6),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.pink[300],
                  ),
                  child: Icon(
                    getFileIcon(file.file.name.split('.').last), // 使用传入的文件类型图标
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min, // 让 Column 的大小包裹内容
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      truncateString(file.file.name, 10), // 调用截取函数
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: settings.getForegroundColor(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${file.file.name.split('.').last}文件',
                      textAlign: TextAlign.start,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: settings.getForegroundColor(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (file.uploadFailed)
            Positioned.fill(
              // 确保文本占据整个 Stack
              child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: InkWell(
                      onTap: () {
                        // setState(() {
                        //   uploadingFile.uploadFailed = false;
                        //   uploadingFile.isUploaded = false;
                        // });
                        // uploadSingleFile(uploadingFile, index);
                      },
                      child: const Text(
                        '上传失败,文件内容解析失败,请更换文件',
                        textAlign: TextAlign.center, // 确保文本居中
                        style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )),
            )
        ],
      ),
    );
  }
}
