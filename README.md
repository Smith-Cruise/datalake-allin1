# datalake-allin1
One command to start your data lake test env! Including Hive metasotre, trino, minio, starrocks, spark, ... etc.

## What
Now we are using minio as storage, hive metastore and trino for writing.

## How

Start cluster:
```bash
docker-compose up
```

Stop cluster:
```bash
docker-compose down
```

Resume cluster:
Change `IS_RESUME` flag to 'true' in metastore-standalone.
```bash
docker-compose up
```

Restart new cluster:
```bash
rm -rf data

docker-compose up
```

Insert data:
```bash
docker exec -it trino trino
```

```sql
create schema hive.test;

create table hive.test.region as select * from tpch.sf1.region;

select * from hive.test.region;
```
