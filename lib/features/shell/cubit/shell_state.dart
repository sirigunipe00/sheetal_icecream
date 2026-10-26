import 'package:equatable/equatable.dart';

enum AppTab {
  home,
  categories,
  wishlist,
  cart,
  profile,
}

class ShellState extends Equatable {
  const ShellState(this.tab);

  final AppTab tab;

  @override
  List<Object?> get props => [tab];
}
