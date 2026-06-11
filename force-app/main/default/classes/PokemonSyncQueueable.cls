/**
 * Importa todos os Pokémons da PokeAPI para o objeto Pokemon__c.
 *
 * Estratégia: Queueable encadeado. Cada execução processa UMA página
 * (20 registros), insere os dados e, se houver "next", enfileira o
 * próximo job apontando para a próxima página. A corrente termina
 * quando "next" vem nulo.
 *
 * Implementa Database.AllowsCallouts para permitir o HTTP callout
 * dentro do contexto assíncrono.
 *
 * Acionamento (Execute Anonymous):
 *     System.enqueueJob(new PokemonSyncQueueable());
 */
public with sharing class PokemonSyncQueueable implements Queueable, Database.AllowsCallouts {

    private static final String FIRST_PAGE =
        'https://pokeapi.co/api/v2/pokemon?offset=0&limit=20';

    private final String endpoint;

    /** Construtor padrão: começa pela primeira página. */
    public PokemonSyncQueueable() {
        this(FIRST_PAGE);
    }

    /** Construtor usado no encadeamento: recebe a URL da página a processar. */
    public PokemonSyncQueueable(String endpoint) {
        this.endpoint = endpoint;
    }

    public void execute(QueueableContext context) {
        HttpResponse response = doCallout(this.endpoint);

        if (response.getStatusCode() != 200) {
            throw new CalloutException(
                'Falha ao consultar a PokeAPI. Status: ' + response.getStatusCode());
        }

        PokemonResponse body =
            (PokemonResponse) JSON.deserialize(response.getBody(), PokemonResponse.class);

        upsertPokemons(body.results);

        // Encadeia o próximo job apenas se houver próxima página.
        if (String.isNotBlank(body.next)) {
            System.enqueueJob(new PokemonSyncQueueable(body.next));
        }
    }

    private HttpResponse doCallout(String url) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(url);
        request.setMethod('GET');
        request.setTimeout(120000);
        return new Http().send(request);
    }

    private void upsertPokemons(List<PokemonResponse.Result> results) {
        if (results == null || results.isEmpty()) {
            return;
        }

        List<Pokemon__c> pokemons = new List<Pokemon__c>();
        for (PokemonResponse.Result item : results) {
            pokemons.add(new Pokemon__c(
                Name  = item.name,
                Url__c = item.url
            ));
        }

        // Upsert pela URL (External Id) torna a importação idempotente:
        // rodar novamente não duplica registros.
        upsert pokemons Url__c;
    }
}
