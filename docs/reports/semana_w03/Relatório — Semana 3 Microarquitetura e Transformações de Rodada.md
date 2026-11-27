Projeto: MiniSoC AES — Acelerador Criptográfico AES-128 com Interface SPI  Ferramenta EDA: Synopsys VCS (`vlogan` / `vcs +lint=all`) — Servidor `srv-microeletronica3`

---

## 1. O que foi feito

Nesta terceira semana do projeto, elaborei a primeira versão do documento de microarquitetura (`docs/architecture/microarchitecture.md`), seguindo todas as interfaces e restrições estabelecidas pelo *Block Guide* v1.0.0.

Em paralelo, concluí a implementação em SystemVerilog e a validação de todas as transformações combinacionais de rodada do padrão **AES-128 (NIST FIPS-197)**. Foram desenvolvidos os blocos diretos (`AddRoundKey` e `MixColumns`) e os blocos inversos (`InvS-Box`, `InvSubBytes`, `InvShiftRows` e `InvMixColumns`), que são indispensáveis para realizar a decriptação nos modos **ECB**, **CBC** e **PCBC**.

---

## 2. Arquitetura e Implementação

Para garantir que todos os 9 módulos combinacionais feitos entre a Semana 2 e a Semana 3 estivessem funcionando corretamente, escrevi um testbench autoverificável (`tb/tb_semana_03.sv`) cobrindo testes unitários e em cadeia com os vetores oficiais dos Apêndices B e C.1 da norma FIPS-197.

Toda a suíte passou com **100% de aprovação**, e a análise estática (*lint*) rodou limpa com **0 erros**.

### 2.1. Documento de Microarquitetura v1.0 (`docs/architecture/microarchitecture.md`)

Nesse documento, detalhei como cada parte interna do módulo de topo `minisoc_top.sv` vai funcionar na prática, respeitando as interfaces externas (`CLK`, `RESET`, `SPI` e `MEMORY DATA`), a divisão entre os quatro blocos principais (`minisoc_spi`, `minisoc_pll_mock`, `minisoc_aes_top` e `minisoc_memory`) e o mapa de registradores (`0x00` a `0x0F` e `0x3F`) fixados pelo *Block Guide*:

* **Microarquitetura Iterativa do Núcleo AES (1 Rodada por Ciclo):** Escolhi uma arquitetura iterativa em que o mesmo estágio combinacional de rodada é reutilizado durante as 10 rodadas do AES-128 (somando 1 ciclo inicial para o `AddRoundKey`). Essa decisão economiza bastante área de silício e entrega uma vazão que atende com folga o limite da interface serial SPI ($\le 25\text{ MHz}$).
* **FSM de Controle (`minisoc_aes_top`):** Estruturei a máquina de estados em cinco etapas principais:
  * `IDLE`: valida se `MODE <= 3'b101` e `1 <= NUM_BLOCKS <= 256`[cite: 11];
  * `KEY_EXP`: gera as 11 *round keys* do AES-128;
  * `MEM_READ`: lê sequencialmente as 4 palavras de 32 bits que formam cada bloco;
  * `AES_ROUND`: executa as rodadas de forma iterativa, pulando o `MixColumns`/`InvMixColumns` na 10.ª rodada;
  * `MEM_WRITE`: escreve o resultado *in-place* na `minisoc_memory` e atualiza `BLOCKS_DONE`.
* **Cruzamento de Domínios de Clock — CDC (Seção 5.3):** Para transferir os comandos entre o clock serial `spi_sclk` e o domínio *always-on* `clk` ($2\text{ GHz}$), adotei a sincronização por *toggle*. Sempre que um frame SPI de 40 bits (Mode 0, MSB-first) termina de chegar e os dados estabilizam, um flip-flop (`frame_toggle`) inverte seu estado e é capturado no domínio `clk` por um sincronizador de 2 flip-flops (*2-FF*) ligado a um detector de borda.
* **Sequência de Reset do Domínio do Sistema (Seção 4.2):** Enquanto o PLL (`minisoc_pll_mock`) não trava (`o_locked == 0`), o clock `sys_clk` fica bloqueado e o reset interno `sys_rst_n` permanece ativo em nível baixo. Assim que `o_locked` vai para `1`, o reset `sys_rst_n` é liberado de forma síncrona após 2 ciclos de `sys_clk`.

