// Podemos dar o nome dessa classe também de Trigger Dispatcher (Despachante de Gatilhos) ou Trigger Orchestrator


public with sharing class TriggerMaestro {
    
    public static void executa(ContratoTrigger handler){

        //Verificar o tipo de operação que o Salesforce está executando agora

        switch on Trigger.operationType {

            when BEFORE_INSERT {
                handler.beforeInsert(Trigger.new);
            }

            when BEFORE_UPDATE {
                handler.beforeUpdate(Trigger.new, Trigger.oldMap);
            }
            when AFTER_INSERT {
                handler.afterInsert(Trigger.new);
            }
            when AFTER_UPDATE {
                handler.afterUpdate(Trigger.new, Trigger.oldMap);
            }
            when AFTER_DELETE {
                handler.afterDelete(Trigger.old);
            }
            when AFTER_UNDELETE {
                handler.afterUndelete(Trigger.new);
            }
        }
    }

}


     