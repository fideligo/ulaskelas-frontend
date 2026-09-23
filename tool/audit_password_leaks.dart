// Fails if the SLCM password can reach storage, a log, or a crash report.
//
// Run it by hand or from CI:
//
//     fvm dart run tool/audit_password_leaks.dart
//
// Exits 0 when clean, 1 with a report otherwise.
//
// ## What it actually checks
//
// A line under `lib/` that mentions a password-ish identifier *and* one of the
// sinks below is a finding. That is deliberately blunt: the point is to catch
// the accidental `Pref.saveString('pw', password)` or `print(credentials)`, not
// to prove absence in general. Anything it flags needs a human to look, and
// anything genuinely safe gets an `// ignore: password-audit` on the line.
//
// It cannot see through indirection - assigning the password to a variable
// called `value` and persisting that would pass - so it is a tripwire, not a
// guarantee. `test/unit/slcm_credentials_test.dart` covers the other half by
// pinning the redaction behaviour itself.

import 'dart:io';

/// Identifiers that plausibly hold the secret.
final RegExp _secretHolder = RegExp(
  r'\b(password|credentials|SlcmCredentials)\b',
  caseSensitive: false,
);

/// Somewhere a secret must never end up.
final Map<String, RegExp> _sinks = <String, RegExp>{
  'SharedPreferences / Pref': RegExp(
    r'\b(Pref\.(save|set)\w*|SharedPreferences|setString|setBool)\b',
  ),
  'GetStorage': RegExp(r'\bGetStorage\b'),
  'FlutterSecureStorage': RegExp(r'\b(FlutterSecureStorage|secureStorage)\b'),
  'Hive': RegExp(r'\b(Hive|\.put\()'),
  'print / debugPrint': RegExp(r'\b(print|debugPrint)\s*\('),
  'Logger': RegExp(r'\bLogger\s*\(\s*\)\s*\.\w+|\blogger\.\w+'),
  'Crashlytics': RegExp(r'\bFirebaseCrashlytics\b|\brecordError\b|\blog\s*\('),
  'file write': RegExp(r'\bFile\s*\(|writeAsString'),
};

/// Escape hatch for a line a human has already cleared.
final RegExp _ignore = RegExp(r'//\s*ignore:\s*password-audit');

class Finding {
  Finding(this.path, this.line, this.sink, this.text);

  final String path;
  final int line;
  final String sink;
  final String text;

  @override
  String toString() => '  $path:$line  [$sink]\n      ${text.trim()}';
}

void main() {
  final root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('Run this from the project root (lib/ not found).');
    exit(2);
  }

  final findings = <Finding>[];
  var scanned = 0;

  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    // Generated code is not hand-written and is excluded from lint too.
    if (entity.path.endsWith('.g.dart')) {
      continue;
    }
    scanned++;
    final lines = entity.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_ignore.hasMatch(line) || !_secretHolder.hasMatch(line)) {
        continue;
      }
      // A doc comment explaining the rule is not a violation of it.
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('///') || trimmed.startsWith('//')) {
        continue;
      }
      for (final entry in _sinks.entries) {
        if (entry.value.hasMatch(line)) {
          findings.add(Finding(entity.path, i + 1, entry.key, line));
        }
      }
    }
  }

  stdout.writeln('Scanned $scanned Dart files under lib/.');
  if (findings.isEmpty) {
    stdout.writeln('PASS - no password-bearing line reaches a storage, '
        'logging, or crash-reporting sink.');
    exit(0);
  }

  stdout.writeln('FAIL - ${findings.length} suspicious line(s):');
  for (final finding in findings) {
    stdout.writeln(finding);
  }
  stdout.writeln(
    '\nIf a line is genuinely safe, append "// ignore: password-audit" '
    'and say why in a comment above it.',
  );
  exit(1);
}
