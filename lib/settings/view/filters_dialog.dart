import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glider/common/constants/app_animation.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/common/extensions/widget_list_extension.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';
import 'package:glider/settings/cubit/settings_cubit.dart';
import 'package:go_router/go_router.dart';

class const FiltersDialog(final SettingsCubit _settingsCubit, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.l10n.filters),
    content: SingleChildScrollView(child: _FiltersBody(_settingsCubit)),
    actions: [
      TextButton(
        onPressed: () => context.pop(),
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}

class const _FiltersBody(final SettingsCubit _settingsCubit)
    extends StatefulWidget {
  @override
  State<_FiltersBody> createState() => _FiltersBodyState();
}

class _FiltersBodyState() extends State<_FiltersBody> {
  late final TextEditingController _wordsController;
  late final TextEditingController _domainsController;
  late final FocusNode _wordsFocusNode;
  late final FocusNode _domainsFocusNode;

  @override
  void initState() {
    super.initState();
    _wordsController = TextEditingController();
    _domainsController = TextEditingController();
    _wordsFocusNode = FocusNode();
    _domainsFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _wordsController.dispose();
    _domainsController.dispose();
    _wordsFocusNode.dispose();
    _domainsFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SettingsCubit, SettingsState>(
    bloc: widget._settingsCubit,
    buildWhen: (previous, current) =>
        !setEquals(previous.wordFilters, current.wordFilters) ||
        !setEquals(previous.domainFilters, current.domainFilters),
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.l,
      children: <Widget>[
        Text(
          context.l10n.words,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          spacing: AppSpacing.m,
          children: [
            Expanded(
              child: TextFormField(
                controller: _wordsController,
                focusNode: _wordsFocusNode,
                decoration: InputDecoration(hintText: context.l10n.wordsHint),
                keyboardType: TextInputType.text,
                onFieldSubmitted: (text) => _addWordFilter(),
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: _addWordFilter,
            ),
          ],
        ),
        AnimatedSize(
          alignment: AlignmentDirectional.topStart,
          duration: AppAnimation.emphasized.duration,
          curve: AppAnimation.emphasized.easing,
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: AppSpacing.m,
              children: [
                for (final word in state.wordFilters)
                  InputChip(
                    label: Text(word),
                    onDeleted: () => widget._settingsCubit.setWordFilter(
                      word,
                      filter: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
        Text(
          context.l10n.domains,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Row(
          spacing: AppSpacing.m,
          children: [
            Expanded(
              child: TextFormField(
                controller: _domainsController,
                focusNode: _domainsFocusNode,
                decoration: InputDecoration(hintText: context.l10n.domainsHelp),
                keyboardType: TextInputType.url,
                onFieldSubmitted: (text) => _addDomainFilter(),
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: _addDomainFilter,
            ),
          ],
        ),
        AnimatedSize(
          alignment: AlignmentDirectional.topStart,
          duration: AppAnimation.emphasized.duration,
          curve: AppAnimation.emphasized.easing,
          child: SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: AppSpacing.m,
              children: [
                for (final domain in state.domainFilters)
                  InputChip(
                    label: Text(domain),
                    onDeleted: () => widget._settingsCubit.setDomainFilter(
                      domain,
                      filter: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _addWordFilter() async {
    if (_wordsController.text.isNotEmpty) {
      await widget._settingsCubit.setWordFilter(
        _wordsController.text.trim().toLowerCase(),
        filter: true,
      );
      _wordsController.clear();
      _wordsFocusNode.requestFocus();
    }
  }

  Future<void> _addDomainFilter() async {
    if (_domainsController.text.isNotEmpty) {
      await widget._settingsCubit.setDomainFilter(
        _domainsController.text.trim().toLowerCase(),
        filter: true,
      );
      _domainsController.clear();
      _domainsFocusNode.requestFocus();
    }
  }
}
