# ===============
#   Makefile - Semana 3 (Transformações de Rodada Diretas e Inversas)
# ===============

# Variáveis de ficheiros e módulos
TOP_TB      = tb_semana_03
RTL_SRCS    = rtl/minisoc_aes_sbox.sv \
              rtl/minisoc_aes_sub_bytes.sv \
              rtl/minisoc_aes_shift_rows.sv \
              rtl/minisoc_aes_mix_columns.sv \
              rtl/minisoc_aes_add_round_key.sv \
              rtl/minisoc_aes_inv_sbox.sv \
              rtl/minisoc_aes_inv_sub_bytes.sv \
              rtl/minisoc_aes_inv_shift_rows.sv \
              rtl/minisoc_aes_inv_mix_columns.sv
TB_SRCS     = tb/tb_semana_03.sv

# Ferramentas Synopsys
VLOGAN      = vlogan
VCS         = vcs
VERDI       = verdi

# Flags de compilação, lint e simulação
VLOGAN_FLAGS = -full64 -sverilog -kdb +v2k
VCS_FLAGS    = -full64 -debug_access+all -kdb -l vcs_compile.log
LINT_FLAGS   = -full64 -sverilog +lint=all -l scripts/lint_semana_03.log
SIM_EXEC     = ./simv

.PHONY: all analyze compile run lint verdi clean

# Alvo padrão: analisa, compila e executa a simulação
all: analyze compile run

# 1. Análise dos ficheiros SystemVerilog (vlogan)
analyze:
	@echo "=== [1/3] Análise de RTL e Testbench da Semana 03 ==="
	$(VLOGAN) $(VLOGAN_FLAGS) $(RTL_SRCS)
	$(VLOGAN) $(VLOGAN_FLAGS) $(TB_SRCS)

# 2. Elaboração e Geração do Binário (vcs)
compile:
	@echo "=== [2/3] Elaboração com VCS ==="
	$(VCS) $(VCS_FLAGS) $(TOP_TB) -o simv

# 3. Execução da Simulação
run:
	@echo "=== [3/3] Executando simulação da Semana 03 ==="
	$(SIM_EXEC) -l simv.log

# 4. Verificação de Lint (gera relatório em scripts/lint_semana_03.log)
lint:
	@echo "=== Executando verificação de Lint com VCS ==="
	$(VCS) $(LINT_FLAGS) $(RTL_SRCS)

# 5. Visualização no Verdi (Opcional)
verdi:
	@echo "=== A abrir o Verdi ==="
	$(VERDI) -ssf novas.fsdb -noupdate &

# Limpeza de ficheiros temporários
clean:
	@echo "=== Limpando arquivos de simulação ==="
	rm -rf csrc simv simv.daidir ucli.key
	rm -rf AN.DB work.lib++ 64
	rm -rf novas.* verdiLog verdi_config_files
	rm -rf *.log *.fsdb *.vcd