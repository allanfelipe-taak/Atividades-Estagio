/*
 * GoalBatchScheduler
 * ------------------
 * Schedulable que dispara o GoalBatch todo dia útil (seg–sex) às 9h00.
 *
 * Para agendar via Execute Anonymous (uma única vez):
 *
 *   String cron = '0 0 9 ? * MON-FRI';
 *   System.schedule('GoalBatch - Diário 9h', cron, new GoalBatchScheduler());
 *
 * Expressão CRON:
 *   Segundos  Minutos  Horas  Dia-do-mês  Mês  Dia-da-semana  (Ano opcional)
 *       0        0       9       ?          *     MON-FRI
 */
public with sharing class GoalBatchScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GoalBatch(), 200);
    }
}