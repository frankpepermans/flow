library flow.digest;

class Digestable {

  final int key;
  final Map<String, dynamic> data;

  Digestable(this.key, this.data);

}

class Digest {

  final Map<int, Map<String, dynamic>> _digestables = <int, Map<String, dynamic>>{};

  Digest();

  void append(Digestable digestable) {
    _digestables[digestable.key] = digestable.data;
  }

  Map<int, Map<String, dynamic>> flush() => _digestables;

}