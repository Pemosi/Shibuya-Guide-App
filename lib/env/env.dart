// ignore: depend_on_referenced_packages
import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'KEY', obfuscate: true)
  static final String key = _Env.key;
}