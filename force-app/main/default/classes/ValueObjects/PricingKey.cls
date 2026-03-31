/**
 * Value Object que representa a chave única de precificação.
 * Essencial para a regra de duplicidade e comparação de registros.
 */
public class PricingKey {
    public Id produtoId;
    public Id contaId;
    public String estado;
    public String cidade;

    public PricingKey(SObject record) {
        // Pega o mapa de campos que realmente existem no registro enviado
        Map<String, Object> campos = record.getPopulatedFieldsAsMap();

        this.produtoId = (Id) record.get('Produto__c');
        
        // SÓ TENTA PEGAR A CONTA SE O CAMPO EXISTIR (Resolve o erro do Frete)
        this.contaId = campos.containsKey('Conta__c') ? (Id) record.get('Conta__c') : null;
        
        this.estado = campos.containsKey('Estado__c') ? (String) record.get('Estado__c') : null;
        this.cidade = campos.containsKey('Cidade__c') ? (String) record.get('Cidade__c') : null;
    }

    public Boolean equals(Object obj) {
        if (obj instanceof PricingKey) {
            PricingKey other = (PricingKey) obj;
            return (this.produtoId == other.produtoId && this.contaId == other.contaId && 
                    this.estado == other.estado && this.cidade == other.cidade);
        }
        return false;
    }

    public Integer hashCode() {
        Integer code = 7;
        code = 31 * code + (produtoId == null ? 0 : String.valueOf(produtoId).hashCode());
        code = 31 * code + (contaId == null ? 0 : String.valueOf(contaId).hashCode());
        code = 31 * code + (estado == null ? 0 : estado.hashCode());
        code = 31 * code + (cidade == null ? 0 : cidade.hashCode());
        return code;
    }
}