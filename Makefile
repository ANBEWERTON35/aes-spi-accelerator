# ===============
#   Makefile - Semana 2
# ===============

# Variáveis de ficheiros e módulos
TOP_TB      = tb_semana_02
RTL_SRCS    = rtl/minisoc_aes_sbox.sv \
              rtl/minisoc_aes_sub_bytes.sv \
              rtl/minisoc_aes_shift_rows.sv
TB_SRCS     = tb/tb_semana_02.sv

# Ferramentas Synopsys
VLOGAN      = vlogan
VCS         = vcs
VERDI       = verdi

# Flags de compilação e simulação
VLOGAN_FLAGS = -full64 -sverilog -kdb +v2k
VCS_FLAGS    = -full64 -debug_access+all -kdb -l vcs_compile.log
SIM_EXEC     = ./simv

.PHONY: all analyze compile run verdi clean

# Alvo padrão
all: analyze compile run

# 1. Análise dos ficheiros SystemVerilog (vlogan)
analyze:
	@echo "=== [1/3] Análise de RTL e Testbench da Semana 02 ==="
	$(VLOGAN) $(VLOGAN_FLAGS) $(RTL_SRCS)
	$(VLOGAN) $(VLOGAN_FLAGS) $(TB_SRCS)

# 2. Elaboração e Geração do Binário (vcs)
compile:
	@echo "=== [2/3] Elaboração com VCS ==="
	$(VCS) $(VCS_FLAGS) $(TOP_TB) -o simv

# 3. Execução da Simulação
run:
	@echo "=== [3/3] Executando simulação da Semana 02 ==="
	$(SIM_EXEC) -l simv.log

# 4. Visualização no Verdi (Opcional)
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