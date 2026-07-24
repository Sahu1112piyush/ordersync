import '../../data/models/order_status.dart';

class ConflictResolutionResult {
  final OrderStatus winningStatus;
  final bool isConflict;
  final String strategy;
  final String explanation;

  const ConflictResolutionResult({
    required this.winningStatus,
    required this.isConflict,
    required this.strategy,
    required this.explanation,
  });
}

class ConflictResolver {
  /// Evaluates conflict between Server Status and Offline Client Status
  static ConflictResolutionResult resolve({
    required OrderStatus serverStatus,
    required OrderStatus clientStatus,
    required DateTime serverTimestamp,
    required DateTime clientTimestamp,
  }) {
    // 1. Identical states - No conflict
    if (serverStatus == clientStatus) {
      return ConflictResolutionResult(
        winningStatus: serverStatus,
        isConflict: false,
        strategy: 'Direct Match',
        explanation: 'Server and client statuses are identical (${serverStatus.displayName}).',
      );
    }

    // 2. Terminal State Conflict: Delivered vs Cancelled
    if (serverStatus == OrderStatus.delivered && clientStatus == OrderStatus.cancelled) {
      return const ConflictResolutionResult(
        winningStatus: OrderStatus.delivered,
        isConflict: true,
        strategy: 'Terminal Precedence (Server Delivered Wins)',
        explanation:
            'Order was already marked Delivered on the server. Offline cancellation request was overridden to protect physical fulfillment.',
      );
    }

    if (serverStatus == OrderStatus.cancelled && clientStatus == OrderStatus.delivered) {
      return const ConflictResolutionResult(
        winningStatus: OrderStatus.cancelled,
        isConflict: true,
        strategy: 'Terminal Precedence (Server Cancelled Wins)',
        explanation:
            'Order was cancelled on the server prior to offline delivery submission. Server cancellation retained.',
      );
    }

    // 3. Precedence Rank check
    final int serverRank = serverStatus.precedenceRank;
    final int clientRank = clientStatus.precedenceRank;

    if (clientRank > serverRank) {
      return ConflictResolutionResult(
        winningStatus: clientStatus,
        isConflict: true,
        strategy: 'Progressive Rank Advancement',
        explanation:
            'Client update (${clientStatus.displayName}) advances order progress beyond server state (${serverStatus.displayName}).',
      );
    } else if (serverRank > clientRank) {
      return ConflictResolutionResult(
        winningStatus: serverStatus,
        isConflict: true,
        strategy: 'Server Precedence (Regressive Update Ignored)',
        explanation:
            'Server is at a more advanced state (${serverStatus.displayName}) than client offline update (${clientStatus.displayName}). Server state preserved.',
      );
    }

    // 4. Equal Rank (e.g., both terminal or parallel branches), fallback to Last-Write-Wins (Timestamp)
    if (clientTimestamp.isAfter(serverTimestamp)) {
      return ConflictResolutionResult(
        winningStatus: clientStatus,
        isConflict: true,
        strategy: 'Last-Write-Wins (Client Timestamp)',
        explanation:
            'Client offline timestamp (${clientTimestamp.toIso8601String()}) is newer than server timestamp (${serverTimestamp.toIso8601String()}).',
      );
    } else {
      return ConflictResolutionResult(
        winningStatus: serverStatus,
        isConflict: true,
        strategy: 'Last-Write-Wins (Server Timestamp)',
        explanation:
            'Server timestamp (${serverTimestamp.toIso8601String()}) is newer than client timestamp.',
      );
    }
  }
}
