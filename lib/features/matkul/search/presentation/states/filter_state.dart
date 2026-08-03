// Created by Muhamad Fauzi Ridwan on 07/11/21.

part of '_states.dart';

class FilterState {
  final selectedType = <String>[];
  final selectedSks = <String>[];
  final selectedSemester = <String>[];
  String? selectedJurusan;
  String? selectedFakultas;

  final tempSelectedType = <String>[];
  final tempSelectedSks = <String>[];
  final tempSelectedSemester = <String>[];
  String? tempSelectedJurusan;
  String? tempSelectedFakultas;

  void initTempState() {
    tempSelectedType.clear();
    tempSelectedType.addAll(selectedType);
    tempSelectedSks.clear();
    tempSelectedSks.addAll(selectedSks);
    tempSelectedSemester.clear();
    tempSelectedSemester.addAll(selectedSemester);
    tempSelectedJurusan = selectedJurusan;
    tempSelectedFakultas = selectedFakultas;
  }

  void applyFilters() {
    selectedType.clear();
    selectedType.addAll(tempSelectedType);
    selectedSks.clear();
    selectedSks.addAll(tempSelectedSks);
    selectedSemester.clear();
    selectedSemester.addAll(tempSelectedSemester);
    selectedJurusan = tempSelectedJurusan;
    selectedFakultas = tempSelectedFakultas;
  }

  /// Major list fetched from the backend API.
  List<String> majorOrgCodes = [];
  final _majorDisplayNames = <String, String>{};
  final _majorFaculty = <String, String>{};
  final _majorStudyProgram = <String, String>{};
  final _majorEducationalProgram = <String, String>{};
  String getMajorDisplayName(String orgCode) =>
      _majorDisplayNames[orgCode] ?? orgCode;
  String getMajorFaculty(String orgCode) =>
      _majorFaculty[orgCode] ?? '';
  String getMajorStudyProgram(String orgCode) {
    final sp = _majorStudyProgram[orgCode] ?? orgCode;
    final ep = _majorEducationalProgram[orgCode] ?? '';
    if (ep.isEmpty) return sp;
    return '$sp - $ep';
  }

  /// Get sorted list of unique faculty names.
  List<String> get facultyList {
    final faculties = <String>{};
    for (final orgCode in majorOrgCodes) {
      final faculty = _majorFaculty[orgCode];
      if (faculty != null && faculty.isNotEmpty) {
        faculties.add(faculty);
      }
    }
    final sorted = faculties.toList()..sort((a, b) => a.compareTo(b));
    return sorted;
  }

  /// Get org codes filtered by the currently selected faculty.
  List<String> get filteredJurusanOrgCodes {
    if (tempSelectedFakultas == null) return [];
    return majorOrgCodes
        .where((code) => _majorFaculty[code] == tempSelectedFakultas)
        .toList();
  }

  /// Whether majors are currently being loaded from the API.
  bool isLoadingMajors = false;

  final matkulTypes = [
    CheckboxItem(
      text: 'Wajib Jurusan',
      value: 'MANDATORY',
    ),
    CheckboxItem(
      text: 'Wajib UI',
      value: 'WAJIB_UI',
    ),
    CheckboxItem(
      text: 'Pilihan',
      value: 'ELECTIVE',
    ),
  ];

  final sksTotals = [
    CheckboxItem(
      text: '2 SKS',
      value: '2',
    ),
    CheckboxItem(
      text: '3 SKS',
      value: '3',
    ),
    CheckboxItem(
      text: '4 SKS',
      value: '4',
    ),
    CheckboxItem(
      text: '6 SKS',
      value: '6',
    ),
  ];

  final semesterPreconditions = [
    CheckboxItem(
      text: 'Semester 1',
      value: '1',
    ),
    CheckboxItem(
      text: 'Semester 2',
      value: '2',
    ),
    CheckboxItem(
      text: 'Semester 3',
      value: '3',
    ),
    CheckboxItem(
      text: 'Semester 4',
      value: '4',
    ),
    CheckboxItem(
      text: 'Semester 5',
      value: '5',
    ),
    CheckboxItem(
      text: 'Semester 6',
      value: '6',
    ),
    CheckboxItem(
      text: 'Semester 7',
      value: '7',
    ),
    CheckboxItem(
      text: 'Semester 8',
      value: '8',
    ),
  ];

