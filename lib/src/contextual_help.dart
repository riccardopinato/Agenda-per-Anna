part of '../main.dart';

/// On-demand, read-only contextual education; never a first-run gate.
enum AnnaHelpSection { capture, shared, memories, more }

class _AnnaHelpEntry {
  final IconData icon;
  final String title;
  final String detail;
  final _UnifiedCaptureAction? captureAction;
  const _AnnaHelpEntry(this.icon, this.title, this.detail, {this.captureAction});
}

String _annaHelpLocale(BuildContext context) {
  final code = AnnaStrings.of(context).languageCode;
  return const {'it','en','es','fr','pt'}.contains(code) ? code : 'en';
}

String _annaHelpText(Map<String,String> text, String locale) =>
    text[locale] ?? text['en']!;

String _annaHelpTitle(AnnaHelpSection section, String locale) {
  return switch (section) {
    AnnaHelpSection.capture => _annaHelpText({'it': "Guida a Crea+",'en': "Create+ guide",'es': "Guía de Crear+",'fr': "Guide de Créer+",'pt': "Guia de Criar+"}, locale),
    AnnaHelpSection.shared => _annaHelpText({'it': "Guida allo Spazio condiviso",'en': "Shared Space guide",'es': "Guía del espacio compartido",'fr': "Guide de l’espace partagé",'pt': "Guia do espaço partilhado"}, locale),
    AnnaHelpSection.memories => _annaHelpText({'it': "Guida ai Ricordi",'en': "Memories guide",'es': "Guía de recuerdos",'fr': "Guide des souvenirs",'pt': "Guia de memórias"}, locale),
    AnnaHelpSection.more => _annaHelpText({'it': "Guida ad Altro",'en': "More guide",'es': "Guía de Más",'fr': "Guide d’Autres",'pt': "Guia de Mais"}, locale),
  };
}

String _annaHelpIntro(AnnaHelpSection section, String locale) {
  return switch (section) {
    AnnaHelpSection.capture => _annaHelpText({'it': "Ogni scelta apre uno strumento dedicato. Prima di creare qualcosa puoi cambiare la data nel pannello Crea+. Le azioni proposte possono variare in base alle funzioni abilitate.",'en': "Each choice opens a dedicated tool. You can change the date before creating. Available actions depend on enabled features.",'es': "Cada opción abre una herramienta. Puedes cambiar la fecha antes de crear; las acciones dependen de las funciones activadas.",'fr': "Chaque option ouvre un outil. Modifiez la date avant de créer ; les actions dépendent des fonctions activées.",'pt': "Cada opção abre uma ferramenta. Podes mudar a data antes de criar; as ações dependem das funções ativas."}, locale),
    AnnaHelpSection.shared => _annaHelpText({'it': "Questa è una guida consultabile in qualunque momento: non modifica i dati e non richiede nuovi permessi.",'en': "You can reopen this guide at any time. It changes no data and requests no permissions.",'es': "Puedes volver a abrir esta guía cuando quieras. No cambia datos ni solicita permisos.",'fr': "Vous pouvez rouvrir ce guide à tout moment. Il ne modifie aucune donnée ni autorisation.",'pt': "Podes reabrir este guia quando quiseres. Não altera dados nem pede permissões."}, locale),
    AnnaHelpSection.memories => _annaHelpText({'it': "Le sezioni mostrano i ricordi realmente conservati nel tuo diario e rispettano le impostazioni di privacy.",'en': "The sections show memories actually saved in your diary and respect privacy settings.",'es': "Las secciones muestran recuerdos guardados de verdad y respetan la privacidad.",'fr': "Les rubriques affichent les souvenirs réellement enregistrés et respectent la confidentialité.",'pt': "As secções mostram memórias realmente guardadas e respeitam a privacidade."}, locale),
    AnnaHelpSection.more => _annaHelpText({'it': "Altro raccoglie impostazioni, strumenti e collegamenti. La disponibilità cambia secondo le sezioni che hai abilitato.",'en': "More groups settings, tools and links. Available sections depend on what you have enabled.",'es': "Más reúne ajustes, herramientas y enlaces. Las secciones dependen de tus preferencias.",'fr': "Autres rassemble réglages, outils et liens. Les sections dépendent de vos choix.",'pt': "Mais reúne definições, ferramentas e ligações. As secções dependem das tuas preferências."}, locale),
  };
}

