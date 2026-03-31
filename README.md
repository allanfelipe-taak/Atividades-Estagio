Checklist está completo:

ContratoTrigger (A Regra) - Interface

TriggerMaestro (O Maestro) - Dispatcher o orquestrador

OrderItemTrigger (O Gatilho) - O Point que liga o Trigger

OrderItemHandler (O Porteiro/Validador) - Controller da trigger

PricingSelector (O Buscador de Dados) - Infra o SOQL

PricingService (O Orquestrador do Cálculo) - Camada de serviço 

PricingItem (O Especialista no Cálculo) - Entity dominio



force-app/main/default/
├── classes/
│   ├── Application/
│   │   └── PricingService.cls       <-- (O Cérebro: Faz os cálculos)
│   ├── Domain/
│   │   ├── Handlers/
│   │   │   ├── OrderHandler.cls      <-- (Trava de Cliente/Status)
│   │   │   ├── OrderItemHandler.cls  <-- (Aplica Pricing e SaveResult)
│   │   │   └── MargemHandler.cls     <-- (Trava de Duplicidade)
│   │   └── Entities/
│   │       ├── PricingItem.cls       <-- (Objeto de cálculo)
│   │       └── PricingKey.cls        <-- (Chave de duplicidade)
│   ├── Infrastructure/
│   │   └── PricingSelector.cls       <-- (Queries/Buscas no banco)
│   └── Shared/
│       ├── Interfaces/
│       │   └── ContratoTrigger.cls   <-- (O molde dos Handlers)
│       └── Framework/
│           └── TriggerMaestro.cls    <-- (O motor que roda as Triggers)
└── triggers/
    ├── OrderTrigger.trigger
    ├── OrderItemTrigger.trigger
    └── MargemTrigger.trigger


  1. Camada de Domínio (Domain)
Entities (Entidades): É a  classe PricingItem.cls.

Por que? No DDD, uma Entidade é um objeto que tem identidade e lógica de negócio. A PricingItem "encapsula" o OrderItem e dá inteligência a ele (sabe calcular o próprio preço).

Value Objects (Objetos de Valor): É a classe PricingKey.cls.

Por que? Objetos de Valor não têm identidade própria, eles servem apenas para descrever algo (neste caso, a combinação de Produto + Conta + Localidade). Eles são imutáveis e usados para comparação (duplicidade).

Aggregate (Agregado): O Agregado é o Pedido (Order) + Itens (OrderItem).

Por que? O Pedido é a "Raiz do Agregado" (Aggregate Root). Nada acontece no item sem o contexto do pedido (Conta, Endereço, etc.). Sua PricingService garante que o Agregado seja processado de forma consistente.

2. Camada de Aplicação (Application)
Services (Serviços): É a PricingService.cls.

Por que? O Service não "é" um objeto, ele é uma "ação". Ele orquestra o fluxo: pede dados ao Selector, manda a Entidade calcular e devolve o resultado. Ele coordena a tarefa.

3. Camada de Infraestrutura (Infrastructure)
Repositories / Selectors: É a PricingSelector.cls.

Por que? Ela isola o banco de dados (SOQL) do resto do código. Se o nome de uma tabela mudar, você só mexe aqui.

Handlers / Triggers: São os seus OrderItemHandler.cls e as Triggers.

Por que? Eles são a "porta de entrada" (Gateway) do mundo externo para dentro do seu domínio.

4. Design Patterns (Padrões de Projeto) Utilizados
uma combinação poderosa:

Strategy Pattern (Estratégia): na lógica de Pesos/Especificidade. Em vez de um monte de if/else bagunçado, criou uma estratégia de pontuação para decidir qual preço vence.

Selector Pattern: Usado na PricingSelector para centralizar queries e evitar SOQL em loops.

Trigger Handler Pattern: Para manter as Triggers limpas e organizadas, delegando a lógica para classes específicas.

Service Layer Pattern: Para isolar a lógica de negócio pesada das Triggers, permitindo que o cálculo seja chamado de outros lugares (como um botão ou um processo em lote).