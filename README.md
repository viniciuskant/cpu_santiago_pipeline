# CPU Santiago Pipeline

A **Santiago Pipeline** é uma evolução da CPU Santiago original.

O projeto aplica os conceitos fundamentais de **pipeline de instruções**, permitindo que múltiplas instruções sejam processadas simultaneamente em diferentes estágios de execução. Dessa forma, enquanto uma instrução está sendo executada, outras podem estar sendo buscadas, decodificadas ou preparadas para execução, aumentando o aproveitamento do processador e o desempenho geral do sistema.

Como se trata de um processador bastante simples, que possui apenas as instruções **ADD**, **SUB**, **MUL**, **DIV**, **NOP**, **READ** e **WRITE**, não foi necessário implementar mecanismos adicionais para tratar problemas relacionados a desvios de execução (*branch hazards*), uma vez que não existem instruções de controle de fluxo que alterem a sequência normal de execução.

## Trabalhos Futuros

* Desenvolver um *benchmark* mais abrangente para avaliar o desempenho da arquitetura pipeline.
* Comparar métricas como **instruções por ciclo (IPC)** e tempo total de execução entre a CPU Santiago original e a versão pipeline.
* Criar diagramas dos estágios do pipeline e o fluxo das instruções.
