part of '_widgets.dart';

/// Collects the SSO credentials an SLCM autofill run needs.
///
/// Replaces the noVNC popup: the backend now signs in to SLCM over HTTP, so
/// the student types their password here instead of into a remote browser.
///
/// Resolves to the entered [SlcmCredentials], or null when the sheet is
/// dismissed. The result is handed straight to `AutoFillPage` and never
/// stored — see [SlcmCredentials] for the rules that keeps.
///
/// ## Why the password field is configured the way it is
///
/// `obscureText` hides it on screen, but on its own that is not enough:
/// `autocorrect` and `enableSuggestions` are what stop the platform keyboard
/// from learning the string into its personal dictionary, where it would
/// outlive this sheet entirely and resurface as a suggestion in other apps.
/// Both are off deliberately; do not remove them.
class SlcmCredentialSheet extends StatefulWidget {
  const SlcmCredentialSheet._({this.initialUsername});

  /// Prefilled when the previous run failed on the credentials, so a mistyped
  /// password does not cost the student their username too.
  final String? initialUsername;

  static Future<SlcmCredentials?> show(
    BuildContext context, {
    String? initialUsername,
  }) {
    return showModalBottomSheet<SlcmCredentials>(
      context: context,
      // The keyboard covers a half-height sheet, so the content has to be able
      // to scroll and grow past it.
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (_) => SlcmCredentialSheet._(initialUsername: initialUsername),
    );
  }

  @override
  State<SlcmCredentialSheet> createState() => _SlcmCredentialSheetState();
}

class _SlcmCredentialSheetState extends State<SlcmCredentialSheet> {
  late final TextEditingController _username =
      TextEditingController(text: widget.initialUsername ?? '');
  final TextEditingController _password = TextEditingController();
  final TextEditingController _semester = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    // Blanked before disposal rather than just disposed. `dispose` releases the
    // controller but leaves whatever String it held to the garbage collector's
    // own schedule; clearing drops the reference now.
    _password.clear();
    _username.dispose();
    _password.dispose();
    _semester.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _username.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _onSubmit() {
    if (!_canSubmit) {
      return;
    }
    Navigator.of(context).pop(
      SlcmCredentials(
        username: _username.text,
        password: _password.text,
        givenSemester: _semester.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lifts the sheet clear of the keyboard as it opens.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: BaseColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1, thickness: 1, color: BaseColors.gray5),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUsernameField(),
                      const HeightSpace(16),
                      _buildPasswordField(),
                      const HeightSpace(16),
                      _buildSemesterField(),
                      const HeightSpace(16),
                      _buildPrivacyNote(),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: BaseColors.gray3,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Masuk SSO UI',
              style: FontTheme.poppins16w700black(),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close_rounded,
              size: 24,
              color: BaseColors.gray2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: FontTheme.poppins14w700black().copyWith(fontSize: 15),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: FontTheme.poppins12w400black().copyWith(
        color: BaseColors.gray3,
      ),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: BaseColors.gray4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: BaseColors.purpleHearth),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Username SSO'),
        const HeightSpace(8),
        TextField(
          controller: _username,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          style: FontTheme.poppins12w400black(),
          decoration: _fieldDecoration('contoh: nama.lengkap31'),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Password SSO'),
        const HeightSpace(8),
        TextField(
          controller: _password,
          obscureText: _obscure,
          // Both off on purpose - see the class doc. Without them the platform
          // keyboard can persist the password in its own dictionary.
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.done,
          style: FontTheme.poppins12w400black(),
          decoration: _fieldDecoration('Password SSO UI').copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: BaseColors.gray2,
              ),
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _onSubmit(),
        ),
      ],
    );
  }

  Widget _buildSemesterField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel('Semester'),
            const WidthSpace(6),
            Text(
              '(opsional)',
              style: FontTheme.poppins12w400black().copyWith(
                color: BaseColors.gray2,
              ),
            ),
          ],
        ),
        const HeightSpace(6),
        Text(
          'Kosongkan agar sistem menentukan semester berjalan.',
          style: FontTheme.poppins10w400black().copyWith(
            color: BaseColors.gray2,
          ),
        ),
        const HeightSpace(8),
        TextField(
          controller: _semester,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          style: FontTheme.poppins12w400black(),
          decoration: _fieldDecoration('contoh: 5'),
        ),
      ],
    );
  }

  Widget _buildPrivacyNote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: BaseColors.gray2,
        ),
        const WidthSpace(8),
        Expanded(
          child: Text(
            'Password hanya dipakai sekali untuk mengambil IRS kamu dan '
            'tidak disimpan di aplikasi.',
            style: FontTheme.poppins10w400black().copyWith(
              color: BaseColors.gray2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: SizedBox(
        width: double.infinity,
        child: SecondaryButton(
          height: 44,
          borderRadius: BorderRadius.circular(8),
          backgroundColor:
              _canSubmit ? BaseColors.purpleHearth : BaseColors.gray4,
          text: 'Ambil Data IRS',
          onPressed: _canSubmit ? _onSubmit : null,
        ),
      ),
    );
  }
}
