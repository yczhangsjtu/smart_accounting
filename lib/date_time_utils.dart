class TimeInterval {
  final int? start;
  final int? length;

  TimeInterval({this.start, this.length});

  String toString() {
    return start == null
        ? ""
        : DateTimeUtils.timeToString(start!)! +
            (length == null
                ? ""
                : "到${DateTimeUtils.timeToString(start! + length!)}");
  }
}

class DateTimeUtils {
  static final weekDayNames = <String>["日", "一", "二", "三", "四", "五", "六"];

  static String weekDayName(int day) {
    return weekDayNames[day];
  }

  static int? dayOfWeekByName(String day) {
    for (int i = 0; i < weekDayNames.length; i++) {
      if (weekDayNames[i] == day) {
        return i;
      }
    }
    return null;
  }

  static int today() {
    var today = DateTime.now();
    return _gregorianToJulian(today.year, today.month, today.day);
  }

  static int now() {
    var now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  static String durationToString(int minutes) {
    if (minutes == 0) {
      return "0m";
    }
    var h = minutes ~/ 60;
    var m = minutes % 60;
    // If m is 0, omit the minutes part
    return "${h > 0 ? "${h}h" : ""}${m > 0 ? "${m}m" : ""}";
  }

  static String? timeToString(int? time) {
    if (time == null) {
      return null;
    }
    var h = time ~/ 60;
    var m = time % 60;
    return "$h:${m ~/ 10}${m % 10}";
  }

  static String? dayToString(int? day) {
    if (day == null) {
      return null;
    }
    var gregorian = _julianToGregorian(day);
    var y = gregorian ~/ 10000;
    var m = (gregorian % 10000) ~/ 100;
    var d = gregorian % 100;
    return "$y-$m-$d";
  }

  static int? dayOfWeek(int? day) {
    if (day == null) {
      return null;
    }
    return (day + 1) % 7;
  }

  static int? yearMonthDayToInt(int? y, int? m, int? d) {
    if (y == null || m == null || d == null) {
      return null;
    }
    return _gregorianToJulian(y, m, d);
  }

  static int? yearMonthDayFromInt(int? day) {
    if (day == null) {
      return null;
    }
    return _julianToGregorian(day);
  }

  // Refer to http://www.stiltner.org/book/bookcalc.htm for gregorian
  // and julian date
  static int _gregorianToJulian(int y, int m, int d) {
    return (1461 * (y + 4800 + (m - 14) ~/ 12)) ~/ 4 +
        (367 * (m - 2 - 12 * ((m - 14) ~/ 12))) ~/ 12 -
        (3 * ((y + 4900 + (m - 14) ~/ 12) / 100)) ~/ 4 +
        d -
        32075;
  }

  static int _julianToGregorian(int jd) {
    var l = jd + 68569;
    var n = (4 * l) ~/ 146097;
    l = l - (146097 * n + 3) ~/ 4;
    var i = (4000 * (l + 1)) ~/ 1461001;
    l = l - (1461 * i) ~/ 4 + 31;
    var j = (80 * l) ~/ 2447;
    var d = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    var m = j + 2 - (12 * l);
    var y = 100 * (n - 49) + i + l;
    return y * 10000 + m * 100 + d;
  }

  static final hourMinutePattern =
      r"(上午|下午)?([1-2]?[0-9])(?::|点)(([0-5][0-9])分?|半)?";
  static final hourMinuteExp = RegExp(r"^" + hourMinutePattern + r"$");
  static final timeLengthPattern =
      r"(?:([1-2]?[0-9])(?:小时|h|H))?(?:(\d+)(?:分钟|M|m))?";
  static final timeLengthExp = RegExp(r"^" + timeLengthPattern + r"$");
  static final timeIntervalPattern =
      "($hourMinutePattern)" + // 5 captured groups
          r"(\s*(?:-|到)\s*" + // start 6th captured group
          "($hourMinutePattern)" + // group 7 to 11
          r"|\s+(" +
          timeLengthPattern +
          "))"; // group 12, end group 6
  static final timeIntervalExp = RegExp(r"^" + timeIntervalPattern + r"$");

  static final relativeDayPattern = r"今天|明天|后天|大后天";
  static final relativeWeekDayPattern = r"(下{0,2})周(日|一|二|三|四|五|六)";
  static final relativeWeekDayExp =
      RegExp(r"^" + relativeWeekDayPattern + r"$");
  static final monthDayPattern = r"(?:([1-2]?[0-9])月)?([1-3]?[0-9])(?:日|号)";
  static final monthDayExp = RegExp(r"^" + monthDayPattern + r"$");
  static final yearMonthDayPattern =
      "([1-2][0-9][0-9][0-9])-([1-2]?[0-9])-([1-3]?[0-9])";
  static final yearMonthDayExp = RegExp(r"^" + yearMonthDayPattern + r"$");

  static int? absoluteTime(String? time) {
    if (time == null) {
      return null;
    }
    var match = hourMinuteExp.firstMatch(time);
    if (match != null) {
      String? noon = match.group(1);
      int h = int.parse(match.group(2)!);
      if (h > 23 || ((noon == "下午" || noon == "上午") && h > 12)) {
        return null;
      }
      if ((noon == "上午" || noon == "下午") && h == 12) {
        h = 0;
      }
      String? minute = match.group(3);
      int m = minute == null
          ? 0
          : (minute == "半" ? 30 : int.parse(minute.substring(0, 2)));
      return (noon == "上午" || noon == null) ? (h * 60 + m) : (h * 60 + m + 720);
    }
    return null;
  }

  static TimeInterval? absoluteTimeInterval(String? time) {
    if (time == null) {
      return null;
    }
    int? t = absoluteTime(time);
    if (t != null) {
      // This is not interval, just a time point, leave length null
      return TimeInterval(start: t);
    }

    var match = timeIntervalExp.firstMatch(time);
    if (match != null) {
      int? startTime = absoluteTime(match.group(1));
      assert(startTime != null);
      var endTimeStr = match.group(7);
      var lengthStr = match.group(12);
      if (endTimeStr != null) {
        int? endTime = absoluteTime(endTimeStr);
        if (endTime == null) {
          return null;
        }
        if (endTime < startTime!) {
          return null;
        }
        return TimeInterval(start: startTime, length: endTime - startTime);
      } else {
        assert(lengthStr != null);
        int? length = timeLengthFromString(lengthStr!);
        if (startTime! + length! > 1440) {
          return null;
        }
        return TimeInterval(start: startTime, length: length);
      }
    }

    return null;
  }

  static int? timeLengthFromString(String? timeLength) {
    if (timeLength == null) {
      return null;
    }
    var match = timeLengthExp.firstMatch(timeLength);
    if (match != null) {
      var hourStr = match.group(1);
      var minStr = match.group(2);
      if (hourStr == null && minStr == null) {
        return null;
      }
      if (hourStr == null) {
        int min = int.parse(minStr!);
        if (min > 1440) {
          // Longer than a day
          return null;
        }
        return min;
      }
      if (minStr == null) {
        int hour = int.parse(hourStr);
        if (hour > 24) {
          return null;
        }
        return hour * 60;
      }
      int hour = int.parse(hourStr);
      int min = int.parse(minStr);
      if (min >= 60) {
        return null;
      }
      int ret = hour * 60 + min;
      if (ret > 1440) {
        return null;
      }
      return ret;
    }
    return null;
  }

  static int? absoluteDateToday(String day) {
    return absoluteDate(today(), day);
  }

  // Compute the absolute date that is referred to as <day> in <today>
  static int? absoluteDate(int today, String? day) {
    if (day == null) {
      return null;
    }
    if (day == "今天") {
      return today;
    }
    if (day == "明天") {
      return today + 1;
    }
    if (day == "后天") {
      return today + 2;
    }
    if (day == "大后天") {
      return today + 3;
    }
    var match = relativeWeekDayExp.firstMatch(day);
    if (match != null) {
      int next = match.group(1)?.length ?? 0;
      int? relativeDayOfWeek = dayOfWeekByName(match.group(2)!);
      int? todayOfWeek = dayOfWeek(today);
      int offset = relativeDayOfWeek! - todayOfWeek!;
      if (offset < 0) {
        offset += 7;
      }
      if (next > 0 &&
          ((relativeDayOfWeek >= todayOfWeek && todayOfWeek != 0) ||
              relativeDayOfWeek == 0)) {
        offset += 7;
      }
      if (next > 1) {
        offset += 7 * (next - 1);
      }
      return today + offset;
    }

    match = monthDayExp.firstMatch(day);
    if (match != null) {
      int dayOfMonth = int.parse(match.group(2)!);
      if (dayOfMonth == 0) {
        return null;
      }
      int? todayDate = yearMonthDayFromInt(today);
      int todayOfMonth = todayDate! % 100;
      int todayMonth = (todayDate % 10000) ~/ 100;
      int year = todayDate ~/ 10000;
      if (match.group(1) == null) {
        // Month is not provided
        if (dayOfMonth == todayOfMonth) {
          return today;
        }
        if (dayOfMonth > todayOfMonth) {
          int? ret = yearMonthDayToInt(year, todayMonth, dayOfMonth);
          if (yearMonthDayFromInt(ret) !=
              year * 10000 + todayMonth * 100 + dayOfMonth) {
            return null;
          }
          return ret;
        }
        var month = todayMonth % 12 + 1;
        int? ret = yearMonthDayToInt(year, month, dayOfMonth);
        if (yearMonthDayFromInt(ret) !=
            year * 10000 + month * 100 + dayOfMonth) {
          return null;
        }
        return ret;
      }
      // In the case the month is given
      int month = int.parse(match.group(1)!);
      if (month > 12 || month < 1) {
        return null;
      }
      int? ret = yearMonthDayToInt(year, month, dayOfMonth);
      if (yearMonthDayFromInt(ret) != year * 10000 + month * 100 + dayOfMonth) {
        return null;
      }
      return ret;
    }

    match = yearMonthDayExp.firstMatch(day);
    if (match != null) {
      int year = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int day = int.parse(match.group(3)!);
      int? ret = yearMonthDayToInt(year, month, day);
      if (yearMonthDayFromInt(ret) != year * 10000 + month * 100 + day) {
        return null;
      }
      return ret;
    }

    return null;
  }
}

abstract class TimeOption extends TimeInterval {
  TimeOption({int? start, int? length}) : super(start: start, length: length);

