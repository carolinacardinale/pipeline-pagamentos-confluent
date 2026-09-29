-- Verificações úteis antes/depois de subir o conector CDC.

SHOW wal_level;
SHOW max_replication_slots;
SHOW max_wal_senders;

SELECT pubname, puballtables
FROM pg_publication
WHERE pubname = 'dbz_publication';

SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'dbz_publication'
ORDER BY schemaname, tablename;

-- Depois que o conector criar o slot, ele deve aparecer aqui.
SELECT slot_name, plugin, slot_type, active, restart_lsn
FROM pg_replication_slots;
