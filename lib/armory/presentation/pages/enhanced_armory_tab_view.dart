import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../armory/presentation/bloc/armory_bloc.dart';
import '../../../../armory/presentation/bloc/armory_event.dart';
import '../../../../armory/presentation/bloc/armory_state.dart';
import '../../../../armory/presentation/widgets/common/common_delete_dilogue.dart';
import '../../../../armory/presentation/widgets/common/common_widgets.dart';
import '../../../../armory/presentation/widgets/navigation/grid_navigation_widget.dart';
import '../../../../armory/presentation/widgets/navigation/list_navigation_widget.dart';
import '../../../../armory/presentation/widgets/tab_widgets/ammunition_tab_widget.dart';
import '../../../../armory/presentation/widgets/tab_widgets/firearms_tab_widget.dart';
import '../../../../armory/presentation/widgets/tab_widgets/gear_tab_widget.dart';
import '../../../../armory/presentation/widgets/tab_widgets/loadouts_tab_widget.dart';
import '../../../../armory/presentation/widgets/tab_widgets/report_tab_widget.dart';
import '../../../../armory/presentation/widgets/tab_widgets/tools_tab_widget.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';


class EnhancedArmoryTabView extends StatefulWidget {
  const EnhancedArmoryTabView({super.key});

  @override
  State<EnhancedArmoryTabView> createState() => _EnhancedArmoryTabViewState();
}

class _EnhancedArmoryTabViewState extends State<EnhancedArmoryTabView> {
  String? userId;
  int _selectedTabIndex = 0;
  bool _showListContent = false;

  final List<TabInfo> _tabs = [
    TabInfo(title: 'Firearms', tabType: ArmoryTabType.firearms),
    TabInfo(title: 'Ammo', tabType: ArmoryTabType.ammunition),
    TabInfo(title: 'Gear', tabType: ArmoryTabType.gear),
    TabInfo(title: 'Tools & Maint.', tabType: ArmoryTabType.tools),
    TabInfo(title: 'Loadouts', tabType: ArmoryTabType.loadouts),
    TabInfo(title: 'Report', tabType: ArmoryTabType.report),
  ];

  bool _shouldUseSidebarLayout(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.landscape;
  }

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId != null) {
      context.read<ArmoryBloc>().add(LoadAllDataEvent(userId: userId!));
    }
  }

  // Replace _onTabChanged method (line ~50)
  void _onTabChanged(int index) {
    if (mounted) {
      // Hide form if open to preserve data state
      final state = context.read<ArmoryBloc>().state;
      if (state is ShowingAddForm) {
        context.read<ArmoryBloc>().add(const HideFormEvent());
      }

      setState(() {
        _selectedTabIndex = index;
        if (AppConfig.navigationStyle == NavigationStyle.list) {
          _showListContent = true;
        }
      });
    }
  }

  void _navigateToAddAmmo() {
    setState(() {
      _selectedTabIndex = 1; // Ammunition tab index
      if (AppConfig.navigationStyle == NavigationStyle.list) {
        _showListContent = true;
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<ArmoryBloc>().add(
          ShowAddFormEvent(tabType: ArmoryTabType.ammunition),
        );
      }
    });
  }

  void _onBackToList() {
    if (mounted) {
      setState(() {
        _showListContent = false;
      });
    }
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
      child: BlocBuilder<ArmoryBloc, ArmoryState>(
        builder: (context, state) {
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
    );
  }

  Map<ArmoryTabType, int> _getCounts(ArmoryState state) {
    if (state is ArmoryDataLoaded) {
      return {
        ArmoryTabType.firearms: state.firearms.length,
        ArmoryTabType.ammunition: state.ammunition.length,
        ArmoryTabType.gear: state.gear.length,
        ArmoryTabType.tools: state.tools.length,
        ArmoryTabType.maintenence : state.maintenance.length,
        ArmoryTabType.loadouts: state.loadouts.length,
        ArmoryTabType.report: state.firearms.length + state.ammunition.length + state.gear.length + state.tools.length +state.maintenance.length +state.loadouts.length,
      };
    } else if (state is ShowingAddForm) {
      // ✅ ShowingAddForm se bhi counts nikalo
      return {
        ArmoryTabType.firearms: state.firearms.length,
        ArmoryTabType.ammunition: state.ammunition.length,
        ArmoryTabType.gear: state.gear.length,
        ArmoryTabType.tools: state.tools.length,
        ArmoryTabType.loadouts: state.loadouts.length,
        ArmoryTabType.report: state.firearms.length + state.ammunition.length + state.gear.length + state.tools.length + state.loadouts.length,
      };
    }
    return {
      ArmoryTabType.firearms: 0,
      ArmoryTabType.ammunition: 0,
      ArmoryTabType.gear: 0,
      ArmoryTabType.tools: 0,
      ArmoryTabType.loadouts: 0,
      ArmoryTabType.report: 0,
    };
  }

  Widget _buildSidebarLayout(ArmoryState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.20,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.surface(context),
            border: Border(right: BorderSide(color: AppTheme.border(context), width: 1)),
          ),
          child: ListNavigationWidget(
            selectedTabIndex: _selectedTabIndex,
            onTabChanged: _onTabChanged,
            state: state,
            counts: _getCounts(state),
          ),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppTheme.background(context)),
            alignment: Alignment.topLeft,
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ArmoryBloc>().add(LoadAllDataEvent(userId: userId!));
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppTheme.paddingLarge,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.topLeft,
                  child: _buildTabContent(_tabs[_selectedTabIndex].tabType),
                ),
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
          counts: _getCounts(state),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: AppTheme.background(context)),
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ArmoryBloc>().add(LoadAllDataEvent(userId: userId!));
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppTheme.paddingLarge,
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
      decoration: BoxDecoration(color: AppTheme.background(context)),
      child: _showListContent ? _buildListContentView() : _buildListNavigationView(state),
    );
  }

  Widget _buildListNavigationView(ArmoryState state) {
    return ListNavigationWidget(
      selectedTabIndex: -1,
      onTabChanged: _onTabChanged,
      state: state,
      counts: _getCounts(state),
    );
  }

  Widget _buildListContentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            alignment: Alignment.topLeft,
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<ArmoryBloc>().add(LoadAllDataEvent(userId: userId!));
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppTheme.paddingLarge,
                child: _buildTabContent(_tabs[_selectedTabIndex].tabType),
              ),
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
        return LoadoutsTabWidget(
          userId: userId!,
          onNavigateToAddAmmo: _navigateToAddAmmo, // ADD THIS
        );
      case ArmoryTabType.report:
        return ReportTabWidget(userId: userId!);
      case ArmoryTabType.maintenence:
        return ToolsTabWidget(userId: userId!);
    }
  }
}

class TabInfo {
  final String title;
  final ArmoryTabType tabType;

  const TabInfo({required this.title, required this.tabType});
}