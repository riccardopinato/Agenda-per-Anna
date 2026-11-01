part of '../main.dart';

/// CAP-0111: derived private task counts. No alternate data ownership.
class WeeklyReviewSummary {
  final int completedDatedThisWeek, pendingDatedThisWeek, overdueFromBefore;
  const WeeklyReviewSummary(this.completedDatedThisWeek,
      this.pendingDatedThisWeek, this.overdueFromBefore);
  static WeeklyReviewSummary fromItems(Iterable<AgendaItem> items, DateTime anyDay) {
    final start = mondayOf(anyDay);
    final end = DateTime(start.year, start.month, start.day + 7);
    var completed = 0, pending = 0, overdue = 0;
    final ids = <String>{};
    for (final item in items) {
      if (item.type != ItemType.task || !ids.add(item.id)) continue;
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      if (date.isBefore(start)) {
        if (!item.done) overdue++;
      } else if (date.isBefore(end)) {
        if (item.done) { completed++; } else { pending++; }
      }
    }
    return WeeklyReviewSummary(completed, pending, overdue);
  }
}

const _wrCopy = <String,List<String>>{
 'week':['La tua settimana','Your week','Tu semana','Ta semaine','A tua semana'],
 'review':['Bilancio','Review','Balance','Bilan','Balanço'],
 'memories':['Ricordi','Memories','Recuerdos','Souvenirs','Memórias'],
 'intentions':['Intenzioni','Intentions','Intenciones','Intentions','Intenções'],
 'look':['Uno sguardo alla settimana','A look at the week','Una mirada a la semana','Un regard sur la semaine','Um olhar sobre a semana'],
 'new':['La settimana che inizia','The week ahead','La semana que empieza','La semaine à venir','A semana que começa'],
 'saved':['Una settimana da custodire','A week to cherish','Una semana para recordar','Une semaine à garder','Uma semana para guardar'],
 'done':['Segnate come fatte','Marked done','Marcadas hechas','Marquées faites','Marcadas feitas'],
 'pending':['Da riprendere','To revisit','Pendientes','À reprendre','Por retomar'],
 'open':['Apri la Weekly Review','Open Weekly Review','Abrir revisión semanal','Ouvrir le bilan','Abrir revisão semanal'],
 'reopen':['Rileggi o modifica','Read or edit','Leer o editar','Relire ou modifier','Reler ou editar'],
 'archive':['Le tue settimane','Your weeks','Tus semanas','Tes semaines','As tuas semanas'],
 'reminders':['Promemoria','Reminders','Recordatorios','Rappels','Lembretes'],
 'focus':['La tua intenzione','Your intention','Tu intención','Ton intention','A tua intenção'],
 'priorities':['Tre piccole priorità','Three priorities','Tres prioridades','Trois priorités','Três prioridades'],
 'best':['La cosa più bella','The best moment','Lo mejor','Le plus beau moment','O melhor momento'],
 'reflection':['Cosa porti con te?','What will you remember?','¿Qué te llevas?','Que gardes-tu ?','O que levas contigo?'],
 'next':['Continua','Continue','Continuar','Continuer','Continuar'],
 'back':['Indietro','Back','Volver','Retour','Voltar'],
 'finish':['Concludi per ora','Finish for now','Terminar por ahora','Terminer pour le moment','Concluir por agora'],
 'close':['Torna a Oggi','Back to Today','Volver a Hoy','Retour à Aujourd’hui','Voltar a Hoje'],
 'noMemories':['Nessun ricordo: puoi scrivere liberamente.','No memories: write freely.','Sin recuerdos: escribe libremente.','Aucun souvenir : écris librement.','Sem memórias: escreve livremente.'],
 'privacy':['Dettagli nascosti','Details hidden','Detalles ocultos','Détails masqués','Detalhes ocultos'],
 'optional':['Facoltativo','Optional','Opcional','Facultatif','Opcional'],
 'notification':['Notifica settimanale','Weekly notification','Notificación semanal','Notification hebdomadaire','Notificação semanal'],
 'sunday':['Domenica · Bilancio','Sunday · Review','Domingo · Balance','Dimanche · Bilan','Domingo · Balanço'],
 'monday':['Lunedì · Intenzioni','Monday · Intentions','Lunes · Intenciones','Lundi · Intentions','Segunda · Intenções'],
 'time':['Orario','Time','Hora','Heure','Hora'],
 'off':['Disattivata inizialmente.','Off by default.','Desactivada inicialmente.','Désactivée par défaut.','Desativada inicialmente.'],
 'denied':['Permesso non disponibile.','Permission unavailable.','Permiso no disponible.','Autorisation indisponible.','Permissão indisponível.'],
 'error':['Salvataggio non riuscito.','Save failed.','Error al guardar.','Échec de sauvegarde.','Falha ao guardar.'],
 'completed':['Conclusa','Completed','Terminada','Terminée','Concluída'],
 'unfinished':['Da riprendere','Unfinished','Pendiente','À reprendre','Por retomar'],
 'empty':['Senza contenuti','No entries','Sin contenido','Sans contenu','Sem conteúdos'],
 'summary':['Task datate nel periodo; la data effettiva di completamento non è nota.','Tasks dated in this period; actual completion dates are unknown.','Tareas fechadas; se desconoce la fecha real de finalización.','Tâches datées ; dates réelles de fin inconnues.','Tarefas datadas; datas reais de conclusão desconhecidas.'],
 'use':['Usa il titolo come spunto','Use as inspiration','Usar como inspiración','Utiliser comme inspiration','Usar como inspiração'],
 'replace':['Sostituire il testo esistente?','Replace existing text?','¿Reemplazar el texto?','Remplacer le texte ?','Substituir o texto?'],
 'cancel':['Annulla','Cancel','Cancelar','Annuler','Cancelar'],
 'confirm':['Sostituisci','Replace','Reemplazar','Remplacer','Substituir'],
 'previous':['Settimana precedente','Previous week','Semana anterior','Semaine précédente','Semana anterior'],
 'following':['Settimana successiva','Next week','Semana siguiente','Semaine suivante','Semana seguinte'],
 'noticeSunday':['Un momento per la tua settimana ♡','A moment for your week ♡','Un momento para tu semana ♡','Un moment pour ta semaine ♡','Um momento para a tua semana ♡'],
 'noticeMonday':['Scegli ciò a cui dare spazio questa settimana ♡','Choose what matters this week ♡','Elige qué importa esta semana ♡','Choisis ce qui compte cette semaine ♡','Escolhe o que importa esta semana ♡'],
};
String wrText(BuildContext c,String key){
  final lang=Localizations.localeOf(c).languageCode;
  final i=switch(lang){'it'=>0,'es'=>2,'fr'=>3,'pt'=>4,_=>1};
  return _wrCopy[key]?[i]??key;
}
String wrRange(BuildContext c,DateTime m){
  final locale=AnnaStrings.intlLocale(c);
  final end=DateTime(m.year,m.month,m.day+6);
  return '${DateFormat('d MMM',locale).format(m)} – ${DateFormat('d MMM yyyy',locale).format(end)}';
}
DateTime wrMonday(DateTime d)=>mondayOf(d);

