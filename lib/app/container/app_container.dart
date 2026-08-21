import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glider/auth/cubit/auth_cubit.dart';
import 'package:glider/edit/cubit/edit_cubit.dart';
import 'package:glider/favorites/cubit/favorites_cubit.dart';
import 'package:glider/inbox/cubit/inbox_cubit.dart';
import 'package:glider/item/cubit/item_cubit.dart';
import 'package:glider/item_tree/cubit/item_tree_cubit.dart';
import 'package:glider/navigation_shell/cubit/navigation_shell_cubit.dart';
import 'package:glider/reply/cubit/reply_cubit.dart';
import 'package:glider/settings/cubit/settings_cubit.dart';
import 'package:glider/stories/cubit/stories_cubit.dart';
import 'package:glider/stories_search/bloc/stories_search_bloc.dart';
import 'package:glider/stories_search/models/search_type.dart';
import 'package:glider/story_item_search/bloc/story_item_search_bloc.dart';
import 'package:glider/story_similar/cubit/story_similar_cubit.dart';
import 'package:glider/submit/cubit/submit_cubit.dart';
import 'package:glider/user/cubit/user_cubit.dart';
import 'package:glider/user_item_search/bloc/user_item_search_bloc.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef ItemCubitFactory = ItemCubit Function(int);

typedef ItemTreeCubitFactory = ItemTreeCubit Function(int);

typedef StorySimilarCubitFactory = StorySimilarCubit Function(int);

typedef StoryItemSearchBlocFactory = StoryItemSearchBloc Function(int);

typedef EditCubitFactory = EditCubit Function(int);

typedef ReplyCubitFactory = ReplyCubit Function(int);

typedef UserCubitFactory = UserCubit Function(String);

typedef UserItemSearchBlocFactory = UserItemSearchBloc Function(String);

class const AppContainer(
  final NavigationShellCubit navigationShellCubit,
  final AuthCubit authCubit,
  final SettingsCubit settingsCubit,
  final StoriesCubit storiesCubit,
  final StoriesSearchBloc storiesSearchBloc,
  final StoriesSearchBloc catchUpBloc,
  final SubmitCubit submitCubit,
  final ItemCubitFactory itemCubitFactory,
  final ItemTreeCubitFactory itemTreeCubitFactory,
  final StorySimilarCubitFactory storySimilarCubitFactory,
  final StoryItemSearchBlocFactory storyItemSearchCubitFactory,
  final EditCubitFactory editCubitFactory,
  final ReplyCubitFactory replyCubitFactory,
  final FavoritesCubit favoritesCubit,
  final InboxCubit inboxCubit,
  final UserCubitFactory userCubitFactory,
  final UserItemSearchBlocFactory userItemSearchBlocFactory,
) {
  static Future<AppContainer> create() async {
    final httpClient = http.Client();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final SharedPreferences sharedPreferencesFactory =
        await SharedPreferences.getInstance();
    const flutterSecureStorage = FlutterSecureStorage(
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
    final algoliaApiService = AlgoliaApiService(httpClient);
    final genericWebsiteService = GenericWebsiteService(httpClient);
    final hackerNewsApiService = HackerNewsApiService(httpClient);
    final hackerNewsWebsiteService = HackerNewsWebsiteService(
      httpClient,
      userAgent: 'Glider/${packageInfo.version}',
    );
    const secureStorageService = SecureStorageService(flutterSecureStorage);
    final sharedPreferencesService = SharedPreferencesService(
      sharedPreferencesFactory,
    );
    final authRepository = AuthRepository(
      hackerNewsWebsiteService,
      secureStorageService,
      sharedPreferencesService,
    );
    final itemRepository = ItemRepository(
      algoliaApiService,
      hackerNewsApiService,
    );
    final itemInteractionRepository = ItemInteractionRepository(
      hackerNewsWebsiteService,
      secureStorageService,
      sharedPreferencesService,
    );
    final packageRepository = PackageRepository(
      sharedPreferencesService,
      packageInfo,
    );
    final settingsRepository = SettingsRepository(sharedPreferencesService);
    final userRepository = UserRepository(hackerNewsApiService);
    final userInteractionRepository = UserInteractionRepository(
      hackerNewsWebsiteService,
      secureStorageService,
      sharedPreferencesService,
    );
    final websiteRepository = WebsiteRepository(genericWebsiteService);

    return AppContainer(
      NavigationShellCubit(packageRepository),
      AuthCubit(authRepository, itemInteractionRepository),
      SettingsCubit(
        settingsRepository,
        packageRepository,
        itemInteractionRepository,
      ),
      StoriesCubit(itemRepository),
      StoriesSearchBloc(itemRepository),
      StoriesSearchBloc(itemRepository, searchType: SearchType.catchUp),
      SubmitCubit(itemInteractionRepository, websiteRepository),
      (id) => ItemCubit(
        itemRepository,
        itemInteractionRepository,
        userInteractionRepository,
        id: id,
      ),
      (id) => ItemTreeCubit(itemRepository, id: id),
      (id) => StorySimilarCubit(itemRepository, id: id),
      (id) => StoryItemSearchBloc(itemRepository, id: id),
      (id) => EditCubit(itemRepository, itemInteractionRepository, id: id),
      (id) => ReplyCubit(itemRepository, itemInteractionRepository, id: id),
      FavoritesCubit(itemInteractionRepository),
      InboxCubit(itemRepository, authRepository),
      (username) => UserCubit(
        userRepository,
        userInteractionRepository,
        itemInteractionRepository,
        username: username,
      ),
      (username) => UserItemSearchBloc(itemRepository, username: username),
    );
  }
}
