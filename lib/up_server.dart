import 'package:netframework/netframework.dart';

class UpServer extends Server {
  UpServer(super.port, {Printer? printer}) : super(printer: printer);

  @override
  void onMessage(Connection connection, Message message) {}
}
