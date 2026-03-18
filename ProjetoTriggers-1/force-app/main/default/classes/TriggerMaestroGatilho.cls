public class TriggerMaestroGatilho {
    public static void gerenciar(ContratoTrigger handler, System.TriggerOperation tipoOperacao) {
        switch on tipoOperacao {
            when BEFORE_INSERT { handler.executarBeforeInsert(Trigger.new); }
            when AFTER_INSERT { handler.executarAfterInsert(Trigger.new); }
            when BEFORE_UPDATE { handler.executarBeforeUpdate(Trigger.newMap, Trigger.oldMap); }
            when AFTER_UPDATE { handler.executarAfterUpdate(Trigger.newMap, Trigger.oldMap); }
            when BEFORE_DELETE { handler.executarBeforeDelete(Trigger.oldMap); }
            when AFTER_DELETE { handler.executarAfterDelete(Trigger.oldMap); }
            when AFTER_UNDELETE { handler.executarAfterUndelete(Trigger.new); }
        }
    }
}