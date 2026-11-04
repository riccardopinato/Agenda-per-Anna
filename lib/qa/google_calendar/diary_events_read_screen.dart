// Anna's Diary — first-party read-only Google event review screen.
// This screen is reachable from Settings in an opt-in QA build only.
// No sync, import, storage, Calendar write permission or Google token on device.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'event_correspondence.dart';
import 'two_phase_flutter_client.dart';
import 'two_phase_flutter_panel.dart' show gcalQaErrorMessage;
import 'two_phase_flutter_transport.dart';

typedef GcalDiaryLocalContextLoader = List<GcalDiaryLocalContext> Function(
    DateTime startInclusive, DateTime endExclusive);

class GcalDiaryReadScreen extends StatefulWidget {
  final GcalDiaryLocalContextLoader localContextsForWindow;
  final VoidCallback onManageConnection;

  const GcalDiaryReadScreen({
    super.key,
    required this.localContextsForWindow,
    required this.onManageConnection,
  });

  @override
  State<GcalDiaryReadScreen> createState() => _GcalDiaryReadScreenState();
}

class _GcalDiaryReadScreenState extends State<GcalDiaryReadScreen> {
  late final http.Client _http = http.Client();
  late final GcalTwoPhaseFlutterStagingClient _client =
      createGcalStagingClient(httpClient: _http);
  late DateTime _month = DateTime(DateTime.now().year,DateTime.now().month);
  List<GcalStageConnection> _accounts = const [];
  List<GcalStageCalendar> _calendars = const [];
  GcalStageEventBatch? _batch;
  List<GcalDiaryLocalContext> _local = const [];
  String? _selectedSubject;
  String? _selectedCalendar;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  @override
  void dispose() {
    _client.clearForAccountSwitch();
    _http.close();
    super.dispose();
  }

