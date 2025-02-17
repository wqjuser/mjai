import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:tuitu/pages/main/viewmodels/main_viewmodel.dart';
import 'package:tuitu/pages/main/views/widgets/contact_info.dart';
import 'package:tuitu/pages/main/views/widgets/login_status.dart';
import 'package:tuitu/pages/main/views/widgets/menu_group.dart';
import 'package:tuitu/pages/main/views/widgets/sponsor_info.dart';
import 'package:window_manager/window_manager.dart';
import '../../../config/change_settings.dart';
import '../../../config/global_params.dart';
import '../../../utils/common_methods.dart';
import '../../../widgets/auto_scroll_text.dart';
import '../../../widgets/image_preview_widget.dart';
import '../../../widgets/keep_alive_page.dart';
import '../../../widgets/menu_item.dart';
import '../../../widgets/window_button.dart';
import '../../ai_art_images.dart';
import '../../ai_chat_page.dart';
import '../../ai_music_page.dart';
import '../../ai_video_page.dart';
import '../../article_generator_view.dart';
import '../../create_knowledge_base_page.dart';
import '../../manage_packages_page.dart';
import '../../manage_user_page.dart';
import '../../random_generator_view.dart';
import '../../settings/view/settings_page.dart';
import '../../work_flows/views/work_flows_view.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = MainViewModel();
        viewModel.init(context);
        return viewModel;
      },
      child: const _MainPageView(),
    );
  }
}

class _MainPageView extends StatelessWidget {
  const _MainPageView();

