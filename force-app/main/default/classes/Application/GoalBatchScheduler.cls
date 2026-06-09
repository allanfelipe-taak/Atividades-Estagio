/**
 * GoalBatchScheduler
 * ------------------
 * Schedulable que dispara o GoalBatch todo dia útil (seg–sex) às 9h00.
 *
 * Para agendar (Execute Anonymous):
 *   String cron = '0 0 9 ? * MON-FRI';
 *   System.schedule('GoalBatch - Diário 9h', cron, new GoalBatchScheduler());
 */
public with sharing class GoalBatchScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GoalBatch(), 200);
    }
}
