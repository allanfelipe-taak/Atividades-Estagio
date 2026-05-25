/**
 * Essencial para a regra de duplicidade e comparação de registros.
 */
public class PricingKey {
    public Id productId;
    public Id accountId;
    public Id hierarchyId;
public Id groupId;
public Id countryId;
    public String state;
    public String city;

    public PricingKey(SObject record) {
        // Pega o mapa de campos que realmente existem no registro enviado
        Map<String, Object> fields = record.getPopulatedFieldsAsMap();

        this.productId = (Id) record.get('Product__c');

        // SÓ TENTA PEGAR A CONTA SE O CAMPO EXISTIR (Resolve o erro do Frete)
        this.accountId = fields.containsKey('Account__c') ? (Id) record.get('Account__c') : null;

        this.state = fields.containsKey('State__c') ? (String) record.get('State__c') : null;
        this.city = fields.containsKey('City__c') ? (String) record.get('City__c') : null;

        this.hierarchyId = fields.containsKey('ProductHierarchy__c') ? (Id) record.get ('ProductHierarchy__c') : null;
         this.groupId = fields.containsKey ('AccountGroup__c') ? (Id) record.get('AccountGroup__c') : null;
        this.countryId =   fields.containsKey ('Country__c')   ?      (Id)record.get('Country__c') : null;
    }

    public Boolean equals(Object obj) {
        if (obj instanceof PricingKey) {
            PricingKey other = (PricingKey) obj;
            return (this.productId == other.productId && this.accountId == other.accountId &&
                    this.state == other.state && this.city == other.city &&
                    this.groupId == other.groupId && this.countryId == other.countryId &&
                    this.hierarchyId == other.hierarchyId);
        }
        return false;
    }

    public Integer hashCode() {
        Integer code = 7;
        code = 31 * code + (productId == null ? 0 : String.valueOf(productId).hashCode());
        code = 31 * code + (accountId == null ? 0 : String.valueOf(accountId).hashCode());
        code = 31 * code + (state == null ? 0 : state.hashCode());
        code = 31 * code + (city == null ? 0 : city.hashCode());
        code = 31 * code + (groupId == null ? 0 : groupId.hashCode());
        code = 31 * code + (countryId == null ? 0 : countryId.hashCode());
        code = 31 * code + (hierarchyId == null ? 0 : hierarchyId.hashCode());

        return code;
    }
}