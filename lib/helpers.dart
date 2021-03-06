Duration diffDate(date) {
    Duration difference = date.difference(DateTime.now());
    return difference;
  }

  String formatDate(date) {
    Duration difference = diffDate(date);
    final hasPassed = difference.isNegative == true;
    final suffix = hasPassed ? "ago" : "away";

    final weeks =
        difference.inDays.abs() > 7 ? (difference.inDays.abs() / 7).floor() : 0;
    final weekString = weeks == 0
        ? null
        : weeks > 1 ? "$weeks weeks" : weeks > 0 ? "$weeks week" : null;
    final hours =
        difference.inHours.abs() < 24 ? difference.inHours.abs().floor() : 0;
    final hoursString = hours == 0
        ? null
        : hours > 1 ? "$hours hours" : hours > 0 ? "$hours hour" : null;
    final minutes = difference.inSeconds.abs() < 3600
        ? (difference.inSeconds.abs() / 60).floor()
        : 0;
    final minutesString = hours != 0 && hours > 1
        ? null
        : minutes > 1
            ? "$minutes minutes"
            : minutes > 0 ? "$minutes minute" : "less than a minute";
    final days =
        difference.inDays.abs() < 7 ? difference.inDays.abs().floor() : 0;
    final dayString =
        days == 0 ? null : days > 1 ? "$days days" : days > 0 ? "$days day" : "";

    // Use the largest interval available that is not null!
    final intervalToUse = weekString ?? dayString ?? hoursString ?? minutesString;
    return "$intervalToUse $suffix";
  }
