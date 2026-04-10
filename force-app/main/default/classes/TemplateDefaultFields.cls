public with sharing class TemplateDefaultFields {
    public interface FieldDefaults {
        Map<String, Object> getFieldDefaults(Decimal countSObjectCreated);
    }

    // --- RECEITAS DOS SEUS OBJETOS DO PROJETO ---
    
    public class AccountDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Name' => 'Conta Teste ' + count };
        }
    }

    public class Product2Defaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Name' => 'Produto Teste ' + count, 'IsActive' => true };
        }
    }

    public class GrupodeContaDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Name' => 'Grupo Teste ' + count };
        }
    }

    public class EstadoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Name' => 'Estado ' + count };
        }
    }

    public class CidadeDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Name' => 'Cidade ' + count };
        }
    }

    public class MargemDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Status__c' => 'Aprovado' };
        }
    }

    public class FreteDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Status__c' => 'Aprovado' };
        }
    }

    public class ImpostoDefaults implements FieldDefaults {
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object>{ 'Status__c' => 'Aprovado' };
        }
    }

   public class OrderItemDefaults implements FieldDefaults {
        // O segredo está nesse (Decimal d) que a sua interface exige!
        public Map<String, Object> getFieldDefaults(Decimal count) {
            return new Map<String, Object> {
                'Quantity' => 1,
                'UnitPrice' => 0
            };
        }
    }
}