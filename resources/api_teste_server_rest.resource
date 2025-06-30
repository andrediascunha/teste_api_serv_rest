*** Settings ***

Library      RequestsLibrary
Library      FakerLibrary
Library      Collections

*** Variables ***
${URL}        https://serverest.dev 

*** Keywords ***

###    Keywords auxiliares    ###

Inicializar ambiente de teste
    # Inicializa lista para armazenar IDs de usuários criados no teste
    @{lista} =    Create List
    Set Suite Variable    @{ID_USERS_LIST}    @{lista}

    # Inicializa um usuário válido do tipo Admin
    Criar credenciais    valid=${True}
    Criar Sessao nao autenticada
    Cadastro o novo usuario como    "admin"
    

Finalizar ambiente de teste
    # Exclui o carrinho para permitir exclusão do usuário - a medida que outros testes sejam criados, isso poderá mudar
    Run Keyword And Ignore Error    Excluir carrinho

    # Percorre a lista de usuarios criados no teste e os exclui
    FOR    ${id}    IN    @{ID_USERS_LIST}
        Run Keyword And Ignore Error    DELETE On Session      # Para diminuir o controle quanto a lista de IDs (remover IDs), a keyword ignorará erro
        ...    alias=UnAuthenticated
        ...    url=/usuarios/${id}
        ...    expected_status=200
    END

Criar credenciais
    [Arguments]    ${valid}
    IF    ${valid}
        ${EMAIL}       FakerLibrary.Email
    ELSE
        ${EMAIL}       FakerLibrary.Name
    END
    Set Global Variable    ${EMAIL}
    ${USERNAME}    FakerLibrary.User Name
    Set Global Variable    ${USERNAME}
    ${PASSWORD}    FakerLibrary.Password
    Set Global Variable    ${PASSWORD}

Criar Sessao nao autenticada
    ${headers}  Create Dictionary  accept=application/json  Content-Type=application/json
    Create Session    alias=UnAuthenticated    url=${URL}   headers=${headers}  verify=True

Criar Sessao autenticada

    # Pega o usuario de teste da suite para criar sessao autenticada
    ${ID_USUARIO_SUITE_TEST} =    Get From List    ${ID_USERS_LIST}    0
    ${resposta_consulta}  GET On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO_SUITE_TEST}  expected_status=200
    Set Global Variable    ${ID_USUARIO}  ${ID_USUARIO_SUITE_TEST}
    Set Global Variable    ${EMAIL}       ${resposta_consulta.json()['email']}
    Set Global Variable    ${USERNAME}    ${resposta_consulta.json()['nome']}
    Set Global Variable    ${PASSWORD}    ${resposta_consulta.json()['password']}

    ${body}  Create Dictionary
    ...      email=${EMAIL}
    ...      password=${PASSWORD}

    ${answer}  POST On Session  alias=UnAuthenticated  url=/login  json=${body}  expected_status=any

    ${token}    Get From Dictionary    ${answer.json()}    authorization

    ${headers}  Create Dictionary  accept=application/json  Content-Type=application/json  Authorization=${token}
    Create Session    alias=Authenticated    url=${URL}   headers=${headers}  verify=True

Excluir carrinho
    ${answer}  DELETE On Session  alias=Authenticated  url=/carrinhos/cancelar-compra  expected_status=200

###    Keywords do teste    ###
Crio um novo usuario valido
    Criar credenciais    valid=${True}

Crio um novo usuario invalido
    Criar credenciais    valid=${FALSE}

Crio um usuario duplicado
    # Verifica se um usuário já está criado na suite e cria caso não exista
    ${VARIAVEL_ID_USUARIO}=    Get Variable Value    ${ID_USUARIO}
    IF    $VARIAVEL_ID_USUARIO == None
        Crio um novo usuario valido
        Cadastro o novo usuario como    "admin"
    END
    

Cadastro o novo usuario como
    [Arguments]    ${USER_TYPE}
    IF  ${USER_TYPE} == "admin"
        Set Global Variable  ${ADMINISTRATOR}    true
    ELSE
        Set Global Variable  ${ADMINISTRATOR}    false
    END
    ${body}  Create Dictionary
    ...      nome=${USERNAME}
    ...      email=${EMAIL}
    ...      password=${PASSWORD}
    ...      administrador=${ADMINISTRATOR}   

    ${answer}  POST On Session  alias=UnAuthenticated  url=/usuarios  json=${body}  expected_status=any

    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}

    IF  ${answer.status_code} == 201
        Set Global Variable    ${ID_USUARIO}  ${answer.json()["_id"]}
        Append To List  ${ID_USERS_LIST}  ${answer.json()["_id"]}
    END

