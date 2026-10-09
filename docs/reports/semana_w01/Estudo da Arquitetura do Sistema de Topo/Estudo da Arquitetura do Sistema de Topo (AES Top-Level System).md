

---

## 1. Visão Geral da Arquitetura

O **AES Top-Level System** integra o núcleo criptográfico AES com a infraestrutura de gestão de relógio, controlo de reset, interface de comunicação SPI e subsistema de memória. 

A arquitetura foi concebida de forma modular, permitindo a separação clara entre as rotinas de controlo/configuração (via SPI) e o fluxo de transferência de dados em larga escala (via subsistema de memória).

![alt text](<Pasted image 20261009105210.png>)

---

## 2. Interfaces Externas do Sistema

O sistema de topo expõe 4 interfaces externas principais:

| Interface            |     Tipo     | Descrição                                                                                                                                     |
| :------------------- | :----------: | :-------------------------------------------------------------------------------------------------------------------------------------------- |
| **`GLOBAL RESET`**   |   Entrada    | Sinal global de reinicialização do sistema, responsável por colocar todos os blocos num estado inicial conhecido.                             |
| **`clk from OSC`**   |   Entrada    | Sinal de relógio primário vindo do oscilador externo (OSC).                                                                                   |
| **`SPI IF`**         | Bidirecional | Interface física do barramento SPI (SCK, CS_N, MOSI/PICO, MISO/POCI) utilizada para envio de comandos, configurações e verificação de estado. |
| **`MEMORY DATA IF`** | Bidirecional | Interface de dados de alta velocidade dedicada à transferência dos blocos de dados de entrada (*plaintext*) e saída (*ciphertext*).           |

---

## 3. Descrição dos Blocos Internos

### 3.1. Módulo RESET (Reset Control)
* **Função:** Recebe o sinal externo `GLOBAL RESET` e distribui os sinais de reinicialização sincronizados para os restantes subsistemas (`PLL`, `SPI`, `AES` e `MEMORY`).
* **Objetivo:** Prevenir condições de corrida (*race conditions*) e garantir que o sistema só abandona o estado de reset após a estabilização dos sinais.

### 3.2. Módulo PLL (Phase-Locked Loop — Mocked)
* **Função:** Recebe o sinal de relógio do oscilador (`clk from OSC`) e gera as frequências internas de operação do acelerador.
* **Sinais de Interface:**
  * **`configuration bits from SPI`:** Permite ajustar os parâmetros de funcionamento da PLL via comandos no barramento SPI.
  * **`locked`:** Sinal de estado enviado para os blocos `SPI` e `AES`, indicando que o sinal de relógio está estável e pronto para ser utilizado.

### 3.3. Módulo SPI (Serial Peripheral Interface Slave)
* **Função:** Atua como a ponte de controlo entre o utilizador/host externo e o acelerador.
* **Interações Principais:**
  * Comunica com o exterior através da interface **`SPI IF.
  * Aguarda pela sinalização **`locked`** da PLL antes de validar as operações de leitura/escrita.
  * Envia bits de configuração para o módulo **`PLL.
  * Troca sinais de controlo e estado (**`control and status`**) com o núcleo **`AES`** (ex.: iniciar cifragem, indicar fim de processamento, leitura de erros).

### 3.4. Módulo AES (Core Criptográfico)
* **Função:** Motor de processamento do algoritmo AES-128.
* **Interações Principais:**
  * É ativado e monitorizado pelo módulo **`SPI`** através do barramento de controlo e estado (**`control and status`**).
  * Opera com base no sinal de relógio estabilizado (`locked`) e de reset.
  * Realiza a leitura dos blocos de entrada e a escrita dos resultados cifrados diretamente na memória de suporte **`MEMORY (model/mock).

### 3.5. Subsistema de Memória (`MEMORY model/mock` + `MEMORY / DATA System`)
* **`MEMORY (model/mock)`:** Buffer de memória interno que armazena temporariamente os blocos de 128 bits de dados a processar (*plaintext*) e já processados (*ciphertext*).
* **`MEMORY / DATA System`:** Módulo de gestão do fluxo de dados que faz a ponte entre a interface externa **`MEMORY DATA IF`** e o modelo de memória interno **`MEMORY.

---

## 4. Fluxo de Operação do Sistema

1. **Inicialização e Estabilização:**
   * O sinal `GLOBAL RESET` é ativado.
   * A `PLL` recebe o relógio do oscilador e, assim que estabiliza, ativa o sinal `locked` para a `SPI` e o `AES.

2. **Configuração via SPI:**
   * O Host envia comandos através da `SPI IF` para configurar parâmetros do sistema e preparar a operação criptográfica.

3. **Carga de Dados e Processamento:**
   * Os dados a serem cifrados dão entrada através da interface `MEMORY DATA IF` e são gravados na `MEMORY.
   * O bloco `SPI` envia o sinal de início de controlo para o bloco `AES.
   * O motor `AES` lê os dados da `MEMORY`, executa as 10 rodadas do algoritmo e grava os resultados de volta na `MEMORY.

4. **Conclusão:**
   * O bloco `AES` atualiza os registos de estado no módulo `SPI`.
   * O Host consulta o estado via `SPI IF` e extrai os dados cifrados através da interface `MEMORY DATA IF`.