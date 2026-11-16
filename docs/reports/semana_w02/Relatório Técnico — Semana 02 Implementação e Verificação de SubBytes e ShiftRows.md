# Relatório Técnico — Semana 02: Implementação e Verificação de SubBytes e ShiftRows

**Projeto:** Acelerador Criptográfico AES-128 com Interface SPI (MiniSoC AES)  
**Fase:** 2. Desenvolvimento do RTL (Semana 02)  
**Especificação de Referência:** *Block Guide — MiniSoC AES (v1.0.0)* e *NIST FIPS-197*  
**Ferramentas Utilizadas:** Synopsys VCS (`X-2025.06-SP2_Full64`) e Verdi  

---
![Diagrama Visual](./bloco%20_visual.png)
## 1. Resumo Executivo

Na Semana 02 foi executada a primeira etapa de desenvolvimento de hardware do núcleo criptográfico **MiniSoC AES**, com foco na implementação puramente combinacional da tabela de substituição não linear (**S-Box**), da transformação de substituição de bytes (**SubBytes**) e da permutação cíclica de linhas (**ShiftRows**), além da configuração do fluxo automatizado de compilação, elaboração e simulação no ambiente **Synopsys VCS**.

Os três módulos obrigatórios (`minisoc_aes_sbox`, `minisoc_aes_sub_bytes` e `minisoc_aes_shift_rows`) foram validados por meio de um testbench autoverificável (`tb/tb_semana_02.sv`), atingindo 100% de aprovação (**PASS**) na varredura exaustiva das 256 entradas da S-Box e nos vetores intermediários das Rodadas 1 e 10 do Apêndice B da norma **NIST FIPS-197**.

---

## 2. Arquitetura e Detalhamento dos Módulos RTL

Os blocos foram desenvolvidos em Verilog/SystemVerilog sintetizável no diretório `rtl/`, projetados como circuitos estritamente combinacionais e independentes para posterior reutilização direta no datapath sequencial (`minisoc_aes_dp`) na Semana 03.

### 2.1. Convenção de Mapeamento do Estado (128 bits)

Em conformidade com a Seção 3.4 da FIPS-197 e com a convenção definida no *Block Guide* do MiniSoC AES, o bloco de estado de 128 bits é organizado em ordem *big-endian* por palavra de 32 bits (`Word 0` em `[127:96]`) e disposto logicamente em uma matriz bidimensional $s[r][c]$ de $4 \times 4$ bytes (*column-major*), onde:

- O **Byte 0** ocupa os bits mais significativos `[127:120]` e o **Byte 15** ocupa os bits menos significativos `[7:0]`;
- Cada byte de índice $n \in \{0, 1, \dots, 15\}$ corresponde à posição matricial $s[r][c]$ com $r = n \bmod 4$ (linha) e $c = \lfloor n / 4 \rfloor$ (coluna).

| Linha ($r$) / Coluna ($c$) | Coluna 0 (`[127:96]`) | Coluna 1 (`[95:64]`) | Coluna 2 (`[63:32]`) | Coluna 3 (`[31:0]`) |
| :--- | :---: | :---: | :---: | :---: |
| **Linha 0** ($r = 0$) | Byte 0 `[127:120]` | Byte 4 `[95:88]` | Byte 8 `[63:56]` | Byte 12 `[31:24]` |
| **Linha 1** ($r = 1$) | Byte 1 `[119:112]` | Byte 5 `[87:80]` | Byte 9 `[55:48]` | Byte 13 `[23:16]` |
| **Linha 2** ($r = 2$) | Byte 2 `[111:104]` | Byte 6 `[79:72]` | Byte 10 `[47:40]` | Byte 14 `[15:8]` |
| **Linha 3** ($r = 3$) | Byte 3 `[103:96]` | Byte 7 `[71:64]` | Byte 11 `[39:32]` | Byte 15 `[7:0]` |

### 2.2. Módulo `minisoc_aes_sbox` (`rtl/minisoc_aes_sbox.sv`)

