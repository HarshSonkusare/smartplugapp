class EnergyModel {
  final day;
  final week;
  final month;

  EnergyModel({this.day, this.week, this.month});

  factory EnergyModel.fromJason(final json) {
    return EnergyModel(
        day: json['day'], week: json['week'], month: json['month']);
  }
}