class WeeklyReviewHomeCard extends StatefulWidget{
 final AgendaStore store;
 const WeeklyReviewHomeCard({super.key,required this.store});
 @override State<WeeklyReviewHomeCard> createState()=>_WeeklyReviewHomeCardState();
}
class _WeeklyReviewHomeCardState extends State<WeeklyReviewHomeCard>{
 @override void initState(){
   super.initState();
   if(widget.store.preferences.weeklyReviewReminderEnabled){
     unawaited(WeeklyReviewReminders.reconcile(widget.store));
   }
 }
 @override Widget build(BuildContext c){
   final now=DateTime.now(), current=wrMonday(now);
   final review=now.weekday==DateTime.monday?
     DateTime(current.year,current.month,current.day-7):current;
   final plan=now.weekday==DateTime.sunday?
     DateTime(current.year,current.month,current.day+7):current;
   final sunday=now.weekday==DateTime.sunday,monday=now.weekday==DateTime.monday;
   final week=widget.store.week(sunday?review:plan);
   final complete=week.reviewCompletedAt!=null;
   final compact=complete||(!sunday&&!monday);
   final hidden=widget.store.preferences.hideHomeDetails;
   final counts=WeeklyReviewSummary.fromItems(widget.store.items,review);
   return AnnaJournalCard(hero:!compact,child:Column(
     crossAxisAlignment:CrossAxisAlignment.start,children:[
       Row(children:[
         Icon(Icons.auto_stories_outlined,color:Theme.of(c).colorScheme.primary),
         const SizedBox(width:8),
         Expanded(child:Text(wrText(c,'week'),style:Theme.of(c).textTheme.titleMedium)),
         IconButton(tooltip:wrText(c,'reminders'),icon:const Icon(Icons.notifications_none_outlined),
           onPressed:()=>Navigator.push<void>(c,MaterialPageRoute(builder:(_)=>
             WeeklyReviewSettingsPage(store:widget.store)))),
       ]),
       Text(wrText(c,complete?'saved':monday?'new':'look'),
         style:AnnaJournalTypography.editorial(c,size:compact?19:23)),
       const SizedBox(height:6),
       Text(wrRange(c,sunday?review:plan),style:Theme.of(c).textTheme.bodySmall),
       if(!compact&&!monday)...[
         const SizedBox(height:12),
         Row(children:[
           Expanded(child:_WrMetric(value:hidden?'—':counts.completedDatedThisWeek.toString(),
             label:wrText(c,'done'))),
           const SizedBox(width:8),
           Expanded(child:_WrMetric(value:hidden?'—':(counts.pendingDatedThisWeek+counts.overdueFromBefore).toString(),
             label:wrText(c,'pending'))),
         ]),
       ],
       if(compact&&week.focus.trim().isNotEmpty)...[
         const SizedBox(height:8),
         Text(hidden?wrText(c,'privacy'):week.focus,maxLines:2,overflow:TextOverflow.ellipsis),
       ],
       const SizedBox(height:12),
       SizedBox(width:double.infinity,child:FilledButton.tonal(
         onPressed:()=>Navigator.push<void>(c,MaterialPageRoute(builder:(_)=>
           WeeklyReviewScreen(store:widget.store,reviewWeek:review,planWeek:plan,
             initialStep:(!sunday&&!monday)?2:0))),
         child:Text(wrText(c,complete?'reopen':'open')),
       )),
       Align(alignment:Alignment.centerRight,child:TextButton(
         onPressed:()=>Navigator.push<void>(c,MaterialPageRoute(builder:(_)=>
           WeeklyReviewArchivePage(store:widget.store))),
         child:Text(wrText(c,'archive')))),
     ]));
 }
}
class _WrMetric extends StatelessWidget{
 final String value,label;
 const _WrMetric({required this.value,required this.label});
 @override Widget build(BuildContext c)=>Container(
   padding:const EdgeInsets.all(10),
   decoration:BoxDecoration(color:Theme.of(c).colorScheme.surfaceContainerLowest,
     borderRadius:BorderRadius.circular(12)),
   child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
     Text(value,style:Theme.of(c).textTheme.titleLarge),
     Text(label,style:Theme.of(c).textTheme.labelSmall),
   ]));
}

