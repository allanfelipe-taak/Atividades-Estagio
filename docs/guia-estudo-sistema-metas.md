# 📚 Guia de Estudo — Sistema de Metas e Comissões (Apex Batch)

> Explicação **linha por linha** de todo o código do sistema de Metas, para estudo.
> Cobre: `GoalBatch`, `GoalBatchScheduler`, a Validation Rule `Salesperson_Required` e a classe de teste `GoalBatchTest`.

---

## Índice
1. [GoalBatch.cls — a classe Batch](#1-goalbatchcls--a-classe-batch)
2. [GoalBatchScheduler.cls — o agendador](#2-goalbatchschedulercls--o-agendador)
3. [Validation Rule Salesperson_Required](#3-validation-rule-salesperson_required)
4. [GoalBatchTest.cls — a classe de teste](#4-goalbatchtestcls--a-classe-de-teste)
5. [Conceitos-chave para fixar](#-conceitos-chave-para-fixar)
6. [Glossário rápido](#-glossário-rápido)

---

## 1️⃣ GoalBatch.cls — a classe Batch

Esta é a classe que percorre todos os `GoalItem__c` e atualiza a **% atingida** quando a meta é batida.

```apex
public with sharing class GoalBatch implements Database.Batchable<sObject> {
```
- `public` → a classe pode ser usada por outras classes.
- `with sharing` → respeita as **regras de compartilhamento/segurança** do usuário (o código não "fura" permissões).
- `implements Database.Batchable<sObject>` → é um **contrato**: ao "implementar Batchable", você é **obrigado** a escrever 3 métodos: `start`, `execute`, `finish`.
- O `<sObject>` é o tipo genérico de registro. Usamos `sObject` porque o `start` devolve um `QueryLocator`.
  - 🐞 **Bug que corrigimos:** estava `<GoalItem__c>` e não compilava ("Class GoalBatch must implement the method... Iterable"). A regra: se `start()` devolve `QueryLocator`, o tipo TEM que ser `<sObject>`.

### Método `start` — roda 1 vez (define O QUE processar)
```apex
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, TargetValue__c, RealizedValue__c, ' +
            'GoalCommissionPercentage__c, AchievedPercentage__c ' +
            'FROM GoalItem__c'
        );
    }
```
- `start` → **roda 1 vez** no início. Diz **quais registros** o batch vai processar.
- `Database.QueryLocator` → um "ponteiro" eficiente que aguenta **milhões de registros** sem estourar limite (é por isso que o desafio pede Batch).
- `Database.getQueryLocator('SELECT ...')` → monta a consulta. Busca **todos** os `GoalItem__c` e os campos necessários.

### Método `execute` — roda VÁRIAS vezes (processa cada lote)
```apex
    public void execute(Database.BatchableContext bc, List<GoalItem__c> scope) {
```
- `execute` → roda **uma vez por lote (chunk)**. O `scope` é a **lista de registros do lote atual** (máx. 200 por padrão). É isso que mantém o batch dentro dos Governor Limits.

```apex
        List<GoalItem__c> recordsToUpdate = new List<GoalItem__c>();
```
- Cria uma **lista vazia** para juntar só os registros que precisam mudar, e fazer **1 update no final** (técnica de *bulkificação*).

```apex
        for (GoalItem__c item : scope) {
```
- Percorre **cada item** do lote.

```apex
            Boolean metaAtingida = item.RealizedValue__c != null
                                && item.TargetValue__c   != null
                                && item.RealizedValue__c >= item.TargetValue__c;
```
- Calcula se a meta foi atingida: "realizado **não é nulo** E meta **não é nula** E realizado **≥** meta".
- Os `!= null` são **defensivos** (evitam erro se um campo estiver vazio).

```apex
            Decimal novaPorcentagem = metaAtingida
                ? (item.GoalCommissionPercentage__c != null ? item.GoalCommissionPercentage__c : 0)
                : 0;
```
- Operador **ternário** → `condição ? valorSeVerdadeiro : valorSeFalso`:
  - Se `metaAtingida` for `true` → usa a `% de comissão da meta` (ou 0 se nula).
  - Se for `false` → `0`.

```apex
            if (item.AchievedPercentage__c != novaPorcentagem) {
                item.AchievedPercentage__c = novaPorcentagem;
                recordsToUpdate.add(item);
            }
```
- **Otimização**: só mexe no registro **se o valor realmente mudou**. Evita update à toa (economiza limites e não dispara automações desnecessárias).

```apex
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
```
- Se a lista tem algo, faz **um único `update`** com todos de uma vez (bulkificado).
- ⚠️ **Regra de ouro:** NUNCA faça DML (insert/update/delete) dentro de um `for`. Sempre acumule numa lista e faça 1 DML fora do loop.

### Método `finish` — roda 1 vez no fim
```apex
    public void finish(Database.BatchableContext bc) {
        System.debug('GoalBatch concluído. JobId: ' + bc.getJobId());
    }
```
- `finish` → roda **1 vez no fim**. Bom lugar para logs ou e-mail de conclusão. Aqui só grava um log de debug.

---

## 2️⃣ GoalBatchScheduler.cls — o agendador

```apex
public with sharing class GoalBatchScheduler implements Schedulable {
```
- `implements Schedulable` → contrato que obriga **1 método**: `execute`. É o que permite **agendar** a classe.

```apex
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new GoalBatch(), 200);
    }
```
- Quando o horário agendado chega, esse método roda.
- `Database.executeBatch(new GoalBatch(), 200)` → **dispara o batch**, processando de **200 em 200** registros.

### Como agendar (rodar 1 vez no Execute Anonymous)
```apex
String cron = '0 0 9 ? * MON-FRI';   // segundo minuto hora dia mês dia-da-semana
System.schedule('GoalBatch - Diário 9h', cron, new GoalBatchScheduler());
```
- O **cron** `0 0 9 ? * MON-FRI` = "às 9h00, de segunda a sexta". (Atende "todo dia da semana às 9h" do desafio.)

**Anatomia do cron (`Seconds Minutes Hours Day_of_month Month Day_of_week`):**
| Campo | Valor | Significado |
|---|---|---|
| Segundos | `0` | no segundo 0 |
| Minutos | `0` | no minuto 0 |
| Horas | `9` | às 9h |
| Dia do mês | `?` | qualquer (ignorado) |
| Mês | `*` | todos os meses |
| Dia da semana | `MON-FRI` | de segunda a sexta |

---

## 3️⃣ Validation Rule Salesperson_Required

Arquivo: `objects/Goal__c/validationRules/Salesperson_Required.validationRule-meta.xml`

```xml
<errorConditionFormula>ISBLANK(Salesperson__c)</errorConditionFormula>
<errorDisplayField>Salesperson__c</errorDisplayField>
<errorMessage>O Vendedor é obrigatório.</errorMessage>
```
- ⚠️ **Pegadinha importante:** na Validation Rule, a fórmula é a **condição de ERRO**. Ou seja: "se `Salesperson__c` estiver **vazio** (`ISBLANK`) → **bloqueia** o salvamento e mostra o erro".
- `errorDisplayField` → faz a mensagem aparecer **embaixo do campo** Vendedor (não no topo da tela).

### Por que usamos Validation Rule em vez do checkbox "Required"?
- O Salesforce **não permite** marcar um campo Lookup para **User** como obrigatório no nível do campo.
- Motivo técnico: campo Lookup obrigatório exige uma regra de exclusão (`deleteConstraint` Cascade/Restrict), e o objeto **User** não aceita esse tipo de relação filha.
- A Validation Rule resolve isso e ainda é **mais robusta**: vale na tela E via API/importação.

---

## 4️⃣ GoalBatchTest.cls — a classe de teste

### Cabeçalho
```apex
@isTest
private class GoalBatchTest {
```
- `@isTest` → marca a classe como **de teste**. Ela **não conta** no limite de código da org e **não vai pra produção** como código "real".

### O `@testSetup` (dados de teste)
```apex
@testSetup
static void setupTestData() {
```
- `@testSetup` → roda **uma vez antes de cada método de teste**, criando os dados. Cada teste começa com os **mesmos dados limpos** (isolamento).

```apex
User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
```
- Busca um **usuário ativo** existente para usar como Vendedor (sem ele, a inserção falharia por causa da Validation Rule).
- 💡 **Por que SOQL entre colchetes `[ ]`?** No Apex você escreve SOQL "inline" assim. O resultado vira lista (ou um registro, se atribuído a uma variável única).

```apex
for (Integer i = 0; i < 100; i++) {
    GoalItem__c item = new GoalItem__c(
        Goal__c = goals[0].Id,
        TargetValue__c = 5000,
        RealizedValue__c = 7500,   // >= meta → "atingida"
        GoalCommissionPercentage__c = 25.0,
        AchievedPercentage__c = null
    );
    goalItems.add(item);
}
```
- Cria **100 itens "meta atingida"** (realizado 7500 ≥ meta 5000). O loop só monta a lista; o `insert` acontece **uma vez no fim** (bulkificação).
- Criamos 3 cenários (atingida=100, não-atingida=50, realizado-nulo=50) = **200 itens** (necessário para o teste de massa).

```apex
// NOTE: cenário "TargetValue null" NÃO é criado de propósito —
// TargetValue__c é REQUIRED (desafio: "Valor meta *"), nunca pode ser nulo.
```
- 🐞 **Bug que corrigimos:** o teste original tentava inserir item com `TargetValue__c = null`, mas o campo é obrigatório → o banco rejeitava (`REQUIRED_FIELD_MISSING`) e derrubava TODOS os testes. Esse cenário é **impossível** justamente porque o campo é obrigatório (como o desafio pede).

### Estrutura de cada teste: **Arrange → Act → Assert**
Padrão universal de testes. Exemplo no `testGoalBatch_metaAtingida`:

**Arrange (preparar):**
```apex
List<GoalItem__c> items = [
    SELECT Id, AchievedPercentage__c, GoalCommissionPercentage__c
    FROM GoalItem__c
    WHERE TargetValue__c = 5000 AND RealizedValue__c = 7500
];
System.assertEquals(100, items.size(), 'Should have 100 items...');
```
- Busca os itens "atingidos" e confirma que são 100 (garante que o setup criou os dados certos).
- ⚠️ **Bug que corrigimos:** usamos `RealizedValue__c = 7500` (valor **literal**), NÃO `>= TargetValue__c`. **SOQL não permite comparar campo com campo.**

**Act (agir — executar o que queremos testar):**
```apex
Test.startTest();
Database.executeBatch(new GoalBatch(), 200);
Test.stopTest();
```
- `Test.startTest()` / `Test.stopTest()` → delimitam o "trecho sob teste". Dão **limites de governor frescos** e, crucialmente, **forçam o batch (assíncrono) a terminar** antes do `stopTest` retornar.

**Assert (verificar):**
```apex
for (GoalItem__c item : updatedItems) {
    Assert.areEqual(25.0, item.AchievedPercentage__c, '...');
}
```
- Reconsulta os itens (**depois** do batch) e verifica se a `% atingida` virou 25 (= % de comissão). `Assert.areEqual(esperado, real, mensagem)`.
- 💡 **Por que reconsultar?** A lista antiga está com os valores **antes** do batch. O batch alterou no banco; para ver o novo valor, precisa buscar de novo.

### Conceitos especiais nos outros testes

**`testGoalBatch_bulkProcessing`** — prova que aguenta volume:
```apex
Integer totalItems = [SELECT count() FROM GoalItem__c];
System.assert(totalItems >= 200, '...');
```
- `SELECT count()` conta registros. Confirma 200+ → valida o **propósito do Batch** (Governor Limits).

**`testGoalBatch_equalValues`** — caso de borda (realizado == meta):
```apex
delete [SELECT Id FROM GoalItem__c];
```
- ⚠️ Apaga os 200 itens do setup **antes**. Por quê? Em teste, o batch só pode rodar **1 lote**. Se somássemos 50 novos aos 200 do setup (=250) com lote de 200, daria 2 lotes → erro "No more than one executeBatch". Limpando, ficam só 50 → 1 lote.

**`testGoalBatchScheduler_execution`** — testa o agendamento:
```apex
String jobId = System.schedule(jobName, cronExpression, new GoalBatchScheduler());
CronTrigger cronTrigger = [
    SELECT Id, CronExpression, CronJobDetail.Name
    FROM CronTrigger WHERE Id = :jobId
];
Assert.areEqual(cronExpression, cronTrigger.CronExpression, '...');
```
- `System.schedule(...)` agenda o job e devolve um `jobId`.
- `CronTrigger` é a tabela do sistema que guarda jobs agendados. Verificamos que o cron salvo é o que pedimos.
- ⚠️ **Bug que corrigimos:** o SOQL pedia `CronJobDetailId`, mas o assert usava `CronJobDetail.Name`. Tem que pedir `CronJobDetail.Name` no SELECT.
- 💡 `:jobId` com dois-pontos = **bind variable** (injeta a variável Apex dentro do SOQL com segurança).

---

## 📌 Conceitos-chave para fixar

| Conceito | Resumo |
|---|---|
| **Batchable (start/execute/finish)** | Processa muitos registros em lotes, sem estourar limites |
| **Bulkificação** | Junta tudo numa lista e faz 1 DML (nunca DML dentro de loop) |
| **Arrange / Act / Assert** | Estrutura de todo teste |
| **Test.startTest/stopTest** | Limites frescos + força o assíncrono terminar |
| **SOQL não compara campo-a-campo** | Use valores literais ou bind variables (`:var`) |
| **Validation Rule = condição de ERRO** | `ISBLANK(campo)` bloqueia quando vazio |
| **Em teste, batch roda só 1 lote** | Total de registros ≤ tamanho do lote |
| **Lookup p/ User não pode ser "Required"** | Use Validation Rule com `ISBLANK` |

---

## 📖 Glossário rápido

- **Apex** → a linguagem de programação do Salesforce (parecida com Java).
- **Governor Limits** → limites que o Salesforce impõe por transação (nº de queries, DMLs, registros, CPU). Batch existe para contorná-los processando em lotes.
- **DML** → Data Manipulation Language: `insert`, `update`, `delete`, `upsert`.
- **SOQL** → Salesforce Object Query Language: a linguagem de consulta (`SELECT ... FROM ...`).
- **sObject** → "Salesforce Object": qualquer registro (Account, Goal__c, etc.). Tipo genérico.
- **Bind variable** → variável Apex usada dentro do SOQL com `:` (ex.: `WHERE Id = :jobId`).
- **QueryLocator** → ponteiro de consulta que aguenta milhões de registros (usado no `start` do batch).
- **Bulkificação** → escrever código que trata muitos registros de uma vez (listas + 1 DML), em vez de um por um.
- **Cron expression** → texto que define um agendamento recorrente.
- **Cobertura de código** → % das linhas do código "real" exercitadas pelos testes. Produção exige ≥ 75%.

---

## ✅ Resultado final do sistema
- **9 testes**, 100% passando.
- **100% de cobertura** em `GoalBatch` e `GoalBatchScheduler`.
- Atende todos os requisitos do desafio (objetos, campos, roll-up, fórmula, record types, batch, agendamento diário, obrigatoriedades).

> Documento gerado como material de estudo do projeto Sistema de Metas e Comissões.
