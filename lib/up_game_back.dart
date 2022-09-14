import 'dart:async';
import 'dart:isolate';
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
  final ReceivePort receivePort = ReceivePort();
  final ReceivePort loggingPort = ReceivePort();
  final isolate = await Isolate.spawn(
      serverIsolate, [receivePort.sendPort, loggingPort.sendPort]);
  final SendPort sendPort = await receivePort.first;

  final loggingSubscription = loggingPort.listen((message) {
    print(message);
  });

  bool exit = false;
  while (!exit) {
    String selected = menu(
      options: [
        'Start server',
        'Stop server',
        'Restart server',
        'Show logs',
        'Exit',
      ],
      prompt: 'Your selection:',
    );
    print(selected);
    switch (selected) {
      case 'Start server':
        sendPort.send(CliCommands.start);
        break;
      case 'Stop server':
        sendPort.send(CliCommands.stop);
        break;
      case 'Restart server':
        sendPort.send(CliCommands.restart);
        break;
      case 'Show logs':
        sendPort.send(CliCommands.showLog);
        break;
      case 'Exit':
        sendPort.send(CliCommands.exit);
        exit = true;
        break;
    }
    await Future.delayed(Duration(seconds: 1));
  }
  receivePort.close();
  loggingPort.close();
  await loggingSubscription.cancel();
  print('Exiting...');
}

void serverIsolate(List<SendPort> ports) async {
  // Setup
  bool quit = false;
  SendPort sendPort = ports[0];
  SendPort loggingPort = ports[1];
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final UpServer server = UpServer(6000, printer: ((level, actor, message) {
    switch (level) {
      case LogLevel.none:
        break;
      case LogLevel.info:
      case LogLevel.debug:
      case LogLevel.verbose:
        loggingPort.send("[$level][$actor] $message");
        break;
      case LogLevel.error:
        loggingPort.send("[${red(level.toString())}][$actor] $message");
        break;
      case LogLevel.warning:
        loggingPort.send("[${yellow(level.toString())}][$actor] $message");
        break;
    }
  }));

  // listen to Cli commands
  late final StreamSubscription<dynamic> commandSubscription;
  commandSubscription = receivePort.listen((message) async {
    final CliCommands command = message as CliCommands;

    switch (command) {
      case CliCommands.start:
        await server.start();
        break;
      case CliCommands.stop:
        await server.stop();
        break;
      case CliCommands.restart:
        await server.start();
        await server.stop();
        break;
      case CliCommands.showLog:
        print("coucou");
        break;
      case CliCommands.hideLog:
        break;
      case CliCommands.exit:
        quit = true;
        await server.stop();
        commandSubscription.cancel();
        receivePort.close();
        break;
    }
  });

  while (!quit) {
    await server.update(blocking: true);
  }
}
