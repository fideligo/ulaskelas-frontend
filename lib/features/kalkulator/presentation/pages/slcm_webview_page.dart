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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BaseColors.white,
      appBar: AppBar(
        backgroundColor: BaseColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BaseColors.mineShaft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'SSO Login',
          style: FontTheme.poppins14w700black().copyWith(
            fontSize: 16,
          ),
        ),
        titleSpacing: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