  static TimeOption? fromString(String s) {
    return FixedTime.fromString(s);
  }

  bool match(int dayOfInterest);
}

class FixedTime extends TimeOption {
  final int day;

  FixedTime(this.day, {int? start, int? length})
      : super(start: start, length: length);

  @override
  String toString() {
    String time = super.toString();
    return DateTimeUtils.dayToString(day)! + (time == "" ? "" : " $time");
  }

  static final fixedTimeExp = RegExp(r"^(" + // start group 1
      DateTimeUtils.relativeDayPattern +
      "|" +
      DateTimeUtils.relativeWeekDayPattern + // 2 groups
      "|" +
      DateTimeUtils.monthDayPattern + // 2 groups
      "|" +
      DateTimeUtils.yearMonthDayPattern + // 3 groups
      r")?\s*(" + // end group 1, start group 9
      DateTimeUtils.timeIntervalPattern +
      "|" +
      DateTimeUtils.hourMinutePattern +
      r")?\s*$");

  static FixedTime? fromString(String s) {
    var match = fixedTimeExp.firstMatch(s);
    if (match == null) {
      return null;
    }
    var dateStr = match.group(1);
    var timeStr = match.group(9);
    if (dateStr == null && timeStr == null) {
      return null;
    }
    var day = DateTimeUtils.absoluteDateToday(dateStr!);
    if (timeStr == null) {
      return FixedTime(day!);
    }
    var absoluteTime = DateTimeUtils.absoluteTime(timeStr);
    if (absoluteTime != null) {
      return FixedTime(day ?? DateTimeUtils.today(), start: absoluteTime);
    }
    var timeInterval = DateTimeUtils.absoluteTimeInterval(timeStr);
    if (timeInterval != null) {
      return FixedTime(day ?? DateTimeUtils.today(),
          start: timeInterval.start, length: timeInterval.length);
    }
    assert(false);
    return null;
  }

  @override
  bool match(int dayOfInterest) {
    return day == dayOfInterest;
  }
}
