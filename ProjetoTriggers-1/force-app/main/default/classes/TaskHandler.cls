public with sharing class TaskHandler implements ContratoTrigger {
    
    // O Desafio 01 exige lógica no BEFORE_INSERT
    public void executarBeforeInsert(List<SObject> newRecords) {
        // Casting: Transformamos a lista genérica em uma lista de Tasks
        validateOneOpenTaskPerCase((List<Task>)newRecords);
    }

    private void validateOneOpenTaskPerCase(List<Task> newTasks) {
        Set<Id> caseIds = new Set<Id>();

        for (Task t : newTasks) {
            // Nível Profissional: Usando getSObjectType() em vez de '500'
            if (t.WhatId != null && t.WhatId.getSObjectType() == Case.sObjectType) {
                caseIds.add(t.WhatId);
            }
        }

        if (!caseIds.isEmpty()) {
            Set<Id> casesWithOpenTasks = new Set<Id>();
            
            // Query bulkificada
            for (Task existingTask : [SELECT WhatId FROM Task 
                                       WHERE WhatId IN :caseIds 
                                       AND IsClosed = false]) {
                casesWithOpenTasks.add(existingTask.WhatId);
            }

            for (Task t : newTasks) {
                if (casesWithOpenTasks.contains(t.WhatId)) {
                    t.addError('Já existe uma tarefa em aberto nesse caso. Encerre-a antes de abrir uma nova.');
                }
            }
        }
    }

    // MÉTODOS OBRIGATÓRIOS: Precisa "cumprir o contrato"
    // Esta vazio porque o desafio 01 não precisa deles, mas a Interface exige que existam.
    public void executarAfterInsert(List<SObject> newRecords) {}
    public void executarBeforeUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {}
    public void executarAfterUpdate(Map<Id, SObject> newMap, Map<Id, SObject> oldMap) {}
    public void executarBeforeDelete(Map<Id, SObject> oldMap) {}
    public void executarAfterDelete(Map<Id, SObject> oldMap) {}
    public void executarAfterUndelete(List<SObject> newRecords) {}
}