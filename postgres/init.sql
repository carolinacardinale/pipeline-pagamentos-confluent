CREATE TABLE IF NOT EXISTS contas (
    id BIGSERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    cartao VARCHAR(20) UNIQUE NOT NULL,
    limite NUMERIC(12,2) NOT NULL CHECK (limite >= 0),
    status VARCHAR(20) NOT NULL DEFAULT 'ATIVA',
    atualizado_em TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS transacoes (
    id BIGSERIAL PRIMARY KEY,
    conta_id BIGINT NOT NULL REFERENCES contas(id),
    cartao VARCHAR(20) NOT NULL,
    valor NUMERIC(12,2) NOT NULL CHECK (valor > 0),
    estabelecimento VARCHAR(120) NOT NULL,
    cidade VARCHAR(80) NOT NULL,
    data_hora TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Ajuda o CDC a representar UPDATE/DELETE com todos os dados anteriores.
ALTER TABLE contas REPLICA IDENTITY FULL;
ALTER TABLE transacoes REPLICA IDENTITY FULL;

-- Publicação usada pelo conector PostgreSQL CDC V2 (Debezium).
-- Se já existir, o bloco apenas mantém a configuração atual.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'dbz_publication') THEN
        CREATE PUBLICATION dbz_publication FOR TABLE contas, transacoes;
    END IF;
END
$$;
