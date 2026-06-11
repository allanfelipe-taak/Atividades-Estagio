/**
 * Mock de callout HTTP para os testes do PokemonSyncQueueable.
 * Devolve uma página com "next" nulo, encerrando a corrente em 1 execução
 * (testes só permitem 1 nível de encadeamento de Queueable).
 */
@isTest
public class PokemonCalloutMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        response.setHeader('Content-Type', 'application/json');
        response.setBody(
            '{' +
                '"count":2,' +
                '"next":null,' +
                '"previous":null,' +
                '"results":[' +
                    '{"name":"bulbasaur","url":"https://pokeapi.co/api/v2/pokemon/1/"},' +
                    '{"name":"ivysaur","url":"https://pokeapi.co/api/v2/pokemon/2/"}' +
                ']' +
            '}'
        );
        return response;
    }
}
