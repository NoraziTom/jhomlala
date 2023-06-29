///Configuration of notification which is displayed once user moves app to
///background.
class BetterPlayerNotificationConfiguration {
  ///Is player controls notification enabled
  final bool? showNotification;

  ///Using for clear notification info of previous video. Used only in iOS.
  final bool? shouldClearPreviousNotificationInfo;

  ///Title of the given data source, used in controls notification
  final String? title;

  ///Author of the given data source, used in controls notification
  final String? author;

  ///Image of the video, used in controls notification
  final String? imageUrl;

  ///Name of the notification channel. Used only in Android.
  final String? notificationChannelName;

  ///Name of activity used to open application from notification. Used only
  ///in Android.
  final String? activityName;

  const BetterPlayerNotificationConfiguration({
    this.showNotification = false,
    this.shouldClearPreviousNotificationInfo = true,
    this.title,
    this.author,
    this.imageUrl,
    this.notificationChannelName,
    this.activityName,
  });
}
