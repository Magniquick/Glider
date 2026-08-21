import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:equatable/equatable.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:pub_semver/pub_semver.dart';

part 'navigation_shell_cubit_event.dart';
part 'navigation_shell_state.dart';

class NavigationShellCubit(final PackageRepository _packageRepository)
    extends Cubit<NavigationShellState>
    with
        BlocPresentationMixin<
          NavigationShellState,
          NavigationShellPresentationEvent
        > {
  this : super(const NavigationShellState());

  Future<void> init() async {
    final Version version = _packageRepository.getVersion();
    final Version? lastVersion = await _packageRepository.getLastVersion();

    if (version != lastVersion) {
      await _packageRepository.setLastVersion(value: version);

      if (lastVersion != null && version >= lastVersion.nextMajor) {
        emitPresentation(ShowWhatsNewEvent());
      }
    }
  }
}
