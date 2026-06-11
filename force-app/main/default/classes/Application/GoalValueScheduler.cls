/**
 * GoalValueScheduler
 * ------------------
 * Schedulable que dispara o GoalValueBatch em um horário configurável.
 *
 * Para agendar (Execute Anonymous):
 *   String cron = '0 0 9 ? * MON-FRI';
 *   System.schedule('GoalValueBatch - Diário 9h', cron, new GoalValueScheduler());
 *
 * Cron Format: segundo minuto hora ? mês dia_da_semana
 * Exemplo: '0 0 9 ? * MON-FRI' = 09:00:00 (seg–sex)
 */
public with sharing class GoalValueScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GoalValueBatch(), 200);
    }
}
