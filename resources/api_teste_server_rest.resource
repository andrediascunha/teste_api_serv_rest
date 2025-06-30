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
    @{LIST} =    Create List
    Set Suite Variable    @{ID_USERS_LIST}    @{LIST}

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

    ${USERNAME}=    FakerLibrary.Word
    Set Global Variable    ${USERNAME}

    IF    ${valid}
        ${EMAIL}=    Set Variable    ${USERNAME}@${USERNAME}.com
    ELSE
        ${EMAIL}=    FakerLibrary.Word
    END
    Set Global Variable    ${EMAIL}

    ${PASSWORD}=    FakerLibrary.Word
    Set Global Variable    ${PASSWORD}

Criar Sessao nao autenticada
    ${headers}  Create Dictionary  accept=application/json  Content-Type=application/json
    Create Session    alias=UnAuthenticated    url=${URL}   headers=${headers}  verify=True

Criar Sessao autenticada

    # Pega o usuario de teste da suite para criar sessao autenticada
    ${suite_test_user_id} =    Get From List    ${ID_USERS_LIST}    0
    ${answer}  GET On Session  alias=UnAuthenticated  url=/usuarios/${suite_test_user_id}  expected_status=200
    Set Global Variable    ${ID_USUARIO}  ${suite_test_user_id}
    Set Global Variable    ${EMAIL}       ${answer.json()['email']}
    Set Global Variable    ${USERNAME}    ${answer.json()['nome']}
    Set Global Variable    ${PASSWORD}    ${answer.json()['password']}

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
    ${user_id_var}=    Get Variable Value    ${ID_USUARIO}
    IF  $user_id_var == None
        Crio um novo usuario valido
        Cadastro o novo usuario como    "admin"
    END
    

Cadastro o novo usuario como
    [Arguments]    ${user_type}
    IF  ${user_type} == "admin"
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
    ${answer}  GET On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  expected_status=200
    Set Test Variable     ${QUERY_USER_ANSWER}  ${answer.json()}

O body deve conter as informacoes do usuario
    &{expected_userdata}=    Create Dictionary
    ...    nome=${USERNAME}
    ...    email=${EMAIL}
    ...    password=${PASSWORD}
    ...    administrador=${ADMINISTRATOR}

    FOR    ${CHAVE}    IN    @{expected_userdata.keys()}
        Dictionary Should Contain Item    ${QUERY_USER_ANSWER}    ${CHAVE}    ${expected_userdata['${CHAVE}']}
    END

Estou logado no sistema
    Criar Sessao autenticada

Pego os dados de um usuario existente
    consulto os dados do usuario

Altero o usuario
    ${new_name}=    FakerLibrary.Word
    ${QUERY_USER_ANSWER}=    Set To Dictionary    ${QUERY_USER_ANSWER}    nome=${new_name}
    Remove From Dictionary    ${QUERY_USER_ANSWER}    _id
    ${answer}  PUT On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  json=${QUERY_USER_ANSWER}  expected_status=200

    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}

Altero o usuario sem dados no body
    ${answer}  PUT On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  expected_status=any

    Set Test Variable    ${STATUS_CODE_RESPONSE}   ${answer.status_code}
    Set Test Variable    ${BODDY_RESPONSE}        ${answer.json()}
    
O body deve listar as informacoes ausentes
    &{expected_data}=    Create Dictionary
    ...    nome=nome é obrigatório
	...    email=email é obrigatório
    ...    password=password é obrigatório
	...    administrador=administrador é obrigatório
    
    FOR    ${CHAVE}    IN    @{expected_data.keys()}
        Dictionary Should Contain Item    ${BODDY_RESPONSE}    ${CHAVE}    ${expected_data['${CHAVE}']}
    END

Altero o usuario para email em uso
    Consulto os dados do usuario
    
    # Armazena email do usuario atual
    ${current_user_email}    Get From Dictionary    ${QUERY_USER_ANSWER}    email

    # Cadastra um novo usuário para tentar editar com email em uso
    Crio um novo usuario valido
    Cadastro o novo usuario como    "admin"

    # Pega os dados do usurio autal e altera para email em uso
    Consulto os dados do usuario
    ${QUERY_USER_ANSWER}=    Set To Dictionary    ${QUERY_USER_ANSWER}    email=${current_user_email}
    
    # Remode a propriedade _id do body pois o endpoint não aceita
    Remove From Dictionary    ${QUERY_USER_ANSWER}    _id
    
    # Envia alteração para API
    ${answer}  PUT On Session  alias=UnAuthenticated  url=/usuarios/${ID_USUARIO}  json=${QUERY_USER_ANSWER}  expected_status=any
    
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