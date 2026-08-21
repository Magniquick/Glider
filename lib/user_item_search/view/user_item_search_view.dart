import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glider/app/container/app_container.dart';
import 'package:glider/app/extensions/super_sliver_list_extension.dart';
import 'package:glider/app/models/app_route.dart';
import 'package:glider/auth/cubit/auth_cubit.dart';
import 'package:glider/common/mixins/data_mixin.dart';
import 'package:glider/common/widgets/refreshable_scroll_view.dart';
import 'package:glider/item/widgets/item_tile.dart';
import 'package:glider/settings/cubit/settings_cubit.dart';
import 'package:glider/user_item_search/bloc/user_item_search_bloc.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:go_router/go_router.dart';

class const UserItemSearchView(
  final UserItemSearchBloc _userItemSearchBloc,
  final ItemCubitFactory _itemCubitFactory,
  final AuthCubit _authCubit,
  final SettingsCubit _settingsCubit, {
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RefreshableScrollView(
    onRefresh: () async =>
        _userItemSearchBloc.add(const LoadUserItemSearchEvent()),
    edgeOffset: 0,
    slivers: [
      SliverSafeArea(
        top: false,
        sliver: _SliverUserItemSearchBody(
          _userItemSearchBloc,
          _itemCubitFactory,
          _authCubit,
          _settingsCubit,
        ),
      ),
    ],
  );
}

class const _SliverUserItemSearchBody(
  final UserItemSearchBloc _userItemSearchBloc,
  final ItemCubitFactory _itemCubitFactory,
  final AuthCubit _authCubit,
  final SettingsCubit _settingsCubit,
) extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<UserItemSearchBloc, UserItemSearchState>(
        bloc: _userItemSearchBloc,
        builder: (context, state) => state.whenOrDefaultSlivers(
          nonEmpty: () => SuperSliverListExtension.builder(
            itemCount: state.data!.length,
            itemBuilder: (context, index) {
              final int id = state.data![index];
              return ItemTile.create(
                _itemCubitFactory,
                _authCubit,
                _settingsCubit,
                id: id,
                loadingType: ItemType.story,
                onTap: (context, item) => context.push(
                  AppRoute.item.location(parameters: {'id': id}),
                ),
              );
            },
          ),
          onRetry: () =>
              _userItemSearchBloc.add(const LoadUserItemSearchEvent()),
        ),
      );
}