  /// Fallback list if API fails
  static const _fallbackMajors = [
    'F.Psi - Ilmu Psikologi',
    'F.Psi - Psikologi',
    'F.Psi - Psikologi Profesi',
    'ILMU KOMPUTER - Ilmu Komputer',
    'ILMU KOMPUTER - Sistem Informasi',
    'ILMU KOMPUTER - Sistem Informasi - Ekstensi',
    'ILMU KOMPUTER - Teknologi Informasi',
    'FEB - Akuntansi',
    'FEB - Akuntansi - Ekstensi',
    'FEB - Bisnis Islam',
    'FEB - Ilmu Akuntansi',
    'FEB - Ilmu Ekonomi',
    'FEB - Ilmu Ekonomi Islam',
    'FEB - Ilmu Manajemen',
    'FEB - Magister Akuntansi',
    'FEB - Magister Manajemen',
    'FEB - Manajemen',
    'FEB - Manajemen - Ekstensi',
    'FEB - Pendidikan Profesi Akuntansi',
    'FEB - Perencanaan & Kebijakan Publik',
    'FF - Apoteker',
    'FF - Farmasi',
    'FF - Herbal',
    'FF - Ilmu Kefarmasian',
    'FH - Ilmu Hukum',
    'FH - Ilmu Hukum - Ekstensi',
    'FH - Kenotariatan',
    'FIA - Ilmu Administrasi',
    'FIA - Ilmu Administrasi Fiskal',
    'FIA - Ilmu Administrasi Fiskal - Ekstensi',
    'FIA - Ilmu Administrasi Negara',
    'FIA - Ilmu Administrasi Negara - Ekstensi',
    'FIA - Ilmu Administrasi Niaga',
    'FIA - Ilmu Administrasi Niaga - Ekstensi',
    'FIB - Arkeologi',
    'FIB - Asia Tenggara',
    'FIB - Bahasa dan Kebudayaan Korea',
    'FIB - Ilmu Filsafat',
    'FIB - Ilmu Linguistik',
    'FIB - Ilmu Perpustakaan',
    'FIB - Ilmu Sejarah',
    'FIB - Ilmu Susastra',
    'FIB - Penerjemahan Bahasa Arab',
    'FIB - Penerjemahan Bahasa Inggris',
    'FIB - Penerjemahan Bahasa Perancis',
    'FIB - Sastra Arab',
    'FIB - Sastra Belanda',
    'FIB - Sastra Cina',
    'FIB - Sastra Daerah untuk Sastra Jawa',
    'FIB - Sastra Indonesia',
    'FIB - Sastra Inggris',
    'FIB - Sastra Jepang',
    'FIB - Sastra Jerman',
    'FIB - Sastra Perancis',
    'FIB - Sastra Rusia',
    'FIK - Ilmu Keperawatan',
    'FIK - Ilmu Keperawatan - Ekstensi',
    'FIK - Ners Spesialis Keperawatan Anak',
    'FIK - Ners Spesialis Keperawatan Jiwa',
    'FIK - Ners Spesialis Keperawatan Komunitas',
    'FIK - Ners Spesialis Keperawatan Maternitas',
    'FIK - Ners Spesialis Keperawatan Medikal Bedah',
    'FIK - Profesi Keperawatan',
    'FISIP - Antropologi',
    'FISIP - Antropologi Sosial',
    'FISIP - Ilmu Administrasi',
    'FISIP - Ilmu Administrasi Fiskal',
    'FISIP - Ilmu Administrasi Fiskal - Ekstensi',
    'FISIP - Ilmu Administrasi Negara',
    'FISIP - Ilmu Administrasi Negara - Ekstensi',
    'FISIP - Ilmu Administrasi Niaga',
    'FISIP - Ilmu Administrasi Niaga - Ekstensi',
    'FISIP - Ilmu Hub Internasional',
    'FISIP - Ilmu Hubungan Internasional',
    'FISIP - Ilmu Kesejahteraan Sosial',
    'FISIP - Ilmu Komunikasi',
    'FISIP - Ilmu Politik',
    'FISIP - Ilmu Politik - Ekstensi',
    'FISIP - Kajian Terorisme dalam Keamanan Internasional',
    'FISIP - Kriminologi',
    'FISIP - Kriminologi - Ekstensi',
    'FISIP - Sosiologi',
    'FK - Akupuntur Medik',
    'FK - Anestesiologi',
    'FK - Bedah Torak Kardiovaskular',
    'FK - Farmakologi Klinik',
    'FK - Fisioterapi',
    'FK - Ilmu Bedah',
    'FK - Ilmu Bedah Plastik',
    'FK - Ilmu Bedah Syaraf',
    'FK - Ilmu Biomedik',
    'FK - Ilmu Gizi',
    'FK - Ilmu Gizi Klinik',
    'FK - Ilmu Kedokteran',
    'FK - Ilmu Kedokteran Forensik',
    'FK - Ilmu Kedokteran Jiwa',
    'FK - Ilmu Kedokteran Olahraga',
    'FK - Ilmu Kesehatan Anak',
    'FK - Ilmu Kesehatan Kulit & Kelamin',
    'FK - Ilmu Kesehatan Mata',
    'FK - Ilmu Orthopaedi dan Traumatologi',
    'FK - Ilmu Penyakit Dalam',
    'FK - Ilmu Penyakit Jantung & Pembuluh Darah',
    'FK - Ilmu Penyakit Saraf',
    'FK - Ilmu Penyakit Telinga, Hidung & Tenggorok',
    'FK - Ilmu Rehabilitasi Medik',
    'FK - Kedokteran Kerja',
    'FK - Kedokteran Okupasi',
    'FK - Kedokteran Penerbangan',
    'FK - Mikrobiologi Klinik',
    'FK - Obstetri & Ginekologi',
    'FK - Okupasi Terapi',
    'FK - Onkologi Radiasi',
    'FK - Parasitologi Klinik',
    'FK - Patologi Anatomik',
    'FK - Patologi Klinik',
    'FK - Pendidikan Dokter',
    'FK - Pendidikan Dokter Kelas Khusus Internasional',
    'FK - Pendidikan Kedokteran',
    'FK - Perumahsakitan',
    'FK - Profesi Dokter',
    'FK - Pulmonologi dan Ilmu Kedokteran Respirasi',
    'FK - Radiologi',
    'FK - Rehabilitasi Medik',
    'FK - Urologi',
    'FKG - Ilmu Bedah Mulut',
    'FKG - Ilmu Kedokteran Gigi',
    'FKG - Ilmu Kedokteran Gigi Dasar',
    'FKG - Ilmu Kedokteran Gigi Komunitas',
    'FKG - Ilmu Kesehatan Gigi Anak',
    'FKG - Ilmu Konservasi Gigi',
    'FKG - Ilmu Penyakit Mulut',
    'FKG - Kedokteran Gigi',
    'FKG - Ortodonsia',
    'FKG - Pendidikan Dokter Gigi',
    'FKG - Periodonsia',
    'FKG - Prostodonsia',
    'FKM - Administrasi Rumah Sakit',
    'FKM - Asuransi Kesehatan',
    'FKM - Epidemiologi',
    'FKM - Ilmu Kesehatan Masyarakat',
    'FKM - Kehumasan Pelayanan Kesehatan',
    'FKM - Kesehatan Lingkungan',
    'FKM - Kesehatan Masyarakat',
    'FKM - Kesehatan Masyarakat - Ekstensi',
    'FKM - Keselamatan & Kesehatan Kerja',
    'FKM - Keselamatan dan Kesehatan Kerja',
    'FKM - Manajemen Informasi Kesehatan & Rekam Medis',
    'FKM - Manajemen Pelayanan Rumah Sakit',
    'FKM - Promosi & Pendidikan Kesehatan',
    'FKM - Studi Gizi',
    'FMIPA - Biologi',
    'FMIPA - Fisika',
    'FMIPA - Geofisika',
    'FMIPA - Geografi',
    'FMIPA - Geologi',
    'FMIPA - Ilmu Bahan-bahan',
    'FMIPA - Ilmu Fisika',
    'FMIPA - Ilmu Geografi',
    'FMIPA - Ilmu Kelautan',
    'FMIPA - Ilmu Kimia',
    'FMIPA - Kimia',
    'FMIPA - Matematika',
    'FMIPA - Statistika',
    'FT - Arsitektur',
    'FT - Arsitektur - Ekstensi',
    'FT - Arsitektur - Intl',
    'FT - Arsitektur Interior',
    'FT - Opto Elektroteknika & Aplikasi Laser',
    'FT - Pendidikan Profesi Arsitek',
    'FT - Teknik Elektro',
    'FT - Teknik Elektro - Ekstensi',
    'FT - Teknik Elektro - Intl',
    'FT - Teknik Industri',
    'FT - Teknik Industri - Ekstensi',
    'FT - Teknik Kimia',
    'FT - Teknik Kimia - Ekstensi',
    'FT - Teknik Kimia - Intl',
    'FT - Teknik Komputer',
    'FT - Teknik Lingkungan',
    'FT - Teknik Mesin',
    'FT - Teknik Mesin - Ekstensi',
    'FT - Teknik Mesin - Intl',
    'FT - Teknik Metalurgi & Material',
    'FT - Teknik Metalurgi & Material - Ekstensi',
    'FT - Teknik Metalurgi - Intl',
    'FT - Teknik Perkapalan',
    'FT - Teknik Sipil',
    'FT - Teknik Sipil - Ekstensi',
    'FT - Teknik Sipil - Intl',
    'FT - Teknologi Bioproses',
    'PASCASARJANA - Ilmu Lingkungan',
    'PASCASARJANA - Kajian Gender',
    'PASCASARJANA - Kajian Ilmu Kepolisian',
    'PASCASARJANA - Kajian Ilmu Lingkungan',
    'PASCASARJANA - Kajian Kependudukan & Ketenagaan Kerja',
    'PASCASARJANA - Kajian Ketahanan Nasional',
    'PASCASARJANA - Kajian Pengembangan Perkotaan',
    'PASCASARJANA - Kajian Wilayah Amerika',
    'PASCASARJANA - Kajian Wilayah Eropa',
    'PASCASARJANA - Kajian Wilayah Jepang',
    'PASCASARJANA - Kajian Wilayah Timur Tengah Islam',
    'PASCASARJANA - Teknologi Biomedis',
    'PEROLEHAN KREDIT - Honoris Causa',
    'PEROLEHAN KREDIT - Pertukaran Mahasiswa',
    'VOKASI - Administrasi Asuransi & Aktuaria',
    'VOKASI - Administrasi Keuangan & Perbankan',
    'VOKASI - Administrasi Perkantoran & Sekretari',
    'VOKASI - Administrasi Perpajakan',
    'VOKASI - Akuntansi',
    'VOKASI - Fisioterapi',
    'VOKASI - Komunikasi',
    'VOKASI - Manajemen Informasi & Dokumen',
    'VOKASI - Okupasi Terapi',
    'VOKASI - Pariwisata',
    'VOKASI - Perumahsakitan',
  ];

