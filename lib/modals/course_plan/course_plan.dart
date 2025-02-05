import 'package:bsmrau_cg/modals/course_plan/course.dart';
import 'package:bsmrau_cg/modals/course_plan/course_location.dart';
import 'package:bsmrau_cg/modals/course_plan/level.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
part 'course_plan.g.dart';

@HiveType(typeId: 4)
class CoursePlan extends HiveObject {
  @HiveField(0)
  CourseLocation startLocation;

  @HiveField(3)
  CourseLocation currentLocation;

  @HiveField(1)
  double startCgpa = 0.00;

  @HiveField(2)
  List<Level> levels = [];

  CoursePlan(
      {required this.levels,
      required this.startCgpa,
      required this.startLocation,
      required this.currentLocation});

  factory CoursePlan.zero() {
    return CoursePlan(
        levels: <Level>[],
        startCgpa: 0.00,
        startLocation: CourseLocation.zero(),
        currentLocation: CourseLocation.zero());
  }

  factory CoursePlan.fromJson(
    Map<String, dynamic> coursePlan,
  ) {
    CoursePlan tmpPlan = CoursePlan.zero();

    //Decode all the level files and store it in the temporary variable
    for (var level in coursePlan['levels']) {
      Level tmpLevel = Level.fromJson(level);
      tmpPlan.levels.add(tmpLevel);
    }

    return tmpPlan;
  }

  factory CoursePlan.fromCSV(String csvString) {
    //Convert CSV String to List
    List<List<dynamic>> csvData = const CsvToListConverter()
        .convert(csvString, fieldDelimiter: ',', eol: '\n');

    csvData = csvData.sublist(1);

    CoursePlan coursePlan = CoursePlan.zero();

    for (var elements in csvData) {
      final credits = (double.tryParse(elements[4].toString()) ?? 0.00) +
          (double.tryParse(elements[5].toString()) ?? 0.00);

      coursePlan.insertLevel(
          levelName: elements[0] ?? '',
          termName: elements[1] ?? '',
          courseName: '${elements[2]}: ${elements[3]}',
          credits: credits);
    }

    return coursePlan;
  }

  void update(String csvCoursePlan) {
    final newPlan = CoursePlan.fromCSV(csvCoursePlan).levels;

    //check if the plan has new levels
    for (var i = 0; i < levels.length; i++) {
      if (newPlan.length - 1 < i) break;
      //Update the level name if correction available
      for (var j = 0; j < levels[i].terms.length; j++) {
        if (newPlan[i].terms.length - 1 < j) break;
        //Update the term name if correction available
        for (var k = 0; k < levels[i].terms[j].courses.length; k++) {
          if (levels[i].terms[j].courses[k].pointAchieved < 0) break;

          bool updated = false;

          //Iterate Over all the courses and check if same course name is found
          //If match found then update the achieved point of newPlan
          //Update the course name if correction available
          for (var p = 0; p < newPlan[i].terms[j].courses.length; p++) {
            if (newPlan[i].terms[j].courses[p].name.trim().toLowerCase() ==
                levels[i].terms[j].courses[p].name.trim().toLowerCase()) {
              newPlan[i].terms[j].courses[p].pointAchieved =
                  levels[i].terms[j].courses[k].pointAchieved;
              updated = true;
            }
          }

          //Check whether the point is updated
          //check whether the newPlan has enough courses
          //Check whether the index is empty

          if (!updated &&
              newPlan[i].terms[j].courses.length - 1 >= k &&
              newPlan[i].terms[j].courses[k].pointAchieved < 0) {
            //Update achieved point assuming that it is the same course and
            //course name has changed
            newPlan[i].terms[j].courses[k].pointAchieved =
                levels[i].terms[j].courses[k].pointAchieved;
          }
        }
      }
    }

    levels = newPlan;
    save();
  }