class WeeklyReviewScreen extends StatefulWidget{
 final AgendaStore store;
 final DateTime reviewWeek,planWeek;
 final int initialStep;
 const WeeklyReviewScreen({super.key,required this.store,required this.reviewWeek,
   required this.planWeek,this.initialStep=0});
 @override State<WeeklyReviewScreen> createState()=>_WeeklyReviewScreenState();
}
class _WeeklyReviewScreenState extends State<WeeklyReviewScreen>{
 late int step=widget.initialStep;
 late final best=TextEditingController(text:widget.store.week(widget.reviewWeek).bestThing);
 late final reflection=TextEditingController(text:widget.store.week(widget.reviewWeek).reflection);
 late final focus=TextEditingController(text:widget.store.week(widget.planWeek).focus);
 late final List<TextEditingController> priorityFields=List.generate(3,(i){
   final old=widget.store.week(widget.planWeek).priorities;
   return TextEditingController(text:i<old.length?old[i]:'');
 });
 bool busy=false,finished=false;
 @override void dispose(){best.dispose();reflection.dispose();focus.dispose();
   for(final p in priorityFields){p.dispose();}super.dispose();}
 Future<bool> saveStep() async{
   if(busy)return false;
   setState(()=>busy=true);
   try{
     if(step==1){
       final old=widget.store.week(widget.reviewWeek);
       await widget.store.saveWeek(widget.reviewWeek,old.copyWith(
         bestThing:best.text.trim(),reflection:reflection.text.trim()));
     }else if(step==2){
       final old=widget.store.week(widget.planWeek);
       final first=priorityFields.map((p)=>p.text.trim()).where((p)=>p.isNotEmpty).toList();
       await widget.store.saveWeek(widget.planWeek,old.copyWith(
         focus:focus.text.trim(),priorities:[...first,...old.priorities.skip(3)]));
     }
     return true;
   }catch(_){
     if(mounted){
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content:Text(wrText(context,'error'))));
     }
     return false;
   }finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> changeStep(int n)async{
   if(!await saveStep()||!mounted)return;
   setState(()=>step=n);
 }
 Future<void> finish()async{
   if(!await saveStep()||!mounted)return;
   setState(()=>busy=true);
   try{
     final old=widget.store.week(widget.reviewWeek);
     await widget.store.saveWeek(widget.reviewWeek,
       old.copyWith(reviewCompletedAt:DateTime.now()));
     await WeeklyReviewReminders.reconcile(widget.store);
     if(mounted)setState(()=>finished=true);
   }catch(_){if(mounted){
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content:Text(wrText(context,'error'))));
     }}
   finally{if(mounted)setState(()=>busy=false);}
 }
 Future<void> moveWeek(int delta)async{
   if(!await saveStep()||!mounted)return;
   final current=widget.reviewWeek;
   final other=DateTime(current.year,current.month,current.day+delta*7);
   Navigator.pushReplacement<void,void>(context,MaterialPageRoute(builder:(_)=>
     WeeklyReviewScreen(store:widget.store,reviewWeek:other,
       planWeek:DateTime(other.year,other.month,other.day+7))));
 }
 Future<void> useMemory(String text)async{
   if(best.text.trim().isNotEmpty){
     final confirmed=await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
       title:Text(wrText(c,'replace')),actions:[
         TextButton(onPressed:()=>Navigator.pop(c,false),child:Text(wrText(c,'cancel'))),
         FilledButton(onPressed:()=>Navigator.pop(c,true),child:Text(wrText(c,'confirm'))),
       ]));
     if(confirmed!=true||!mounted)return;
   }
   best.text=text;
 }
 @override Widget build(BuildContext c){
   final hidden=widget.store.preferences.hideHomeDetails;
   final counts=WeeklyReviewSummary.fromItems(widget.store.items,widget.reviewWeek);
   final memories=<String>[];
   for(var i=0;i<7;i++){
     final m=widget.reviewWeek;
     final journal=widget.store.journal(DateTime(m.year,m.month,m.day+i));
     if(journal.beautiful.trim().isNotEmpty&&!memories.contains(journal.beautiful.trim())){
       memories.add(journal.beautiful.trim());
     }
   }
   return Scaffold(appBar:AppBar(title:Text(wrText(c,'week'))),
     body:SafeArea(child:AnnaJournalContent(child:AnnaMotionReveal(token:step,axis:Axis.vertical,child:ListView(
       padding:const EdgeInsets.symmetric(vertical:14),children:finished?[
         AnnaJournalCard(hero:true,child:Column(children:[
           Icon(Icons.local_florist_outlined,size:46,color:Theme.of(c).colorScheme.primary),
           const SizedBox(height:12),
           Text(wrText(c,'saved'),style:AnnaJournalTypography.editorial(c,size:26)),
           const SizedBox(height:15),
           FilledButton(onPressed:()=>Navigator.pop(c),child:Text(wrText(c,'close'))),
           TextButton(onPressed:()=>setState(()=>finished=false),
             child:Text(wrText(c,'reopen'))),
         ])),
       ]:[
         Text(wrRange(c,step==2?widget.planWeek:widget.reviewWeek),
           style:Theme.of(c).textTheme.bodySmall),
         Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
           IconButton(tooltip:wrText(c,'previous'),onPressed:busy?null:()=>moveWeek(-1),
             icon:const Icon(Icons.chevron_left)),
           IconButton(tooltip:wrText(c,'following'),onPressed:busy?null:()=>moveWeek(1),
             icon:const Icon(Icons.chevron_right)),
         ]),
         const SizedBox(height:10),
         Text(wrText(c,['review','memories','intentions'][step]),
           style:AnnaJournalTypography.editorial(c,size:27)),
         const SizedBox(height:15),
         Row(children:List.generate(3,(i)=>Expanded(child:Padding(
           padding:const EdgeInsets.symmetric(horizontal:3),
           child:OutlinedButton(
             onPressed:busy?null:()=>changeStep(i),
             style:OutlinedButton.styleFrom(
               backgroundColor:i==step?Theme.of(c).colorScheme.primaryContainer:null),
             child:Text((i+1).toString()),
           ))))),
         const SizedBox(height:13),
         if(step==0)AnnaJournalCard(child:Column(
           crossAxisAlignment:CrossAxisAlignment.start,children:[
             Text(wrText(c,'summary'),style:Theme.of(c).textTheme.bodySmall),
             const SizedBox(height:12),
             Row(children:[
               Expanded(child:_WrMetric(value:hidden?'—':counts.completedDatedThisWeek.toString(),
                 label:wrText(c,'done'))),
               const SizedBox(width:8),
               Expanded(child:_WrMetric(value:hidden?'—':
                 (counts.pendingDatedThisWeek+counts.overdueFromBefore).toString(),
                 label:wrText(c,'pending'))),
             ]),
             if(!hidden)...[
               const SizedBox(height:10),
               for(final task in widget.store.items.where((e)=>
                 e.type==ItemType.task&&!e.done&&
                 e.date.isBefore(DateTime(widget.reviewWeek.year,
                   widget.reviewWeek.month,widget.reviewWeek.day+7))).take(12))
                 ListTile(dense:true,leading:const Icon(Icons.arrow_forward),
                   title:Text(task.title),subtitle:Text(DateFormat.yMMMd(
                     AnnaStrings.intlLocale(c)).format(task.date))),
             ],
           ])),
         if(step==1)...[
           if(!hidden&&memories.isNotEmpty)AnnaJournalCard(child:Column(
             crossAxisAlignment:CrossAxisAlignment.start,children:[
               Text(wrText(c,'memories'),style:Theme.of(c).textTheme.titleMedium),
               for(final memory in memories.take(5))ListTile(
                 leading:const Icon(Icons.auto_stories_outlined),
                 title:Text(memory,maxLines:2,overflow:TextOverflow.ellipsis),
                 trailing:const Icon(Icons.add_circle_outline),
                 onTap:()=>useMemory(memory)),
             ])),
           if(memories.isEmpty)Padding(padding:const EdgeInsets.all(12),
             child:Text(wrText(c,'noMemories'))),
           if(hidden)Text(wrText(c,'privacy')) else ...[
             TextField(controller:best,maxLines:3,decoration:InputDecoration(
               labelText:wrText(c,'best'),helperText:wrText(c,'optional'),
               border:const OutlineInputBorder())),
             const SizedBox(height:12),
             TextField(controller:reflection,maxLines:4,decoration:InputDecoration(
               labelText:wrText(c,'reflection'),border:const OutlineInputBorder())),
           ],
         ],
         if(step==2)...[
           if(hidden)Text(wrText(c,'privacy'))else...[
             TextField(controller:focus,maxLines:3,decoration:InputDecoration(
               labelText:wrText(c,'focus'),border:const OutlineInputBorder())),
             const SizedBox(height:16),
             Text(wrText(c,'priorities'),style:Theme.of(c).textTheme.titleMedium),
             const SizedBox(height:8),
             for(var i=0;i<3;i++)Padding(padding:const EdgeInsets.only(bottom:10),
               child:TextField(controller:priorityFields[i],decoration:InputDecoration(
                 labelText:(i+1).toString(),border:const OutlineInputBorder()))),
           ],
         ],
         const SizedBox(height:17),
         Row(children:[
           Expanded(child:OutlinedButton(onPressed:busy?null:
             ()=>step==0?Navigator.pop(c):changeStep(step-1),
             child:Text(wrText(c,'back')))),
           const SizedBox(width:8),
           Expanded(child:FilledButton(onPressed:busy?null:
             ()=>step==2?finish():changeStep(step+1),
             child:Text(wrText(c,step==2?'finish':'next')))),
         ]),
         TextButton(onPressed:()=>Navigator.push<void>(c,
           MaterialPageRoute(builder:(_)=>WeeklyReviewArchivePage(store:widget.store))),
           child:Text(wrText(c,'archive'))),
       ],
     )))));
 }
}

