import 'package:dartz/dartz.dart';

import '../error/old_failuers.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}

class Params<T> {
  final T data;

  Params(this.data);
}