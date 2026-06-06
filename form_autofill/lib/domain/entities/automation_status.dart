enum AutomationState {
  idle,
  scanning,
  filling,
  scrolling,
  waitingDropdown,
  completed,
  error,
  stopped,
}

class AutomationStatus {
  final AutomationState state;
  final String message;
  final int fieldsFilled;
  final int fieldsTotal;
  final int scrollCount;

  const AutomationStatus({
    required this.state,
    this.message = '',
    this.fieldsFilled = 0,
    this.fieldsTotal = 0,
    this.scrollCount = 0,
  });

  AutomationStatus copyWith({
    AutomationState? state,
    String? message,
    int? fieldsFilled,
    int? fieldsTotal,
    int? scrollCount,
  }) {
    return AutomationStatus(
      state: state ?? this.state,
      message: message ?? this.message,
      fieldsFilled: fieldsFilled ?? this.fieldsFilled,
      fieldsTotal: fieldsTotal ?? this.fieldsTotal,
      scrollCount: scrollCount ?? this.scrollCount,
    );
  }
}
