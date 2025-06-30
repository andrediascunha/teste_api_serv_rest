*** Settings ***
Resource  ../resources/api_teste_server_rest.resource

Suite Setup     Inicializar ambiente de teste         # Inicializa o ambiente de teste
Suite Teardown  Finalizar ambiente de teste           # Finaliza o ambiente de testes

*** Variables ***

${MESSAGE_USER_CREATED}           Cadastro realizado com sucesso
${MESSAGE_USER_DUPLICATED}        Este email já está sendo usado
${MESSAGE_USER_WRONG_EMAIL}       email deve ser um email válido
${MESSAGE_USER_EDITED}            Registro alterado com sucesso
${MESSAGE_USER_DELETED}           Registro excluído com sucesso
${MESSAGE_USER_NOT_DELETED}       Não é permitido excluir usuário com carrinho cadastrado

${STATUS_CODE_OK}                 200
${STATUS_CODE_CREATED}            201
${STATUS_CODE_BAD_REQUEST}        400
${STATUS_CODE_BAD_UNAUTHORIZED}   401

*** Test Cases ***

Criar usuário comum valido
    Given crio um novo usuario valido
    When cadastro o novo usuario como    "nao_admin"
    Then a resposta deve conter    status_code=${STATUS_CODE_CREATED}    message=${MESSAGE_USER_CREATED}
    When consulto os dados do usuario
    Then o body deve conter as informacoes do usuario

Criar usuário administrador valido
    Given crio um novo usuario valido
    When cadastro o novo usuario como    "admin"
    Then a resposta deve conter    status_code=${STATUS_CODE_CREATED}    message=${MESSAGE_USER_CREATED}
    When consulto os dados do usuario
    Then o body deve conter as informacoes do usuario

Criar usuário duplicado
    Given crio um usuario duplicado
    When cadastro o novo usuario como    "admin"
    Then a resposta deve conter    status_code=${STATUS_CODE_BAD_REQUEST}    message=${MESSAGE_USER_DUPLICATED}

Criar usuário invalido
    Given crio um novo usuario invalido
    When cadastro o novo usuario como    "admin"
    Then a resposta deve conter    status_code=${STATUS_CODE_BAD_REQUEST}    message=${MESSAGE_USER_WRONG_EMAIL}

Editar usuário
    Given pego os dados de um usuario existente
    When altero o usuario
    Then a resposta deve conter    status_code=${STATUS_CODE_OK}    message=${MESSAGE_USER_EDITED}

Editar usuário sem dados
    Given pego os dados de um usuario existente
    When altero o usuario sem dados no body
    Then o body deve listar as informacoes ausentes

Editar usuário para email em uso
    Given pego os dados de um usuario existente
    When altero o usuario para email em uso
    Then a resposta deve conter    status_code=${STATUS_CODE_BAD_REQUEST}    message=${MESSAGE_USER_DUPLICATED}

Excluir usuário sem carrinho de compras
    Given excluo o usuario existente
    Then a resposta deve conter    status_code=${STATUS_CODE_OK}    message=${MESSAGE_USER_DELETED}

Excluir usuário com carrinho de compras
    Given estou logado no sistema
    When cadastro um carrinho de compra
    Then a resposta deve conter    status_code=${STATUS_CODE_CREATED}    message=${MESSAGE_USER_CREATED}
    When excluo o usuario existente
    Then a resposta deve conter    status_code=${STATUS_CODE_BAD_REQUEST}    message=${MESSAGE_USER_NOT_DELETED}