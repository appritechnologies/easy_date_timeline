import 'package:easy_date_timeline/src/easy_infinite_date_time/widgets/web_scroll_behavior.dart';
import 'package:flutter/material.dart';

import '../../easy_date_time_line_picker/easy_date_time_line_picker.exports.dart';
import '../../easy_date_time_line_picker/utils/typed_ahead.dart';
import '../../properties/easy_day_props.dart';
import '../../properties/time_line_props.dart';
import '../../utils/utils.dart';
import '../easy_day_widget/easy_day_widget.dart';

/// A widget that displays a timeline of days.
class TimeLineWidget extends StatefulWidget {
  TimeLineWidget({
    super.key,
    required this.initialDate,
    required this.focusedDate,
    required this.activeDayTextColor,
    required this.activeDayColor,
    this.inactiveDates,
    this.dayProps = const EasyDayProps(),
    this.locale = "en_US",
    this.timeLineProps = const EasyTimeLineProps(),
    this.viewType = ViewType.list,
    this.onDateChange,
    this.itemBuilder,
  })  : assert(timeLineProps.hPadding > -1,
            "Can't set timeline hPadding less than zero."),
        assert(timeLineProps.separatorPadding > -1,
            "Can't set timeline separatorPadding less than zero."),
        assert(timeLineProps.vPadding > -1,
            "Can't set timeline vPadding less than zero.");

  /// Represents the initial date for the timeline widget.
  /// This is the date that will be displayed as the first day in the timeline.
  final DateTime initialDate;

  /// The currently focused date in the timeline.
  final DateTime? focusedDate;

  /// The color of the text for the selected day.
  final Color activeDayTextColor;

  /// The background color of the selected day.
  final Color activeDayColor;

  /// Represents a list of inactive dates for the timeline widget.
  /// Note that all the dates defined in the inactiveDates list will be deactivated.
  final List<DateTime>? inactiveDates;

  /// Contains properties for configuring the appearance and behavior of the timeline widget.
  /// This object includes properties such as the height of the timeline, the color of the selected day,
  /// and the animation duration for scrolling.
  final EasyTimeLineProps timeLineProps;

  /// Contains properties for configuring the appearance and behavior of the day widgets in the timeline.
  /// This object includes properties such as the width and height of each day widget,
  /// the color of the text and background, and the font size.
  final EasyDayProps dayProps;

  /// Called when the selected date in the timeline changes.
  /// This function takes a `DateTime` object as its parameter, which represents the new selected date.
  final OnDateChangeCallBack? onDateChange;

  /// Called for each day in the timeline, allowing the developer to customize the appearance and behavior of each day widget.
  /// This function takes a `BuildContext` and a `DateTime` object as its parameters, and should return a `Widget` that represents the day.
  final ItemBuilderCallBack? itemBuilder;

  final ViewType viewType;

  /// A `String` that represents the locale code to use for formatting the dates in the timeline.
  final String locale;

  @override
  State<TimeLineWidget> createState() => _TimeLineWidgetState();
}

class _TimeLineWidgetState extends State<TimeLineWidget> {
  EasyDayProps get _dayProps => widget.dayProps;
  EasyTimeLineProps get _timeLineProps => widget.timeLineProps;
  bool get _isLandscapeMode => _dayProps.landScapeMode;
  double get _dayWidth => _dayProps.width;
  double get _dayHeight => _dayProps.height;
  double get _dayOffsetConstrains => _isLandscapeMode ? _dayHeight : _dayWidth;

