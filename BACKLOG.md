# Backlog do Projeto: Acelerador AES-SPI

  

Este documento contém a lista de tarefas, histórias e entregas do projeto divididas por disciplina e fases de desenvolvimento.

  

---

  

## 📌 Status das Sprints / Semanas

  

- [x] **Semana 1:** Kick-off, Estudo da Especificação (AES/SPI), Estruturação do Repositório e Fluxo Mínimo

- [ ] **Semana 2:** Desenvolvimento do Bloco SPI e Testbench de Bloco

- [ ] **Semana 3:** Desenvolvimento do Core AES-128 e Testbench de Bloco

- [ ] **Semana 4:** Integração Top-Level (AES + SPI + Registradores)

- [ ] **Semana 5:** Verificação Top-Level, Cobertura e Síntese Lógica (Design Compiler)

  

---

  

## 🏗️ 1. Trilha de RTL (Design & Arquitetura)

  

| ID | Tarefa / Descrição | Critério de Aceite | Status |

| :--- | :--- | :--- | :---: |

| **RTL-01** | Desenvolver o módulo SPI Slave (suporte a Modos 0 e 3) | Deslocamento correto dos dados nos pinos MOSI/MISO | `[ ]` |

| **RTL-02** | Implementar o bloco de Key Expansion (AES-128) | Gerar as 11 subchaves a partir da chave inicial | `[ ]` |

| **RTL-03** | Implementar as rodadas de cifra AES (SubBytes, ShiftRows, MixColumns, AddRoundKey) | Processar o bloco de 128 bits de acordo com FIPS-197 | `[ ]` |

| **RTL-04** | Criar a Máquina de Estados (FSM) do Top-Level e Registradores de Configuração/Status | Controlar fluxo de dados entre SPI e AES sem estourar buffer | `[ ]` |

  

---

  

## 🧪 2. Trilha de Verificação (DV & Testbench)

  

| ID | Tarefa / Descrição | Critério de Aceite | Status |

| :--- | :--- | :--- | :---: |

| **DV-01** | Criar Testbench para a interface SPI Slave | Validar transações de escrita e leitura de registradores | `[ ]` |

| **DV-02** | Criar Testbench para o Core AES com vetores conhecidos (NIST) | Criptografar vetores FIPS-197 e bater com resultados esperados | `[ ]` |

| **DV-03** | Desenvolver Testbench Top-Level com Scoreboard | Comparar pacote recebido na SPI com saída criptografada | `[ ]` |

| **DV-04** | Análise de Cobertura de Código e Funcional | Atingir meta de cobertura estipulada (>90% statement/branch) | `[ ]` |

  

---

  

## ⚙️ 3. Trilha de Integração, Lint e Síntese

  

| ID | Tarefa / Descrição | Critério de Aceite | Status |

| :--- | :--- | :--- | :---: |

| **INT-01** | Configurar script de Lint no VCS/Verilator para zero *warnings* | Execução do `make analyze` sem alertas críticos | `[x]` |

| **INT-02** | Integrar scripts de automação via Makefile e TCL | Comandos `make sim` e `make syn` executando sem intervenção | `[x]` |

| **INT-03** | Executar síntese lógica no Design Compiler (`dc_shell`) | Gerar *netlist* e relatórios de área/tempo sem erros em `syn/` | `[ ]` |

| **INT-04** | Fechamento de Timing e Análise de Área | Nenhuma violação de setup/hold no relatório de timing | `[ ]` |