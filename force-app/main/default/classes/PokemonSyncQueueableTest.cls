@isTest
private class PokemonSyncQueueableTest {

    @isTest
    static void deveInserirPokemonsDaPagina() {
        // Arrange: simula a resposta da PokeAPI.
        Test.setMock(HttpCalloutMock.class, new PokemonCalloutMock());

        // Act: enfileira e executa o job dentro do bloco de teste.
        Test.startTest();
        System.enqueueJob(new PokemonSyncQueueable());
        Test.stopTest();

        // Assert: os 2 pokémons do mock devem estar persistidos.
        List<Pokemon__c> registros =
            [SELECT Name, Url__c FROM Pokemon__c ORDER BY Name ASC];

        System.assertEquals(2, registros.size(),
            'Deveria inserir os 2 pokémons retornados pelo mock.');
        System.assertEquals('bulbasaur', registros[0].Name,
            'O primeiro pokémon (ordem alfabética) deveria ser bulbasaur.');
        System.assertEquals('https://pokeapi.co/api/v2/pokemon/1/', registros[0].Url__c,
            'A URL deveria ser mapeada para Url__c.');
    }

    @isTest
    static void deveSerIdempotenteNoUpsert() {
        Test.setMock(HttpCalloutMock.class, new PokemonCalloutMock());

        // Pré-existe um registro com a mesma URL (External Id).
        insert new Pokemon__c(
            Name = 'antigo',
            Url__c = 'https://pokeapi.co/api/v2/pokemon/1/'
        );

        Test.startTest();
        System.enqueueJob(new PokemonSyncQueueable());
        Test.stopTest();

        // O upsert por Url__c atualiza o existente em vez de duplicar.
        List<Pokemon__c> mesmaUrl =
            [SELECT Name FROM Pokemon__c WHERE Url__c = 'https://pokeapi.co/api/v2/pokemon/1/'];

        System.assertEquals(1, mesmaUrl.size(),
            'Não deveria duplicar registros com a mesma URL.');
        System.assertEquals('bulbasaur', mesmaUrl[0].Name,
            'O registro existente deveria ter sido atualizado.');
    }
}
