# Datalake all in 1
One command to start your data lake test env! Including Hive metasotre, trino, rustfs, starrocks, spark, ... etc.

## What
Now we are using [RustFS](https://github.com/rustfs/rustfs) as storage, hive metastore and trino for writing.

Trino catalogs:
- `hms_catalog`: Hive / Iceberg / Delta tables on Hive metastore, data in bucket `warehouse`.
- `iceberg_rest`: Iceberg tables on RustFS built-in Iceberg REST catalog (S3 Tables), data in table bucket `iceberg-rest`.

## How

You need to `git clone https://github.com/Smith-Cruise/datalake-allin1.git` first, then `cd datalake-allin1`.

Start cluster:
```bash
docker-compose up
```

Stop cluster:
```bash
docker-compose down
```

Resume cluster:
Change `IS_RESUME` flag to `true` in metastore-standalone.
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

Iceberg REST catalog:
```sql
create schema iceberg_rest.test;

create table iceberg_rest.test.region as select * from tpch.sf1.region;

select * from iceberg_rest.test.region;
```

> RustFS does not support `purgeRequested=true`, so `DROP TABLE` in Trino fails on `iceberg_rest`.
> Remove the catalog entry with rc instead (data files are kept)