- **Interface:** Entrada `in_byte [7:0]` e saída `out_byte [7:0]`.
- **Implementação:** Circuito puramente combinacional baseado na formulação algébrica da S-Box do AES (FIPS-197, Seção 5.1.1), dividida em duas etapas:
  1. **Inversa Multiplicativa em $\text{GF}(2^8)$:** Cálculo de $x^{-1} \bmod m(x)$ sobre o polinômio irredutível $m(x) = x^8 + x^4 + x^3 + x + 1$ (`8'h1b`), utilizando exponenciação pelo Pequeno Teorema de Fermat ($x^{-1} = x^{254} = x^2 \cdot x^4 \cdot x^8 \cdot x^{16} \cdot x^{32} \cdot x^{64} \cdot x^{128}$, com mapeamento natural $8\text{'h00} \mapsto 8\text{'h00}$) por meio de multiplicações combinacionais em campo finito (`gf_mul`).
  2. **Transformação Afim sobre $\text{GF}(2)$:** Aplicação de rotações circulares de bits (1, 2, 3 e 4 posições à esquerda) combinadas por operações XOR com a constante `8'h63` dentro de um bloco `always_comb`.
- **Justificativa de Projeto (Design ASIC):** A abordagem algébrica garante cobertura completa e determinística das 256 combinações de entrada sem dependência de inferência de ROM externa, elimina riscos de falhas em tabelas `case` extensas e permite que a ferramenta de síntese lógica otimize a rede combinacional conforme as restrições de área e tempo da biblioteca PDK.

### 2.3. Módulo `minisoc_aes_sub_bytes` (`rtl/minisoc_aes_sub_bytes.sv`)

- **Interface:** Entrada `state_in [127:0]` e saída `state_out [127:0]`.
- **Implementação:** Realiza a substituição não linear independente em cada um dos 16 bytes do estado em paralelo. Utiliza um laço `generate` com 16 instâncias de `minisoc_aes_sbox`, endereçando cada byte de 8 bits desde o mais significativo (`[127:120]`) até o menos significativo (`[7:0]`).

### 2.4. Módulo `minisoc_aes_shift_rows` (`rtl/minisoc_aes_shift_rows.sv`)

- **Interface:** Entrada `state_in [127:0]` e saída `state_out [127:0]`.
- **Implementação:** Realizada exclusivamente por atribuição contínua (`assign state_out = { ... };`) de reordenação direta de fios, apresentando custo zero de área em células padrão e atraso lógico nulo:
  - **Linha 0 ($r = 0$):** Sem deslocamento (Bytes 0, 4, 8 e 12 mantidos);
  - **Linha 1 ($r = 1$):** Deslocamento circular de 1 byte à esquerda ($s[1][c] \leftarrow s[1][(c+1) \bmod 4]$);
  - **Linha 2 ($r = 2$):** Deslocamento circular de 2 bytes à esquerda ($s[2][c] \leftarrow s[2][(c+2) \bmod 4]$);
  - **Linha 3 ($r = 3$):** Deslocamento circular de 3 bytes à esquerda ($s[3][c] \leftarrow s[3][(c+3) \bmod 4]$).

---

## 3. Verificação Funcional, Automação e Resultados

### 3.1. Automação do Ambiente e Fluxo de Execução (`preparação synopsys` e `Makefile`)

No servidor Linux (`srv-microeletronica3`), as ferramentas da suíte Synopsys (`vlogan`, `vcs`, `verdi`, `dc_shell`) e as bibliotecas de células padrão (PDK) dependem de variáveis de ambiente (`PATH` e servidores de licença) que não vêm carregadas por padrão no terminal. Como variáveis carregadas em um subshell comum são perdidas ao término de um script convencional, foi criado na raiz do repositório o script executável **`preparação synopsys`** para encapsular a configuração do ambiente e disparar o `Makefile` na mesma sessão:

