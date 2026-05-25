# Sequência de Execução Estruturada

## Contexto
- Refactoring português → inglês está 95% completo
- Destructive deploy falhou com 11 erros
- Código está 100% correto, problema está na org

## Execução (Ordem Obrigatória)

### FASE 1: DIAGNÓSTICO (5-10 min)

#### 1.1 Verificar Dependências via CLI
```bash
cd /Users/grupotaak/Documents/ProjetoPricing
sf project retrieve \
  --target-org prod \
  --metadata "CustomObject:Frete__c" \
  --single-package \
  --output-dir ./retrieve-dependencies
```

**Saída esperada:** Mensagem de erro indicando bloqueadores

#### 1.2 Registrar Bloqueadores Encontrados
Exemplo de bloqueadores possíveis:
- Flow com nome X referencia Frete__c
- Validation Rule em Frete__c é usada em outro lugar
- Permission Set tem field-level security em Frete__c

---

### FASE 2: CORREÇÃO DE DEPENDÊNCIAS (30 min - 1 hora)

#### 2.1 Se Encontrou Flows
**Responsável:** Admin Agent ou Developer Agent

Cada Flow encontrado precisa:
1. Ser deletado OU
2. Ser migrado para usar Freight__c

#### 2.2 Se Encontrou Validation Rules
**Responsável:** Admin Agent

Cada Validation Rule:
1. Deletar (se não usada) OU
2. Migrar para novo objeto

#### 2.3 Se Encontrou Permission Sets
**Responsável:** Admin Agent

1. Remover field-level security dos campos antigos
2. Não é necessário adicionar aos novos (herança automática)

---

### FASE 3: DEPLOY REGULAR (10-15 min)

#### 3.1 Preparar Deploy
```bash
cd /Users/grupotaak/Documents/ProjetoPricing

# Verificar status
sf project status --target-org prod

# Deploy APENAS código (sem destructive ainda)
sf project deploy start \
  --target-org prod \
  --manifest force-app/main/default \
  --wait 30 \
  --verbose
```

**Checklist de Deploy:**
- ✅ FreightHandler.cls
- ✅ MarginHandler.cls
- ✅ TaxHandler.cls
- ✅ FreightTrigger.trigger
- ✅ MarginTrigger.trigger
- ✅ TaxTrigger.trigger
- ✅ Agro_implements.app-meta.xml
- ✅ Layouts renomeados
- ✅ CustomTabs
- ✅ LWC recalculatePricing
- ✅ PricingService.cls
- ✅ PricingSelector.cls
- ✅ TriggerMaestro.cls

---

### FASE 4: VALIDAÇÃO DE FUNCIONALIDADE (15 min)

#### 4.1 Testar Triggers
1. Na org (sandbox/prod):
   - Ir para aba "Freight__c"
   - Criar novo registro
   - Verificar que FreightTrigger disparou (debug logs)
   - Verificar que FreightHandler.beforeInsert foi chamado

2. Repetir para Margin__c e Tax__c

#### 4.2 Testar Pricing Engine
1. Na org:
   - Ir para um Order
   - Criar um OrderItem
   - Verificar que preço foi calculado
   - Verificar debug logs mostrando:
     - MARGEM buscada
     - FRETE buscado
     - IMPOSTO buscado

#### 4.3 Testar Dados Antigos
1. Verificar se ainda há registros em Frete__c, Margem__c, Imposto__c
2. Se houver, migrar para novos objetos ANTES de deletar

---

### FASE 5: DESTRUCTIVE DEPLOY (10-15 min)

#### 5.1 Preparar Destructive
```bash
cd /Users/grupotaak/Documents/ProjetoPricing/destructiveChanges

# Revisar o que será deletado
cat destructiveChanges.xml
```

**Deve conter:**
```xml
<members>Frete__c</members>
<members>Margem__c</members>
<members>Imposto__c</members>
... outros 8 objetos
```

