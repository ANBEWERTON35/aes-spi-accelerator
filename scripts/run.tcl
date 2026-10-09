# ==============================================================================
# scripts- Automação 
# ==============================================================================

# Configuração de caminhos e parâmetros
set RTL_SRCS   [list rtl/dummy_top.sv]
set TB_SRCS    [list tb/tb_dummy_top.sv]
set TOP_MODULE "tb_dummy_top"
set SIM_BIN    "simv"

# ------------------------------------------------------------------------------
# 1. Análise Sintática (vlogan)
# ------------------------------------------------------------------------------
proc run_vlogan {} {
    global RTL_SRCS TB_SRCS
    puts "\n=== [1/4] Análise de RTL e Testbench (vlogan) ==="
    foreach file [concat $RTL_SRCS $TB_SRCS] {
        puts "Analisando: $file"
        if {[catch {exec vlogan -full64 -sverilog -kdb +v2k $file} msg]} {
            puts "Erro no vlogan: $msg"
            exit 1
        }
    }
}

# ------------------------------------------------------------------------------
# 2. Elaboração e Compilação (vcs)
# ------------------------------------------------------------------------------
proc run_vcs {} {
    global TOP_MODULE SIM_BIN
    puts "\n=== [2/4] Elaboração com VCS ==="
    if {[catch {exec vcs -full64 -debug_access+all -kdb $TOP_MODULE -o $SIM_BIN -l vcs_compile.log} msg]} {
        puts "Erro no VCS: $msg"
        exit 1
    }
}

# ------------------------------------------------------------------------------
# 3. Execução da Simulação
# ------------------------------------------------------------------------------
proc run_sim {} {
    global SIM_BIN
    puts "\n=== [3/4] Executando Simulação ==="
    if {[catch {exec ./$SIM_BIN -l simv.log} msg]} {
        puts "Erro na simulação: $msg"
        exit 1
    }
}

# ------------------------------------------------------------------------------
# 4. Abertura do Visualizador de Ondas (verdi)
# ------------------------------------------------------------------------------
proc open_verdi {} {
    puts "\n=== [4/4] Abrindo o Verdi ==="
    if {[file exists novas.fsdb]} {
        exec verdi -ssf novas.fsdb &
    } else {
        puts "Aviso: Ficheiro novas.fsdb não encontrado. Verifique a geração de ondas no testbench."
    }
}

# ------------------------------------------------------------------------------
# 5. Síntese Lógica com Design Compiler (dc_shell)
# ------------------------------------------------------------------------------
proc run_synthesis {} {
    puts "\n=== A executar Síntese no dc_shell ==="
    if {[catch {exec dc_shell -64bit -f syn/synth.tcl | tee syn/synthesis.log} msg]} {
        puts "Erro na síntese: $msg"
        exit 1
    }
}

# ------------------------------------------------------------------------------
# Fluxo Padrão: Executa análise, compilação e simulação
# ------------------------------------------------------------------------------
run_vlogan
run_vcs
run_sim

puts "\n[SUCESSO] Fluxo de simulação concluído com sucesso!"