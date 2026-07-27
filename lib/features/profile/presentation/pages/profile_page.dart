// Created by Muhamad Fauzi Ridwan on 08/11/21.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ristek_material_component/ristek_material_component.dart';
import 'package:ulaskelas/core/bases/states/_states.dart';
import 'package:ulaskelas/core/environment/_environment.dart';
import 'package:ulaskelas/core/theme/_theme.dart';
import 'package:ulaskelas/core/utils/in_app_tour/showcase_flow.dart';
import 'package:ulaskelas/features/matkul/search/presentation/widgets/_widgets.dart';
import 'package:ulaskelas/features/profile/presentation/widgets/profile_data.dart';
import 'package:ulaskelas/services/_services.dart';
import 'package:ulaskelas/services/notification/dev/dev_notification_menu.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends BaseStateful<ProfilePage> {
  static const int _devMenuTapCount = 7;

  int _avatarTaps = 0;
  Timer? _avatarTapTimer;

  @override
  void init() {}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Pref.getBool('doneAppTour') == false ||
          Pref.getBool('doneAppTour') == null) {
        showInAppTourClosing(context);
      }
    });
  }

  @override
  void dispose() {
    _avatarTapTimer?.cancel();
    super.dispose();
  }

  @override
  ScaffoldAttribute buildAttribute() {
    return ScaffoldAttribute();
  }

  @override
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return BaseAppBar(
      hasLeading: false,
      label: 'Profil Pengguna',
    );
  }

  @override
  Widget buildNarrowLayout(
    BuildContext context,
    SizingInformation sizeInfo,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 10,
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 42),
                GestureDetector(
                  onTap: _onAvatarTap,
                  child: Icon(
                    Icons.account_circle,
                    size: 140,
                    color: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 24),
                ProfileData(
                  'Nama',
                  profileRM.state.profile.name.toString(),
                ),
                // TODO(pawpaw): angkatan.
                ProfileData(
                  'Angkatan',
                  profileRM.state.profile.generation.toString(),
                ),
                ProfileData(
                  'Jurusan',
                  profileRM.state.profile.studyProgram.toString(),
                ),
              ],
            ),
          ),
          Center(
            child: InkWell(
              onTap: () {
                nav.goToBookmarksPage();
              },
              child: Text(
                'Mata Kuliah Tersimpan',
                style: FontTheme.poppins14w500black().copyWith(
                  color: BaseColors.purpleHearth,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const HeightSpace(24),
          Center(
            child: InkWell(
              onTap: () => nav.goToHomeDaftarUlasan(),
              child: Text(
                'Riwayat Ulasan',
                style: FontTheme.poppins14w500black().copyWith(
                  color: BaseColors.purpleHearth,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const HeightSpace(24),
          SecondaryButton(
            width: double.infinity,
            text: 'Keluar',
            backgroundColor: BaseColors.error,
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  @override
  Widget buildWideLayout(
    BuildContext context,
    SizingInformation sizeInfo,
  ) {
    return buildNarrowLayout(context, sizeInfo);
  }

  @override
  Future<bool> onBackPressed() async {
    return true;
  }

  Future<void> _logout() async {
    await Cleaner().cleanWhenLogout();
    unawaited(nav.replaceToSsoPage());
  }

  /// Hidden entry point to the notification simulator: seven taps on the
  /// avatar. Inert in production, where [showDevNotificationMenu] returns
  /// immediately.
  void _onAvatarTap() {
    if (!Config.isDevelopment) return;
    _avatarTapTimer?.cancel();
    _avatarTaps++;
    if (_avatarTaps >= _devMenuTapCount) {
      _avatarTaps = 0;
      unawaited(showDevNotificationMenu(context));
      return;
    }
    // Taps must be consecutive; otherwise the counter would accumulate across
    // ordinary use and eventually open the sheet.
    _avatarTapTimer = Timer(const Duration(seconds: 1), () => _avatarTaps = 0);
  }
}
