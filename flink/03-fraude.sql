-- Regra: 3 ou mais transações do mesmo cartão dentro de uma janela de 60 segundos.
--
-- HOP usa uma janela móvel de 60 s com avanço de 5 s. Isso reduz o problema
-- de uma janela TUMBLE fixa separar uma sequência que cruza a fronteira do minuto.
-- A agregação aceita tabelas atualizáveis vindas de CDC e produz uma saída
-- final por janela.

INSERT INTO alertas_fraude
SELECT
  cartao,
  window_start AS janela_inicio,
  window_end AS janela_fim,
  COUNT(*) AS transacoes_60s,
  CAST(SUM(valor) AS DECIMAL(18,2)) AS valor_total,
  '3_OU_MAIS_TRANSACOES_EM_60_SEGUNDOS' AS regra
FROM TABLE(
  HOP(
    TABLE `payments.public.transacoes`,
    DESCRIPTOR(`$rowtime`),
    INTERVAL '5' SECOND,
    INTERVAL '60' SECOND
  )
)
GROUP BY cartao, window_start, window_end
HAVING COUNT(*) >= 3;

-- Evidência sugerida:
-- SELECT * FROM alertas_fraude;
