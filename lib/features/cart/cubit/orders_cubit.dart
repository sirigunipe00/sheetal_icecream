import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StoreOrder extends Equatable {
  const StoreOrder({
    required this.number,
    required this.date,
    required this.lines,
    required this.total,
    required this.address,
    required this.payment,
  });

  final String number;
  final String date;
  final List<String> lines;
  final int total;
  final String address;
  final String payment;

  @override
  List<Object?> get props => [number, date, lines, total, address, payment];
}

class OrdersCubit extends Cubit<List<StoreOrder>> {
  OrdersCubit() : super(const []);

  void add(StoreOrder order) => emit([order, ...state]);
}
