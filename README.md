# Pipeline de Pagamentos em Tempo Real com Confluent Cloud

Projeto de portfólio desenvolvido para demonstrar um pipeline de streaming de ponta a ponta: **PostgreSQL → CDC → Confluent Cloud → Flink SQL → alerta de fraude**.

> **Importante:** este repositório contém os scripts e configurações do pipeline. As evidências de execução (prints, eventos, métricas e custo) devem ser produzidas durante a execução real no Confluent Cloud. Não há evidências fictícias neste projeto.

## Arquitetura

```text
PostgreSQL
    │
    │ Change Data Capture (CDC)
    ▼
PostgreSQL CDC Source V2 (Debezium)
    │
    ├── payments.public.contas
    └── payments.public.transacoes
              │
              ▼
         Apache Flink SQL
              │
              ├── enriquecimento com dados da conta
              └── regra: 3+ transações/60 s
                          │
                          ▼
                    alertas_fraude
```

## Camadas do desafio

### 1. Fundação

Criar no Confluent Cloud:

- um Environment;
- um Kafka Cluster;
- Schema Registry;
- uma identidade/service account para escrita;
- outra identidade/service account para leitura/consumo;
- permissões mínimas necessárias para cada identidade.

A separação de identidades reduz o escopo de acesso e facilita auditoria.

**Evidência real sugerida:** `evidencias/01-cluster.png` e `evidencias/02-identidades.png`.

---

### 2. Contrato de dados

Os exemplos estão em:

```text
schemas/pagamento-v1.avsc
schemas/pagamento-v2.avsc
```

A versão 2 adiciona o campo opcional `cidade` com valor padrão `null`, mantendo compatibilidade backward em Avro.

O Schema Registry do Confluent usa `BACKWARD` como modo padrão. A ideia desta etapa é registrar a versão inicial e depois verificar se a evolução é aceita.

**Evidência real sugerida:** `evidencias/03-schema-v1.png` e `evidencias/04-schema-v2-compativel.png`.

---

### 3. Ingestão com CDC

O projeto usa o **PostgreSQL CDC Source V2 (Debezium)** do Confluent Cloud.

A documentação atual do Confluent identifica o plugin como:

```text
PostgresCdcSourceV2
```

O conector captura `INSERT`, `UPDATE` e `DELETE` e publica as alterações em tópicos Kafka.

Arquivo-modelo:

```text
connector/postgres-cdc.json.example
```

O exemplo utiliza:

```json
{
  "connector.class": "PostgresCdcSourceV2",
  "topic.prefix": "payments",
  "table.include.list": "public.contas,public.transacoes",
  "output.data.format": "AVRO"
}
```

> Nunca coloque API key, secret ou senha real neste arquivo versionado.

#### Atenção sobre o Postgres local

O `docker-compose.yml` deste repositório cria um Postgres preparado para replicação lógica, mas o **Confluent Cloud precisa conseguir alcançar o banco pela rede**. Um container em `localhost` não é acessível diretamente pelo serviço gerenciado do Confluent Cloud.

Para a execução real, use um PostgreSQL acessível pelo Confluent Cloud, por exemplo um banco em nuvem ou outra configuração de rede compatível com o seu ambiente.

#### Pré-requisitos do Postgres

O `docker-compose.yml` habilita:

```text
wal_level=logical
max_replication_slots=10
max_wal_senders=10
```

O banco também cria a publicação:

```text
dbz_publication
```

para as tabelas:

```text
public.contas
public.transacoes
```

Para conferir a configuração:

```bash
docker compose exec postgres psql -U postgres -d payments -f /dev/stdin < postgres/check-cdc.sql
```

Ou abra o arquivo `postgres/check-cdc.sql` e execute as consultas individualmente.

#### Gerando INSERT, UPDATE e DELETE

Depois que o conector estiver em estado **RUNNING**, execute:

```bash
docker compose exec -T postgres psql -U postgres -d payments < postgres/changes.sql
```

