# SKILL: Resumo de Testes Apex em Português

## Objetivo
Esta ferramenta serve para rodar testes de classes Apex no Salesforce, capturar o resultado técnico em inglês e gerar um resumo amigável e 100% em português para o desenvolvedor.

## Fluxo de Execução
Sempre que o usuário pedir para usar a skill "Resumo de Testes" ou indicar uma classe de teste, você deve seguir estes passos de forma autônoma:

1. **Rodar os Testes:** Execute o comando `sf apex run test --classnames <Nome_Da_Classe> --result-format human --wait 5` para rodar a classe de teste solicitada pelo usuário.
2. **Analisar o Resultado:** Leia o retorno do terminal (mesmo se der erro de código ou falha de teste).
3. **Gerar o Relatório em Português:** Crie um arquivo chamado `resultado-testes.md` na raiz do projeto com a seguinte estrutura:
   - **Status do Teste:** (Use 🟢 PASSOU ou 🔴 FALHOU em letras grandes)
   - **Classe Analisada:** (Nome da classe)
   - **Cobertura de Código:** (A porcentagem de linhas cobertas, se disponível)
   - **Resumo do que aconteceu:** (Explique em português claro o que o teste validou ou, se falhou, explique exatamente qual erro aconteceu e em qual linha, traduzindo o erro técnico).
