import 'dart:async';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/config/change_settings.dart';

import '../utils/common_methods.dart';

class CustomCarousel extends StatefulWidget {
  final int currentIndex;
  final List<String> imagePaths;
  final bool autoScroll;
  final Function(int, String) onPageChangedCallback;
  final double aspectRatio;
  final Function(int)? onImageDoubleTap;
  final bool useAssetImage;
  final bool isNeedIndicator;

  const CustomCarousel({
    Key? key,
    required this.currentIndex,
    required this.imagePaths,
    this.autoScroll = true,
    this.useAssetImage = false,
    required this.onPageChangedCallback,
    this.aspectRatio = 1 / 1,
    this.onImageDoubleTap,
    this.isNeedIndicator = true,
  }) : super(key: key);

  @override
  State<CustomCarousel> createState() => CustomCarouselState();
}

class CustomCarouselState extends State<CustomCarousel> {
  late PageController _pageController;
  late int _currentPage;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.currentIndex;
    _pageController = PageController(initialPage: _currentPage);

    if (widget.autoScroll) {
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (_currentPage < widget.imagePaths.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  Widget buildPageIndicator(ChangeSettings settings) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(
        widget.imagePaths.length,
        (int index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            width: _currentPage == index ? 16.0 : 8.0,
            height: 8.0,
            decoration: BoxDecoration(
              color: _currentPage == index ? settings.getSelectedBgColor() : Colors.grey,
              borderRadius: BorderRadius.circular(4.0),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    return SizedBox(
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: widget.aspectRatio, // Set the aspect ratio as needed
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.velocity.pixelsPerSecond.dx > 0) {
                  if (_currentPage > 0) {
                    _currentPage--;
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                } else if (details.velocity.pixelsPerSecond.dx < 0) {
                  if (_currentPage < widget.imagePaths.length - 1) {
                    _currentPage++;
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imagePaths.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onDoubleTap: () {
                      if (widget.onImageDoubleTap != null) {
                        widget.onImageDoubleTap!(index); // Call the callback with the index
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0), // 设置圆角半径为8
                      child: Stack(
                        children: [
                          widget.useAssetImage
                              ? Image(image: AssetImage(widget.imagePaths[index]))
                              : ExtendedImage.network(
                                  widget.imagePaths[index],
                                  fit: BoxFit.contain,
                                ),
                          if (getRealDarkMode(settings))
                            Container(
                              color: Colors.black.withAlpha(76),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                  widget.onPageChangedCallback(_currentPage, widget.imagePaths[_currentPage]);
                },
              ),
            ),
          ),
          widget.isNeedIndicator ? const SizedBox(height: 10.0) : Container(),
          widget.isNeedIndicator ? buildPageIndicator(settings) : Container(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (widget.autoScroll) {
      _timer.cancel();
    }
    super.dispose();
  }
}
