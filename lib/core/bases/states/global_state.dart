part of '_states.dart';

/// Top level injection
final searchCourseRM = RM.inject(
  SearchCourseState.new,
  autoDisposeWhenNotUsed: false,
);

final filterRM = RM.inject(
  FilterState.new,
  autoDisposeWhenNotUsed: false,
);

// final reviewRM = RM.inject(
//   () => ReviewState(),
//   autoDisposeWhenNotUsed: false,
// );

final reviewFormRM = RM.inject(
  ReviewCourseFormState.new,
  autoDisposeWhenNotUsed: false,
);

final searchTagRM = RM.inject(
  SearchTagState.new,
);

final bookmarkRM = RM.inject(
  BookmarkState.new,
  autoDisposeWhenNotUsed: false,
);

final authRM = RM.inject(
  AuthState.new,
  autoDisposeWhenNotUsed: false,
);

final progressWebView = RM.inject(
  ProgressWebViewState.new,
);

final currentTermCourseRM = RM.inject(
  CurrentTermCourseState.new,
  autoDisposeWhenNotUsed: false,
);

final profileRM = RM.inject(
  ProfileState.new,
  autoDisposeWhenNotUsed: false,
);

final reviewCourseRM = RM.inject(
  ReviewCourseState.new,
  autoDisposeWhenNotUsed: false,
);

final reviewHistoryRM = RM.inject(
  ReviewHistoryState.new,
  autoDisposeWhenNotUsed: false,
);

final courseDetailRM = RM.inject(
  CourseDetailState.new,
);

final leaderboardRM = RM.inject(
  LeaderboardState.new,
);

final semesterRM = RM.inject(
  SemesterState.new,
);

final calculatorRM = RM.inject(
  CalculatorState.new,
);

final addSemesterRM = RM.inject(
  AddSemesterState.new,
);

final autoFillRM = RM.inject(
  AutoFillState.new,
);

final manualFillRM = RM.inject(
  ManualFillState.new,
  autoDisposeWhenNotUsed: false,
);

final componentRM = RM.inject(
  ComponentState.new,
);

final calculatorComponentRM = RM.inject(
  CalculatorComponentState.new,
);

final componentFormRM = RM.inject(
  ComponentFormState.new,
  autoDisposeWhenNotUsed: false,
);

final questionsRM = RM.inject(
  QuestionState.new,
);

final searchQuestionRM = RM.inject(
  SearchQuestionState.new,
);

final answersRM = RM.inject(
  AnswerState.new,
);

final questionFormRM = RM.inject(
  QuestionFormState.new,
);

final answerFormRM = RM.inject(
  AnswerFormState.new,
);

final mockComponentRM = RM.inject(
  MockComponentState.new,
);

/// Selected tab of the bottom navigation bar in `MainPage`.
///
/// Global rather than local widget state so that a notification deep link can
/// switch tabs from outside the widget tree. Not auto-disposed, because the
/// router may write to it before `MainPage` has mounted.
final mainTabRM = RM.inject(
  () => 0,
  autoDisposeWhenNotUsed: false,
);

/// Indices into `MainPage`'s children. Declared alongside [mainTabRM] because
/// both must be updated when a tab is added or reordered.
class MainTab {
  static const int beranda = 0;
  static const int matkul = 1;
  static const int tanyaTeman = 2;
  static const int kalkulator = 3;
  static const int profil = 4;
}

/// Semua state harus diinject di global state
class GlobalState {
  static List<Injectable> injectDataMocks() {
    return <Injectable>[
      Inject(
        () => ThemeState(
          themeData: ThemeData(
            primaryColor: BaseColors.purpleHearth,
          ),
        ),
      ),
      Inject(NavigationServiceState.new),
      Inject(FilterState.new),
      Inject(SearchCourseState.new),
      // Inject(() => ReviewState()),
      Inject(SearchTagState.new),
      Inject(BookmarkState.new),
      Inject(CalculatorState.new),
      Inject(AddSemesterState.new),
      Inject(AutoFillState.new),
      Inject(ManualFillState.new),
      Inject(SemesterState.new),
      Inject(QuestionState.new),
      Inject(SearchQuestionState.new),
      Inject(AnswerState.new),
      Inject(QuestionFormState.new),
      Inject(AnswerFormState.new),
      Inject(MockComponentState.new),
      Inject<int>(() => 0),
    ];
  }

  static List<Injectable> injectData = <Injectable>[
    Inject(ThemeState.new),
    Inject(NavigationServiceState.new),
    Inject(FilterState.new),
    Inject(SearchCourseState.new),
    // Inject(() => ReviewState()),
    Inject(SearchTagState.new),
    Inject(BookmarkState.new),
    Inject(CalculatorState.new),
    Inject(AddSemesterState.new),
    Inject(AutoFillState.new),
    Inject(ManualFillState.new),
    Inject(SemesterState.new),
    Inject(QuestionState.new),
    Inject(SearchQuestionState.new),
    Inject(AnswerState.new),
    Inject(QuestionFormState.new),
    Inject(AnswerFormState.new),
    Inject(MockComponentState.new),
    Inject<int>(() => 0),
  ];

  static ReactiveModel<ThemeState> theme() {
    return Injector.getAsReactive<ThemeState>();
  }

  static ReactiveModel<NavigationServiceState> navigation() {
    return Injector.getAsReactive<NavigationServiceState>();
  }
}
