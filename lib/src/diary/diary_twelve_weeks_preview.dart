part of '../../main.dart';

String annaTwelveWeeksConceptTitle(AnnaStrings strings) => strings._pick(
      it: 'Dodici settimane che contano',
      en: 'Twelve Meaningful Weeks',
      es: 'Doce semanas con sentido',
      fr: 'Douze semaines essentielles',
      pt: 'Doze semanas com significado',
    );

String annaTwelveWeeksConceptDefaultTitle(AnnaStrings strings) =>
    strings._pick(
      it: 'Le mie dodici settimane',
      en: 'My twelve weeks',
      es: 'Mis doce semanas',
      fr: 'Mes douze semaines',
      pt: 'As minhas doze semanas',
    );

String annaTwelveWeeksConceptCatalogSubtitle(AnnaStrings strings) =>
    strings._pick(
      it: 'Anteprima privata · non acquistabile · nessun dato salvato',
      en: 'Private preview · not for sale · no data saved',
      es: 'Vista privada · no disponible · sin guardar datos',
      fr: 'Aperçu privé · non disponible · aucune donnée enregistrée',
      pt: 'Prévia privada · indisponível · nenhum dado guardado',
    );

/// Read-only Flutter counterpart of the approved UX prototype. No DiaryBlock,
/// reminder, sync, entitlement, Store, or billing call is made on any path.
Future<void> showTwelveWeeksConceptPreview(BuildContext context) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => const TwelveWeeksConceptPreview(),
    ));

class TwelveWeeksConceptPreview extends StatefulWidget {
  const TwelveWeeksConceptPreview({super.key});

  @override
  State<TwelveWeeksConceptPreview> createState() => _TwelveWeeksConceptPreviewState();
}

class _TwelveWeeksConceptPreviewState extends State<TwelveWeeksConceptPreview> {
  static const _it = <String>[
    'Da dove voglio partire?|Quale piccolo cambiamento mi farebbe piacere provare?',
    'Una piccola abitudine|Quale gesto semplice vorrei ripetere?',
    'Cosa mi dà energia|Cosa mi ha dato un po’ di energia?',
    'Le persone importanti|A chi vorrei dedicare un pensiero?',
    'Un momento da custodire|Quale dettaglio recente voglio ricordare?',
    'Un luogo che vorrei vivere|Dove vorrei trascorrere un momento speciale?',
    'Fare spazio|A cosa posso dare meno importanza?',
    'La gratitudine possibile|Che cosa è andato bene, anche solo per un istante?',
    'Un desiderio concreto|Quale desiderio posso descrivere con parole mie?',
    'Cosa ho imparato|Che cosa ho capito di me stessa in questi giorni?',
    'Guardarmi con gentilezza|Come posso accogliere un momento difficile?',
    'Quello che porto con me|Cosa desidero ricordare di queste settimane?',
  ];
  static const _en = <String>[
    'Where do I begin?|What small change would I like to try?',
    'A small habit|What simple gesture would I repeat?',
    'What gives me energy?|What gave me a little energy?',
    'Important people|Who would I like to think about?',
    'A moment to treasure|What recent detail do I want to remember?',
    'A place to experience|Where would I like to spend a special moment?',
    'Making space|What can I give less importance to?',
    'Everyday gratitude|What went well, even for a moment?',
    'A concrete wish|What wish can I put into my own words?',
    'What I learned|What did I learn about myself?',
    'Looking at myself kindly|How can I welcome a difficult moment?',
    'What I take with me|What do I want to remember from these weeks?',
  ];
  static const _es = <String>[
    '¿Por dónde empezar?|¿Qué pequeño cambio me gustaría probar?',
    'Un pequeño hábito|¿Qué gesto sencillo repetiría?',
    'Lo que me da energía|¿Qué me dio algo de energía?',
    'Personas importantes|¿A quién quiero dedicar un pensamiento?',
    'Un momento para guardar|¿Qué detalle reciente quiero recordar?',
    'Un lugar por vivir|¿Dónde quisiera pasar un momento especial?',
    'Hacer espacio|¿A qué puedo dar menos importancia?',
    'Gratitud cotidiana|¿Qué salió bien, aunque fuera un instante?',
    'Un deseo concreto|¿Qué deseo puedo expresar con mis palabras?',
    'Lo que aprendí|¿Qué he aprendido sobre mí?',
    'Mirarme con cariño|¿Cómo puedo acoger un momento difícil?',
    'Lo que me llevo|¿Qué quiero recordar de estas semanas?',
  ];
  static const _fr = <String>[
    'Par où commencer ?|Quel petit changement aimerais-je essayer ?',
    'Une petite habitude|Quel geste simple aimerais-je répéter ?',
    'Ce qui me donne de l’énergie|Qu’est-ce qui m’a donné de l’énergie ?',
    'Les personnes importantes|À qui aimerais-je penser ?',
    'Un souvenir précieux|Quel détail récent garder en mémoire ?',
    'Un lieu à découvrir|Où aimerais-je vivre un moment spécial ?',
    'Faire de la place|À quoi puis-je donner moins d’importance ?',
    'La gratitude possible|Qu’est-ce qui s’est bien passé, même brièvement ?',
    'Un souhait concret|Quel souhait puis-je formuler avec mes mots ?',
    'Ce que j’ai appris|Qu’ai-je appris sur moi-même ?',
    'Me regarder avec douceur|Comment accueillir un moment difficile ?',
    'Ce que j’emporte|Que garder en mémoire de ces semaines ?',
  ];
  static const _pt = <String>[
    'Por onde começar?|Que pequena mudança gostaria de experimentar?',
    'Um pequeno hábito|Que gesto simples gostaria de repetir?',
    'O que me dá energia|O que me deu um pouco de energia?',
    'Pessoas importantes|A quem gostaria de dedicar um pensamento?',
    'Um momento para guardar|Que detalhe recente quero recordar?',
    'Um lugar para viver|Onde gostaria de passar um momento especial?',
    'Criar espaço|A que posso dar menos importância?',
    'Gratidão possível|O que correu bem, mesmo por um instante?',
    'Um desejo concreto|Que desejo posso descrever com as minhas palavras?',
    'O que aprendi|O que aprendi sobre mim?',
    'Olhar-me com carinho|Como posso acolher um momento difícil?',
    'O que levo comigo|O que quero recordar destas semanas?',
  ];

