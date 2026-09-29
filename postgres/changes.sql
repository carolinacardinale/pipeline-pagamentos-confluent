-- Execute este arquivo DEPOIS que o conector CDC estiver RUNNING.
-- Ele gera evidências de INSERT, UPDATE e DELETE e também três transações
-- para o mesmo cartão em menos de 60 segundos.

-- 1) INSERT
INSERT INTO transacoes (conta_id, cartao, valor, estabelecimento, cidade, data_hora)
SELECT id, cartao, 59.90, 'Loja CDC Insert', 'Bauru', CURRENT_TIMESTAMP
FROM contas WHERE cartao = '5555444433331111';

-- 2) UPDATE no registro recém-criado
UPDATE transacoes
SET valor = 69.90,
    estabelecimento = 'Loja CDC Update'
WHERE id = (SELECT MAX(id) FROM transacoes);

-- 3) DELETE
DELETE FROM transacoes
WHERE id = (SELECT MAX(id) FROM transacoes);

-- 4) Cenário sintético de fraude: 3 transações do mesmo cartão em 60 segundos
INSERT INTO transacoes (conta_id, cartao, valor, estabelecimento, cidade, data_hora)
SELECT id, cartao, 49.90, 'Loja A', 'Bauru', CURRENT_TIMESTAMP
FROM contas WHERE cartao = '5555444433331111';

INSERT INTO transacoes (conta_id, cartao, valor, estabelecimento, cidade, data_hora)
SELECT id, cartao, 79.90, 'Loja B', 'Bauru', CURRENT_TIMESTAMP + INTERVAL '20 seconds'
FROM contas WHERE cartao = '5555444433331111';

INSERT INTO transacoes (conta_id, cartao, valor, estabelecimento, cidade, data_hora)
SELECT id, cartao, 129.90, 'Loja C', 'Bauru', CURRENT_TIMESTAMP + INTERVAL '40 seconds'
FROM contas WHERE cartao = '5555444433331111';