class WeeklyReviewArchivePage extends StatelessWidget{
 final AgendaStore store;
 const WeeklyReviewArchivePage({super.key,required this.store});
 @override Widget build(BuildContext c){
   final now=wrMonday(DateTime.now());
   final mondays=<DateTime>{for(final key in store.weeks.keys)
     if(DateTime.tryParse(key)!=null)wrMonday(DateTime.parse(key))};
   for(var i=0;i<12;i++){
     mondays.add(DateTime(now.year,now.month,now.day-7*i));
   }
   final dates=mondays.toList()..sort((a,b)=>b.compareTo(a));
   final groups=<String,List<DateTime>>{};
   for(final date in dates){
     final month=DateFormat('MMMM yyyy',AnnaStrings.intlLocale(c)).format(date);
     groups.putIfAbsent(month,()=>[]).add(date);
   }
   return Scaffold(appBar:AppBar(title:Text(wrText(c,'archive'))),
     body:AnnaJournalContent(child:ListView(
       padding:const EdgeInsets.symmetric(vertical:15),children:[
         for(final group in groups.entries)...[
           Padding(padding:const EdgeInsets.symmetric(vertical:12),
             child:Text(group.key,style:AnnaJournalTypography.editorial(c,size:22))),
           for(final monday in group.value)
           Padding(padding:const EdgeInsets.only(bottom:8),child:AnnaJournalCard(
             child:ListTile(contentPadding:EdgeInsets.zero,
               leading:Icon(store.week(monday).reviewCompletedAt!=null?
                 Icons.check_circle_outline:Icons.auto_stories_outlined,
                 color:Theme.of(c).colorScheme.primary),
               title:Text(wrRange(c,monday)),
               subtitle:Text(wrText(c,store.week(monday).reviewCompletedAt!=null?
                 'completed':store.weeks.containsKey(AgendaStore.dateKey(monday))?
                 'unfinished':'empty')),
               trailing:const Icon(Icons.chevron_right),
               onTap:()=>Navigator.push<void>(c,MaterialPageRoute(builder:(_)=>
                 WeeklyReviewScreen(store:store,reviewWeek:monday,
                   planWeek:DateTime(monday.year,monday.month,monday.day+7)))),
             ))),
         ],
       ])));
 }
}

