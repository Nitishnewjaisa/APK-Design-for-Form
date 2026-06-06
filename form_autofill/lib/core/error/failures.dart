abstract class Failure {
  final String message;
  const Failure(this.message);
}

class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class AutomationFailure extends Failure {
  const AutomationFailure(super.message);
}

class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}