- **Carregamento das ferramentas Synopsys:** Executa `source /Tools/synopsys-scripts/snps.sh` logo no início (`[0/3]`), garantindo que o `make` reconheça os executáveis e licenças da suíte EDA.
- **Carregamento condicional do PDK SAED32:** Caso o script seja chamado com o argumento `syn`, executa `source /Tools/synopsys-scripts/load_saed32.sh`, deixando o ambiente preparado para futuras etapas de síntese lógica com a biblioteca tecnológica SAED32.
- **Execução automática do `Makefile`:** Dispara `make clean && make "$@"` no mesmo contexto de ambiente, realizando a limpeza de arquivos temporários (`csrc/`, `simv`, `simv.daidir/`, `AN.DB/`, `work.lib++/`, `*.log`, `*.fsdb`), a análise sintática (`vlogan -full64 -sverilog -kdb +v2k`), a elaboração (`vcs -full64 -debug_access+all -kdb`) e a simulação (`./simv -l simv.log`) em comando único.

**Conteúdo do script (`preparação synopsys`):**

![[Pasted image 20261116025631.png]]

### 3.2. Cobertura do Testbench Autoverificável (`tb/tb_semana_02.sv`)

O ambiente de verificação executa duas baterias automáticas de checagem com reporte explícito de falha (`$error` e `$fatal`) em caso de divergência:

1. **Varredura Exaustiva da S-Box (256 entradas):** Percorre sequencialmente todos os valores de `8'h00` a `8'hFF`, comparando a saída do módulo `minisoc_aes_sbox` com uma função de referência independente que calcula a inversa multiplicativa em $\text{GF}(2^8)$ e a transformação afim.
2. **Vetores de Referência FIPS-197 (Apêndice B — Rodadas 1 e 10):** Aplica os estados de entrada da cifragem padrão AES-128 e valida a cadeia completa `Start of Round` $\rightarrow$ `After SubBytes` $\rightarrow$ `After ShiftRows`.

### 3.3. Resultados Obtidos

A simulação foi concluída no tempo `260000 ps` (`0.390 s` de CPU) sem erros ou avisos, produzindo os resultados abaixo:

| Caso de Teste | Vetor de Entrada (`state_in` / `in_byte`) | Resultado Esperado | Resultado Obtido | Status |
| :--- | :--- | :--- | :--- | :---: |
| **S-Box (256 entradas)** | `8'h00` .. `8'hFF` | Tabela completa FIPS-197 Fig. 7 | 256/256 coincidências | **PASS** |
| **Rodada 1 — SubBytes** | `193de3bea0f4e22b9ac68d2ae9f84808` | `d42711aee0bf98f1b8b45de51e415230` | `d42711aee0bf98f1b8b45de51e415230` | **PASS** |
| **Rodada 1 — ShiftRows** | `d42711aee0bf98f1b8b45de51e415230` | `d4bf5d30e0b452aeb84111f11e2798e5` | `d4bf5d30e0b452aeb84111f11e2798e5` | **PASS** |
| **Rodada 10 — SubBytes** | `eb40f21e592e38848ba113e71bc342d2` | `e9098972cb31075f3d327d94af2e2cb5` | `e9098972cb31075f3d327d94af2e2cb5` | **PASS** |
| **Rodada 10 — ShiftRows** | `e9098972cb31075f3d327d94af2e2cb5` | `e9317db5cb322c723d2e895faf090794` | `e9317db5cb322c723d2e895faf090794` | **PASS** |

### 3.4. Análise Estática (Lint)

A verificação estática foi executada sobre os três arquivos RTL (`minisoc_aes_sbox.sv`, `minisoc_aes_sub_bytes.sv` e `minisoc_aes_shift_rows.sv`) via `vcs -full64 -sverilog +lint=all` (com log versionado em `scripts/lint_semana_02.log`), confirmando **0 erros de sintaxe**, ausência de truncamento de largura de barramentos e ausência de *latches* inferidos.

---

## 4. Problemas Encontrados e Soluções Aplicadas