#### 5.2 Executar Destructive Deploy
```bash
cd /Users/grupotaak/Documents/ProjetoPricing

sf project deploy start \
  --target-org prod \
  --manifest destructiveChanges/package.xml \
  --post-destructive-changes destructiveChanges/destructiveChanges.xml \
  --wait 30 \
  --verbose
```

**Checklist antes de executar:**
- ✅ Nenhum Apex referencia Frete__c, Margem__c, Imposto__c
- ✅ Nenhum Flow usa objetos antigos
- ✅ Nenhum Validation Rule usa objetos antigos
- ✅ Nenhum Permission Set restringe campos antigos
- ✅ Nenhum dado importante ainda está nos objetos antigos
- ✅ Testes passaram na FASE 4

---

### FASE 6: VALIDAÇÃO FINAL (10 min)

#### 6.1 Confirmar Deletions
```bash
# Tentar fazer retrieve de objeto deletado (deve falhar)
sf project retrieve \
  --target-org prod \
  --metadata "CustomObject:Frete__c" \
  --single-package
```

**Saída esperada:** Erro "metadata not found"

#### 6.2 Confirmar Novos Objetos Existem
```bash
# Deve funcionar
sf project retrieve \
  --target-org prod \
  --metadata "CustomObject:Freight__c,Margin__c,Tax__c" \
  --single-package
```

#### 6.3 Smoke Test Completo
1. Ir para Order
2. Adicionar OrderItem
3. Verificar que preço foi calculado
4. Verificar debug logs
5. Tudo deve funcionar normalmente

---

### FASE 7: GIT COMMIT (5 min)

#### 7.1 Commit as Alterações
```bash
cd /Users/grupotaak/Documents/ProjetoPricing

git add -A
git status

git commit -m "Refactoring completo: português → inglês (100%)

- Objetos renomeados: Frete→Freight, Margem→Margin, Imposto→Tax
- Classes renomeadas: FreteHandler→FreightHandler, etc
- Triggers atualizados para usar novos objetos
- Aplicação, layouts e tabs atualizados
- Código de pricing engine validado e funcionando
- Objetos antigos deletados da org via destructiveChanges

Co-Authored-By: Claude Code <noreply@anthropic.com>"

git push origin feature/ProjetoPricing
```

---

## TEMPOS ESTIMADOS

| Fase | Descrição | Tempo |
|------|-----------|-------|
| 1 | Diagnóstico de bloqueadores | 5-10 min |
| 2 | Corrigir dependências na org | 30 min - 1 hora |
| 3 | Deploy regular do código | 10-15 min |
| 4 | Validar funcionalidade | 15 min |
| 5 | Destructive deploy | 10-15 min |
| 6 | Validação final | 10 min |
| 7 | Git commit e push | 5 min |
| **TOTAL** | | **1.5 - 2.5 horas** |

---

## ABORTES ESPERADOS (ROLLBACK)

Se em qualquer ponto algo falhar:

### Se falhar em FASE 1 (Diagnóstico)
- Não há impacto
- Revisar erro e documentar
- Nada foi alterado

### Se falhar em FASE 3 (Deploy Regular)
```bash
# Rollback automático (org não muda)
# Revisar erro de deployment
# Corrigir código
# Re-tentar deployment
```

### Se falhar em FASE 5 (Destructive)
```bash
# Org fica parcialmente em estado intermediário
# Fazer rollback manual:
# 1. Deploy dos objetos antigos de volta
# 2. Migrar dados de novos para antigos (se necessário)
# 3. Recomençar do PASSO 2
```

---

## DOCUMENTAÇÃO APÓS CONCLUSÃO

Criar arquivo `/docs/refactoring-português-inglês.md` com:
- O que foi feito
- Porque foi feito
- Como foi feito
- Quem fez
- Quando foi feito
- Lições aprendidas

---

## CONTATOS DE SUPORTE

Se travado:
1. Verificar logs em `/Users/grupotaak/.sfdx/tools/debug/logs/`
2. Procurar por "Deploy Error" ou "Unable to delete"
3. Documentar o erro específico
4. Escalcar para código específico caso necessário
