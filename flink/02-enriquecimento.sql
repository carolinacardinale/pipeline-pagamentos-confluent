-- Enriquece cada transação com o cadastro da conta.
-- Ajuste os nomes entre crases caso o catálogo do seu Workspace mostre
-- nomes diferentes para as tabelas inferidas do CDC.
--
-- O temporal join usa a versão da conta válida no momento do evento.

INSERT INTO transacoes_enriquecidas
SELECT
  t.id AS transacao_id,
  t.conta_id,
  c.nome,
  t.cartao,
  t.valor,
  t.estabelecimento,
  t.cidade,
  c.status AS status_conta,
  t.`$rowtime` AS evento_em
FROM `payments.public.transacoes` AS t
LEFT JOIN `payments.public.contas` FOR SYSTEM_TIME AS OF t.`$rowtime` AS c
  ON t.conta_id = c.id;

-- Evidência sugerida após iniciar o statement:
-- SELECT * FROM transacoes_enriquecidas;
