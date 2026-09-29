-- Confluent Cloud for Apache Flink
-- O PostgreSQL CDC V2 cria tópicos no padrão <topic.prefix>.<schema>.<tabela>.
-- Com topic.prefix=payments, os nomes esperados são:
--   payments.public.contas
--   payments.public.transacoes
--
-- Quando os tópicos usam Schema Registry, o Flink pode inferir as tabelas.
-- Confirme os nomes no Workspace antes de executar as consultas abaixo.

-- Saída do enriquecimento. O modo retract aceita alterações vindas do CDC.
CREATE TABLE IF NOT EXISTS transacoes_enriquecidas (
  transacao_id BIGINT,
  conta_id BIGINT,
  nome STRING,
  cartao STRING,
  valor DECIMAL(12,2),
  estabelecimento STRING,
  cidade STRING,
  status_conta STRING,
  evento_em TIMESTAMP_LTZ(3)
) WITH (
  'changelog.mode' = 'retract'
);

-- Saída agregada da regra de fraude.
CREATE TABLE IF NOT EXISTS alertas_fraude (
  cartao STRING,
  janela_inicio TIMESTAMP_LTZ(3),
  janela_fim TIMESTAMP_LTZ(3),
  transacoes_60s BIGINT,
  valor_total DECIMAL(18,2),
  regra STRING
);

SHOW TABLES;
