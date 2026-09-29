# Evidências da execução

Esta pasta deve receber apenas evidências reais geradas durante a execução do projeto.

Sugestão de arquivos:

- `01-cluster.png` — ambiente e cluster criados no Confluent Cloud;
- `02-identidades.png` — service accounts/identidades com permissões separadas;
- `03-schema-v1.png` — schema inicial registrado;
- `04-schema-v2-compativel.png` — evolução compatível aceita pelo Schema Registry;
- `05-connector-running.png` — PostgreSQL CDC V2 em estado RUNNING;
- `06-cdc-insert.png` — evento correspondente ao INSERT;
- `07-cdc-update.png` — evento correspondente ao UPDATE;
- `08-cdc-delete.png` — evento correspondente ao DELETE;
- `09-flink-enriquecimento.png` — resultado de `transacoes_enriquecidas`;
- `10-alerta-fraude.png` — resultado de `alertas_fraude` com 3+ transações/60 s;
- `11-metricas.png` — métricas do cluster/conector/statement;
- `12-custo.png` — tela de billing/custos referente ao período do teste.

## Boas práticas

1. Oculte API keys, secrets, senhas, IDs sensíveis e dados que não precisam aparecer.
2. Não use imagens de exemplo como se fossem evidência da sua execução.
3. Atualize o README principal com os nomes reais dos arquivos que você adicionar aqui.
4. Apague os recursos em nuvem ao terminar os testes para evitar cobrança desnecessária.
