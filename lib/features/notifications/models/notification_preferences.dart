import 'package:equatable/equatable.dart';

class NotificationPreferences extends Equatable {
  final bool promotions;
  final bool newCars;
  final bool bookingReminders;
  final bool offers;

  const NotificationPreferences({
    this.promotions = true,
    this.newCars = true,
    this.bookingReminders = true,
    this.offers = true,
  });

  Map<String, dynamic> toMap() => {
        'promotions': promotions,
        'newCars': newCars,
        'bookingReminders': bookingReminders,
        'offers': offers,
      };

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      promotions: map['promotions'] ?? true,
      newCars: map['newCars'] ?? true,
      bookingReminders: map['bookingReminders'] ?? true,
      offers: map['offers'] ?? true,
    );
  }

  NotificationPreferences copyWith({
    bool? promotions,
    bool? newCars,
    bool? bookingReminders,
    bool? offers,
  }) {
    return NotificationPreferences(
      promotions: promotions ?? this.promotions,
      newCars: newCars ?? this.newCars,
      bookingReminders: bookingReminders ?? this.bookingReminders,
      offers: offers ?? this.offers,
    );
  }

  List<String> get enabledTopics {
    final topics = <String>[];
    if (promotions) topics.add('promotions');
    if (newCars) topics.add('new_cars');
    if (bookingReminders) topics.add('booking_reminders');
    if (offers) topics.add('offers');
    return topics;
  }

  @override
  List<Object?> get props =>
      [promotions, newCars, bookingReminders, offers];
}
