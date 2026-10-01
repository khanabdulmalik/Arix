abstract class MeshTransport {
  Future<void> broadcast(String payload);
  Stream<String> get onMessageReceived;
}
