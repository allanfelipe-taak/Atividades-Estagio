public with sharing class TriggerMaestroGatilho {
    public static void executar(System.Type handlerType) {
        ContratoTrigger handler = (ContratoTrigger)handlerType.newInstance();

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
            // ADICIONE ESTAS LINHAS ABAIXO:
            else if (Trigger.isDelete) {
                handler.afterDelete(Trigger.oldMap);
            }
        }
    }
}