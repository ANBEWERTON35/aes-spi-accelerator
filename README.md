# Acelerador Hardware AES-SPI (`aes-spi-accelerator`)

Este repositório contém a implementação em SystemVerilog e a infraestrutura de verificação e síntese para um **Acelerador Criptográfico AES-128** integrado com interface **SPI Slave**.

---

## 📁 Estrutura do Repositório

```text
aes-spi-accelerator/
├── docs/             # Documentação, relatórios e especificações
├── formal/           # Scripts e propriedades de verificação formal
├── rtl/              # Código-fonte SystemVerilog (Sintetizável)
│   └── dummy_top.sv  # Módulo top-level mínimo
├── scripts/          # Scripts de automação (TCL, Shell)
│   └── run.tcl       # Script de execução do fluxo Synopsys
├── syn/              # Scripts de síntese (Design Compiler) e relatórios
│   └── synth.tcl     # Script de síntese no dc_shell
├── tb/               # Testbenches e ambiente de verificação
│   └── tb_dummy_top.sv # Testbench top-level mínimo
├── upf/              # Ficheiros de gerenciamento de potência (Power Intent)
├── BACKLOG.md        # Gestão e acompanhamento das tarefas do projeto
├── Makefile          # Automação principal de comandos
└── README.md         # Instruções gerais do repositório

Requisitos e Ferramentas Necessárias

Para executar o fluxo completo de lint, compilação, simulação e síntese, garantido ambiente configurado com as seguintes ferramentas:

- GCC / GNU Make (3.81)
    
- Tcl Shell (`tclsh`)
    
- Synopsys VCS / vlogan (Análise e Simulação)
    
- Synopsys Verdi (Visualização de Formas de Onda / Debug)
    
- Synopsys Design Compiler (`dc_shell`) (Síntese Lógica)

Como Executar (Fluxo Mínimo)

O projeto está configurado para executar todo o fluxo de verificação (análise sintática, compilação e simulação) em um único comando:

make


Backlog do Projeto
O acompanhamento das entregas e histórias de usuário por disciplina (RTL, DV e Síntese) está documentado em:
 
 BACKLOG.md