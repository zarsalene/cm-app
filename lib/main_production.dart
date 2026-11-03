import 'package:cm_app/app/app.dart';
import 'package:cm_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap((push) => App(push: push));
}
