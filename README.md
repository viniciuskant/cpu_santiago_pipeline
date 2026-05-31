# CPU Santiago Pipeline

A **Santiago Pipeline** é uma evolução da CPU Santiago original.

O projeto aplica os conceitos fundamentais de **pipeline de instruções**, permitindo que múltiplas instruções sejam processadas simultaneamente em diferentes estágios de execução. Dessa forma, enquanto uma instrução está sendo executada, outras podem estar sendo buscadas, decodificadas ou preparadas para execução, aumentando o aproveitamento do processador e o desempenho geral do sistema.

Como se trata de um processador bastante simples, que possui apenas as instruções **ADD**, **SUB**, **MUL**, **DIV**, **NOP**, **READ** e **WRITE**, não foi necessário implementar mecanismos adicionais para tratar problemas relacionados a desvios de execução (*branch hazards*), uma vez que não existem instruções de controle de fluxo que alterem a sequência normal de execução.

## Execução

Para realizar os reports basta:

```bash
mkdir out
cd out
design_vision -f ../scripts/run_synthesis.tcl
```

Para realizar os testes basta:
```bash
mkdir out
cd out
../scripts/testbench.sh
```
para evitar a criação de arquivos na raiz do projeto

## Reports

A análise temporal foi realizada considerando um clock de 2,36 ns. O pior caminho encontrado apresentou slack positivo de 0,01 ns, indicando que todas as restrições temporais foram atendidas.

O caminho crítico identificado parte do registrador `reg_EX_WB/regs_reg[0]` e termina na saída `dout_low[0]`. Esse registrador corresponde ao estágio de Write Back e armazena o resultado proveniente da ALU. A pequena margem de slack observada sugere que a lógica associada a esse caminho está entre as mais críticas do projeto.

Uma possível justificativa para esse comportamento é a implementação da operação de divisão em ciclo único na ALU. Como divisões normalmente possuem maior atraso combinacional em comparação com operações aritméticas simples, elas tendem a aumentar o tempo de propagação dos dados e, consequentemente, impactar negativamente a folga temporal disponível.


## Trabalhos Futuros

* Desenvolver um *benchmark* mais abrangente para avaliar o desempenho da arquitetura pipeline.
* Comparar métricas como **instruções por ciclo (IPC)** e tempo total de execução entre a CPU Santiago original e a versão pipeline.
* Criar diagramas dos estágios do pipeline e o fluxo das instruções.
