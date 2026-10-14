part of '../../main.dart';

extension AppModulePresentation on AppModule {
  IconData get icon => switch (this) {
        AppModule.memories => Icons.photo_library_outlined,
        AppModule.people => Icons.people_outline,
        AppModule.habits => Icons.check_circle_outline,
        AppModule.sharedSpace => Icons.favorite_outline,
        AppModule.shopping => Icons.shopping_cart_outlined,
        AppModule.workout => Icons.sports_outlined,
        AppModule.cycleTracker => Icons.calendar_month_outlined,
        AppModule.privateVault => Icons.lock_outline,
        AppModule.ecosystem => Icons.hub_outlined,
      };
}

class PersonalizationScreen extends StatelessWidget {
  final AgendaStore store;

  const PersonalizationScreen({
    super.key,
    required this.store,
  });

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
              strings.v101PersonalizeTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                strings.v101PersonalizeSubtitle,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              Text(
                strings.v101PresetSection,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
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
                      identifier: 'personalization_preset_${preset.name}',
                      button: true,
                      selected: prefs.personalizationPreset == preset,
                      child: ChoiceChip(
                        label: Text(strings.v101PresetTitle(preset)),
                        selected: prefs.personalizationPreset == preset,
                        avatar: Icon(
                          switch (preset) {
                            PersonalizationPreset.essential =>
                              Icons.filter_alt_outlined,
                            PersonalizationPreset.life =>
                              Icons.auto_awesome_outlined,
                            PersonalizationPreset.complete =>
                              Icons.dashboard_customize_outlined,
                            PersonalizationPreset.custom =>
                              Icons.tune_outlined,
                          },
                          size: 18,
                        ),
                        onSelected: (_) =>
                            store.applyPersonalizationPreset(preset),
                      ),
                    ),
                  if (prefs.personalizationPreset ==
                      PersonalizationPreset.custom)
                    Chip(
                      avatar: const Icon(Icons.tune_outlined, size: 18),
                      label: Text(strings.v101CustomTitle),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                strings.v101ModulesSection,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 5),
              Text(
                strings.v101ModulesDescription,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              for (final module in AppModule.values)
                Semantics(
                  identifier: 'module_toggle_${module.name}',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: CircleAvatar(
                      child: Icon(module.icon),
                    ),
                    title: Text(
                      strings.v101ModuleTitle(module),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(strings.v101ModuleSubtitle(module)),
                    value: prefs.isModuleEnabled(module),
                    onChanged: (enabled) =>
                        store.setModuleEnabled(module, enabled),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
