part of '_pages.dart';

/// The SLCM login screen, shown while an autofill session waits on the student.
///
/// The URL is single-use. `slcm_autofill_popup` on the backend filters on
/// `popup_opened_at__isnull=True` and stamps it on the first request, so a
/// second load answers 404 `INVALID_POPUP_TOKEN` and strands the session. The
/// load therefore happens exactly once, in `initState` — never in `build`,
/// which Flutter re-runs freely (a keyboard opening or a rotation is enough).
///
/// Unlike `SSOWebPage` this page never clears cookies: SLCM's login sets them,
/// and dropping them mid-flow would send the student back to the login form.
class SlcmWebViewPage extends StatefulWidget {
  const SlcmWebViewPage({
    required this.popupUrl,
    super.key,
  });

  final String popupUrl;

  @override
  State<SlcmWebViewPage> createState() => _SlcmWebViewPageState();
}

class _SlcmWebViewPageState extends State<SlcmWebViewPage> {
  late final WebViewController _controller;

  /// True while the DELETE is in flight, so a second back press cannot fire a
  /// second cancel or pop the page out from under the first one.
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      // Both the noVNC client and SLCM's own login are script-driven; without
      // this the page renders as a blank canvas.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            Logger().e('SLCM webview error: ${error.description}');
          },
        ),
      )
      // Once, here, and nowhere else. See the class doc.
      ..loadRequest(Uri.parse(widget.popupUrl));
  }

  @override
  void dispose() {
    // Safety net for the routes that never reach [_leave]: a predictive-back
    // gesture that completes without PopScope, or this page being removed
    // because something above it popped the stack. `isLoginPageOpen` is
    // already false when the session settled on its own, so a successful
    // scrape is never cancelled here.
    if (autoFillRM.state.isLoginPageOpen) {
      unawaited(autoFillRM.state.cancelFromLoginPage());
    }
    super.dispose();
  }

  /// Releases the SLCM session, then lets the page go.
  ///
  /// Awaited rather than fired and forgotten: the backend allows one live
  /// session at a time, so the slot has to be free before the student can get
  /// back to the Auto-Fill button, or the retry is refused with a 409.
  Future<void> _leave() async {
    if (_leaving) {
      return;
    }
    setState(() => _leaving = true);

    await autoFillRM.state.cancelFromLoginPage();

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Never pop straight away: the session has to be released first. [_leave]
      // performs the pop once the DELETE has come back.
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: BaseColors.white,
        appBar: AppBar(
          backgroundColor: BaseColors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: BaseColors.mineShaft),
            // Routed through [_leave] rather than popping directly. A bare
            // `Navigator.pop` does not consult PopScope, so it would leave the
            // session behind.
            onPressed: _leaving ? null : () => unawaited(_leave()),
          ),
          title: Text(
            'SLCM Autofill',
            style: FontTheme.poppins14w700black().copyWith(
              fontSize: 16,
            ),
          ),
          titleSpacing: 0,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
