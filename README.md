# Interval Reminders

A Flutter application for periodic reminders (Action 10-120min, Rest 5-180min).

## Setup Instructions

Since the Flutter SDK was not detected in the environment during initialization, you need to perform the following steps to build the application:

1.  **Install Flutter**: Ensure Flutter is installed and in your PATH.
2.  **Generate Platform Code**: Run the following command in this directory to generate Android and iOS projects:
    ```bash
    flutter create .
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```

## Features

- **Action Timer**: Adjustable from 10 to 120 minutes.
- **Rest Timer**: Adjustable from 5 to 180 minutes.
- **Visual Countdown**: Clean, modern UI using Material 3.
- **Background Persistence**: (Planned) Uses `android_alarm_manager_plus` for reliable long-duration timing.

## Note on Backend Integration

The `TimerService` class in `lib/main.dart` is designed to be easily extended. To save results:
1.  Add a method in `TimerService` (e.g., `_logSession(IntervalType type, int duration)`).
2.  Call your backend API (Firebase/Rest) inside that method when an interval completes.