  //-----------------------------------------------------------------------------
  //----------------Input Type Methods-------------------------------------------
  //-----------------------------------------------------------------------------

  //This method is to get the initial data such as level, term and cgpa upto previous term
  //the data will be stored in the variables available
  void inputInitialData(
      {required String level, required String term, required double cgpa}) {
    if (startLocation.levelIndex == 0 && startLocation.termIndex == 0) {
      startLocation = _getIndex(term: term, level: level);
      startCgpa = cgpa;
      currentLocation = CourseLocation(
          levelIndex: startLocation.levelIndex,
          termIndex: startLocation.termIndex);
      save();
    }
  }

  //This method is created for setting the achieved point
  //At first get the course index and point achieved then update it
  void setPointAchieved(
      {required int courseIndex, required double pointAchieved}) {
    levels[currentLocation.levelIndex]
        .terms[currentLocation.termIndex]
        .courses[courseIndex]
        .pointAchieved = pointAchieved;
    save();
  }

  //-----------------------------------------------------------------------------
  //-----------------State Type Methods------------------------------------------
  //-----------------------------------------------------------------------------

  //This Method is created for changing term data
  //This method should get the next term data based on current term and level
  void nextTerm() {
    final tmpLevelLocation = startLocation.levelIndex;
    final tmpTermLocation = startLocation.termIndex;

    currentLocation.levelIndex =
        (currentLocation.levelIndex < (levels.length - 1) &&
                currentLocation.termIndex ==
                    (levels[currentLocation.levelIndex].terms.length - 1))
            ? currentLocation.levelIndex + 1
            : currentLocation.levelIndex;
    currentLocation.termIndex = (currentLocation.termIndex <
            (levels[currentLocation.levelIndex].terms.length - 1))
        ? currentLocation.termIndex + 1
        : 0;

    startLocation = CourseLocation(
        levelIndex: tmpLevelLocation, termIndex: tmpTermLocation);
    save();
    print('startLocation $startLocation');
  }

  //This method is created for changing term data
  //This method should get previous term data based on current term and level
  void previousTerm() {
    currentLocation.levelIndex =
        (currentLocation.levelIndex > 0 && currentLocation.termIndex == 0)
            ? currentLocation.levelIndex - 1
            : currentLocation.levelIndex;
    currentLocation.termIndex = (currentLocation.termIndex == 0)
        ? levels[currentLocation.levelIndex].terms.length - 1
        : (currentLocation.termIndex - 1);
    save();
  }

  //-----------------------------------------------------------------------------
  //------------------------------Getters----------------------------------------
  //-----------------------------------------------------------------------------

  //This getter is created for getting current term data availble
  List<String> get levelsList {
    List<String> tmpLevels = [];

    for (var level in levels) {
      if (!tmpLevels.contains(level.name)) tmpLevels.add(level.name);
    }

    return tmpLevels;
  }

  List<String> get termsList {
    List<String> tmpTerms = [];

    for (var level in levels) {
      for (var term in level.terms) {
        if (!tmpTerms.contains(term.name)) tmpTerms.add(term.name);
      }
    }

    return tmpTerms;
  }

  List<Course> get currentCourses {
    return levels[currentLocation.levelIndex]
        .terms[currentLocation.termIndex]
        .courses;
  }

  double get currentGPA {
    return levels[currentLocation.levelIndex]
        .terms[currentLocation.termIndex]
        .gpa;
  }

  String get currentTerm {
    String name = '';
    if (currentLocation != null && levels.length > currentLocation.levelIndex) {
      name =
          '${levels[currentLocation.levelIndex].name} : ${levels[currentLocation.levelIndex].terms[currentLocation.termIndex].name}';
    }
    return name;
  }

  //This getter is created to toogle the next button based on terms available
  bool get showNextButton {
    return (currentLocation.levelIndex == levels.length - 1 &&
            currentLocation.termIndex ==
                levels[currentLocation.levelIndex].terms.length - 1)
        ? false
        : true;
  }

