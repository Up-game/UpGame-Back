import 'dart:async';
import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:netframework/netframework.dart';
import 'package:up_game_back/up_server.dart';

int calculate() {
  return 6 * 7;
}

enum CliCommands {
  start,
  stop,
  restart,
  showLog,
  hideLog,
  exit,
}

enum CliResponse {
  loading,
  done,
}

void main(List<String> args) async {
  final UpServer server = UpServer(6000, printer: (level, actor, message) {
    switch (level) {
      case LogLevel.none:
        break;
      case LogLevel.info:
      case LogLevel.debug:
      case LogLevel.verbose:
        Terminal().write(green('[$level][$actor] $message'));
        break;
      case LogLevel.error:
        Terminal().write("[${red(level.toString())}][$actor] $message");
        break;
      case LogLevel.warning:
        Terminal().write("[${yellow(level.toString())}][$actor] $message");
        break;
    }
  });

  late final StreamSubscription sigintSub;
  sigintSub = ProcessSignal.sigint.watch().listen((signal) async {
    if (signal != ProcessSignal.sigusr1) {
      print("Killing server !");
      server.stop();
    }
  });

  await server.start();

  while (server.isRunning) {
    await server.update(blocking: true);
  }

  print("left");
}