List<_AnnaHelpEntry> _annaHelpEntries(AnnaHelpSection section, String locale) {
  switch (section) {
    case AnnaHelpSection.capture:
      return <_AnnaHelpEntry>[
        _AnnaHelpEntry(Icons.edit_note_outlined, _annaHelpText({'it': "Nota nel diario",'en': "Diary note",'es': "Nota del diario",'fr': "Note de journal",'pt': "Nota do diário"}, locale), _annaHelpText({'it': "Scrivi un pensiero o il racconto della giornata. Tocca la voce, completa il testo e salva: la nota viene collegata al giorno scelto in Crea+.",'en': "Write about your day. Open the editor, enter your text and save it for the selected date.",'es': "Escribe sobre tu día, abre el editor y guarda la nota en la fecha elegida.",'fr': "Racontez votre journée, ouvrez l’éditeur et enregistrez la note à la date choisie.",'pt': "Escreve sobre o teu dia, abre o editor e guarda a nota na data escolhida."}, locale), captureAction: _UnifiedCaptureAction.text),
        _AnnaHelpEntry(Icons.photo_camera_back_outlined, _annaHelpText({'it': "Foto ricordo",'en': "Photo memory",'es': "Foto de recuerdo",'fr': "Souvenir photo",'pt': "Fotografia"}, locale), _annaHelpText({'it': "Scegli un’immagine dalla galleria o scatta una foto. Puoi aggiungere una didascalia: sarà salvata nel diario del giorno selezionato.",'en': "Choose or take a photo, optionally add a caption, and save it in the selected day’s diary.",'es': "Elige o toma una foto, añade una descripción opcional y guárdala en el diario del día elegido.",'fr': "Choisissez ou prenez une photo, ajoutez une légende et enregistrez-la dans le journal du jour.",'pt': "Escolhe ou tira uma foto, adiciona uma legenda opcional e guarda-a no diário do dia."}, locale), captureAction: _UnifiedCaptureAction.photo),
        _AnnaHelpEntry(Icons.check_circle_outline, _annaHelpText({'it': "Attività",'en': "Task",'es': "Tarea",'fr': "Tâche",'pt': "Tarefa"}, locale), _annaHelpText({'it': "Crea qualcosa da fare. Nell’editor puoi definire dettagli, data e opzioni disponibili, quindi confermare il salvataggio.",'en': "Create a to-do. Set its details and date in the editor, then save.",'es': "Crea una tarea, define detalles y fecha en el editor y guarda.",'fr': "Créez une tâche, définissez les détails et la date, puis enregistrez.",'pt': "Cria uma tarefa, define os detalhes e a data e guarda."}, locale), captureAction: _UnifiedCaptureAction.task),
        _AnnaHelpEntry(Icons.auto_awesome_motion_outlined, _annaHelpText({'it': "Attività da una frase",'en': "Task from a sentence",'es': "Tarea desde texto",'fr': "Tâche depuis une phrase",'pt': "Tarefa a partir de texto"}, locale), _annaHelpText({'it': "Scrivi una frase in linguaggio naturale. L’app propone localmente un’attività e apre l’editor: controlla titolo, data e dettagli prima di salvare. Non salva automaticamente.",'en': "Type a natural-language sentence. A local suggestion opens in the task editor; review the details before saving. Nothing is saved automatically.",'es': "Escribe una frase. La propuesta local se abre en el editor: revísala antes de guardar. No se guarda automáticamente.",'fr': "Saisissez une phrase. La proposition locale s’ouvre dans l’éditeur : vérifiez-la avant d’enregistrer.",'pt': "Escreve uma frase. A sugestão local abre no editor: revê os detalhes antes de guardar."}, locale), captureAction: _UnifiedCaptureAction.taskFromText),
        _AnnaHelpEntry(Icons.playlist_add_check_outlined, _annaHelpText({'it': "Checklist da una nota",'en': "Checklist from a note",'es': "Lista desde una nota",'fr': "Liste depuis une note",'pt': "Lista a partir de nota"}, locale), _annaHelpText({'it': "Seleziona una nota già presente nel diario. L’app ne propone una checklist nell’editor attività; verifica ogni voce e salva solo se il risultato è corretto.",'en': "Select an existing diary note to draft a checklist. Review and save the proposed task in the editor.",'es': "Selecciona una nota del diario para crear una lista. Revisa la propuesta antes de guardar.",'fr': "Choisissez une note du journal pour préparer une liste. Vérifiez la proposition avant d’enregistrer.",'pt': "Escolhe uma nota do diário para preparar uma lista. Revê antes de guardar."}, locale), captureAction: _UnifiedCaptureAction.checklistFromNote),
        _AnnaHelpEntry(Icons.mic_none_outlined, _annaHelpText({'it': "Nota vocale",'en': "Voice note",'es': "Nota de voz",'fr': "Note vocale",'pt': "Nota de voz"}, locale), _annaHelpText({'it': "Registra la tua voce e, se vuoi, aggiungi una didascalia. Al termine del flusso la registrazione viene salvata come ricordo del giorno scelto.",'en': "Record your voice, add an optional caption, and save the recording as a diary memory for the chosen day.",'es': "Graba tu voz, añade una descripción opcional y guarda el recuerdo en el día elegido.",'fr': "Enregistrez votre voix, ajoutez une légende facultative et conservez le souvenir à la date choisie.",'pt': "Grava a tua voz, adiciona uma legenda opcional e guarda-a no dia escolhido."}, locale), captureAction: _UnifiedCaptureAction.voice),
        _AnnaHelpEntry(Icons.draw_outlined, _annaHelpText({'it': "Disegno",'en': "Drawing",'es': "Dibujo",'fr': "Dessin",'pt': "Desenho"}, locale), _annaHelpText({'it': "Apri la tela del quaderno, disegna e salva le pagine. Il disegno viene aggiunto ai contenuti del diario nella data scelta.",'en': "Open the sketchbook canvas, draw and save the pages into the selected day’s diary.",'es': "Abre el lienzo, dibuja y guarda las páginas en el diario del día seleccionado.",'fr': "Ouvrez le carnet de dessin, dessinez et enregistrez les pages dans le journal du jour.",'pt': "Abre o caderno de desenho, desenha e guarda as páginas no diário desse dia."}, locale), captureAction: _UnifiedCaptureAction.sketch),
        _AnnaHelpEntry(Icons.dashboard_customize_outlined, _annaHelpText({'it': "Vision board",'en': "Vision board",'es': "Tablero de visión",'fr': "Tableau de vision",'pt': "Quadro de visão"}, locale), _annaHelpText({'it': "Scegli un modello e componi una bacheca visiva nel quaderno. Salva le pagine per conservarle nel diario. Questa funzione è disponibile solo quando lo spazio personale lo consente.",'en': "Choose a template, arrange a visual board and save it in your personal diary. Availability depends on the current space.",'es': "Elige una plantilla, compón un tablero visual y guárdalo en tu diario personal.",'fr': "Choisissez un modèle, composez un tableau visuel et enregistrez-le dans le journal personnel.",'pt': "Escolhe um modelo, cria um quadro visual e guarda-o no diário pessoal."}, locale), captureAction: _UnifiedCaptureAction.visionBoard),
        _AnnaHelpEntry(Icons.inbox_outlined, _annaHelpText({'it': "Inbox rapida",'en': "Quick Inbox",'es': "Bandeja rápida",'fr': "Boîte de réception",'pt': "Inbox rápida"}, locale), _annaHelpText({'it': "Annota rapidamente un’idea senza organizzarla subito. Potrai ritrovarla nell’Inbox e sistemarla in seguito.",'en': "Capture an idea without organising it immediately. Find it later in Inbox.",'es': "Apunta una idea sin organizarla todavía. La encontrarás después en la bandeja.",'fr': "Notez une idée sans l’organiser tout de suite. Retrouvez-la ensuite dans la boîte de réception.",'pt': "Regista uma ideia sem a organizar já. Encontra-a depois na Inbox."}, locale), captureAction: _UnifiedCaptureAction.inbox),
        _AnnaHelpEntry(Icons.event_outlined, _annaHelpText({'it': "Appuntamento",'en': "Appointment",'es': "Cita",'fr': "Rendez-vous",'pt': "Compromisso"}, locale), _annaHelpText({'it': "Apri il compositore degli appuntamenti, inserisci le informazioni e salva. Controlla la data impostata in alto nel pannello Crea+.",'en': "Open the appointment editor, enter the details and save. Check the selected date first.",'es': "Abre el editor de citas, introduce los detalles y guarda. Comprueba la fecha seleccionada.",'fr': "Ouvrez l’éditeur de rendez-vous, saisissez les informations et enregistrez.",'pt': "Abre o editor de compromissos, introduz os detalhes e guarda."}, locale), captureAction: _UnifiedCaptureAction.event),
        _AnnaHelpEntry(Icons.cake_outlined, _annaHelpText({'it': "Compleanno",'en': "Birthday",'es': "Cumpleaños",'fr': "Anniversaire",'pt': "Aniversário"}, locale), _annaHelpText({'it': "Apre la sezione Compleanni: lì puoi registrare e gestire le date importanti delle persone. Non inserisce automaticamente un compleanno.",'en': "Opens Birthdays, where you can add and manage important dates. Opening it does not create an entry.",'es': "Abre Cumpleaños para añadir y gestionar fechas importantes; no se crea nada automáticamente.",'fr': "Ouvre Anniversaires pour ajouter et gérer les dates importantes, sans création automatique.",'pt': "Abre Aniversários para adicionar e gerir datas importantes, sem criar nada automaticamente."}, locale), captureAction: _UnifiedCaptureAction.birthday),
        _AnnaHelpEntry(Icons.person_add_alt_1_outlined, _annaHelpText({'it': "Persona importante",'en': "Important person",'es': "Persona importante",'fr': "Personne importante",'pt': "Pessoa importante"}, locale), _annaHelpText({'it': "Apre Persone direttamente nella modalità di aggiunta. Inserisci i dettagli desiderati e salva la scheda.",'en': "Opens People in add mode. Enter the person's details and save their card.",'es': "Abre Personas en modo añadir. Introduce los datos y guarda la ficha.",'fr': "Ouvre Personnes en mode ajout. Saisissez les détails et enregistrez la fiche.",'pt': "Abre Pessoas no modo de adicionar. Preenche os dados e guarda a ficha."}, locale), captureAction: _UnifiedCaptureAction.person),
        _AnnaHelpEntry(Icons.library_books_outlined, _annaHelpText({'it': "Modelli del diario",'en': "Diary templates",'es': "Plantillas del diario",'fr': "Modèles de journal",'pt': "Modelos de diário"}, locale), _annaHelpText({'it': "Scegli una traccia di scrittura per iniziare più facilmente. Personalizza il testo proposto nell’editor e salva la nota del giorno.",'en': "Choose a writing prompt, edit its suggested text and save the diary note.",'es': "Elige una plantilla, personaliza el texto propuesto y guarda la nota.",'fr': "Choisissez une trame, personnalisez le texte proposé et enregistrez la note.",'pt': "Escolhe um modelo, personaliza o texto sugerido e guarda a nota."}, locale), captureAction: _UnifiedCaptureAction.templates),
      ];
    case AnnaHelpSection.shared:
      return <_AnnaHelpEntry>[
        _AnnaHelpEntry(Icons.groups_outlined, _annaHelpText({'it': "Spazi e partecipanti",'en': "Spaces and members",'es': "Espacios y miembros",'fr': "Espaces et membres",'pt': "Espaços e membros"}, locale), _annaHelpText({'it': "Crea uno spazio, condividi il codice d’invito e visualizza chi partecipa. Gli spazi hanno nome e foto propri; la foto condivisa può essere cambiata dal proprietario.",'en': "Create a space, invite participants and view members. The owner can change its shared name and photo.",'es': "Crea un espacio, invita participantes y consulta los miembros. El propietario puede cambiar su nombre y foto.",'fr': "Créez un espace, invitez des membres et consultez les participants. Le propriétaire peut modifier son nom et sa photo.",'pt': "Cria um espaço, convida membros e consulta os participantes. O proprietário pode alterar o nome e a foto."}, locale)),
        _AnnaHelpEntry(Icons.edit_note_outlined, _annaHelpText({'it': "Contenuti condivisi",'en': "Shared content",'es': "Contenido compartido",'fr': "Contenu partagé",'pt': "Conteúdos partilhados"}, locale), _annaHelpText({'it': "All’interno dello spazio puoi creare e consultare contenuti comuni, come note e foto. Le modifiche si sincronizzano con gli account autorizzati quando la connessione è disponibile.",'en': "Within a space you can create and read shared notes and photos. Sync requires a connection and authorised membership.",'es': "Dentro del espacio puedes crear y consultar notas y fotos compartidas; la sincronización requiere conexión.",'fr': "Dans l’espace, créez et consultez notes et photos partagées ; la synchronisation exige une connexion.",'pt': "Dentro do espaço, cria e consulta notas e fotos partilhadas; a sincronização exige ligação."}, locale)),
        _AnnaHelpEntry(Icons.favorite_outline, _annaHelpText({'it': "Mi piace e commenti",'en': "Likes and comments",'es': "Me gusta y comentarios",'fr': "J’aime et commentaires",'pt': "Gostos e comentários"}, locale), _annaHelpText({'it': "Apri un contenuto per commentare o mettere Mi piace. Se tocchi il numero delle reazioni puoi vedere chi ha reagito e il momento registrato dal server.",'en': "Open an item to comment or react. Tap the reaction count to see confirmed authors and server timestamps.",'es': "Abre un elemento para comentar o reaccionar. Toca el contador para ver autores y fechas confirmados.",'fr': "Ouvrez un contenu pour commenter ou réagir. Touchez le nombre de réactions pour voir les auteurs et les heures confirmées.",'pt': "Abre um item para comentar ou reagir. Toca no total para ver autores e horas confirmadas."}, locale)),
        _AnnaHelpEntry(Icons.sync_outlined, _annaHelpText({'it': "Sincronizzazione e privacy",'en': "Sync and privacy",'es': "Sincronización y privacidad",'fr': "Synchronisation et confidentialité",'pt': "Sincronização e privacidade"}, locale), _annaHelpText({'it': "I contenuti comuni richiedono un account e l’accesso allo spazio. Le modifiche offline possono restare in attesa: controlla lo stato di sincronizzazione prima di considerarle ricevute dagli altri.",'en': "Shared content needs an account and membership. Offline changes may remain pending; check sync status before assuming delivery.",'es': "Se necesita cuenta y acceso al espacio. Los cambios sin conexión pueden quedar pendientes.",'fr': "Un compte et l’accès à l’espace sont nécessaires. Les modifications hors ligne peuvent rester en attente.",'pt': "É necessária uma conta e acesso ao espaço. Alterações offline podem ficar pendentes."}, locale)),
      ];
    case AnnaHelpSection.memories:
      return <_AnnaHelpEntry>[
        _AnnaHelpEntry(Icons.auto_awesome_outlined, _annaHelpText({'it': "Per te",'en': "For you",'es': "Para ti",'fr': "Pour vous",'pt': "Para ti"}, locale), _annaHelpText({'it': "Qui trovi richiami ai tuoi ricordi e collegamenti alle raccolte. I suggerimenti dipendono dai contenuti realmente salvati.",'en': "See memory highlights and links to your collections, based on what you have actually saved.",'es': "Encuentra recuerdos destacados y enlaces a colecciones, basados en contenido guardado.",'fr': "Retrouvez des souvenirs et des liens vers les collections, fondés sur le contenu enregistré.",'pt': "Encontra memórias em destaque e ligações a coleções, baseadas no conteúdo guardado."}, locale)),
        _AnnaHelpEntry(Icons.view_timeline_outlined, _annaHelpText({'it': "Cronologia",'en': "Timeline",'es': "Cronología",'fr': "Chronologie",'pt': "Cronologia"}, locale), _annaHelpText({'it': "Scorri i ricordi nel tempo; usa le viste per giorno, mese o anno per trovare più velocemente un periodo.",'en': "Browse memories chronologically, with day, month and year views to find a period.",'es': "Explora recuerdos por orden cronológico; utiliza las vistas de día, mes o año.",'fr': "Parcourez les souvenirs dans le temps et choisissez le jour, le mois ou l’année.",'pt': "Explora memórias no tempo e usa as vistas por dia, mês ou ano."}, locale)),
        _AnnaHelpEntry(Icons.search_outlined, _annaHelpText({'it': "Ricerca e filtri",'en': "Search and filters",'es': "Búsqueda y filtros",'fr': "Recherche et filtres",'pt': "Pesquisa e filtros"}, locale), _annaHelpText({'it': "La lente cerca tra i tuoi ricordi; i filtri restringono i risultati. Puoi ritrovare contenuti senza modificare gli originali.",'en': "Use search and filters to narrow down memories without changing the originals.",'es': "Usa la búsqueda y los filtros para encontrar recuerdos sin alterar los originales.",'fr': "Utilisez la recherche et les filtres pour retrouver des souvenirs sans les modifier.",'pt': "Usa a pesquisa e os filtros para encontrar memórias sem alterar os originais."}, locale)),
        _AnnaHelpEntry(Icons.collections_bookmark_outlined, _annaHelpText({'it': "Raccolte e riepiloghi",'en': "Collections and summaries",'es': "Colecciones y resúmenes",'fr': "Collections et résumés",'pt': "Coleções e resumos"}, locale), _annaHelpText({'it': "Apri le Raccolte per organizzare ricordi collegati. I comandi di riepilogo, quando disponibili, lavorano sui contenuti esistenti.",'en': "Open Collections to group related memories; available summaries use existing content.",'es': "Abre Colecciones para agrupar recuerdos; los resúmenes utilizan contenido existente.",'fr': "Ouvrez Collections pour regrouper les souvenirs ; les résumés utilisent le contenu existant.",'pt': "Abre Coleções para agrupar memórias; os resumos usam conteúdos existentes."}, locale)),
      ];
    case AnnaHelpSection.more:
      return <_AnnaHelpEntry>[
        _AnnaHelpEntry(Icons.person_outline, _annaHelpText({'it': "Profilo e impostazioni",'en': "Profile and settings",'es': "Perfil y ajustes",'fr': "Profil et réglages",'pt': "Perfil e definições"}, locale), _annaHelpText({'it': "Apri Profilo o Impostazioni per scegliere nome, aspetto, colori e preferenze dell’app. Alcune opzioni sono raggiungibili nelle schermate dedicate.",'en': "Open Profile or Settings to change your name, appearance, colours and preferences.",'es': "Abre Perfil o Ajustes para cambiar nombre, aspecto, colores y preferencias.",'fr': "Ouvrez Profil ou Réglages pour modifier nom, apparence, couleurs et préférences.",'pt': "Abre Perfil ou Definições para alterar nome, aparência, cores e preferências."}, locale)),
        _AnnaHelpEntry(Icons.search_outlined, _annaHelpText({'it': "Ricerca e Inbox",'en': "Search and Inbox",'es': "Búsqueda y bandeja",'fr': "Recherche et boîte de réception",'pt': "Pesquisa e Inbox"}, locale), _annaHelpText({'it': "Usa la ricerca per ritrovare informazioni e l’Inbox per organizzare in seguito ciò che hai annotato rapidamente.",'en': "Use search to find information and Inbox to organise your quick notes later.",'es': "Usa la búsqueda y la bandeja para encontrar y organizar tus notas rápidas.",'fr': "Utilisez la recherche et la boîte de réception pour retrouver et organiser vos notes.",'pt': "Usa a pesquisa e a Inbox para encontrar e organizar notas rápidas."}, locale)),
        _AnnaHelpEntry(Icons.explore_outlined, _annaHelpText({'it': "Funzioni personali",'en': "Personal features",'es': "Funciones personales",'fr': "Fonctions personnelles",'pt': "Funções pessoais"}, locale), _annaHelpText({'it': "Esplora raccoglie i collegamenti alle sezioni abilitate, ad esempio Persone, Compleanni e altre funzioni. Le sezioni disponibili dipendono dalla tua personalizzazione.",'en': "Explore links to enabled sections such as People or Birthdays. Available destinations depend on your settings.",'es': "Explorar abre secciones activadas, como Personas y Cumpleaños, según tus preferencias.",'fr': "Explorer ouvre les sections activées, comme Personnes ou Anniversaires, selon vos choix.",'pt': "Explorar abre secções ativas como Pessoas e Aniversários, conforme as preferências."}, locale)),
        _AnnaHelpEntry(Icons.archive_outlined, _annaHelpText({'it': "Archivio, backup e cloud",'en': "Archive, backup and cloud",'es': "Archivo, copia y nube",'fr': "Archives, sauvegarde et cloud",'pt': "Arquivo, cópias e nuvem"}, locale), _annaHelpText({'it': "Apri Archivio per i contenuti archiviati, Backup per proteggere i dati e Account cloud per le funzioni di sincronizzazione. Controlla sempre l’esito dei salvataggi.",'en': "Use Archive for archived content, Backup for data copies and Cloud Account for sync. Always check completion.",'es': "Usa Archivo, Copia de seguridad y Cuenta en la nube según necesites; verifica los resultados.",'fr': "Utilisez Archives, Sauvegarde et Compte cloud selon vos besoins ; vérifiez les résultats.",'pt': "Usa Arquivo, Backup e Conta cloud conforme necessário; verifica os resultados."}, locale)),
      ];
  }
}

