# SKILL: Criar Botão Customizado no Salesforce

## Descrição
Esta ferramenta automatiza a criação de botões de URL customizados (Web Links) em qualquer objeto do Salesforce. Ela gera a estrutura de metadados XML correta, injeta o botão automaticamente no Layout de Página e executa o deploy para a Org conectada.

## Requisitos e Parâmetros
Sempre que o usuário solicitar a criação de um botão ou link de atalho, identifique:
- **Objeto Alvo:** (Ex: Lead, Account, Contact)
- **Label do Botão:** O nome visível na tela (Ex: Ver LinkedIn)
- **URL Dinâmica:** O link de destino usando campos do objeto (Ex: {!Lead.Company})

## Fluxo de Execução Autônomo

1. **Gerar Metadados do WebLink:** Criar o arquivo XML do botão na pasta correta do objeto:
   - Caminho: `force-app/main/default/objects/<Objeto>/webLinks/<Nome_do_Botao>.webLink-meta.xml`
   - Use esta estrutura base:
     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <WebLink xmlns="http://soap.sforce.com/2006/04/metadata">
         <availability>online</availability>
         <displayType>button</displayType>
         <encodingKey>UTF-8</encodingKey>
         <hasMenubar>false</hasMenubar>
         <hasScrollbars>true</hasScrollbars>
         <hasToolbar>false</hasToolbar>
         <height>600</height>
         <isResizable>true</isResizable>
         <linkType>url</linkType>
         <masterLabel>NOME_DO_BOTAO</masterLabel>
         <openType>newWindow</openType>
         <position>none</position>
         <protected>false</protected>
         <showsLocation>false</showsLocation>
         <showsStatus>false</showsStatus>
         <url>URL_DINAMICA</url>
     </WebLink>
     ```

2. **Injetar no Layout de Página:** Abrir o arquivo de layout do objeto (Ex: `force-app/main/default/layouts/Lead-Lead_Layout.layout-meta.xml`) e incluir o nome do botão na tag `<customButtons>`.

3. **Deploy Automático:** Executar o comando `sf project deploy start` no terminal para aplicar as mudanças na Org.

4. **Feedback:** Confirmar a criação com um relatório em português indicando onde o botão foi inserido e como testar.