O arquivo gera:

1. um `INSERT`;
2. um `UPDATE`;
3. um `DELETE`;
4. três transações do mesmo cartão em até 60 segundos.

**Evidências reais sugeridas:**

```text
evidencias/05-connector-running.png
evidencias/06-cdc-insert.png
evidencias/07-cdc-update.png
evidencias/08-cdc-delete.png
```

---

### 4. Processamento com Flink SQL

Os arquivos estão em:

```text
flink/01-tabelas.sql
flink/02-enriquecimento.sql
flink/03-fraude.sql
```

#### 4.1 Tabelas de saída

Execute primeiro:

```text
flink/01-tabelas.sql
```

Ele cria:

- `transacoes_enriquecidas`;
- `alertas_fraude`.

No Confluent Cloud for Apache Flink, um `CREATE TABLE` cria uma tabela respaldada por um tópico Kafka e também os schemas correspondentes no Schema Registry.

#### 4.2 Enriquecimento

O arquivo `02-enriquecimento.sql` combina transações e contas usando **temporal join**:

```sql
LEFT JOIN `payments.public.contas`
FOR SYSTEM_TIME AS OF t.`$rowtime`
```

Isso permite utilizar a versão do cadastro da conta correspondente ao momento do evento.

> Os nomes `payments.public.contas` e `payments.public.transacoes` seguem o padrão esperado pelo `topic.prefix`. Confira os nomes inferidos no seu Workspace e ajuste se necessário.

**Evidência real sugerida:** `evidencias/09-flink-enriquecimento.png`.

#### 4.3 Regra de fraude

O arquivo `03-fraude.sql` implementa:

```text
mesmo cartão
+
3 ou mais transações
+
janela de 60 segundos
=
alerta de fraude
```

Foi usada uma janela `HOP` de 60 segundos, avançando a cada 5 segundos. Isso reduz o problema de uma janela fixa separar transações próximas que aconteceriam em lados diferentes da fronteira de um minuto.

Trecho central:

```sql
HOP(
  TABLE `payments.public.transacoes`,
  DESCRIPTOR(`$rowtime`),
  INTERVAL '5' SECOND,
  INTERVAL '60' SECOND
)
```

A condição final é:

```sql
HAVING COUNT(*) >= 3
```

Para visualizar os alertas:

```sql
SELECT * FROM alertas_fraude;
```

**Evidência real sugerida:** `evidencias/10-alerta-fraude.png`.

---

### 5. Operação, acesso e custo

Durante a execução, registrar:

- estado do conector;
- quantidade de registros processados;
- erros/retries;
- statements Flink em execução;
- consumo e métricas do cluster;
- custo gerado durante o período do teste.

**Evidências reais sugeridas:**

```text
evidencias/11-metricas.png
evidencias/12-custo.png
```

#### Custo real do projeto

Preencha após encerrar a execução:

```text
Período de execução: ____________________
Custo exibido no Confluent Cloud: _______
Moeda: _________________________________
Recursos utilizados: ____________________
```

Não foi colocado um valor estimado no repositório para não confundir estimativa com cobrança real.

---

## Como executar do zero

### 1. Clonar

```bash
git clone https://github.com/carolinacardinale/pipeline-pagamentos-confluent.git
cd pipeline-pagamentos-confluent
```

### 2. Criar variáveis locais

```bash
cp .env.example .env
```

Edite `.env` apenas localmente.

### 3. Subir o PostgreSQL local para estudo/teste

```bash
docker compose up -d
```

Verifique:

```bash
docker compose ps
```

Acesse:

```bash
docker compose exec postgres psql -U postgres -d payments
```

### 4. Conferir os dados

```sql
SELECT * FROM contas;
SELECT * FROM transacoes;
```

### 5. Criar os recursos no Confluent Cloud

Crie Environment, Kafka Cluster, Schema Registry e service accounts.

### 6. Registrar/testar o contrato