  int step = 0;
  int week = 0;
  bool includeReview = true;
  bool confirmed = false;
  bool simulated = false;
  DateTime? chosenDate;
  final title = TextEditingController();
  bool _titleInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_titleInitialized) {
      title.text = annaTwelveWeeksConceptDefaultTitle(AnnaStrings.of(context));
      _titleInitialized = true;
    }
  }
  final intention = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    intention.dispose();
    super.dispose();
  }

  String pick({required String it, required String en,
    required String es, required String fr, required String pt}) =>
      AnnaStrings.of(context)._pick(it: it, en: en, es: es, fr: fr, pt: pt);

  List<String> get weekText {
    final code = AnnaStrings.of(context).languageCode;
    final list = switch (code) {
      'it' => _it, 'es' => _es, 'fr' => _fr, 'pt' => _pt, _ => _en,
    };
    return list[week].split('|');
  }

  @override
  Widget build(BuildContext context) {
    final heading = annaTwelveWeeksConceptTitle(AnnaStrings.of(context));
    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: SafeArea(child: ListView(
        key: const ValueKey('anna-12w-native-preview'),
        padding: const EdgeInsets.all(18),
        children: [
          Text(pick(it: 'CONCEPT · NON ACQUISTABILE · SOLO PRIVATO',
            en: 'CONCEPT · NOT FOR SALE · PRIVATE ONLY',
            es: 'CONCEPTO · NO DISPONIBLE · PRIVADO',
            fr: 'CONCEPT · NON DISPONIBLE · PRIVÉ',
            pt: 'CONCEITO · INDISPONÍVEL · PRIVADO')),
          const SizedBox(height: 12),
          Text(heading, style: const TextStyle(
            fontFamily: 'Lora', fontSize: 25, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Text(pick(it: 'Un capitolo alla volta. Nessuna scadenza, punteggio o obbligo.',
            en: 'One chapter at a time. No deadlines, scores or obligations.',
            es: 'Un capítulo a la vez. Sin plazos, puntos ni obligaciones.',
            fr: 'Un chapitre à la fois. Ni délais, ni scores, ni obligations.',
            pt: 'Um capítulo de cada vez. Sem prazos, pontuação ou obrigações.')),
          const SizedBox(height: 12),
          Text('${step + 1} / 4'),
          const SizedBox(height: 14),
          if (step == 0) ...[
            Text(weekText.first, style: Theme.of(context).textTheme.titleMedium),
            Text(weekText.last),
          ],
          if (step == 1) ...[
            Wrap(spacing: 6, runSpacing: 4,
              children: List.generate(12, (index) => ChoiceChip(
                key: ValueKey('anna-12w-week-$index'),
                label: Text((index + 1).toString()),
                selected: week == index,
                onSelected: (_) => setState(() => week = index),
              )),
            ),
            const SizedBox(height: 14),
            Text(weekText.first, style: Theme.of(context).textTheme.titleMedium),
            Text(weekText.last),
          ],
          if (step == 2) ...[
            TextField(key: const ValueKey('anna-12w-title'), controller: title,
              maxLength: 90,
              decoration: InputDecoration(labelText: pick(
                it: 'Titolo personale', en: 'Personal title',
                es: 'Título personal', fr: 'Titre personnel', pt: 'Título pessoal'))),
            TextButton.icon(
              key: const ValueKey('anna-12w-date'),
              onPressed: () async {
                final value = await showDatePicker(context: context,
                  firstDate: DateTime(2000), lastDate: DateTime(2100),
                  initialDate: chosenDate ?? DateTime.now());
                if (value != null && mounted) setState(() => chosenDate = value);
              },
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(chosenDate == null
                ? pick(it: 'Scegli data (facoltativa)', en: 'Choose date (optional)',
                  es: 'Elegir fecha (opcional)', fr: 'Choisir une date (facultatif)',
                  pt: 'Escolher data (opcional)')
                : DateFormat('dd/MM/yyyy').format(chosenDate!)),
            ),
            TextField(controller: intention, maxLength: 300, maxLines: 3,
              decoration: InputDecoration(labelText: pick(it: 'Intenzione facoltativa',
                en: 'Optional intention', es: 'Intención opcional',
                fr: 'Intention facultative', pt: 'Intenção opcional'))),
            CheckboxListTile(
              value: includeReview,
              title: Text(pick(it: 'Riflessione settimanale',
                en: 'Weekly reflection', es: 'Reflexión semanal',
                fr: 'Bilan hebdomadaire', pt: 'Reflexão semanal')),
              onChanged: (v) => setState(() => includeReview = v ?? false)),
          ],
          if (step == 3) ...[
            Text(title.text.trim().isEmpty ? heading : title.text.trim(),
              style: Theme.of(context).textTheme.titleLarge),
            if (chosenDate != null) Text(DateFormat('dd/MM/yyyy').format(chosenDate!)),
            if (intention.text.trim().isNotEmpty) Text(intention.text.trim()),
            Text(pick(it: 'Soltanto un futuro DiarioBlock alla volta, con conferma.',
              en: 'Only one future diary entry at a time, with confirmation.',
              es: 'Solo una futura entrada cada vez, con confirmación.',
              fr: 'Une seule future entrée à la fois, avec confirmation.',
              pt: 'Apenas uma futura entrada de cada vez, com confirmação.')),
            CheckboxListTile(
              value: confirmed,
              title: Text(pick(it: 'Ho letto il riepilogo simulato',
                en: 'I reviewed the simulated summary',
                es: 'He revisado el resumen simulado',
                fr: "J'ai lu le récapitulatif simulé",
                pt: 'Li o resumo simulado')),
              onChanged: (v) => setState(() => confirmed = v ?? false)),
            FilledButton(
              key: const ValueKey('anna-12w-simulate'),
              onPressed: !confirmed ? null : () => setState(() => simulated = true),
              child: Text(pick(it: 'Simula inizio', en: 'Simulate start',
                es: 'Simular inicio', fr: 'Simuler le début', pt: 'Simular início'))),
            if (simulated)
              Semantics(
                liveRegion: true,
                child: Text(pick(it: 'Simulazione completa: nessun diario o promemoria salvato.',
                  en: 'Simulation complete: no diary or reminder saved.',
                  es: 'Simulación completa: no se guardó nada.',
                  fr: 'Simulation terminée : aucune donnée enregistrée.',
                  pt: 'Simulação concluída: nenhum dado guardado.'),
                  key: const ValueKey('anna-12w-done')),
              ),
          ],
          const SizedBox(height: 16),
        ],
      )),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Wrap(
            key: const ValueKey('anna-12w-actions'),
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (step > 0)
                TextButton(
                  onPressed: () => setState(() {
                    step--;
                    simulated = false;
                  }),
                  child: Text(pick(it: 'Indietro', en: 'Back',
                      es: 'Atrás', fr: 'Retour', pt: 'Voltar')),
                ),
              if (step < 3)
                FilledButton(
                  key: const ValueKey('anna-12w-next'),
                  onPressed: () => setState(() => step++),
                  child: Text(pick(it: 'Avanti', en: 'Next',
                      es: 'Siguiente', fr: 'Suivant', pt: 'Próximo')),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(pick(it: 'Chiudi', en: 'Close',
                      es: 'Cerrar', fr: 'Fermer', pt: 'Fechar')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
