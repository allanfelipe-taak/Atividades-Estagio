

//



Taak
Desafio em tempo real








Introdução
	Vamos iniciar agora nosso desafio em tempo real, para realizar este desafio com exatidão, certifique-se de que você está em um ambiente tranquilo, e que você se sinta confortável para desenvolver uma lógica de desenvolvimento Apex.
Regras
Você tem um total de 1h para realização;
É possível utilizar o google para pesquisar e tirar dúvidas;
Pedimos para que deixe a tela do Computador aberta para certificarmos que você está realizando o desenvolvimento;
Não poderá utilizar nenhum modelo de IA para criar a sua lógica.
Habilidades avaliadas
	Para este desafio queremos avaliar o maior número de habilidades técnicas possíveis, ou seja, trigger, integração, batch, e etc. Queremos certificar que você conhece essas ferramentas, e sabe utilizá-las da melhor forma, use o seu tempo a seu favor e nos entregue o melhor que você pode.

Modelagem
Crie o seguinte objeto customizado: DevUser__c
Crie os seguintes campos personalizados:

Nome: Login
Nome de api: Login__c
Tipo: Texto(255)


Nome: Id Externo
Nome de api: ExternalId__c
Tipo: Número

	3.3	Nome: Tipo
		Nome de api: Type__c
		Tipo: Texto (255)
	3.5 	
		Nome: Bio
		Nome de api: Bio__c
		Tipo:  Texto (255)


Desafio
	
De acordo com o último documento que foi enviado, você terá que utilizar a api pública de usuários do gitHub para criar uma lógica que toda vez que for inserido um registro dentro do objeto DevUser__c com o campo Login__c preenchido, for feita uma requisição REST API, para atualizar os outros campos de retorno do json com os campos do Salesforce respectivamente:

O usuário deverá ser cadastrado apenas com Login__c, e o restante das informações deverá ser coletada do serviço disponibilizado pelo GitHub.

	id => ExternalId__c
	type => Type__c
bio => Bio__c

Só será necessário uma nova requisição dos campos quando for atualizado o campo Login__c.
Observação: deve ser possível inserir uma carga de N registros (quantos forem necessários).
API utilizada
https://api.github.com/users/{user}
ex: https://api.github.com/users/octoca

