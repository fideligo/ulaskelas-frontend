// Created by Muhamad Fauzi Ridwan on 24/08/21.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ristek_material_component/ristek_material_component.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:ulaskelas/features/kalkulator/presentation/pages/_pages.dart';
import 'package:ulaskelas/services/_services.dart';
import 'package:ulaskelas/services/notification/_notification.dart';
import 'package:ulaskelas/src/bar/_bar.dart';
import 'core/bases/states/_states.dart';
import 'core/utils/in_app_tour/showcase_flow.dart';
import 'features/home/presentation/pages/_pages.dart';
import 'features/matkul/search/presentation/pages/_pages.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/tanyateman/presentation/pages/_pages.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends BaseStateful<MainPage>
    with WidgetsBindingObserver {
  late List<Widget> _children;

  @override
  void init() {
    _children = <Widget>[
      HomePage(
        onOpenCalculator: () {
          mainTabRM.state = MainTab.kalkulator;
          MixpanelService.track('open_calculator');
        },
      ),
      const SearchCoursePage(),
      // const LeaderboardPage(),   this page has been shut down
      const TanyaTemanPage(),
      const CalculatorPage(),
      const ProfilePage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tourDone = Pref.getBool('doneAppTour') ?? false;
      if (!tourDone) {
        unawaited(_startInAppTour());
      }
      // Consent is asked at the end of the tour (`showcase_flow.dart`). This
      // call only backfills installs that finished the tour before that
      // shipped; `requestIfNeeded` is a no-op once the sheet has been shown.
      unawaited(_onFirstFrame(askPermission: tourDone));
    });
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Returning to the app marks pending reminders as seen.
    if (state == AppLifecycleState.resumed) {
      unawaited(BadgeService.reset());
    }
  }

  /// Opens the tour only once `MainPage` can actually host a dialog.
  ///
  /// The previous call site — `showInAppTourOpening(navbarContext!)` straight
  /// from the first post-frame callback — assumed `ShowCaseWidget`'s builder
  /// had already run, because that builder is what assigns `navbarContext`.
  /// When that assumption does not hold the `!` throws inside a future nobody
  /// awaits, so Flutter merely prints it and the tour never opens.
  ///
  /// The failure is invisible rather than loud, and it leaves the tour
  /// half-started: every per-page showcase is gated on `doneAppTour` alone, so
  /// they keep firing, while `showInAppTourClosing` is never reached and the
  /// flag is never set. Waiting for a non-null `navbarContext` on a settled
  /// route drops both the bang and the single-frame assumption; on the path
  /// that already worked the loop exits on its first iteration.
  Future<void> _startInAppTour() async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (!mounted) return;
      final settled = ModalRoute.of(context)?.isCurrent ?? true;
      if (navbarContext != null && settled) {
        await showInAppTourOpening(navbarContext!);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    debugPrint(
      'MainPage: in-app tour skipped - navbarContext '
      '${navbarContext == null ? 'never set' : 'set'}, route never settled',
    );
  }

  Future<void> _onFirstFrame({required bool askPermission}) async {
    await BadgeService.reset();
    if (!askPermission) return;
    await NotificationPermission.requestIfNeeded();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return null;
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute(
      bottomNavigation: _convexNavigation(),
    );
  }

  @override
  Widget buildNarrowLayout(
    BuildContext context,
    SizingInformation sizeInfo,
  ) {
    return SafeArea(
      child: OnBuilder<int>.data(
        listenTo: mainTabRM,
        builder: (index) => _children[index],
      ),
    );
  }

  @override
  Widget buildWideLayout(
    BuildContext context,
    SizingInformation sizeInfo,
  ) {
    return buildNarrowLayout(
      context,
      sizeInfo,
    );
  }

  Widget? _convexNavigation() {
    return ShowCaseWidget(
      builder: (context) {
        navbarContext = context;
        // The bar recomputes `isSelected` from initialActiveIndex on every
        // build and holds no internal selection, so rebuilding it on mainTabRM
        // keeps the highlight in sync with the body, including when a deep
        // link changes the tab from outside the widget tree.
        return OnBuilder<int>.data(
          listenTo: mainTabRM,
          builder: (index) => NewRistekBotNavBar(
            initialActiveIndex: index,
            onTap: _onTabTapped,
            items: const [
              NewRistekBotNavItem(
                icon: Icons.home,
                text: 'Beranda',
              ),
              NewRistekBotNavItem(
                icon: Icons.list_alt,
                text: 'Matkul',
              ),
              // RistekBotNavItem(            this page has been shut down
              //   icon: Icons.leaderboard,      for ulaskelas revamp
              //   text: 'Klasemen',               changed into tanya teman
              // ),
              NewRistekBotNavItem(
                svgIcon: 'assets/icons/tanyateman.svg',
                text: 'Tanya Teman',
              ),
              NewRistekBotNavItem(
                icon: Icons.calculate,
                text: 'Kalkulator',
              ),
              NewRistekBotNavItem(
                icon: Icons.account_circle,
                text: 'Profil',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Also invoked by the in-app tour: `NewRistekBotNavBar` assigns its `onTap`
  /// to the global `navbarController`, which the showcase flow calls to move
  /// between tabs. Routing every change through [mainTabRM] keeps the tour,
  /// manual taps and deep links on a single code path.
  void _onTabTapped(int index) {
    switch (index) {
      case MainTab.matkul:
        MixpanelService.track('open_courses');
      case MainTab.tanyaTeman:
        MixpanelService.track('open_askfriends');
      case MainTab.kalkulator:
        MixpanelService.track('open_calculator');
      case MainTab.profil:
        MixpanelService.track('open_profile');
    }
    mainTabRM.state = index;
  }

  DateTime? preBackPress;

  @override
  Future<bool> onBackPressed() async {
    final timeGap = DateTime.now().difference(preBackPress ?? DateTime.now());
    final cantExit = timeGap >= const Duration(seconds: 2);
    preBackPress = DateTime.now();
    if (cantExit) {
      // show warning messenger.
      WarningMessenger('Press Back button again to Exit').show(ctx!);
      return false;
    } else {
      return true;
    }
  }
}
