import 'package:bloc/bloc.dart';
import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:equatable/equatable.dart';
import 'package:glider_domain/glider_domain.dart';

part 'navigation_shell_cubit_event.dart';
part 'navigation_shell_state.dart';

class NavigationShellCubit(this._packageRepository)
    extends Cubit<NavigationShellState>
    with
        BlocPresentationMixin<NavigationShellState, NavigationShellCubitEvent> {
  this : super(const NavigationShellState());

  final PackageRepository _packageRepository;

  Future<void> init() async {
    final version = _packageRepository.getVersion();
    final lastVersion = await _packageRepository.getLastVersion();

    if (version != lastVersion) {
      await _packageRepository.setLastVersion(value: version);

      if (lastVersion != null && version >= lastVersion.nextMajor) {
        emitPresentation(ShowWhatsNewEvent());
      }
    }
  }
}