  Future<void> _perform(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {_busy=true;_message=null;});
    try {
      await action();
    } on GcalStageClientException catch(error) {
      if(mounted) setState(() {_message=gcalQaErrorMessage(error.kind);});
    } catch (_) {
      if(mounted) {
        setState(() {
          _message='Impossibile completare la lettura. '
            'Nessun evento del diario è stato modificato.';
        });
      }
    } finally {
      if(mounted) setState(() {_busy=false;});
    }
  }

  Future<void> _loadConnections() => _perform(() async {
    final accounts=await _client.recoverConnections();
    if(!mounted)return;
    setState(() {
      _accounts=accounts;
      _selectedSubject=accounts.length==1?accounts.single.googleSubject:null;
      _calendars=const [];
      _selectedCalendar=null;
      _batch=null;
      _local=const [];
    });
    if(accounts.length==1) await _loadCalendarsInternal();
  });

  Future<void> _loadCalendarsInternal() async {
    final calendars=await _client.readCalendars();
    if(!mounted)return;
    final owned=calendars.where((c)=>c.accessRole=='owner').toList();
    setState(() {
      _calendars=calendars;
      _selectedCalendar=owned.isNotEmpty?owned.first.id:null;
      _batch=null;
      _local=const [];
    });
  }

  Future<void> _selectAccount(String subject) => _perform(() async {
    _client.selectConnection(subject);
    setState(() {
      _selectedSubject=subject;_selectedCalendar=null;
      _batch=null;_local=const [];
    });
    await _loadCalendarsInternal();
  });

  Future<void> _readMonth() => _perform(() async {
    final id=_selectedCalendar;
    if(id==null)return;
    final start=DateTime(_month.year,_month.month,1);
    final end=DateTime(_month.year,_month.month+1,1);
    final batch=await _client.readEvents(calendarId:id,from:start,until:end);
    if(!mounted)return;
    // Canonical Anna content remains LOCAL. Not transmitted to the backend.
    final context=widget.localContextsForWindow(start,end);
    setState(() {_batch=batch;_local=List.unmodifiable(context);});
  });

  void _changeMonth(int delta){
    if(_busy)return;
    setState((){
      _month=DateTime(_month.year,_month.month+delta);
      _batch=null;_local=const [];
      _message=null;
    });
  }

  String _eventDate(GcalStageEvent event){
    final date=event.start.toLocal();
    final localizations=MaterialLocalizations.of(context);
    final day=localizations.formatMediumDate(date);
    if(event.allDay)return '$day · Tutto il giorno';
    final clock=TimeOfDay.fromDateTime(date).format(context);
    return '$day · $clock';
  }

  Widget _eventCard(GcalStageEvent event){
    final matches=googleDiarySuggestions(event,_local);
    final surface=Theme.of(context).colorScheme;
    return Card(
      margin:const EdgeInsets.only(bottom:12),
      child:Padding(
        padding:const EdgeInsets.all(16),
        child:Column(
          crossAxisAlignment:CrossAxisAlignment.start,
          children:[
            Row(children:[
              Icon(Icons.event_outlined,color:surface.primary,size:21),
              const SizedBox(width:8),
              const Expanded(child:Text('Evento Google · sola lettura',
                  style:TextStyle(fontSize:12,fontWeight:FontWeight.w600))),
            ]),
            const SizedBox(height:8),
            Text(event.title,style:Theme.of(context).textTheme.titleMedium),
            Text(_eventDate(event),style:Theme.of(context).textTheme.bodySmall),
            const SizedBox(height:10),
            if(matches.isEmpty)
              const Text('Nessuna corrispondenza con appuntamenti o note '
                  'del diario per titolo e giornata.',
                  style:TextStyle(fontSize:12))
            else ...[
              Text('Possibili corrispondenze nel diario',
                  style:TextStyle(color:surface.primary,
                      fontWeight:FontWeight.w600)),
              for(final match in matches.take(3))
                Padding(
                  padding:const EdgeInsets.only(top:6),
                  child:Text(
                    (match.local.kind==GcalDiaryContextKind.appointment
                      ? 'Appuntamento: ' : 'Nota: ')+match.local.title+
                    (match.ambiguous?' · verifica manuale':
                      match.level==GcalDiaryMatchLevel.exactTimeAndTitle
                        ? ' · stesso orario' : ' · stesso giorno'),
                    style:const TextStyle(fontSize:12),
                  ),
                ),
              if(matches.length>3)Text(
                'Altre corrispondenze possibili: ${matches.length-3}',
                style:const TextStyle(fontSize:12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    final scheme=Theme.of(context).colorScheme;
    final owned=_calendars.where((c)=>c.accessRole=='owner').toList();
    final restricted=_calendars.where((c)=>c.accessRole!='owner').length;
    final events=_batch?.events??const <GcalStageEvent>[];
    return Scaffold(
      appBar:AppBar(title:const Text('Google Calendar')),
      body:SafeArea(child:Center(child:ConstrainedBox(
        constraints:const BoxConstraints(maxWidth:640),
        child:ListView(
          padding:const EdgeInsets.fromLTRB(16,12,16,28),
          children:[
            Text('Eventi e corrispondenze',
              style:Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height:8),
            const Text('Anteprima privata: leggi gli eventi Google e confrontali '
                'con gli appuntamenti e le note di Anna’s Diary. '
                'Nessuna importazione, scrittura o abbinamento automatico.'),
            const SizedBox(height:12),
            Wrap(spacing:8,runSpacing:8,children:[
              Chip(avatar:Icon(Icons.visibility_outlined,
                size:18,color:scheme.primary),
                label:const Text('Sola lettura')),
              const Chip(label:Text('Corrispondenze suggerite')),
              const Chip(label:Text('Solo staging QA')),
            ]),
            const SizedBox(height:14),
            OutlinedButton.icon(
              key:const ValueKey('google-diary-manage-account'),
              onPressed:_busy?null:widget.onManageConnection,
              icon:const Icon(Icons.manage_accounts_outlined),
              label:const Text('Gestisci collegamento Google'),
            ),
            OutlinedButton.icon(
              key:const ValueKey('google-diary-refresh-connections'),
              onPressed:_busy?null:_loadConnections,
              icon:const Icon(Icons.refresh_outlined),
              label:const Text('Aggiorna account e calendari'),
            ),
            if(_accounts.isEmpty)
              const Padding(
                padding:EdgeInsets.symmetric(vertical:16),
                child:Text('Nessun account Google collegato. '
                  'Collegalo con il pulsante qui sopra, poi premi Aggiorna.'),
              ),
            if(_accounts.length>1)
              DropdownButtonFormField<String>(
                key:const ValueKey('google-diary-account-selector'),
                initialValue:_selectedSubject,
                decoration:const InputDecoration(labelText:'Account Google'),
                items:_accounts.map((c)=>DropdownMenuItem(
                  value:c.googleSubject,
                  child:Text(c.verifiedEmail??'Account Google',
                    overflow:TextOverflow.ellipsis),
                )).toList(),
                onChanged:_busy?null:(v){if(v!=null)_selectAccount(v);},
              ),
            if(_selectedSubject!=null && _accounts.isNotEmpty) ...[
              const SizedBox(height:12),
              DropdownButtonFormField<String>(
                key:ValueKey('google-diary-calendar-${_selectedCalendar??'none'}'),
                initialValue:_selectedCalendar,
                decoration:const InputDecoration(labelText:'Calendario Google'),
                items:owned.map((calendar)=>DropdownMenuItem(
                  value:calendar.id,
                  child:Text(calendar.name,overflow:TextOverflow.ellipsis),
                )).toList(),
                onChanged:_busy?null:(id)=>setState((){
                  _selectedCalendar=id;_batch=null;_local=const [];
                }),
              ),
              if(restricted>0)Padding(
                padding:const EdgeInsets.only(top:8),
                child:Text(
                  'Calendari non di proprietà: $restricted. '
                  'Gli attuali permessi Google consentono la lettura '
                  'degli eventi solo dai calendari di tua proprietà.',
                  style:Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if(owned.isEmpty)
                const Padding(
                  padding:EdgeInsets.only(top:10),
                  child:Text('Nessun calendario di proprietà disponibile.'),
                ),
              const SizedBox(height:16),
              Row(children:[
                IconButton(
                  tooltip:'Mese precedente',
                  onPressed:_busy?null:()=>_changeMonth(-1),
                  icon:const Icon(Icons.chevron_left),
                ),
                Expanded(child:Text(
                  MaterialLocalizations.of(context).formatMonthYear(_month),
                  textAlign:TextAlign.center,
                  style:Theme.of(context).textTheme.titleMedium,
                )),
                IconButton(
                  tooltip:'Mese successivo',
                  onPressed:_busy?null:()=>_changeMonth(1),
                  icon:const Icon(Icons.chevron_right),
                ),
              ]),
              FilledButton.icon(
                key:const ValueKey('google-diary-read-events'),
                onPressed:_busy||_selectedCalendar==null?null:_readMonth,
                icon:const Icon(Icons.event_note_outlined),
                label:const Text('Leggi eventi del mese'),
              ),
            ],
            if(_busy)
              const Padding(
                padding:EdgeInsets.symmetric(vertical:16),
                child:LinearProgressIndicator(),
              ),
            if(_message!=null)
              Padding(
                padding:const EdgeInsets.symmetric(vertical:12),
                child:Text(_message!,style:TextStyle(color:scheme.error)),
              ),
            if(_batch!=null)...[
              const SizedBox(height:20),
              Text('Eventi trovati: ${events.length}',
                style:Theme.of(context).textTheme.titleMedium),
              const SizedBox(height:8),
              if(_batch!.truncated)
                const Text('Risultati parziali: Google ha restituito '
                  'un’altra pagina. Non usare questa anteprima per '
                  'concludere che manchino altri eventi.'),
              if(events.isEmpty)
                const Padding(
                  padding:EdgeInsets.symmetric(vertical:20),
                  child:Text('Nessun evento visibile nel periodo selezionato.'),
                ),
              ...events.map(_eventCard),
              const Text('Le corrispondenze sono solo suggerimenti locali '
                'basati su data e titolo: non modificano nessuna delle due '
                'origini e non vengono salvate.',style:TextStyle(fontSize:12)),
            ],
          ],
        ),
      ))),
    );
  }
}