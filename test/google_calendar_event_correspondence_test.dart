import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/qa/google_calendar/event_correspondence.dart';
import 'package:agenda_per_anna/qa/google_calendar/two_phase_flutter_client.dart';
void main(){
 final date=DateTime(2026,11,12,15,0);
 final event=GcalStageEvent(
   calendarId:'owner@gmail.com',eventId:'google-test',
   title:'Dentista',start:date,end:date.add(const Duration(minutes:30)),
   allDay:false,
 );
 GcalDiaryLocalContext local(String id,String title,{DateTime? at,
    GcalDiaryContextKind kind=GcalDiaryContextKind.appointment})=>
     GcalDiaryLocalContext(id:id,title:title,day:DateTime(2026,11,12),
       startTime:at,kind:kind);
 test('candidate only for same normalized title and day; no false equality',(){
   final result=googleDiarySuggestions(event,[
     local('a','DENTISTA',at:DateTime(2026,11,12,15,10)),
     local('b','Dentista',at:DateTime(2026,11,12,20,0)),
     local('c','Altro',at:DateTime(2026,11,12,15,0)),
     GcalDiaryLocalContext(
       id:'x',title:'Dentista',day:DateTime(2026,11,13),
       kind:GcalDiaryContextKind.diaryNote,
     ),
   ]);
   expect(result.length,2);
   expect(result.first.local.id,'a');
   expect(result.first.level,GcalDiaryMatchLevel.exactTimeAndTitle);
   expect(result.first.ambiguous,true);
   expect(result.last.level,GcalDiaryMatchLevel.sameDayAndTitle);
   expect(result.last.ambiguous,true);
 });
 test('blank title yields no match, never auto links',(){
   final empty=GcalStageEvent(
      calendarId:event.calendarId,eventId:event.eventId,
      title:'Senza titolo',start:event.start,end:event.end,allDay:false);
   expect(googleDiarySuggestions(empty,[local('a','Senza titolo')]),isEmpty);
 });
 test('Google source keys do not collide with local canonical IDs',(){
   final other=GcalStageEvent(
     calendarId:'owner@gmail.com',eventId:'google-test-2',
     title:event.title,start:event.start,end:event.end,allDay:false);
   expect(event.sourceKey, isNot(other.sourceKey));
   expect(event.sourceKey,contains('owner@gmail.com'));
 });
 test('diary-note title can be suggested but never persisted as an event',(){
   final candidates=googleDiarySuggestions(event,[
     local('diary-block-123','dentista',kind:GcalDiaryContextKind.diaryNote)
   ]);
   expect(candidates.single.local.kind,GcalDiaryContextKind.diaryNote);
   expect(candidates.single.level,GcalDiaryMatchLevel.sameDayAndTitle);
 });
 test('no automatic match for same date without same title',(){
   expect(googleDiarySuggestions(event,[local('d','Visita')]),isEmpty);
 });
}