  //This getter is created to toggle the prev button based on terms available
  bool get showPrevButton {
    return (currentLocation.levelIndex == 0 && currentLocation.termIndex == 0)
        ? false
        : true;
  }

  bool get termFinished => levels.isNotEmpty
      ? levels[currentLocation.levelIndex]
          .terms[currentLocation.termIndex]
          .allResultPublished
      : false;

  bool get prevTermEditable =>
      currentLocation.levelIndex > startLocation.levelIndex ||
      (currentLocation.levelIndex == startLocation.levelIndex &&
          currentLocation.termIndex > startLocation.termIndex);

  double get totalCredits {
    double tmpTotalCredits = 0.00;

    for (var level in levels) {
      tmpTotalCredits += level.totalCredits;
    }

    return tmpTotalCredits;
  }

  //This getter is created for calculating cgpa upto current term in the page view
  double get cgpa {
    double tmpTotalCredits = 0.00;
    double tmpTotalPoints = 0.00;

    print(currentLocation);
    print(startLocation);
    // print(_getIndex(term: 'Summer', level: 'Level III'));

    //Make sure that for loop go through all the levels and all the terms
    //Loop over all the levels available upto current level
    for (var i = 0; i <= currentLocation.levelIndex; i++) {
      //Loop over all the terms available upto current term
      for (var j = 0; j < levels[i].terms.length; j++) {
        var data = levels[i].terms[j];
        var term = levels[i].terms[j];

        if (i < startLocation.levelIndex ||
            (i == startLocation.levelIndex && j < startLocation.termIndex)) {
          //Calculate Gpa upto current term
          tmpTotalCredits += data.totalCredits;
          tmpTotalPoints += (startCgpa * data.totalCredits);
        } else if (i < currentLocation.levelIndex ||
            (i == currentLocation.levelIndex &&
                j <= currentLocation.termIndex)) {
          tmpTotalCredits += data.workingCredits;
          tmpTotalPoints += (data.workingCredits * data.gpa);
        } else {
          break;
        }
      }
    }

    //At First check if the totalCredits is zero to avoid divide-by-zero error
    return tmpTotalCredits > 0 ? tmpTotalPoints / tmpTotalCredits : 0;
  }

  //============================================================================
  //----------------------------Functions---------------------------------------
  //============================================================================

  void insertLevel(
      {required String levelName,
      required String termName,
      required String courseName,
      required double credits}) {
    int index = getLevelIndex(levelName);

    if (index < 0) {
      levels.add(Level(name: levelName, terms: []));
      index = getLevelIndex(levelName);
    }

    levels[index].insertCourse(
        termName: termName, courseName: courseName, credits: credits);
  }

  int getLevelIndex(String levelName) {
    int index = -1;
    for (int i = 0; i < levels.length; i++) {
      if (levels[i].name == levelName) index = i;
    }
    return index;
  }

  //-----------------------------------------------------------------------------
  //--------------------------------Private Methods------------------------------
  //-----------------------------------------------------------------------------

  //This is a private method generally created to search the index of terms and levels
  CourseLocation _getIndex({required String term, required String level}) {
    for (var i = 0; i < levels.length; i++) {
      if (levels[i].name == level) {
        for (var j = 0; j < levels[i].terms.length; j++) {
          if (levels[i].terms[j].name == term) {
            return CourseLocation(termIndex: j, levelIndex: i);
          }
        }
      }
    }
    return CourseLocation(levelIndex: 0, termIndex: 0);
  }

  //-----------------------------------------------------------------------------
  //---------------------------Ovirride Mehods-----------------------------------
  //-----------------------------------------------------------------------------

  @override
  String toString() {
    return '{totalCredits: $totalCredits, levels: $levels, startLocation: $startLocation, currentLocation: $currentLocation, startCgpa: $startCgpa}, ';
  }
}
