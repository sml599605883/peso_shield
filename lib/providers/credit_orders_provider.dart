import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../data/models/order_data.dart';
import 'repository_provider.dart';

enum OrderFilter {
  all('All order', '4'),
  outstanding('Outstanding', '7'),
  overdue('Overdue', '6'),
  settled('Settled', '5');

  const OrderFilter(this.label, this.segregateValue);
  final String label;
  final String segregateValue;
}

final creditOrdersProvider =
    AsyncNotifierProvider<CreditOrdersNotifier, CreditOrdersState>(
  CreditOrdersNotifier.new,
);

class CreditOrdersState {
  const CreditOrdersState({
    this.orders = const [],
    this.filter = OrderFilter.all,
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
  });

  final List<OrderItem> orders;
  final OrderFilter filter;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;

  bool get hasMore => currentPage < totalPages;
  bool get isEmpty => orders.isEmpty;

  CreditOrdersState copyWith({
    List<OrderItem>? orders,
    OrderFilter? filter,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
  }) {
    return CreditOrdersState(
      orders: orders ?? this.orders,
      filter: filter ?? this.filter,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class CreditOrdersNotifier extends AsyncNotifier<CreditOrdersState> {
  @override
  CreditOrdersState build() {
    return const CreditOrdersState();
  }

  Future<void> loadOrders({OrderFilter? filter}) async {
    final targetFilter = filter ?? state.value?.filter ?? OrderFilter.all;
    
    // Reset to first page when filter changes
    final shouldReset = filter != null && 
        filter != state.value?.filter;
    
    if (shouldReset) {
      state = AsyncData(CreditOrdersState(filter: targetFilter));
    } else if (!state.hasValue) {
      state = const AsyncLoading<CreditOrdersState>();
    }

    try {
      final repository = await ref.read(orderRepositoryProvider.future);
      final response = await repository.getOrderList(
        page: 1,
        pageSize: 20,
        segregate: targetFilter.segregateValue,
      );

      print('API Response: isSuccess=${response.isSuccess}, message=${response.message}');

      if (!response.isSuccess) {
        throw ApiException(
          type: ApiFailureType.business,
          message: response.message,
        );
      }

      final data = response.data;
      print('Orders count: ${data.orders.length}, totalPages: ${data.totalPages}');
      if (data.orders.isNotEmpty) {
        print('First order: ${data.orders.first.productName}');
      }

      if (ref.mounted) {
        state = AsyncData(
          CreditOrdersState(
            orders: data.orders,
            filter: targetFilter,
            currentPage: 1,
            totalPages: data.totalPages,
          ),
        );
      }
    } catch (error, stack) {
      print('Load orders error: $error');
      if (ref.mounted) {
        state = AsyncError<CreditOrdersState>(error, stack);
      }
    }
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final repository = await ref.read(orderRepositoryProvider.future);
      final nextPage = current.currentPage + 1;
      final response = await repository.getOrderList(
        page: nextPage,
        pageSize: 20,
        segregate: current.filter.segregateValue,
      );

      if (!response.isSuccess) {
        throw ApiException(
          type: ApiFailureType.business,
          message: response.message,
        );
      }

      final data = response.data;
      final allOrders = [...current.orders, ...data.orders];

      if (ref.mounted) {
        state = AsyncData(
          current.copyWith(
            orders: allOrders,
            currentPage: nextPage,
            totalPages: data.totalPages,
            isLoadingMore: false,
          ),
        );
      }
    } catch (error) {
      if (ref.mounted) {
        state = AsyncData(current.copyWith(isLoadingMore: false));
      }
    }
  }
}
