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

  loggingPort.listen((message) {
    print(message);
  });

  bool exit = false;
  while (!exit) {
    Future.delayed(Duration(seconds: 1));
    print('1: Start server');
    print('2: Stop server');
    print('3: Restart server');
    print('4: Show logs');
    print('5: Exit');
    String action = ask('number:', required: true, validator: Ask.integer);
    switch (action) {
      case '1':
        sendPort.send(CliCommands.start);
        break;
      case '2':
        sendPort.send(CliCommands.stop);
        break;
      case '3':
        sendPort.send(CliCommands.restart);
        break;
      case '4':
        sendPort.send(CliCommands.showLog);
        break;
      case '5':
        sendPort.send(CliCommands.exit);
        exit = true;
        break;
    }
  }
  receivePort.close();
  loggingPort.close();
  print('Exiting...');
}

void serverIsolate(List<SendPort> ports) async {
  // Setup
  SendPort sendPort = ports[0];
  SendPort loggingPort = ports[1];
  final ReceivePort receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);

  final UpServer server = UpServer(6000, printer: ((level, actor, message) {
    switch (level) {
      case LogLevel.none:
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
  receivePort.listen((message) async {
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
        await server.stop();
        receivePort.close();
        break;
    }
  });

  while (true) {
    await server.update(blocking: true);
  }
}
