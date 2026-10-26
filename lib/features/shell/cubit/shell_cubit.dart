import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sheetal_icecream/features/shell/cubit/shell_state.dart';

class ShellCubit extends Cubit<ShellState> {
  ShellCubit() : super(const ShellState(AppTab.home));

  void select(AppTab tab) => emit(ShellState(tab));
}
