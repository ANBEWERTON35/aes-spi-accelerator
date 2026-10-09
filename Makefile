# ===============
#     Makefile 
# ===============

# Variáveis de ficheiros e módulos
TOP_TB      = tb_dummy_top
RTL_SRCS    = rtl/dummy_top.sv
TB_SRCS     = tb/tb_dummy_top.sv

# Ferramentas Synopsys
VLOGAN      = vlogan
VCS         = vcs
VERDI       = verdi
DC_SHELL    = dc_shell

# Flags de compilação e simulação
VLOGAN_FLAGS = -full64 -sverilog -kdb +v2k
VCS_FLAGS    = -full64 -debug_access+all -kdb -l vcs_compile.log
SIM_EXEC     = ./simv

.PHONY: all analyze compile run verdi syn clean

# Alvo padrão: analisa, compila e executa a simulação
all: analyze compile run

# 1. Análise dos ficheiros SystemVerilog (vlogan)
analyze:
	@echo "=== [1/4] Análise de RTL e Testbench com vlogan ==="
	$(VLOGAN) $(VLOGAN_FLAGS) $(RTL_SRCS)
	$(VLOGAN) $(VLOGAN_FLAGS) $(TB_SRCS)

# 2. Elaboração e Geração do Binário (vcs)
compile:
	@echo "=== [2/4] Elaboração com VCS ==="
	$(VCS) $(VCS_FLAGS) $(TOP_TB) -o simv

# 3. Execução da Simulação
run:
	@echo "=== [3/4] A executar simulação em modo Batch ==="
	$(SIM_EXEC) -l simv.log

# 4. Visualização de Formas de Onda no Verdi
verdi:
	@echo "=== A abrir o Verdi ==="
	$(VERDI) -ssf novas.fsdb -noupdate &

# 5. Síntese Lógica com Synopsys Design Compiler (dc_shell)
syn:
	@echo "=== A executar Síntese Lógica no dc_shell ==="
	$(DC_SHELL) -64bit -f syn/synth.tcl | tee syn/synthesis.log

# Limpeza de ficheiros gerados pelas ferramentas Synopsys
clean:
	@echo "=== A limpar ficheiros de simulação e síntese ==="
	rm -rf csrc simv simv.daidir ucli.key
	rm -rf AN.DB work.lib++ 64
	rm -rf novas.* verdiLog verdi_config_files
	rm -rf *.log *.fsdb *.vcd
	rm -rf command.log filenames*.log