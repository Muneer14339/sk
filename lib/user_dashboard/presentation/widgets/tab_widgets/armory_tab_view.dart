// lib/user_dashboard/presentation/widgets/tab_widgets/armory_tab_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../core/theme/user_app_theme.dart';
import '../common/common_widgets.dart';
import '../report_tab_widget.dart';
import 'ammunition_tab_widget.dart';
import 'firearms_tab_widget.dart';
import 'gear_tab_widget.dart';
import 'loadouts_tab_widget.dart';
import 'tools_tab_widget.dart';

enum ArmoryTabType { firearms, ammunition, gear, tools, loadouts, report, maintenence }

class ArmoryTabView extends StatefulWidget {
  const ArmoryTabView({super.key});

  @override
  State<ArmoryTabView> createState() => _ArmoryTabViewState();
}

class _ArmoryTabViewState extends State<ArmoryTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? userId;
  int _selectedTabIndex = 0;

  final List<TabInfo> _tabs = [
    TabInfo(
      title: 'Firearms',
      tabType: ArmoryTabType.firearms,
    ),
    TabInfo(
      title: 'Ammo',
      tabType: ArmoryTabType.ammunition,
    ),
    TabInfo(
      title: 'Gear',
      tabType: ArmoryTabType.gear,
    ),
    TabInfo(
      title: 'Tools & Maint.',
      tabType: ArmoryTabType.tools,
    ),
    TabInfo(
      title: 'Loadouts',
      tabType: ArmoryTabType.loadouts,
    ),
    TabInfo(
      title: 'Report',
      tabType: ArmoryTabType.report,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
        _loadDataForTab(_tabs[_tabController.index].tabType);
      }
    });
    userId = FirebaseAuth.instance.currentUser?.uid;

    // Load initial data for the first tab
    if (userId != null) {
      _loadDataForTab(_tabs[0].tabType);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadDataForTab(ArmoryTabType tabType) {
    if (userId == null) return;

    final bloc = context.read<ArmoryBloc>();
    switch (tabType) {
      case ArmoryTabType.firearms:
        bloc.add(LoadFirearmsEvent(userId: userId!));
        break;
      case ArmoryTabType.ammunition:
        bloc.add(LoadAmmunitionEvent(userId: userId!));
        break;
      case ArmoryTabType.gear:
        bloc.add(LoadGearEvent(userId: userId!));
        break;
      case ArmoryTabType.tools:
        bloc.add(LoadToolsEvent(userId: userId!));
        bloc.add(LoadMaintenanceEvent(userId: userId!));
        break;
      case ArmoryTabType.loadouts:
        bloc.add(LoadLoadoutsEvent(userId: userId!));
        break;
      case ArmoryTabType.report:
        bloc.add(LoadFirearmsEvent(userId: userId!));
        bloc.add(LoadAmmunitionEvent(userId: userId!));
        bloc.add(LoadGearEvent(userId: userId!));
        bloc.add(LoadToolsEvent(userId: userId!));
        bloc.add(LoadMaintenanceEvent(userId: userId!));
        bloc.add(LoadLoadoutsEvent(userId: userId!));
        break;
      case ArmoryTabType.maintenence:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (userId == null) {
          return _buildUnauthenticatedView();
        }

        return orientation == Orientation.portrait
            ? _buildPortraitLayout()
            : _buildLandscapeLayout();
      },
    );
  }

  Widget _buildUnauthenticatedView() {
    return Center(
      child: CommonWidgets.buildError('User not authenticated'),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Tab Bar
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              bottom: BorderSide(
                color: AppColors.primaryBorder,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.accentText,
            unselectedLabelColor: AppColors.secondaryText,
            indicatorColor: AppColors.accentText,
            labelStyle: AppTextStyles.tabLabel,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.itemSpacing),
            tabs: _tabs.map((tab) => Tab(text: tab.title)).toList(),
          ),
        ),
        // Tab Content
        Expanded(
          child: Container(
            decoration: AppDecorations.pageDecoration,
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _buildTabContent(tab.tabType)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Sidebar Navigation (15% width)
        Container(
          width: MediaQuery.of(context).size.width * 0.15,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              right: BorderSide(
                color: AppColors.primaryBorder,
                width: 1,
              ),
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _tabs.length,
            itemBuilder: (context, index) {
              final tab = _tabs[index];
              final isSelected = _selectedTabIndex == index;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentText.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: AppColors.accentText.withOpacity(0.3))
                      : null,
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    tab.title,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.accentText
                          : AppColors.primaryText,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                    _tabController.animateTo(index);
                  },
                ),
              );
            },
          ),
        ),
        // Main Content (85% width)
        Expanded(
          child: Container(
            decoration: AppDecorations.pageDecoration,
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _buildTabContent(tab.tabType)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(ArmoryTabType tabType) {
    return Container(
      decoration: AppDecorations.pageDecoration,
      child: RefreshIndicator(
        onRefresh: () async {
          _loadDataForTab(tabType); // Re-fetch data for the active tab
          // small delay so the refresh spinner is visible
          await Future.delayed(const Duration(milliseconds: 400));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSizes.pageMargin,
          child: _buildTabWidget(tabType),
        ),
      ),
    );
  }

  Widget _buildTabWidget(ArmoryTabType tabType) {
    if (userId == null) {
      return Center(
        child: CommonWidgets.buildError('User not authenticated'),
      );
    }

    switch (tabType) {
      case ArmoryTabType.firearms:
        return FirearmsTabWidget(userId: userId!);
      case ArmoryTabType.ammunition:
        return AmmunitionTabWidget(userId: userId!);
      case ArmoryTabType.gear:
        return GearTabWidget(userId: userId!);
      case ArmoryTabType.tools:
        return ToolsTabWidget(userId: userId!);
      case ArmoryTabType.loadouts:
        return LoadoutsTabWidget(userId: userId!);
      case ArmoryTabType.report:
        return ReportTabWidget(userId: userId!);
      case ArmoryTabType.maintenence:
        throw UnimplementedError();
    }
  }
}

class TabInfo {
  final String title;
  final ArmoryTabType tabType;

  const TabInfo({
    required this.title,
    required this.tabType,
  });
}