1. **Falha na Primeira Simulação por Tabela `case` Incompleta na S-Box:**
   - *Sintoma:* Na primeira execução, o teste de 128 bits falhou no módulo `SubBytes` retornando `00000000000000000000000000000030` (apenas o byte menos significativo `8'h08` foi mapeado corretamente para `8'h30`, enquanto os demais bytes retornaram o valor `default`).
   - *Causa Raiz:* O esqueleto inicial da S-Box continha apenas os mapeamentos de `8'h00` a `8'h0F` e `8'h53`.
   - *Solução:* Implementação algébrica completa da inversa multiplicativa em $\text{GF}(2^8)$ ($x^{254}$), garantindo precisão em todas as 256 entradas.

2. **Ampliação da Cobertura do Testbench para Atender aos Critérios de Aceite:**
   - *Problema:* A primeira versão de `tb/tb_semana_02.sv` validava apenas duas entradas isoladas da S-Box (`8'h00` e `8'h53`) e somente a Rodada 1 da FIPS-197.
   - *Solução:* Adição de um laço exaustivo para testar todos os 256 bytes possíveis contra um modelo matemático de referência e inclusão dos vetores intermediários da **Rodada 10** do Apêndice B da FIPS-197.

---

## 5. Registro de Dúvidas e Ambiguidades sobre o Block Guide (Seções 1 a 3 e 8)

Ao ler as Seções 1, 2, 3 e 8 do *Block Guide* para entender como os módulos da Semana 02 vão se conectar ao restante do sistema nas próximas etapas, surgiram algumas dúvidas práticas que precisam ser confirmadas antes de implementar o banco de registradores e o controlador:

1. **Ordem dos bytes e palavras na entrada de dados e chave (Seções 2 e 3):** Quando as quatro palavras de 32 bits são carregadas nos registradores (`KEY0` a `KEY3`) ou lidas da memória (`minisoc_memory`), a primeira palavra (`Word 0`) entra direto nos bits `[127:96]` do bloco AES ou é preciso inverter a ordem dos bytes (*byte-swap*) antes de iniciar a cifragem?
2. **Tempo de resposta na leitura e escrita dos registradores (Seção 3):** O acesso aos registradores de controle e status ocorre sempre em 1 ciclo de clock fixo ou a interface precisa suportar ciclos de espera (*wait-states*) quando o núcleo estiver ocupado?
3. **Tentativa de escrita enquanto o AES está rodando (Seções 3 e 8):** O que o `minisoc_aes_top` deve fazer se houver tentativa de escrita nos registradores de chave, configuração ou `AES_CONTROL` enquanto o sinal `BUSY` estiver ativo? Deve apenas ignorar a escrita, sinalizar `ERROR` ou sobrescrever o valor atual?
4. **Reset e limpeza dos registradores internos (Seções 2 e 8):** O reset do domínio do sistema (`sys_clk`) é síncrono e ativo em nível baixo? Além disso, os registradores internos de chave e de estado intermediário devem ser zerados automaticamente ao final de cada operação ou apenas quando ocorrer um reset?

---

## 6. Próximos Passos (Semana 03)

- Elaborar a versão inicial do documento de microarquitetura (`docs/architecture/microarchitecture.md`), detalhando o diagrama de blocos interno, o datapath iterativo de 1 rodada por ciclo, a FSM do `minisoc_aes_top`, a estratégia de CDC por *toggle* entre `spi_sclk` e `clk`, e a sequência de reset do sistema.
- Implementar em RTL os módulos combinacionais `minisoc_aes_mix_columns` e `minisoc_aes_add_round_key`, além das transformações inversas (`minisoc_aes_inv_sbox`, `minisoc_aes_inv_sub_bytes`, `minisoc_aes_inv_shift_rows` e `minisoc_aes_inv_mix_columns`) necessárias para a decriptação.
- Validar todas as transformações diretas e inversas com os vetores intermediários dos Apêndices B e C.1 da FIPS-197 e apresentar a microarquitetura ao verificador parceiro.