  late ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController(
      initialScrollOffset: widget.viewType == ViewType.list
          ? _calculateDateOffset(widget.initialDate)
          : 0,
    );
  }

  @override
  void didUpdateWidget(TimeLineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Auto-scroll to selected date when switching from grid to list view
    if (oldWidget.viewType == ViewType.grid &&
        widget.viewType == ViewType.list &&
        widget.focusedDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate(widget.focusedDate!);
      });
    }

    // Also handle when focused date changes in list view
    if (widget.viewType == ViewType.list &&
        oldWidget.focusedDate != widget.focusedDate &&
        widget.focusedDate != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate(widget.focusedDate!);
      });
    }
  }

  void _scrollToSelectedDate(DateTime selectedDate) {
    if (widget.viewType == ViewType.list && _controller.hasClients) {
      final targetOffset = _calculateDateOffset(selectedDate);
      _controller.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// the method calculates the number of days between startDate and date using the difference() method
  /// of the Duration class. This value is stored in the offset variable.
  /// If offset is equal to 0, the method returns 0.0.
  /// Otherwise, the method calculates the horizontal offset of the day
  /// by multiplying the offset value by the width of a day widget
  /// (which is either the value of widget.easyDayProps.width or a default value of EasyConstants.dayWidgetWidth).
  /// It then adds to this value the product of offset and [EasyConstants.separatorPadding] (which represents the width of the space between each day widget)
  double _calculateDateOffset(DateTime date) {
    final startDate = DateTime(date.year, date.month, 1);
    int offset = date.difference(startDate).inDays;
    double adjustedHPadding =
        _timeLineProps.hPadding > EasyConstants.timelinePadding
            ? (_timeLineProps.hPadding - EasyConstants.timelinePadding)
            : 0.0;
    if (offset == 0) {
      return 0.0;
    }
    return (offset * _dayOffsetConstrains) +
        (offset * _timeLineProps.separatorPadding) +
        adjustedHPadding;
  }

  /// Generate calendar grid data with only current month dates
  List<List<DateTime?>> _generateCalendarGrid() {
    final initialDate = widget.initialDate;
    final firstDayOfMonth = DateTime(initialDate.year, initialDate.month, 1);
    final lastDayOfMonth = DateTime(initialDate.year, initialDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    // Convert to 0-based where Sunday = 0
    int firstWeekday =
        firstDayOfMonth.weekday == 7 ? 0 : firstDayOfMonth.weekday;

    List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);

    // Fill in empty cells before the first day (keep as null)
    for (int i = 0; i < firstWeekday; i++) {
      currentWeek[i] = null;
    }

    // Fill in current month dates only
    int currentWeekday = firstWeekday;
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek[currentWeekday] =
          DateTime(initialDate.year, initialDate.month, day);
      currentWeekday++;

      // If we've filled a week, add it to weeks and start a new week
      if (currentWeekday == 7) {
        weeks.add(List.from(currentWeek));
        currentWeek = List.filled(7, null);
        currentWeekday = 0;
      }
    }

    // Add the last week if it has any days
    if (currentWeekday > 0) {
      weeks.add(currentWeek);
    }

    return weeks;
  }

  Widget _buildGridView() {
    final weeks = _generateCalendarGrid();
    final effectiveTimeLineBackgroundColor = _timeLineProps.decoration == null
        ? _timeLineProps.backgroundColor ?? Colors.white
        : null;
    final effectiveTimeLineBorderRadius =
        _timeLineProps.decoration?.borderRadius ?? BorderRadius.zero;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          margin: _timeLineProps.margin,
          color: effectiveTimeLineBackgroundColor,
          decoration: _timeLineProps.decoration,
          child: ClipRRect(
            borderRadius: effectiveTimeLineBorderRadius,
            child: ScrollConfiguration(
              behavior: EasyCustomScrollBehavior(),
              child: SingleChildScrollView(
                controller: _controller,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Weekday headers
                    Container(
                      height: 40.0,
                      decoration: BoxDecoration(
                        color: effectiveTimeLineBackgroundColor ?? Colors.white,
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.3), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          'Sun',
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat'
                        ].asMap().entries.map((entry) {
                          final index = entry.key;
                          final day = entry.value;
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: index < 6
                                      ? BorderSide(
                                          color: Colors.grey.withOpacity(0.3),
                                          width: 1)
                                      : BorderSide.none,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    // Calendar grid
                    ...weeks.asMap().entries.map((weekEntry) {
                      final weekIndex = weekEntry.key;
                      final week = weekEntry.value;

                      return Container(
                        height: _dayHeight,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: weekIndex < weeks.length - 1
                                ? BorderSide(
                                    color: Colors.grey.withOpacity(0.3),
                                    width: 1)
                                : BorderSide.none,
                          ),
                        ),
                        child: Row(
                          children: week.asMap().entries.map((dayEntry) {
                            final dayIndex = dayEntry.key;
                            final date = dayEntry.value;

                            if (date == null) {
                              return Expanded(
                                child: Container(
                                  height: _dayHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[
                                        50], // Light background for empty cells
                                    border: Border(
                                      right: dayIndex < 6
                                          ? BorderSide(
                                              color:
                                                  Colors.grey.withOpacity(0.3),
                                              width: 1)
                                          : BorderSide.none,
                                    ),
                                  ),
                                ),
                              );
                            }

                            final isSelected = EasyDateUtils.isSameDay(
                                widget.focusedDate ?? widget.initialDate, date);

                            bool isDisabledDay = false;
                            if (widget.inactiveDates != null) {
                              for (DateTime inactiveDate
                                  in widget.inactiveDates!) {
                                if (EasyDateUtils.isSameDay(
                                    date, inactiveDate)) {
                                  isDisabledDay = true;
                                  break;
                                }
                              }
                            }

                            return Expanded(
                              child: Container(
                                height: _dayHeight,
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: dayIndex < 6
                                        ? BorderSide(
                                            color: Colors.grey.withOpacity(0.3),
                                            width: 1)
                                        : BorderSide.none,
                                  ),
                                ),
                                child: widget.itemBuilder != null
                                    ? _dayItemBuilder(context, isSelected, date)
                                    : _buildDefaultGridDay(
                                        date,
                                        isSelected,
                                        true, // Always current month since we only show current month
                                        isDisabledDay),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultGridDay(
      DateTime date, bool isSelected, bool isCurrentMonth, bool isDisabledDay) {
    return GestureDetector(
      onTap: isDisabledDay ? null : () => _onDayChanged(date),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: isSelected
            ? widget.activeDayColor.withOpacity(0.2)
            : Colors.transparent,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.all(4),
        child: Text(
          date.day.toString(),
          style: TextStyle(
            color: isDisabledDay
                ? Colors.grey.withOpacity(0.5)
                : isSelected
                    ? widget.activeDayTextColor
                    : Colors.black,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildListView() {
    final initialDate = widget.initialDate;
    final effectiveTimeLineHeight = _isLandscapeMode ? _dayWidth : _dayHeight;
    final effectiveTimeLineBackgroundColor = _timeLineProps.decoration == null
        ? _timeLineProps.backgroundColor
        : null;
    final effectiveTimeLineBorderRadius =
        _timeLineProps.decoration?.borderRadius ?? BorderRadius.zero;

    return Container(
      height: effectiveTimeLineHeight,
      margin: _timeLineProps.margin,
      color: effectiveTimeLineBackgroundColor,
      decoration: _timeLineProps.decoration,
      child: ClipRRect(
        borderRadius: effectiveTimeLineBorderRadius,
        child: ScrollConfiguration(
          behavior: EasyCustomScrollBehavior(),
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(
              horizontal: _timeLineProps.hPadding,
              vertical: _timeLineProps.vPadding,
            ),
            itemBuilder: (context, index) {
              final currentDate =
                  DateTime(initialDate.year, initialDate.month, index + 1);

              final isSelected = EasyDateUtils.isSameDay(
                  widget.focusedDate ?? initialDate, currentDate);

              bool isDisabledDay = false;
              // Check if this date should be deactivated only for the DeactivatedDates.
              if (widget.inactiveDates != null) {
                for (DateTime inactiveDate in widget.inactiveDates!) {
                  if (EasyDateUtils.isSameDay(currentDate, inactiveDate)) {
                    isDisabledDay = true;
                    break;
                  }
                }
              }
              return widget.itemBuilder != null
                  ? _dayItemBuilder(
                      context,
                      isSelected,
                      currentDate,
                    )
                  : EasyDayWidget(
                      easyDayProps: _dayProps,
                      date: currentDate,
                      locale: widget.locale,
                      isSelected: isSelected,
                      isDisabled: isDisabledDay,
                      onDayPressed: () => _onDayChanged(currentDate),
                      activeTextColor: widget.activeDayTextColor,
                      activeDayColor: widget.activeDayColor,
                    );
            },
            separatorBuilder: (context, index) {
              return SizedBox(
                width: _timeLineProps.separatorPadding,
              );
            },
            itemCount: EasyDateUtils.getDaysInMonth(initialDate),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.viewType == ViewType.grid
        ? _buildGridView()
        : _buildListView();
  }

  Widget _dayItemBuilder(
    BuildContext context,
    bool isSelected,
    DateTime date,
  ) {
    return widget.itemBuilder!(
      context,
      date,
      isSelected,
      () => _onDayChanged(date),
    );
  }

  void _onDayChanged(DateTime currentDate) {
    // A date is selected
    widget.onDateChange?.call(currentDate);
  }
}