A resposta deve conter
    [Arguments]    ${status_code}   ${message}
    # Verifica o status code da requisição
    Should Be Equal As Integers  ${STATUS_CODE_RESPONSE}  ${status_code}
    # Verifica a mensagem retornada
    Dictionary Should Contain Value    ${BODDY_RESPONSE}    ${message}

Consulto os dados do usuario
    # Busca dados do usuário por ID
    ${resposta_consulta}  GET On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  expected_status=200
    Set Test Variable     ${RESP_CONSULTA_USUARIO}  ${resposta_consulta.json()}

O body deve conter as informacoes do usuario
    &{DADOS_USUARIO_ESPERADOS}=    Create Dictionary
    ...    nome=${USERNAME}
    ...    email=${EMAIL}
    ...    password=${PASSWORD}
    ...    administrador=${ADMINISTRATOR}

    FOR    ${CHAVE}    IN    @{DADOS_USUARIO_ESPERADOS.keys()}
        Dictionary Should Contain Item    ${RESP_CONSULTA_USUARIO}    ${CHAVE}    ${DADOS_USUARIO_ESPERADOS['${CHAVE}']}
    END

Estou logado no sistema
    Criar Sessao autenticada

Pego os dados de um usuario existente
    consulto os dados do usuario

Altero o usuario
    ${NEW_NAME}    FakerLibrary.Name
    ${RESP_CONSULTA_USUARIO}=    Set To Dictionary    ${RESP_CONSULTA_USUARIO}    nome=${NEW_NAME}
    Remove From Dictionary    ${RESP_CONSULTA_USUARIO}    _id
    ${answer}  PUT On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  json=${RESP_CONSULTA_USUARIO}  expected_status=200

    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}

Altero o usuario sem dados no body
    ${answer}  PUT On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  expected_status=any

    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}
    
O body deve listar as informacoes ausentes
    &{DADOS_ESPERADOS}=    Create Dictionary
    ...    nome=nome é obrigatório
	...    email=email é obrigatório
    ...    password=password é obrigatório
	...    administrador=administrador é obrigatório
    
    FOR    ${CHAVE}    IN    @{DADOS_ESPERADOS.keys()}
        Dictionary Should Contain Item    ${BODDY_RESPONSE}    ${CHAVE}    ${DADOS_ESPERADOS['${CHAVE}']}
    END

Altero o usuario para email em uso
    Consulto os dados do usuario
    
    # Armazena email do usuario atual
    ${CURRENT_USER_EMAIL}    Get From Dictionary    ${RESP_CONSULTA_USUARIO}    email

    # Cadastra um novo usuário para tentar editar com email em uso
    Crio um novo usuario valido
    Cadastro o novo usuario como    "admin"

    # Pega os dados do usurio autal e altera para email em uso
    Consulto os dados do usuario
    ${RESP_CONSULTA_USUARIO}=    Set To Dictionary    ${RESP_CONSULTA_USUARIO}    email=${CURRENT_USER_EMAIL}
    
    # Remode a propriedade _id do body pois o endpoint não aceita
    Remove From Dictionary    ${RESP_CONSULTA_USUARIO}    _id
    
    # Envia alteração para API
    ${answer}  PUT On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  json=${RESP_CONSULTA_USUARIO}  expected_status=any
    
    # Seta variáveis do teste
    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}


Excluo o usuario existente
    ${answer}  DELETE On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  expected_status=any

    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}

Cadastro um carrinho de compra
    
    # Pegar um produto com saldo para colocar no carrinho
    ${answer}  Get On Session  alias=Authenticated  url=/produtos  expected_status=200
    ${products} =    Get From Dictionary    ${answer.json()}    produtos
    FOR    ${product}    IN    @{products}
        ${qtty} =    Get From Dictionary    ${product}    quantidade
        Run Keyword If    ${qtty} > 0    Set Test Variable    ${selected_product}    ${product}
        Exit For Loop If    ${qtty} > 0
    END
    
    # Criar carrinho de compra
    ${body} =    Evaluate  {"produtos": [{"idProduto": "${product['_id']}", "quantidade": 1}]}  json
     ${answer}  Post On Session  alias=Authenticated  url=/carrinhos  json=${body}  expected_status=any

    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}