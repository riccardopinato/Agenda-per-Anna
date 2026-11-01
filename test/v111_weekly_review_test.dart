import 'package:flutter_test/flutter_test.dart';
import 'package:agenda_per_anna/main.dart' as anna;

void main(){
 test('weekly summary counts current state by dated private tasks',(){
   anna.AgendaItem entry(String id,int day,{bool done=false,anna.ItemType type=anna.ItemType.task})=>
     anna.AgendaItem(id:id,title:id,note:'',date:DateTime(2026,10,day),type:type,done:done);
   final s=anna.WeeklyReviewSummary.fromItems([
     entry('a',26,done:true),entry('b',30),entry('c',24),
     entry('d',30,type:anna.ItemType.appointment),
     entry('a',26,done:true),entry('e',31,done:true),entry('f',20,done:true)
   ],DateTime(2026,10,26));
   expect(s.completedDatedThisWeek,2);
   expect(s.pendingDatedThisWeek,1);
   expect(s.overdueFromBefore,1);
 });
 test('completion defaults absent and round-trips without losing priorities',(){
   final old=anna.WeekData.fromJson({'focus':'x','priorities':['1','2','3','4']});
   expect(old.reviewCompletedAt,isNull);
   final completed=old.copyWith(reviewCompletedAt:DateTime.utc(2026,11,1));
   final decoded=anna.WeekData.fromJson(completed.toJson());
   expect(decoded.reviewCompletedAt,DateTime.utc(2026,11,1));
   expect(decoded.priorities,['1','2','3','4']);
   expect(decoded.copyWith(clearReviewCompleted:true).reviewCompletedAt,isNull);
 });
 test('legacy reminder settings default OFF',(){
   final p=anna.AgendaPreferences.fromJson({});
   expect(p.weeklyReviewReminderEnabled,false);
   expect(p.weeklyReviewReminderDay,7);
   final reread=anna.AgendaPreferences.fromJson(p.copyWith(
     weeklyReviewReminderEnabled:true,weeklyReviewReminderDay:1).toJson());
   expect(reread.weeklyReviewReminderEnabled,true);
   expect(reread.weeklyReviewReminderDay,1);
 });
}