  void initEasyLoading(ChangeSettings settings) {
    EasyLoading.instance
      ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.circle
      ..loadingStyle = getRealDarkMode(settings) ? EasyLoadingStyle.dark : EasyLoadingStyle.light
      ..indicatorSize = 45.0
      ..radius = 10.0
      ..progressColor = Colors.white
      ..backgroundColor = Colors.blueAccent
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..userInteractions = true
      ..dismissOnTap = true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ChangeSettings>();
    final Orientation orientation = MediaQuery.of(context).orientation;
    final bool isPC = Platform.isWindows || Platform.isMacOS;
    initEasyLoading(settings);
    return Consumer<MainViewModel>(builder: (context, viewModel, child) {
      return Scaffold(
        key: viewModel.scaffoldKey,
        appBar: (isPC || (!isPC && orientation == Orientation.portrait))
            ? AppBar(
                automaticallyImplyLeading: false,
                toolbarHeight: isPC ? 80 : 48, // 增加AppBar高度
                backgroundColor: settings.getAppbarColor(),
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    color: settings.getAppbarColor(),
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        if (isPC) ...[
                          SizedBox(
                            height: 32, // 设置固定高度以确保拖动区域稳定
                            child: Stack(
                              children: [
                                // 应用图标和标题
                                Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/app_icon.png',
                                        height: 20,
                                        width: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '魔镜AI',
                                        style: TextStyle(color: settings.getAppbarTextColor()),
                                      ),
                                    ],
                                  ),
                                ),
                                // 添加一个全屏的拖动区域作为底层
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent, // 确保即使是透明区域也能响应事件
                                    onPanStart: (details) {
                                      windowManager.startDragging();
                                    },
                                    onDoubleTap: () async {
                                      if (viewModel.isAppIntoFullScreen) {
                                        windowManager.unmaximize();
                                        viewModel.isAppIntoFullScreen = false;
                                      } else {
                                        windowManager.maximize();
                                        viewModel.isAppIntoFullScreen = true;
                                      }
                                    },
                                    child: Container(
                                      color: Colors.transparent, // 透明容器，但可以接收事件
                                    ),
                                  ),
                                ),
                                // 窗口控制按钮
                                if (Platform.isWindows)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        WindowButton(
                                          tooltip: '最小化',
                                          iconPath: 'assets/images/min_window.svg',
                                          onTap: () {
                                            windowManager.minimize();
                                          },
                                        ),
                                        WindowButton(
                                          isMaximizeButton: true,
                                          tooltip: viewModel.isAppIntoFullScreen ? '向下还原' : '最大化',
                                          iconPath: viewModel.isAppIntoFullScreen
                                              ? 'assets/images/max_window.svg'
                                              : 'assets/images/into_max_window.svg',
                                          onTap: () async {
                                            if (viewModel.isAppIntoFullScreen) {
                                              windowManager.unmaximize();
                                              viewModel.isAppIntoFullScreen = false;
                                            } else {
                                              windowManager.maximize();
                                              viewModel.isAppIntoFullScreen = true;
                                            }
                                          },
                                        ),
                                        WindowButton(
                                          tooltip: '退出',
                                          iconPath: 'assets/images/close_window.svg',
                                          onTap: () {
                                            windowManager.close();
                                          },
                                          isCloseButton: true,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        // AppBar标题和操作按钮
                        Expanded(
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      Icons.menu,
                                      color: settings.getAppbarTextColor(),
                                      size: 30,
                                    ),
                                    onPressed: () async {
                                      FocusScope.of(context).unfocus();
                                      viewModel.scaffoldKey.currentState?.openDrawer();
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    viewModel.title,
                                    style: TextStyle(
                                      color: settings.getAppbarTextColor(),
                                      fontSize: 24,
                                    ),
                                  ),
                                  Expanded(
                                      child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Tooltip(
                                        message: settings.nextThemeModeDescription,
                                        child: IconButton(
                                          icon: Icon(
                                            settings.themeIcon,
                                            color: settings.getAppbarTextColor(),
                                          ),
                                          onPressed: () {
                                            settings.toggleTheme();
                                            // showHint('已切换至${settings.themeModeDescription}', showType: 4, showTime: 100, showPosition: 3);
                                          },
                                        ),
                                      ),
                                      Visibility(
                                          visible: (GlobalParams.isAdminVersion && viewModel.selectedIndex == 12) ||
                                              (!GlobalParams.isAdminVersion && viewModel.selectedIndex == 9),
                                          child: Row(
                                            children: [
                                              Visibility(
                                                  visible: GlobalParams.isAdminVersion || GlobalParams.isFreeVersion,
                                                  child: Row(
                                                    children: [
                                                      Tooltip(
                                                        message: '上传配置',
                                                        child: IconButton(
                                                          icon: const Icon(Icons.cloud_upload),
                                                          color: settings.getAppbarTextColor(),
                                                          onPressed: viewModel.uploadSettings,
                                                        ),
                                                      ),
                                                      Tooltip(
                                                        message: '下载配置',
                                                        child: IconButton(
                                                          icon: const Icon(Icons.cloud_download),
                                                          color: settings.getAppbarTextColor(),
                                                          onPressed: viewModel.downloadNetSettings,
                                                        ),
                                                      ),
                                                    ],
                                                  )),
                                            ],
                                          )),
                                    ],
                                  )),
                                ],
                              ),
                              if (viewModel.showBroadcast) ...[
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0, // Leave space for close button
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: settings.getBackgroundColor().withAlpha(204),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 80, // Leave space for close button
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: AutoScrollText(
                                      text: viewModel.broadcastMessage,
                                      textStyle: TextStyle(
                                        fontSize: 16,
                                        color: settings.getForegroundColor(),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                    top: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: const EdgeInsets.only(right: 16),
                                      decoration: const BoxDecoration(
                                        borderRadius:
                                            BorderRadius.only(bottomRight: Radius.circular(4), topRight: Radius.circular(4)),
                                      ),
                                      child: Center(
                                          child: TextButton(
                                        style: TextButton.styleFrom(
                                          backgroundColor: settings.getSelectedBgColor(),
                                          foregroundColor: settings.getCardTextColor(),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          '我知道了',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: () {
                                          viewModel.showBroadcast = false;
                                        },
                                      )),
                                    )),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        drawer: Drawer(
          child: SafeArea(
              child: Container(
            decoration: BoxDecoration(color: settings.getBackgroundColor()),
            child: Column(
              children: <Widget>[
                // 抽屉头部
                Visibility(
                    visible: isPC || (!isPC && orientation == Orientation.portrait),
                    child: SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: DrawerHeader(
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        child: Stack(fit: StackFit.expand, children: <Widget>[
                          viewModel.topImageUrl != ''
                              ? ImagePreviewWidget(
                                  imageUrl: viewModel.topImageUrl,
                                  previewWidth: double.infinity,
                                  previewHeight: 240,
                                  radius: 0,
                                  padding: const EdgeInsets.all(0),
                                  alignment: Alignment.topCenter,
                                  onDoubleTap: () => viewModel.getImages(),
                                )
                              : const Image(
                                  image: AssetImage('assets/images/drawer_top_bg.png'),
                                  fit: BoxFit.cover,
                                ),
                          if (getRealDarkMode(settings))
                            IgnorePointer(
                                child: Container(
                              color: Colors.black.withAlpha(76),
                            ))
                        ]),
                      ),
                    )),
                // 菜单列表
                Expanded(
                    child: Stack(
                  fit: StackFit.expand,
                  // 允许子组件超出Stack的范围
                  clipBehavior: Clip.none,
                  children: [
                    ListView(
                      padding: const EdgeInsets.all(0),
                      controller: viewModel.scrollController, // 添加滚动控制器
                      children: [
                        // AI 相关功能组

                        buildMenuGroup(
                            title: "AI 创作",
                            items: [
                              MenuItem(
                                icon: Icons.chat,
                                title: 'AI助手',
                                onTap: () => viewModel.onItemTapped(0, 'AI助手', context),
                                settings: settings,
                              ),
                              MenuItem(
                                icon: Icons.brush,
                                title: 'AI绘画',
                                onTap: () => viewModel.onItemTapped(1, 'AI绘画', context),
                                settings: settings,
                              ),
                              MenuItem(
                                icon: Icons.video_library,
                                title: 'AI视频',
                                onTap: () => viewModel.onItemTapped(2, 'AI视频', context),
                                settings: settings,
                              ),
                              MenuItem(
                                icon: Icons.music_note,
                                title: 'AI音乐',
                                onTap: () => viewModel.onItemTapped(3, 'AI音乐', context),
                                settings: settings,
                              ),
                            ],
                            settings: settings),

                        Divider(
                          height: 1,
                          color: settings.getSelectedBgColor(),
                        ),

                        // 创作工具组
                        buildMenuGroup(
                            title: "创作工具",
                            items: [
                              MenuItem(
                                  icon: Icons.edit_note,
                                  title: '小说推文助手',
                                  onTap: () => viewModel.onItemTapped(4, '小说推文助手', context),
                                  settings: settings),
                              MenuItem(
                                  icon: Icons.palette,
                                  title: '艺术图片生成',
                                  onTap: () => viewModel.onItemTapped(5, '艺术图片生成', context),
                                  settings: settings),
                              MenuItem(
                                  icon: Icons.workspaces_filled,
                                  title: '工作流',
                                  onTap: () => viewModel.onItemTapped(6, '工作流', context),
                                  settings: settings),
                            ],
                            settings: settings),

                        Divider(
                          height: 1,
                          color: settings.getSelectedBgColor(),
                        ),

                        // 资源管理组
                        buildMenuGroup(
                            title: "资源管理",
                            items: [
                              MenuItem(
                                  icon: Icons.library_books,
                                  title: '知识库',
                                  onTap: () => viewModel.onItemTapped(7, '知识库', context),
                                  settings: settings),
                              MenuItem(
                                  icon: Icons.photo_library,
                                  title: '画廊',
                                  onTap: () => viewModel.onItemTapped(8, '画廊', context),
                                  settings: settings),
                            ],
                            settings: settings),

                        if (GlobalParams.isAdminVersion) ...[
                          Divider(
                            height: 1,
                            color: settings.getSelectedBgColor(),
                          ),
                          // 管理员功能组
                          buildMenuGroup(
                              title: "管理功能",
                              items: [
                                MenuItem(
                                    icon: Icons.people,
                                    title: '用户管理',
                                    onTap: () => viewModel.onItemTapped(9, '用户管理', context),
                                    settings: settings),
                                MenuItem(
                                    icon: Icons.card_membership,
                                    title: '套餐设置',
                                    onTap: () => viewModel.onItemTapped(10, '套餐设置', context),
                                    settings: settings),
                              ],
                              settings: settings),
                        ],

                        if (!GlobalParams.isFreeVersion) ...[
                          Divider(
                            height: 1,
                            color: settings.getSelectedBgColor(),
                          ),
                          MenuItem(
                              icon: Icons.shopping_cart,
                              title: '购买套餐',
                              onTap: () => viewModel.onItemTapped(GlobalParams.isAdminVersion ? 11 : 9, '购买套餐', context),
                              settings: settings),
                        ],

                        Divider(
                          height: 1,
                          color: settings.getSelectedBgColor(),
                        ),
                        MenuItem(
                            icon: Icons.settings,
                            title: '设置',
                            onTap: () => viewModel.onItemTapped(
                                GlobalParams.isFreeVersion
                                    ? 9
                                    : GlobalParams.isAdminVersion
                                        ? 12
                                        : 10,
                                '设置',
                                context),
                            settings: settings),
                      ],
                    ),
                    // 向下滚动指示器
                    if (viewModel.showScrollIndicator)
                      Visibility(
                          visible: true,
                          child: Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: settings.getBackgroundColor().withAlpha(204),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: IconButton(
                                    onPressed: viewModel.scrollToBottom,
                                    icon: Icon(
                                      Icons.arrow_circle_down,
                                      color: settings.getForegroundColor(),
                                      size: 24,
                                    ),
                                    padding: const EdgeInsets.all(5),
                                  )),
                            ),
                          )),
                  ],
                )),
                // 底部信息区域
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: settings.getBackgroundColor(),
                    border: Border(
                      top: BorderSide(
                        color: settings.getForegroundColor().withAlpha(25),
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 登录状态显示
                      buildLoginStatus(settings, viewModel.isLogin, context, viewModel.onLoginTap, viewModel.onUserTap,
                          viewModel.userName, viewModel.onLogoutTap),
                      const SizedBox(height: 4),
                      // 版本号
                      InkWell(
                        onTap: () => viewModel.checkForUpdate(context, isAutoCheck: false),
                        onDoubleTap: () async {
                          viewModel.showUploadNewVersionFileDialog(context);
                        },
                        child: Text(
                          '版本号：${GlobalParams.version}',
                          style: TextStyle(
                            color: settings.getForegroundColor(),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 联系方式
                      buildContactInfo(settings, context, viewModel.onContactInfoTap),
                      if (!GlobalParams.isFreeVersion) ...[
                        const SizedBox(height: 6),
                      ],
                      // 赞助信息
                      if (GlobalParams.isFreeVersion) ...[
                        buildSponsorInfo(settings, context, viewModel.onSponsorInfoTap),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          )),
        ),
        body: PageView.builder(
          controller: viewModel.pageController,
          onPageChanged: (index) {
            viewModel.onPageChanged(index, context);
          },
          itemCount: GlobalParams.isAdminVersion
              ? 13
              : GlobalParams.isFreeVersion
                  ? 10
                  : 11, // 页面数量
          itemBuilder: (context, index) {
            switch (index) {
              case 0:
                return const KeepAlivePage(
                  child: AIChatPage(),
                );
              case 1:
                return const KeepAlivePage(child: RandomGeneratorView(isGallery: false));
              case 2:
                return const KeepAlivePage(child: AiVideoPage());
              case 3:
                return const KeepAlivePage(child: AiMusicPage());
              case 4:
                return const KeepAlivePage(child: ArticleGeneratorView());
              case 5:
                return const KeepAlivePage(child: AIArtImagesView());
              case 6:
                return const KeepAlivePage(child: WorkFlowsView());
              case 7:
                return const KeepAlivePage(child: CreateKnowledgeBasePage());
              case 8:
                return const RandomGeneratorView(isGallery: true);
              case 9:
                return GlobalParams.isFreeVersion
                    ? const KeepAlivePage(child: SettingsPage())
                    : !GlobalParams.isAdminVersion
                        ? const ManagePackagesPage(isBuy: true)
                        : const KeepAlivePage(child: ManageUserPage());
              case 10:
                return GlobalParams.isAdminVersion
                    ? const KeepAlivePage(child: ManagePackagesPage(isBuy: false))
                    : const KeepAlivePage(child: SettingsPage());
              case 11:
                return const ManagePackagesPage(isBuy: true);
              case 12:
                return const KeepAlivePage(child: SettingsPage());
              default:
                return Container();
            }
          },
        ),
      );
    });
  }
}