Use os schemas da pasta `schemas/` para demonstrar a evolução v1 → v2.

### 7. Criar o conector CDC

Use `connector/postgres-cdc.json.example` como referência e substitua somente os valores específicos do seu ambiente.

Confirme que o conector está `RUNNING` antes de gerar alterações no banco.

### 8. Executar o Flink SQL

Na ordem:

```text
flink/01-tabelas.sql
flink/02-enriquecimento.sql
flink/03-fraude.sql
```

### 9. Gerar alterações e fraude sintética

Execute `postgres/changes.sql` no PostgreSQL usado pelo conector.

### 10. Salvar as evidências

Adicione os arquivos reais em `evidencias/` e atualize esta documentação com os resultados obtidos.

---

## Como derrubar tudo

### PostgreSQL local

```bash
docker compose down
```

Para apagar também o volume e os dados locais:

```bash
docker compose down -v
```

### Confluent Cloud

Ao terminar:

1. pare/remova os statements Flink;
2. remova o conector CDC;
3. remova tópicos que não serão reutilizados;
4. revogue API keys não utilizadas;
5. remova service accounts de teste, quando aplicável;
6. remova o cluster/environment se foram criados exclusivamente para este desafio;
7. confirme a página de billing/cost antes de encerrar.

---

## Estrutura do repositório

```text
pipeline-pagamentos-confluent/
├── connector/
│   └── postgres-cdc.json.example
├── evidencias/
│   └── README.md
├── flink/
│   ├── 01-tabelas.sql
│   ├── 02-enriquecimento.sql
│   └── 03-fraude.sql
├── postgres/
│   ├── check-cdc.sql
│   ├── changes.sql
│   ├── init.sql
│   └── seed.sql
├── schemas/
│   ├── pagamento-v1.avsc
│   └── pagamento-v2.avsc
├── .env.example
├── .gitignore
├── docker-compose.yml
└── README.md
```

## Por que estas tecnologias?

**PostgreSQL:** representa um banco transacional comum em sistemas de pagamentos.

**CDC/Debezium:** publica alterações conforme elas acontecem, evitando depender de consultas batch periódicas.

**Kafka/Confluent Cloud:** desacopla produtores e consumidores e mantém os eventos disponíveis para múltiplos usos.

**Schema Registry:** formaliza o contrato dos eventos e reduz o risco de uma alteração de schema quebrar consumidores.

**Flink SQL:** permite enriquecer, agregar e detectar padrões em streams usando SQL.

## O que este projeto demonstra

- configuração de PostgreSQL para logical replication;
- CDC de `INSERT`, `UPDATE` e `DELETE`;
- evolução de schema Avro;
- Kafka e Schema Registry;
- temporal join no Flink SQL;
- processamento com janela móvel;
- geração de alerta de fraude;
- separação de credenciais;
- observabilidade e análise de custo.

## Segurança

Nunca versione:

- `.env`;
- API keys;
- API secrets;
- senhas de banco;
- certificados privados;
- credenciais exportadas do Confluent Cloud.

O arquivo `.env.example` contém apenas placeholders.

## Referências oficiais

- Confluent Cloud PostgreSQL CDC Source V2 (Debezium): https://docs.confluent.io/cloud/current/connectors/cc-postgresql-cdc-source-v2-debezium/cc-postgresql-cdc-source-v2-debezium.html
- Confluent Cloud Schema Registry: https://docs.confluent.io/cloud/current/sr/schema_registry_ccloud_tutorial.html
- Flink SQL CREATE TABLE: https://docs.confluent.io/cloud/current/flink/reference/statements/create-table.html
- Flink SQL joins: https://docs.confluent.io/cloud/current/flink/reference/queries/joins.html
- Flink windowing TVFs: https://docs.confluent.io/cloud/current/flink/reference/queries/window-tvf.html

## Autora

**Carolina Leite Cardinale**

Projeto desenvolvido como desafio prático de pipeline de dados em tempo real.
