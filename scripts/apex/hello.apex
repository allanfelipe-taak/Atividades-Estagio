// Cancela job anterior com o mesmo nome (evita duplicata)
for (CronTrigger ct : [
    SELECT Id FROM CronTrigger
    WHERE CronJobDetail.Name = 'GoalBatch - Diário 9h'
]) {
    System.abortJob(ct.Id);
}

// Agenda: seg–sex às 09:00
String cron = '0 0 9 ? * MON-FRI';
System.schedule('GoalBatch - Diário 9h', cron, new GoalBatchScheduler());

System.debug('GoalBatchScheduler agendado com sucesso.');