/**
 * DTO que espelha o corpo JSON retornado pela PokeAPI.
 * Os nomes dos atributos batem 1:1 com as chaves do JSON,
 * permitindo o uso de JSON.deserialize(body, PokemonResponse.class).
 */
public class PokemonResponse {
    public Integer count;       // total de registros (1350) - informativo
    public String next;         // URL da próxima página; null na última
    public String previous;     // URL da página anterior; não utilizado
    public List<Result> results; // os 20 pokémons da página atual

    public class Result {
        public String name; // -> Pokemon__c.Name
        public String url;  // -> Pokemon__c.Url__c
    }
}
