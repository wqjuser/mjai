import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class CustomImageView extends StatefulWidget {
  final List<String> imagePaths;
  final List<String> imageUrls;
  final Function(int index, List<String> allImagePaths)? onImageTap;
  final Function(int index, List<String> allImagePaths)? onImageSaveTap;
  final List<int>? imagesDownloadStatus;

  const CustomImageView(
      {Key? key,
      required this.imagePaths,
      this.onImageTap,
      this.onImageSaveTap,
      this.imagesDownloadStatus,
      required this.imageUrls})
      : super(key: key);

  @override
  State<CustomImageView> createState() => _CustomImageViewState();
}

class _CustomImageViewState extends State<CustomImageView> {
  @override
  Widget build(BuildContext context) {
    double spacing = 6.0;
    BorderRadius borderRadius = BorderRadius.circular(6.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        double availableHeight = constraints.maxHeight;
        double imageSize = (availableHeight - (2 * spacing)) / 2;

        return Column(
          children: [
            SizedBox(
              height: imageSize,
              child: Row(
                children: List.generate(
                  2,
                  (index) {
                    if (index < widget.imageUrls.length) {
                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (widget.onImageTap != null) {
                                      widget.onImageTap!(index, widget.imageUrls);
                                    }
                                  },
                                  child: Container(
                                    width: constraints.maxWidth, // 设置为Expanded的宽度
                                    height: constraints.maxHeight, // 设置为Expanded的高度
                                    margin: EdgeInsets.only(right: spacing),
                                    child: ClipRRect(
                                      borderRadius: borderRadius,
                                      child: ExtendedImage.network(widget.imageUrls[index], fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 5 + spacing,
                                  child: InkWell(
                                    child: Tooltip(
                                      message: widget.imagesDownloadStatus![index] == 0 ? '保存此图片' : '此图片已保存',
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(15.0),
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/images/save.svg',
                                          semanticsLabel: widget.imagesDownloadStatus![index] == 0 ? '保存此图片' : '此图片已保存',
                                          colorFilter: ColorFilter.mode(
                                              (widget.imagesDownloadStatus![index] == 0) ? Colors.black : Colors.blue,
                                              BlendMode.srcIn),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      if (widget.onImageSaveTap != null) {
                                        widget.onImageSaveTap!(index, widget.imageUrls);
                                      }
                                    },
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      );
                    } else {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: spacing),
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            color: Colors.grey, // Placeholder color
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Image(image: AssetImage('assets/images/un_generate_image.png')),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: spacing),
            SizedBox(
              height: imageSize,
              child: Row(
                children: List.generate(
                  2,
                  (index) {
                    int realIndex = index + 2;
                    if (realIndex < widget.imageUrls.length) {
                      return Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (widget.onImageTap != null) {
                                      widget.onImageTap!(realIndex, widget.imageUrls);
                                    }
                                  },
                                  child: Container(
                                    width: constraints.maxWidth, // 设置为Expanded的宽度
                                    height: constraints.maxHeight, // 设置为Expanded的高度
                                    margin: EdgeInsets.only(right: spacing),
                                    child: ClipRRect(
                                        borderRadius: borderRadius,
                                        child: ExtendedImage.network(widget.imageUrls[realIndex], fit: BoxFit.cover)),
                                  ),
                                ),
                                Positioned(
                                  bottom: 5,
                                  right: 5 + spacing,
                                  child: InkWell(
                                    child: Tooltip(
                                      message: widget.imagesDownloadStatus![realIndex] == 0 ? '保存此图片' : '此图片已保存',
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        padding: const EdgeInsets.all(8.0),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(15.0),
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/images/save.svg',
                                          semanticsLabel:
                                              widget.imagesDownloadStatus![realIndex] == 0 ? '保存此图片' : '此图片已保存',
                                          colorFilter: ColorFilter.mode(
                                              (widget.imagesDownloadStatus![realIndex] == 0)
                                                  ? Colors.black
                                                  : Colors.blue,
                                              BlendMode.srcIn),
                                        ),
                                      ),
                                    ),
                                    onTap: () {
                                      if (widget.onImageSaveTap != null) {
                                        widget.onImageSaveTap!(realIndex, widget.imageUrls);
                                      }
                                    },
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      );
                    } else {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: spacing),
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            color: Colors.grey, // Placeholder color
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: Image(image: AssetImage('assets/images/un_generate_image.png')),
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
