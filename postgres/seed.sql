INSERT INTO contas (nome, cartao, limite, status)
VALUES
    ('Ana Souza', '5555444433331111', 5000.00, 'ATIVA'),
    ('Bruno Lima', '4111111111111111', 3000.00, 'ATIVA'),
    ('Carla Mendes', '4000000000000002', 7500.00, 'ATIVA')
ON CONFLICT (cartao) DO NOTHING;

INSERT INTO transacoes (conta_id, cartao, valor, estabelecimento, cidade, data_hora)
SELECT id, cartao, 89.90, 'Mercado Central', 'Bauru', CURRENT_TIMESTAMP - INTERVAL '5 minutes'
FROM contas WHERE cartao = '5555444433331111';

INSERT INTO transacoes (conta_id, cartao, valor, estabelecimento, cidade, data_hora)
SELECT id, cartao, 149.90, 'Livraria Exemplo', 'Bauru', CURRENT_TIMESTAMP - INTERVAL '3 minutes'
FROM contas WHERE cartao = '4111111111111111';
