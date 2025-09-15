

## Configuração do Ambiente de Desenvolvimento

Para executar os notebooks e interagir com o BigQuery a partir do ambiente de desenvolvimento local, siga os passos abaixo.

### 1\. Pré-requisitos

  * Python 3.8 ou superior instalado.
  * Acesso ao projeto no Google Cloud com as devidas permissões.

### 2\. Passos para Configuração

1.  **Clone o repositório:**

    ```bash
    git clone <URL_DO_SEU_REPOSITORIO>
    cd CLASSIFICADOR
    ```

2.  **Crie o Ambiente Virtual:**
    Este comando cria uma pasta `env/` local que conterá o Python e as bibliotecas isoladas para este projeto.

    ```bash
    python -m venv env
    ```

3.  **Ative o Ambiente Virtual:**
    Você precisa ativar o ambiente toda vez que for trabalhar no projeto em um novo terminal.

      * **No Windows (PowerShell):**
        ```powershell
        .\env\Scripts\Activate.ps1
        ```
      * **No macOS e Linux:**
        ```bash
        source env/bin/activate
        ```

    Após a ativação, você verá `(env)` no início da linha do seu terminal.

4.  **Instale as Dependências:**
    Este comando lê o arquivo `requirements.txt` e baixa todas as bibliotecas Python necessárias.

    ```bash
    pip install -r requirements.txt
    ```

5.  **Configure a Autenticação (keyfile.json):**
    O arquivo `keyfile.json` contém credenciais de acesso e **nunca deve ser enviado para o repositório**.

      * Faça o download do seu arquivo de chave de serviço a partir do Google Cloud Console.
      * Salve-o na raiz do projeto com o nome `keyfile.json`.
      * O arquivo `.gitignore` já está configurado para impedir o envio deste arquivo.

Pronto\! Agora seu ambiente está configurado para rodar os notebooks e scripts do diretório `dev/`.

-----