/// Reusable fixed top-right information action for primary destinations.
/// The capture sheet passes its real action set, so unavailable features
/// are never advertised in the guide.
class AnnaContextHelpButton extends StatelessWidget {
  final AnnaHelpSection section;
  final Set<_UnifiedCaptureAction>? captureActions;
  const AnnaContextHelpButton({
    super.key,
    required this.section,
    this.captureActions,
  });

  @override
  Widget build(BuildContext context) {
    final locale = _annaHelpLocale(context);
    return IconButton(
      key: ValueKey<String>('context-help-${section.name}'),
      tooltip: _annaHelpTitle(section, locale),
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => _AnnaContextHelpScreen(
            section: section,
            captureActions: captureActions,
          ),
        ),
      ),
    );
  }
}

class _AnnaContextHelpScreen extends StatelessWidget {
  final AnnaHelpSection section;
  final Set<_UnifiedCaptureAction>? captureActions;
  const _AnnaContextHelpScreen({required this.section, this.captureActions});

  @override
  Widget build(BuildContext context) {
    final locale = _annaHelpLocale(context);
    final colors = AnnaEditorialColors.of(context);
    final journal = AnnaOrganicPastel.enabled(context);
    final entries = _annaHelpEntries(section, locale)
        .where((entry) => entry.captureAction == null ||
          captureActions == null || captureActions!.contains(entry.captureAction))
        .toList(growable: false);
    final title = _annaHelpTitle(section, locale);
    return Scaffold(
      backgroundColor: journal ? colors.canvas : null,
      appBar: AppBar(
        key: ValueKey<String>('context-help-appbar-${section.name}'),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: journal ? colors.canvas : null,
        surfaceTintColor: journal ? Colors.transparent : null,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: ListView(
              key: ValueKey<String>('context-help-contents-${section.name}'),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
              children: [
                Text(
                  title,
                  style: journal
                      ? AnnaJournalTypography.editorial(context, size: 28)
                      : Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  _annaHelpIntro(section, locale),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.45,
                    color: journal ? colors.mutedInk : null,
                  ),
                ),
                const SizedBox(height: 20),
                for (final entry in entries) ...[
                  _AnnaHelpEntryCard(entry: entry, journal: journal),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnaHelpEntryCard extends StatelessWidget {
  final _AnnaHelpEntry entry;
  final bool journal;
  const _AnnaHelpEntryCard({required this.entry, required this.journal});

  @override
  Widget build(BuildContext context) {
    final colors = AnnaEditorialColors.of(context);
    final body = Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(entry.icon, color: journal ? colors.accent : null, size: 25),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.title,
                  style: journal
                      ? AnnaJournalTypography.editorial(context, size: 19)
                      : Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 7),
                Text(entry.detail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: journal ? colors.mutedInk : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: '${entry.title}. ${entry.detail}',
      child: journal
          ? AnnaOrganicPaperSurface(
              padding: const EdgeInsets.all(15),
              child: body,
            )
          : Card(
              margin: EdgeInsets.zero,
              child: Padding(padding: const EdgeInsets.all(15), child: body),
            ),
    );
  }
}