### 2.2. Módulos de Transformação Direta (`rtl/`)

Mantive a mesma organização de bytes (*column-major*) de 128 bits usada na Semana 2, onde o `byte 0` fica nos bits `[127:120]` ($s[0][0]$) e o `byte 15` nos bits `[7:0]` ($s[3][3]$)[]. Sobre essa estrutura, implementei dois novos módulos:

| Módulo / Arquivo               | Papel Arquitetural                       | Detalhes de Implementação RTL                                                                                                                                                                                             |
| :----------------------------- | :--------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `minisoc_aes_add_round_key.sv` | Soma da chave da rodada (`AddRoundKey`)  | Faz a operação combinacional XOR bit a bit de 128 bits (`state_out = state_in ^ round_key`), sendo usada tanto na rodada inicial (`RK[0]` ou `RK[10]`) quanto no fechamento de cada rodada.                               |
| `minisoc_aes_mix_columns.sv`   | Difusão linear por coluna (`MixColumns`) | Implementa a multiplicação matricial em $\text{GF}(2^8)$ pelos coeficientes $\{02\}$, $\{03\}$, $\{01\}$ e $\{01\}$, usando a função auxiliar `xtime` com o polinômio redutor $m(x) = x^8 + x^4 + x^3 + x + 1$ (`8'h1b`). |

### 2.3. Módulos de Transformação Inversa (`rtl/`)

Para viabilizar a decifragem nos modos **ECB**, **CBC** e **PCBC**, implementei os quatro blocos combinacionais inversos:

| Módulo / Arquivo                 | Papel Arquitetural                                   | Detalhes de Implementação RTL                                                                                                                                                                                                         |
| :------------------------------- | :--------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `minisoc_aes_inv_sbox.sv`        | Substituição não linear inversa de byte (`InvS-Box`) | Tabela combinacional `case (in_byte)` com as 256 entradas inversas em $\text{GF}(2^8)$ e ramo `default` explícito para evitar inferência de *latch*, mantendo as portas padronizadas (`.in_byte`, `.out_byte`).                       |
| `minisoc_aes_inv_sub_bytes.sv`   | Substituição inversa do estado (`InvSubBytes`)       | Usa um bloco `generate` para instanciar em paralelo 16 unidades de `minisoc_aes_inv_sbox`, aplicando cada uma sobre as fatias `[127 - 8*i -: 8]` do barramento de 128 bits.                                                           |
| `minisoc_aes_inv_shift_rows.sv`  | Permutação inversa de linhas (`InvShiftRows`)        | Faz a reordenação puramente combinacional dos fios para deslocar circularmente **à direita** 0, 1, 2 e 3 bytes nas linhas 0, 1, 2 e 3 da matriz de estado $4 \times 4$ .                                                              |
| `minisoc_aes_inv_mix_columns.sv` | Difusão linear inversa por coluna (`InvMixColumns`)  | Realiza a multiplicação matricial em $\text{GF}(2^8)$ pelo polinômio $\{0b\}x^3 + \{0d\}x^2 + \{09\}x + \{0e\}$, usando funções auxiliares (`mul9`, `mulb`, `muld` e `mule`) construídas a partir de chamadas sucessivas da `xtime` . |

---

## 3. Verificação e Automação

### 3.1. Fluxo de Execução no Servidor (`preparação synopsys` e `Makefile`)

Rodei todas as etapas de compilação, simulação e análise estática no servidor `srv-microeletronica3`, carregando o ambiente da Synopsys (`source /Tools/synopsys-scripts/snps.sh`) e utilizando os alvos que adicionei ao `Makefile` :

