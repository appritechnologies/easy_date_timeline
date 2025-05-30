import '../../easy_date_time_line_picker/easy_date_time_line_picker.exports.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../easy_date_time_line_picker/utils/typed_ahead.dart';
import '../../models/models.dart';
import '../../properties/properties.dart';
import '../../utils/utils.dart';
import '../easy_month_picker/easy_month_picker.dart';
import '../time_line_widget/timeline_widget.dart';
import 'selected_date_widget.dart';

/// Represents a timeline widget for displaying dates in a horizontal line.
class EasyDateTimeLine extends StatefulWidget {
  const EasyDateTimeLine({
    super.key,
    required this.initialDate,
    this.disabledDates,
    this.headerProps = const EasyHeaderProps(),
    this.timeLineProps = const EasyTimeLineProps(),
    this.dayProps = const EasyDayProps(),
    this.gridDayProps,
    this.onDateChange,
    this.itemBuilder,
    this.gridItemBuilder,
    this.activeColor,
    this.viewType,
    this.locale = "en_US",
    this.onViewTypeChange,
    this.showViewToggle = true,
    this.isNavigateGridToList = false,
  });

  /// Represents the initial date for the timeline widget.
  /// This is the date that will be displayed as the first day in the timeline.
  final DateTime initialDate;

  /// Represents a list of inactive dates for the timeline widget.
  /// Note that all the dates defined in the `disabledDates` list will be deactivated.
  final List<DateTime>? disabledDates;

  /// The color for the active day.
  final Color? activeColor;

  /// Contains properties for configuring the appearance and behavior of the timeline header.
  final EasyHeaderProps headerProps;

  /// Contains properties for configuring the appearance and behavior of the timeline widget.
  final EasyTimeLineProps timeLineProps;

  /// Contains properties for configuring the appearance and behavior of the day widgets in the timeline.
  /// This includes properties such as the width and height of each day widget,
  /// the color of the text and background, and the font size.
  final EasyDayProps dayProps;

  /// Contains properties for configuring the appearance and behavior of the day widgets in the grid view.
  /// If not provided, will use dayProps as fallback.
  final EasyDayProps? gridDayProps;

  /// Called when the selected date in the timeline changes.
  /// This function takes a `DateTime` object as its parameter, which represents the new selected date.
  final OnDateChangeCallBack? onDateChange;

  /// > **NOTE:**
  /// > When utilizing the `itemBuilder`, it is essential to provide the width of each day for the date timeline widget.
  /// >
  ///
  /// For example:
  /// ```dart
  /// dayProps: const EasyDayProps(
  ///  // You must specify the width in this case.
  ///  width: 124.0,
  /// )
  /// ```

  final ItemBuilderCallBack? itemBuilder;

  /// Custom item builder specifically for grid view.
  /// If not provided, will use itemBuilder as fallback.
  final ItemBuilderCallBack? gridItemBuilder;
  final ViewType? viewType;

  /// Called when the view type changes between grid and list
  final Function(ViewType)? onViewTypeChange;

  /// Whether to show the view toggle button in the header
  final bool showViewToggle;

  /// When enabled, selecting a date in grid view will automatically switch to list view
  final bool isNavigateGridToList;

  /// A `String` that represents the locale code to use for formatting the dates in the timeline.
  final String locale;

  @override
  State<EasyDateTimeLine> createState() => _EasyDateTimeLineState();
}

class _EasyDateTimeLineState extends State<EasyDateTimeLine> {
  late EasyMonth _easyMonth;
  late int _initialDay;
  late ViewType _currentViewType;

  late ValueNotifier<DateTime?> _focusedDateListener;

  DateTime get initialDate => widget.initialDate;

  @override
  void initState() {
    // Init easy date timeline locale
    initializeDateFormatting(widget.locale, null);
    super.initState();
    // Get initial month
    _easyMonth =
        EasyDateUtils.convertDateToEasyMonth(widget.initialDate, widget.locale);
    _initialDay = widget.initialDate.day;
    _focusedDateListener = ValueNotifier(initialDate);
    _currentViewType = widget.viewType ?? ViewType.list;
  }

  void _onFocusedDateChanged(DateTime date) {
    _focusedDateListener.value = date;
    widget.onDateChange?.call(date);

    // Auto-switch to list view when date is selected in grid view
    if (widget.isNavigateGridToList && _currentViewType == ViewType.grid) {
      setState(() {
        _currentViewType = ViewType.list;
      });
      widget.onViewTypeChange?.call(_currentViewType);
    }
  }

  void _onViewTypeToggle() {
    setState(() {
      _currentViewType =
          _currentViewType == ViewType.list ? ViewType.grid : ViewType.list;
    });
    widget.onViewTypeChange?.call(_currentViewType);
  }

  @override
  void dispose() {
    _focusedDateListener.dispose();
    super.dispose();
  }

  EasyHeaderProps get _headerProps => widget.headerProps;

