
### 1. Sumário Executivo & Propósito
A Serial Peripheral Interface (SPI) é um barramento de comunicação síncrona projetado para operar em modo _full-duplex_, permitindo a transferência simultânea e contínua de dados entre dispositivos. Este relatório detalha a arquitetura física, o modelo de funcionamento circular e as características de implementação em hardware do protocolo SPI, evidenciando como ele gerencia a comunicação em alta velocidade entre um dispositivo Controlador e um ou mais Periféricos.
### 2. Histórico e Contexto da Padronização
- **Origem e Evolução:** Diferente de protocolos assíncronos (como a UART) que exigem configurações prévias de velocidade (baud rate) e a injeção de bits estruturais de início e parada para manter o alinhamento de dados, o SPI foi desenvolvido para ser estritamente síncrono. Historicamente, os dispositivos eram chamados de Mestre e Escravo, terminologia que foi atualizada para Controlador e Periférico em implementações modernas.
- **Adoção:** Devido ao seu _overhead_ mínimo e eficiência, o SPI é o padrão da indústria para aplicações de alta taxa de dados a curtas distâncias. É amplamente utilizado em sistemas embarcados e na comunicação entre processadores principais e módulos criptográficos de alta segurança, como o chip TPM (Trusted Platform Module) presente nas placas-mãe modernas.
### 3. Arquitetura Física e Nomenclatura de Pinos

O SPI utiliza uma arquitetura básica composta por 4 fios dedicados, diferenciando-se de barramentos de dois fios. Para que a comunicação funcione, os componentes são conectados através das seguintes linhas:

- **SCK (Serial Clock):** Linha dedicada exclusivamente para ditar o ritmo da comunicação. Carrega o sinal de relógio gerado pelo Controlador, sincronizando o momento exato em que cada bit é lido ou escrito na linha de dados.
    
- **PICO / SDO (Peripheral In, Controller Out):** Linha física por onde os dados saem do Controlador e entram no Periférico (anteriormente conhecida como MOSI).
    
- **POCI / SDI (Peripheral Out, Controller In):** Linha física por onde os dados já processados saem do Periférico e entram no Controlador (anteriormente conhecida como MISO).
    
- **CS (Chip Select):** Pino utilizado pelo Controlador para "acordar" o chip periférico e iniciar a transação. Geralmente é ativo em nível lógico baixo.

![!\[\[Pasted image 20261008110322.png|398\]\]](<Pasted image 20261008110322.png>)

### 4. Modelo de Funcionamento Interno

O núcleo do processamento do SPI baseia-se na troca de dados através de registradores de deslocamento (shift registers) interligados, formando um anel virtual entre o Controlador e o Periférico.

![!\[\[Pasted image 20261008124603.png\]\]](<Pasted image 20261008124603.png>)
# 4.1. As Quatro Etapas Operacionais por Transação

Em cada transação de comunicação, os dispositivos passam pelos seguintes estágios sequenciais:

1. **Seleção:** O processo é iniciado quando o Controlador altera o pino CS do periférico desejado para nível lógico baixo.
    
2. **Sincronização:** O Controlador passa a gerar os pulsos de clock através do pino SCK. Este sincronismo garantido por hardware é o que dispensa o protocolo de gastar tempo com marcadores de início e fim.
    
3. **Troca Circular de Bits:** A cada pulso e ciclo de clock, ocorre uma troca simultânea. O Controlador envia instruções ou dados em texto plano pela linha PICO e, no exato instante, recebe os dados de volta do Periférico pela linha POCI. Mesmo que o Controlador só queira realizar uma leitura, ele precisa enviar pulsos (geralmente enviando zeros lógicos) para forçar o periférico a transmitir a resposta.
    
4. **Conclusão:** Após a troca dos ciclos necessários (geralmente 8 ciclos para completar um byte), o Controlador interrompe a geração de clock no SCK e puxa a linha CS de volta para o nível lógico alto, encerrando a conexão.

### 4.2. Modos de Operação (CPOL e CPHA)
O protocolo SPI define 4 modos operacionais baseados na combinação da polaridade do clock (CPOL) e na fase de amostragem (CPHA):

| Modo | CPOL | CPHA | Estado de Repouso do Clock | Borda de Amostragem dos Dados |
| :---: | :---: | :---: | :---: | :---: |
| **Modo 0** | 0 | 0 | Nível Baixo (0) | Subida (1ª borda) |
| **Modo 1** | 0 | 1 | Nível Baixo (0) | Descida (2ª borda) |
| **Modo 2** | 1 | 0 | Nível Alto (1) | Descida (1ª borda) |
| **Modo 3** | 1 | 1 | Nível Alto (1) | Subida (2ª borda) |

*Para este projeto de acelerador, o modo padrão prioritário de operação será o **Modo 0** (CPOL=0, CPHA=0) ou **Modo 3** (CPOL=1, CPHA=1).*

### 5. Resumo de Vantagens e Limitações

A simplicidade física do SPI define suas características operacionais críticas:

- **Vantagens (Velocidade e Eficiência):** Por possuir uma linha de sincronismo por hardware (SCK) e não perder banda útil transmitindo bits estruturais, o SPI atinge frequências altíssimas, frequentemente acima de 10 MHz. O sistema _full-duplex_ e a simplicidade de não precisar processar endereços lógicos por software o tornam excepcionalmente rápido.
    
- **Limitações (Comunicação Cega):** A principal desvantagem arquitetônica é que o SPI é uma "comunicação cega". O protocolo não possui mecanismo nativo de controle de fluxo, verificação de erros na estrutura física ou bit de confirmação de recebimento (ACK). Consequentemente, o Controlador lerá ruídos elétricos como se fossem dados válidos caso haja falhas na conexão, independentemente de o periférico estar funcionando corretamente ou não.
    
- **Limitações (Distância e Pinos):** É estritamente desenhado para comunicações de curta distância dentro de uma mesma placa de circuito impresso (PCB) e consome mais pinos do microcontrolador (4 vias básicas) do que barramentos assíncronos que usam apenas TX e RX.