* **Compilação e Simulação:** Compilei juntos os 9 módulos RTL (`minisoc_aes_sbox`, `minisoc_aes_sub_bytes`, `minisoc_aes_shift_rows`, `minisoc_aes_mix_columns`, `minisoc_aes_add_round_key`, `minisoc_aes_inv_sbox`, `minisoc_aes_inv_sub_bytes`, `minisoc_aes_inv_shift_rows` e `minisoc_aes_inv_mix_columns`) com o testbench `tb/tb_semana_03.sv` via `vlogan -full64 -sverilog` e `vcs -full64`[ .
* **Análise Estática (*Lint*):** Executei o comando `vcs +lint=all -sverilog` em todo o RTL e salvei o log completo em `scripts/lint_semana_03.log` para versionamento.
* **Regressão:** Mantive o `tb/tb_semana_02.sv` intacto no repositório para garantir que os testes da semana passada continuem rodando sem quebrar.

### 3.2. Resultados da Simulação (Vetores FIPS-197)

O testbench `tb/tb_semana_03.sv` faz a checagem automática das saídas usando `$error` e `$fatal`, e todas as baterias passaram de primeira após os ajustes de sintaxe:

| Bateria de Teste                      | Referência / Vetor Aplicado                                                                                    | Saída Esperada (128 bits / Byte)                          |   Status   |
| :------------------------------------ | :------------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------- | :--------: |
| **Varredura Exaustiva `InvS-Box`**    | Todas as 256 entradas (`0x00` a `0xFF`)                                                                        | $\text{InvSBox}(\text{SBox}(x)) = x$ para 256/256 valores |  **PASS**  |
| **Invertibilidade 128 bits**          | `InvShiftRows(ShiftRows(X))` e `InvMixColumns(MixColumns(X))`                                                  | Recuperação exata do vetor original `X`                   |  **PASS**  |
| **FIPS-197 Ap. B — Rodada 0**         | `AddRoundKey(3243f6a8..., 2b7e1516...)`                                                                        | `193de3bea0f4e22b9ac68d2ae9f84808`                        | **PASS** |
| **FIPS-197 Ap. B — Rodada 1**         | `SubBytes` $\rightarrow$ `ShiftRows` $\rightarrow$ `MixColumns` $\rightarrow$ `AddRoundKey` (`RK[1]`)          | `a49c7ff2689f352b6b5bea43026a5049`                        | **PASS**  |
| **FIPS-197 Ap. B — Rodada 10**        | `SubBytes` $\rightarrow$ `ShiftRows` $\rightarrow$ `AddRoundKey` (`RK[10]`, sem `MixColumns`)                  | `3925841d02dc09fbdc118597196a0b32`                        |  **PASS**  |
| **FIPS-197 Ap. C.1 — Inicial**        | `AddRoundKey(69c4e0d8..., RK[10])`                                                                             | `7ad5fda789ef4e272bca100b3d9ff59f`                        |  **PASS**  |
| **FIPS-197 Ap. C.1 — Rodada 1 Inv.**  | `InvShiftRows` $\rightarrow$ `InvSubBytes` $\rightarrow$ `AddRoundKey` (`RK[9]`) $\rightarrow$ `InvMixColumns` | `54d990a16ba09ab596bbf40ea111702f`                        |  **PASS**  |
| **FIPS-197 Ap. C.1 — Rodada 10 Inv.** | `InvShiftRows` $\rightarrow$ `InvSubBytes` $\rightarrow$ `AddRoundKey` (`RK[0]`, sem `InvMixColumns`)          | `00112233445                                              |            |


#### Diagrama de Blocos de Topo (`minisoc_top.sv`)

![!\[\[Diagrama de Blocos minisosc_top.jpg\]\]](<Diagrama de Blocos minisosc_top.jpg>)
#### Diagrama de Blocos Interno do Núcleo AES (`minisoc_aes_dp.sv`)

![!\[\[Diagrama de Blocos Interno do Núcleo AES.jpg\]\]](<Diagrama de Blocos Interno do Núcleo AES.jpg>)