/// Finite one-shot local notification horizon; no background permission prompt.
abstract final class WeeklyReviewReminders{
 static String id(DateTime monday)=>'wr:week:${AgendaStore.dateKey(monday)}';
 static Future<void> reconcile(AgendaStore store)async{
   if(kIsWeb)return;
   final prefs=store.preferences,now=DateTime.now(),start=wrMonday(now);
   final service=NotificationService.instance;
   for(var i=0;i<9;i++){
     final week=DateTime(start.year,start.month,start.day+i*7);
     await service.cancel(id(week));
   }
   if(!prefs.weeklyReviewReminderEnabled)return;
   final health=await service.health();
   if(!health.reminderDeliveryReady)return;
   for(var i=0;i<8;i++){
     final week=DateTime(start.year,start.month,start.day+i*7);
     final when=DateTime(week.year,week.month,
       week.day+(prefs.weeklyReviewReminderDay==7?6:0),
       prefs.weeklyReviewReminderHour,prefs.weeklyReviewReminderMinute);
     if(!when.isAfter(now))continue;
     final target=prefs.weeklyReviewReminderDay==7?week:
       DateTime(week.year,week.month,week.day-7);
     if(store.week(target).reviewCompletedAt!=null)continue;
     final lang=prefs.appLanguage.code.isEmpty?
       Intl.getCurrentLocale().split('_').first:prefs.appLanguage.code;
     final index=switch(lang){'it'=>0,'es'=>2,'fr'=>3,'pt'=>4,_=>1};
     final body=_wrCopy[prefs.weeklyReviewReminderDay==7?
       'noticeSunday':'noticeMonday']![index];
     await service.schedule(stableId:id(week),when:when,
       title:"Anna's Diary",requestPermission:false,body:body);
   }
 }
}

