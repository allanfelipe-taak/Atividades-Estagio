public class GitHubUserCalloutQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<Id> devUserIds;

    // Construtor que recebe a lista de IDs enviados pela Trigger
    public GitHubUserCalloutQueueable(List<Id> ids) {
        this.devUserIds = ids;
    }

    public void execute(QueueableContext context) {
        if (devUserIds.isEmpty()) return;
        ///

        // Processa no máximo 50 registros por vez para ficar totalmente seguro contra o limite de 100 callouts do SF
        List<Id> idsToProcessNow = new List<Id>();
        List<Id> remainingIds = new List<Id>();

        for (Integer i = 0; i < devUserIds.size(); i++) {
            if (i < 50) {
                idsToProcessNow.add(devUserIds[i]);
            } else {
                remainingIds.add(devUserIds[i]);
            }
        }

        List<DevUser__c> usersToProcess = [SELECT Id, Login__c FROM DevUser__c WHERE Id IN :idsToProcessNow];
        List<DevUser__c> recordsToUpdate = new List<DevUser__c>();

        for (DevUser__c u : usersToProcess) {
            if (String.isBlank(u.Login__c)) continue;

            Http http = new Http();
            HttpRequest request = new HttpRequest();
            // Sanitiza o login do usuário para evitar problemas com caracteres especiais na URL
            String encodedLogin = EncodingUtil.urlEncode(u.Login__c, 'UTF-8');
            request.setEndpoint('https://api.github.com/users/' + encodedLogin);
            request.setMethod('GET');
            
            // OBRIGATÓRIO PARA API DO GITHUB: Se não enviar o User-Agent, dá erro 403 Forbidden
            request.setHeader('User-Agent', 'Salesforce-Apex-Integration');

            try {
                HttpResponse response = http.send(request);
                
                if (response.getStatusCode() == 200) {
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                    DevUser__c updatedUser = new DevUser__c(Id = u.Id);
                    
                    // Mapeamento dos campos convertendo os tipos do JSON para o Salesforce
                    if (jsonMap.containsKey('id') && jsonMap.get('id') != null) {
                        updatedUser.ExternalId__c = Decimal.valueOf(String.valueOf(jsonMap.get('id')));
                    }
                    if (jsonMap.containsKey('type')) {
                        updatedUser.Type__c = (String) jsonMap.get('type');
                    }
                    if (jsonMap.containsKey('bio')) {
                        updatedUser.Bio__c = (String) jsonMap.get('bio');
                    }

                    recordsToUpdate.add(updatedUser);
                } else {
                    System.debug('Erro na API do GitHub para o usuário ' + u.Login__c + ': Status ' + response.getStatusCode());
                }
            } catch (Exception ex) {
                System.debug('Exception no Callout: ' + ex.getMessage());
            }
        }

        // Salva as atualizações coletadas da API no banco de dados
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }

        // SEGUNDA MÁGICA DA ESCALABILIDADE: Se ainda sobrarem registros na lista, encadeia a próxima execução!
        if (!remainingIds.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new GitHubUserCalloutQueueable(remainingIds));
        }
    }
}