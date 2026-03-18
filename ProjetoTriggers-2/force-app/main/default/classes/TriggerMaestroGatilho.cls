public with sharing class TriggerMaestroGatilho {
    public static void executar(System.Type handlerType) {
        // Cria uma instância da classe Handler que foi passada
        ContratoTrigger handler = (ContratoTrigger)handlerType.newInstance();

        // Verifica o contexto da Trigger e chama o método certo
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                handler.beforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                handler.beforeUpdate(Trigger.new, Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                handler.afterInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                handler.afterUpdate(Trigger.new, Trigger.oldMap);
            }
        }
    }
}