  /// Fetch the list of majors from the backend API.
  Future<void> fetchMajors() async {
    if (majorOrgCodes.isNotEmpty || isLoadingMajors) return;

    isLoadingMajors = true;
    Future.delayed(Duration.zero, () {
      filterRM.notify();
    });

    try {
      final resp = await getIt(EndpointsV1.majors);
      if (resp.statusCode == 200) {
        final body = resp.data as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>;
        final list = data['majors'] as List<dynamic>;
        final codes = <String>[];
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final orgCode = map['org_code'] as String;
          final displayName = map['display_name'] as String;
          final faculty = map['faculty'] as String? ?? '';
          final studyProgram = map['study_program'] as String? ?? '';
          final educationalProgram = map['educational_program'] as String? ?? '';
          codes.add(orgCode);
          _majorDisplayNames[orgCode] = displayName;
          _majorFaculty[orgCode] = faculty;
          _majorStudyProgram[orgCode] = studyProgram;
          _majorEducationalProgram[orgCode] = educationalProgram;
        }
        majorOrgCodes = codes;
      }
    } catch (e) {
      // If API fails, leave empty – user can still use other filters
      majorOrgCodes = [];
    } finally {
      isLoadingMajors = false;
      filterRM.notify();
    }
  }

  bool get hasFilter =>
      selectedType.isNotEmpty ||
      selectedSks.isNotEmpty ||
      selectedSemester.isNotEmpty ||
      selectedJurusan != null;

  bool get isFilteredType => selectedType.isNotEmpty;

  void pickMatkulType(String val) {
    tempSelectedType.add(val);
  }

  void discardMatkulType(String val) {
    tempSelectedType.removeWhere((element) => element == val);
  }

  void pickSksTotal(String val) {
    tempSelectedSks.add(val);
  }

  void discardSksTotal(String val) {
    tempSelectedSks.removeWhere((element) => element == val);
  }

  void pickSemesterPrecondition(String val) {
    tempSelectedSemester.add(val);
  }

  void discardSemesterPrecondition(String val) {
    tempSelectedSemester.removeWhere((element) => element == val);
  }

  void reset() {
    selectedType.clear();
    selectedSks.clear();
    selectedSemester.clear();
    selectedJurusan = null;
    selectedFakultas = null;
    tempSelectedType.clear();
    tempSelectedSks.clear();
    tempSelectedSemester.clear();
    tempSelectedJurusan = null;
    tempSelectedFakultas = null;
  }
}
