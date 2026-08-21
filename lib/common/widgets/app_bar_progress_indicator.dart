import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glider/common/constants/app_animation.dart';
import 'package:glider/common/mixins/data_mixin.dart';
import 'package:glider/common/models/status.dart';

const _height = 2.0;

class const AppBarProgressIndicator<
  B extends BlocBase<S>,
  S extends DataMixin<dynamic>
>(final B _bloc, {super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => BlocSelector<B, S, bool>(
    bloc: _bloc,
    selector: (state) => state.status == Status.loading,
    builder: (context, isLoading) => AnimatedOpacity(
      opacity: isLoading ? 1 : 0,
      duration: AppAnimation.standard.duration,
      curve: AppAnimation.standard.easing,
      child: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight - _height,
        ),
        child: TickerMode(
          enabled: isLoading,
          child: const LinearProgressIndicator(
            minHeight: _height,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    ),
  );
}
