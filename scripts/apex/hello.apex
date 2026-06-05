// Cria o registro informando apenas o Login do GitHub
DevUser__c novoDev = new DevUser__c(Login__c = 'octocat');
insert novoDev;