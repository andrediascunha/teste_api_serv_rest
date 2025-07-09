# Design pattern:
Para este projeto, foi escolhido trabalhar com keyword-driven dado o escopo reduzido da API com poucos end-points.
Dividindo a estrutura do projeto em duas partes principais: a escrita dos testes (utilizando Gherkin) e os recursos (responsáveis pela lógica de execução).
Essa organização torna os testes fáceis de ler e entender assim como complementar com novos testes.

# Ferramentas
Robot Framework + RequestsLibrary (Python Requests Library): Conforme escopo, era um desejo de uso do Robot para o desafio.
Quanto a RequestsLibrary, ela é uma biblioteca robusta, bem documentada para uso em requisições http e também, por já possuir conhecimento prévio em seu uso.

# Dependencias:
- Python 3.13.3 ou superior
  - https://www.python.org/downloads/
- Bibliotecas python em requirements.txt
  - robotframework>=7.3
  - robotframework-faker>=5.0.0
- Para instalar as bibliotecas python:
  - - pip install --upgrade pip
  - - pip install -r requirements.txt

# Como executar a suite de testes
- Necessário ter as dependências instaladas
- Abrir prompt de comando no diretório principal e digitar:
  - robot -d results/ tests/api_teste_server_rest.robot
  - Esse comando executará os testes e colocará os resultados no diretório results/

# Acessar os resultados
- os resultados estarão na pasta results/ definida conforme comando de execução
  - o arquivo log.html trará o resultado dos testes assim como o log de todos os steps executados
  - o arquivo report.html trará apenas o resultado final do testes
- Interpretação dos resultados
  - Na tabela de reultados é possível verificar quantos testes foram executados e desses, quantos passarm, reprovaram ou saltaram.
 
# Especificação dos testes
- Os testes estão especificados no arquivo "cenarios de teste API.pdf"

# Rodando em docker
- Faça um clone do repositório:
  -  git clone https://github.com/andrediascunha/teste_api_serv_rest.git

- Verifique se o make está instalado com o comando:
  - make --v
  - Para instalar o make, basta digitar o comando sudo apt install make

- Faça a build da imagem com:
  - make build

- Rode os testes com:
  - make test ROBOT_ARGS='-d /results tests/'
  - O make test executará o comando robot com os argumentos passados em ROBOT_ARGS, com isso você poderá passar qualquer argumento do Robot por esse parâmetro
  - Exemplo, para executar apenas o teste "Criar usuário comum valido":
      make test ROBOT_ARGS='--test "Criar usuário comum valido" -d /results tests/'
-  Verifique os resultados na pasta results

- Abrindo o container em modo interativo:
  - Caso queira abrir o container e interagir via terminal, basta digitar o comando "make up"