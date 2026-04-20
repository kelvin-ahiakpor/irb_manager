# ashesi irb manager

A new Flutter project.

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.

## Local Configuration

Copy `.env.example` to `.env` and fill in local secrets. Do not commit `.env`.

Run Flutter with the local environment file:

```sh
flutter run --dart-define-from-file=.env
```

In Android Studio, add this to the Flutter run configuration's additional
arguments:

```sh
--dart-define-from-file=.env
```