class WeeklyReviewSettingsPage extends StatefulWidget{
 final AgendaStore store;
 const WeeklyReviewSettingsPage({super.key,required this.store});
 @override State<WeeklyReviewSettingsPage> createState()=>_WeeklyReviewSettingsState();
}
class _WeeklyReviewSettingsState extends State<WeeklyReviewSettingsPage>{
 bool busy=false;
 Future<void> save(AgendaPreferences newPrefs,{bool enabling=false})async{
   if(busy)return;setState(()=>busy=true);
   try{
     if(enabling){
       if(kIsWeb||!await NotificationService.instance.requestPermissions()){
         if(mounted){
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content:Text(wrText(context,'denied'))));
     }
         return;
       }
       final h=await NotificationService.instance.health();
       if(!h.reminderDeliveryReady){
         if(mounted){
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content:Text(wrText(context,'denied'))));
     }
         return;
       }
     }
     await widget.store.savePreferences(newPrefs);
     await WeeklyReviewReminders.reconcile(widget.store);
     if(mounted)setState((){});
   }catch(_){
     if(mounted){
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content:Text(wrText(context,'error'))));
     }
   }finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext c){
   final p=widget.store.preferences;
   return Scaffold(appBar:AppBar(title:Text(wrText(c,'reminders'))),
     body:AnnaJournalContent(child:ListView(
       padding:const EdgeInsets.symmetric(vertical:18),children:[
         AnnaJournalCard(child:Column(children:[
           SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,
             title:Text(wrText(c,'notification')),
             subtitle:Text(wrText(c,'off')),
             value:p.weeklyReviewReminderEnabled,
             onChanged:busy?null:(v)=>save(p.copyWith(weeklyReviewReminderEnabled:v),enabling:v)),
           const SizedBox(height:11),
           DropdownButtonFormField<int>(
             initialValue:p.weeklyReviewReminderDay,
             decoration:InputDecoration(labelText:wrText(c,'week')),
             items:[7,1].map((d)=>DropdownMenuItem(value:d,
               child:Text(wrText(c,d==7?'sunday':'monday')))).toList(),
             onChanged:busy?null:(d){if(d!=null)save(p.copyWith(weeklyReviewReminderDay:d));}),
           const SizedBox(height:11),
          ListTile(
            contentPadding:EdgeInsets.zero,
            title:Text(wrText(c,'time')),
            subtitle:Text('${p.weeklyReviewReminderHour.toString().padLeft(2,'0')}:${p.weeklyReviewReminderMinute.toString().padLeft(2,'0')}'),
            trailing:const Icon(Icons.access_time_outlined),
            onTap:busy?null:()async{
              final chosen=await showTimePicker(context:c,
                initialTime:TimeOfDay(hour:p.weeklyReviewReminderHour,
                  minute:p.weeklyReviewReminderMinute));
              if(chosen!=null&&mounted){
                await save(p.copyWith(weeklyReviewReminderHour:chosen.hour,
                  weeklyReviewReminderMinute:chosen.minute));
              }
            },
          ),
         ])),
       ])));
 }
}
