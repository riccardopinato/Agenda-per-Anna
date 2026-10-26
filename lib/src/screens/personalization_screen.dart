part of '../../main.dart';

class PersonalizationScreen extends StatelessWidget {
  final AgendaStore store;

  const PersonalizationScreen({
    super.key,
    required this.store,
  });

  String _presetLabel(AnnaStrings strings, PersonalizationPreset preset) =>
      switch (preset) {
        PersonalizationPreset.essential =>
          strings.d3('onboardingPresetEssentialTitle'),
        PersonalizationPreset.life =>
          strings.d3('onboardingPresetLifeTitle'),
        PersonalizationPreset.complete =>
          strings.d3('onboardingPresetCompleteTitle'),
        PersonalizationPreset.custom =>
          strings.d3('personalizationCustomTitle'),
      };

  String _moduleTitle(AnnaStrings strings, AppModule module) => switch (module) {
        AppModule.memories => strings.v100MyMemories,
        AppModule.people => strings.v100ImportantPeople,
        AppModule.habits => strings.d3('personalizationHabits'),
        AppModule.sharedSpace => 'Noi ♡',
        AppModule.shopping => strings.v100Shopping,
        AppModule.workout => strings.v100Workout,
        AppModule.cycleTracker => strings.cycleTitle,
        AppModule.privateVault => strings.v100PrivateVault,
        AppModule.ecosystem => strings.lifeEcosystemTitle,
      };

  IconData _moduleIcon(AppModule module) => switch (module) {
        AppModule.memories => Icons.photo_library_outlined,
        AppModule.people => Icons.people_outline,
        AppModule.habits => Icons.check_circle_outline,
        AppModule.sharedSpace => Icons.favorite_outline,
        AppModule.shopping => Icons.shopping_cart_outlined,
        AppModule.workout => Icons.sports_outlined,
        AppModule.cycleTracker => Icons.favorite_border,
        AppModule.privateVault => Icons.lock_person_outlined,
        AppModule.ecosystem => Icons.hub_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store.settingsRevision,
      builder: (context, _) {
        final strings = AnnaStrings.of(context);
        final prefs = store.preferences;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              strings.d3('personalizationTitle'),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              Text(
                strings.d3('personalizationIntro'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        strings.d3('personalizationPresetTitle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.d3Format(
                        'personalizationCurrentPreset',
                        {'preset': _presetLabel(strings, prefs.personalizationPreset)},
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in const [
                          PersonalizationPreset.essential,
                          PersonalizationPreset.life,
                          PersonalizationPreset.complete,
                        ])
                          Semantics(
                            identifier:
                                'personalization_preset_${preset.name}',
                            container: true,
                            button: true,
                            selected: prefs.personalizationPreset == preset,
                            label: _presetLabel(strings, preset),
                            onTap: () =>
                                store.applyPersonalizationPreset(preset),
                            excludeSemantics: true,
                            child: ChoiceChip(
                              key: ValueKey(
                                'personalization-preset-${preset.name}',
                              ),
                              selected: prefs.personalizationPreset == preset,
                              label: Text(_presetLabel(strings, preset)),
                              onSelected: (_) =>
                                  store.applyPersonalizationPreset(preset),
                            ),
                          ),
                      ],
                    ),
                    if (prefs.personalizationPreset ==
                        PersonalizationPreset.custom) ...[
                      const SizedBox(height: 10),
                      Chip(
                        avatar: const Icon(Icons.tune, size: 18),
                        label: Text(strings.d3('personalizationCustomActive')),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      strings.d3('personalizationHiddenDataSafe'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SimpleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        strings.d3('personalizationModulesTitle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.d3('personalizationModulesHint'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    for (final module in AppModule.values.where(
                      (module) => module != AppModule.memories,
                    )) ...[
                      Builder(
                        builder: (context) {
                          final enabled = prefs.isModuleEnabled(module);
                          final hint = module == AppModule.cycleTracker
                              ? strings.d3(
                                  'personalizationCycleDependency',
                                )
                              : module == AppModule.privateVault &&
                                      prefs.isModuleEnabled(
                                        AppModule.cycleTracker,
                                      )
                                  ? strings.d3(
                                      'personalizationVaultDependency',
                                    )
                                  : null;
                          return Semantics(
                            identifier:
                                'personalization_module_${module.name}',
                            container: true,
                            label: _moduleTitle(strings, module),
                            hint: hint,
                            toggled: enabled,
                            enabled: true,
                            onTap: () =>
                                store.setModuleEnabled(module, !enabled),
                            excludeSemantics: true,
                            child: SwitchListTile.adaptive(
                              key: ValueKey(
                                'personalization-module-${module.name}',
                              ),
                              contentPadding: EdgeInsets.zero,
                              secondary: Icon(_moduleIcon(module)),
                              title: Text(_moduleTitle(strings, module)),
                              subtitle: hint == null ? null : Text(hint),
                              value: enabled,
                              onChanged: (value) =>
                                  store.setModuleEnabled(module, value),
                            ),
                          );
                        },
                      ),
                      if (module != AppModule.values.last)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'personalization_restore_complete',
                button: true,
                label: strings.d3('personalizationRestoreComplete'),
                child: OutlinedButton.icon(
                  key: const ValueKey('personalization-restore-complete'),
                  onPressed: () => store.applyPersonalizationPreset(
                    PersonalizationPreset.complete,
                  ),
                  icon: const Icon(Icons.restore_outlined),
                  label: Text(
                    strings.d3('personalizationRestoreComplete'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
