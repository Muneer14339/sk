// lib/user_dashboard/presentation/widgets/tab_widgets/enhanced_armory_tab_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../bloc/armory_bloc.dart';
import '../../bloc/armory_event.dart';
import '../../bloc/armory_state.dart';
import '../../core/theme/user_app_theme.dart';
import '../common/common_widgets.dart';
import '../report_tab_widget.dart';
import '../navigation/grid_navigation_widget.dart';
import '../navigation/list_navigation_widget.dart';
import 'ammunition_tab_widget.dart';
import 'firearms_tab_widget.dart';
import 'gear_tab_widget.dart';
import 'loadouts_tab_widget.dart';
import 'tools_tab_widget.dart';

enum ArmoryTabType { firearms, ammunition, gear, tools, loadouts, report }

class EnhancedArmoryTabView extends StatefulWidget {
  const EnhancedArmoryTabView({super.key});

  @override
  State<EnhancedArmoryTabView> createState() => _EnhancedArmoryTabViewState();
}

class _EnhancedArmoryTabViewState extends State<EnhancedArmoryTabView> {
  String? userId;
  int _selectedTabIndex = 0;
  bool _showListContent = false; // For list navigation mode

  // Yeh map hamesha har tab ke counts store karega
  Map<ArmoryTabType, int> _counts = {
    ArmoryTabType.firearms: 0,
    ArmoryTabType.ammunition: 0,
    ArmoryTabType.gear: 0,
    ArmoryTabType.tools: 0,
    ArmoryTabType.loadouts: 0,
    ArmoryTabType.report: 0,
  };

  final List<TabInfo> _tabs = [
    TabInfo(title: 'Firearms', tabType: ArmoryTabType.firearms),
    TabInfo(title: 'Ammo', tabType: ArmoryTabType.ammunition),
    TabInfo(title: 'Gear', tabType: ArmoryTabType.gear),
    TabInfo(title: 'Tools & Maint.', tabType: ArmoryTabType.tools),
    TabInfo(title: 'Loadouts', tabType: ArmoryTabType.loadouts),
    TabInfo(title: 'Report', tabType: ArmoryTabType.report),
  ];

  bool _shouldUseSidebarLayout(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;

    // Only use sidebar for landscape WITH sufficient width (tablets/desktops)
    // Not for small landscape phones
    return orientation == Orientation.landscape && size.width >= 700;
  }

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      // Load all data initially for counts
      _loadAllData();

      // Load first tab data for grid mode
      if (AppConfig.navigationStyle == NavigationStyle.grid) {
        _loadDataForTab(_tabs[0].tabType);
      }
    }
  }

  void _loadAllData() {
    if (userId == null) return;

    final bloc = context.read<ArmoryBloc>();
    bloc.add(LoadFirearmsEvent(userId: userId!));
    bloc.add(LoadAmmunitionEvent(userId: userId!));
    bloc.add(LoadGearEvent(userId: userId!));
    bloc.add(LoadToolsEvent(userId: userId!));
    bloc.add(LoadLoadoutsEvent(userId: userId!));
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
        break;
      case ArmoryTabType.loadouts:
        bloc.add(LoadLoadoutsEvent(userId: userId!));
        break;
      case ArmoryTabType.report:
        _loadAllData();
        break;
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      if (AppConfig.navigationStyle == NavigationStyle.list) {
        _showListContent = true; // Show content, hide list
      }
    });
    _loadDataForTab(_tabs[index].tabType);
  }

  void _onBackToList() {
    setState(() {
      _showListContent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Center(child: CommonWidgets.buildError('User not authenticated'));
    }

    return WillPopScope(
      onWillPop: () async {
        if (_showListContent) {
          _onBackToList();
          return false;
        }
        return true;
      },
      child: BlocListener<ArmoryBloc, ArmoryState>(
        listener: (context, state) {
          setState(() {
            if (state is FirearmsLoaded) {
              _counts[ArmoryTabType.firearms] = state.firearms.length;
            } else if (state is AmmunitionLoaded) {
              _counts[ArmoryTabType.ammunition] = state.ammunition.length;
            } else if (state is GearLoaded) {
              _counts[ArmoryTabType.gear] = state.gear.length;
            } else if (state is ToolsLoaded) {
              _counts[ArmoryTabType.tools] = state.tools.length;
            } else if (state is LoadoutsLoaded) {
              _counts[ArmoryTabType.loadouts] = state.loadouts.length;
            }
            // Report ka count = sum of all
            _counts[ArmoryTabType.report] =
                _counts[ArmoryTabType.firearms]! +
                    _counts[ArmoryTabType.ammunition]! +
                    _counts[ArmoryTabType.gear]! +
                    _counts[ArmoryTabType.tools]! +
                    _counts[ArmoryTabType.loadouts]!;
          });
        },
        child: BlocBuilder<ArmoryBloc, ArmoryState>(
          builder: (context, state) {
            // Check layout type
            if (_shouldUseSidebarLayout(context)) {
              return _buildSidebarLayout(state);
            }
            switch (AppConfig.navigationStyle) {
              case NavigationStyle.grid:
                return _buildGridLayout(state);
              case NavigationStyle.list:
                return _buildListLayout(state);
            }
          },
        ),
      ),
    );
  }

  // NEW: Sidebar layout for landscape/tablet
  Widget _buildSidebarLayout(ArmoryState state) {
    return Row(
      children: [
        // Left Sidebar Navigation (20% width)
        Container(
          width: MediaQuery.of(context).size.width * 0.20,
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            border: Border(
              right: BorderSide(
                color: AppColors.primaryBorder,
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListNavigationWidget(
              selectedTabIndex: _selectedTabIndex,
              onTabChanged: _onTabChanged,
              state: state,
              counts: _counts,
            ),
          ),
        ),

        // Right Content Area (80% width)
        Expanded(
          child: Container(
            decoration: AppDecorations.pageDecoration,
            child: RefreshIndicator(
              onRefresh: () async {
                _loadDataForTab(_tabs[_selectedTabIndex].tabType);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSizes.pageMargin,
                child: _buildTabContent(_tabs[_selectedTabIndex].tabType),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridLayout(ArmoryState state) {
    return Column(
      children: [
        GridNavigationWidget(
          selectedTabIndex: _selectedTabIndex,
          onTabChanged: _onTabChanged,
          state: state,
        ),
        Expanded(
          child: Container(
            decoration: AppDecorations.pageDecoration,
            child: RefreshIndicator(
              onRefresh: () async {
                _loadDataForTab(_tabs[_selectedTabIndex].tabType);
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppSizes.pageMargin,
                child: _buildTabContent(_tabs[_selectedTabIndex].tabType),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListLayout(ArmoryState state) {
    return Container(
      decoration: AppDecorations.pageDecoration,
      child: _showListContent
          ? _buildListContentView()
          : _buildListNavigationView(state),
    );
  }

  Widget _buildListNavigationView(ArmoryState state) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ListNavigationWidget(
        selectedTabIndex: -1,
        onTabChanged: _onTabChanged,
        state: state,
        counts: _counts,   // 👈 yahan bhej diya
      ),
    );
  }


  Widget _buildListContentView() {
    return Column(
      children: [

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _loadDataForTab(_tabs[_selectedTabIndex].tabType);
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppSizes.pageMargin,
              child: _buildTabContent(_tabs[_selectedTabIndex].tabType),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(ArmoryTabType tabType) {
    if (userId == null) {
      return Center(child: CommonWidgets.buildError('User not authenticated'));
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