  Widget _buildViewToggleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // List view button
          GestureDetector(
            onTap: () {
              if (_currentViewType != ViewType.list) {
                _onViewTypeToggle();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _currentViewType == ViewType.list
                    ? widget.activeColor ?? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  bottomLeft: Radius.circular(0),
                ),
              ),
              child: Icon(
                Icons.today,
                size: 20,
                color: _currentViewType == ViewType.list
                    ? Colors.white
                    : Colors.grey[600],
              ),
            ),
          ),
          // Grid view button
          GestureDetector(
            onTap: () {
              if (_currentViewType != ViewType.grid) {
                _onViewTypeToggle();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _currentViewType == ViewType.grid
                    ? widget.activeColor ?? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(0),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Icon(
                Icons.calendar_month_sharp,
                size: 20,
                color: _currentViewType == ViewType.grid
                    ? Colors.white
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    /// activeDayColor is initialized to the value of widget.activeColor if it is not null,
    /// or to the primary color of the current theme if widget.activeColor is null.
    /// This provides a fallback color if no active color is explicitly provided.
    final activeDayColor = widget.activeColor ?? Theme.of(context).primaryColor;

    /// brightness is initialized to the brightness of the active color or the fallback color,
    /// using the ThemeData.estimateBrightnessForColor method.
    /// This method returns Brightness.dark if the color is closer to black,
    ///  and Brightness.light if the color is closer to white.
    final brightness = ThemeData.estimateBrightnessForColor(
      widget.activeColor ?? activeDayColor,
    );

    /// activeDayTextColor is initialized to EasyColors.dayAsNumColor if the brightness is Brightness.light,
    ///  indicating that the active color is light, or to Colors.white if the brightness is Brightness.dark,
    /// indicating that the active color is dark.
    final activeDayTextColor = brightness == Brightness.light
        ? EasyColors.dayAsNumColor
        : Colors.white;

    return ValueListenableBuilder(
      valueListenable: _focusedDateListener,
      builder: (context, focusedDate, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_headerProps.showHeader)
            Padding(
              padding: _headerProps.padding ??
                  const EdgeInsets.only(
                    left: EasyConstants.timelinePadding * 2,
                    right: EasyConstants.timelinePadding,
                    bottom: EasyConstants.timelinePadding,
                  ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side - Selected date
                  Expanded(
                    child: SelectedDateWidget(
                      date: focusedDate ?? initialDate,
                      locale: widget.locale,
                      headerProps: _headerProps,
                    ),
                  ),

                  // Center - View toggle button
                  if (widget.showViewToggle)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _buildViewToggleButton(),
                    ),

                  // Right side - Month picker
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_showMonthPicker(
                          pickerType: MonthPickerType.dropDown))
                        child!,
                      if (_showMonthPicker(
                          pickerType: MonthPickerType.switcher))
                        EasyMonthSwitcher(
                          locale: widget.locale,
                          value: _easyMonth,
                          onMonthChange: _onMonthChange,
                          style: _headerProps.monthStyle,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          TimeLineWidget(
            initialDate: initialDate.copyWith(
              month: _easyMonth.vale,
              day: _initialDay,
            ),
            inactiveDates: widget.disabledDates,
            focusedDate: focusedDate,
            onDateChange: _onFocusedDateChanged,
            timeLineProps: widget.timeLineProps,
            dayProps: _currentViewType == ViewType.grid
                ? (widget.gridDayProps ?? widget.dayProps)
                : widget.dayProps,
            itemBuilder: _currentViewType == ViewType.grid
                ? (widget.gridItemBuilder ?? widget.itemBuilder)
                : widget.itemBuilder,
            activeDayTextColor: activeDayTextColor,
            activeDayColor: activeDayColor,
            locale: widget.locale,
            viewType: _currentViewType,
          ),
        ],
      ),
      child: EasyMonthDropDown(
        value: _easyMonth,
        locale: widget.locale,
        onMonthChange: _onMonthChange,
        style: _headerProps.monthStyle,
      ),
    );
  }

  void _onMonthChange(month) {
    setState(() {
      _initialDay = 1;
      _easyMonth = month!;
      widget.headerProps.onMonthChange?.call(month);
    });
  }

  /// The method returns a boolean value, which indicates whether the month picker
  /// should be displayed. If the _headerProps object is not null and its monthPickerType property
  /// matches the pickerType parameter,
  /// or if _headerProps is null and the isDefaultPicker parameter is true,
  /// then the method returns true. Additionally,
  /// if the showMonthPicker property of _headerProps is true when _headerProps is not null,
  /// then the method also returns true. Otherwise, it returns false.
  ///
  /// This method used to determine whether to display the month picker in the header of the EasyDateTimeLineWidget.
  bool _showMonthPicker({required MonthPickerType pickerType}) {
    /// Get a boolean flag `useCustomHeader` that is true if `_headerProps` exists
    /// and its `showMonthPicker` property is true, otherwise set it to true.
    final bool showMonthPicker = _headerProps.showMonthPicker;

    /// Return true if the month picker type in `_headerProps` matches `pickerType`
    /// or if `isDefault` is true and `useCustomHeader` is true.
    return _headerProps.monthPickerType == pickerType && showMonthPicker;
  }
}
