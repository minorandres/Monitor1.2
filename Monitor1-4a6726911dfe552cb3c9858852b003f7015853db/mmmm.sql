SELECT d.datname AS Name,  pg_catalog.pg_get_userbyid(d.datdba) AS Owner,
    CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
        THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
        ELSE 'No Access'
    END AS Size
FROM pg_catalog.pg_database d
    ORDER BY
    CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
        THEN pg_catalog.pg_database_size(d.datname)
        ELSE NULL
    END DESC -- nulls first
    LIMIT 20;
	
	
select datname,pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(datname)) from pg_catalog.pg_database;

  datname  | pg_size_pretty
-----------+----------------
 template1 | 6185 kB
 template0 | 6185 kB
 postgres  | 6282 kB
 maynor    | 6298 kB
(4 filas)

SELECT d.datname as "Name",
       r.rolname as "Owner",
       pg_catalog.pg_encoding_to_char(d.encoding) as "Encoding",
       pg_catalog.shobj_description(d.oid, 'pg_database') as "Description",
       t.spcname as "Tablespace"
FROM pg_catalog.pg_database d
  JOIN pg_catalog.pg_roles r ON d.datdba = r.oid
  JOIN pg_catalog.pg_tablespace t on d.dattablespace = t.oid
ORDER BY 1;
**************************

                           List of databases
   Name    | Owner  | Encoding |        Description        | Tablespace
-----------+--------+----------+---------------------------+------------
 postgres  | pyarra | LATIN1   |                           | pg_default
 pyarra    | pyarra | LATIN1   |                           | pg_default
 spctest   | pyarra | LATIN1   |                           | spctable
 template0 | pyarra | LATIN1   |                           | pg_default
 template1 | pyarra | LATIN1   | Default template database | pg_default
 
 
 SELECT
    table_name,
    pg_size_pretty(table_size) AS table_size
FROM (
    SELECT
        table_name,
        pg_table_size(table_name) AS table_size
    FROM (
        SELECT ('"' || table_schema || '"."' || table_name || '"') AS table_name
        FROM information_schema.tables
    ) AS all_tables
) AS pretty_sizes


maynor=# select * from information_schema.tables;
 table_catalog |    table_schema    |              table_name               | table_type | self_referencing_column_name | reference_generation | user_defined_type_catalog | user_defined_type_schema | user_defined_type_name | is_insertable_into | is_typed | commit_action

 maynor        | pg_catalog         | pg_statistic                          | BASE TABLE |                              |                      |      				       |                          |                        | YES 				| NO       |
 maynor        | pg_catalog         | pg_type                               | BASE TABLE |                              |                      |         				   |                          |                        | YES  			    | NO       |
 maynor        | public             | persona                               | BASE TABLE |                              |                      |       				       |                          |                        | YES   			    | NO       |
 
 
  copy(
 SELECT schema, name,
   pg_size_pretty(s) AS size,
   pg_size_pretty(st - s) AS index,
   (100.0 * s / NULLIF(st, 0))::numeric(10,1) AS "% data of total",
   st AS total
 FROM (
   SELECT n.nspname AS schema,
          c.relname AS name,
          pg_relation_size(c.oid) AS s,
          pg_total_relation_size(c.oid) AS st
   FROM pg_class c, pg_namespace n
   WHERE c.relnamespace = n.oid 
 ) as query where schema='public'
 ORDER BY st DESC
 )to e'D:\\Maynor\\try.sql';
 
 
 public	musica	8192 bytes	8192 bytes	50.0	16384
 
 --ESTAs 2 LINEAs ME DA LA CANT DE TUPLAS EN CADA TABLA
 copy(SELECT relname, reltuples, relpages * 8 / 1024 AS "MB" FROM pg_class ORDER BY reltuples DESC )to e'D:\\Maynor\\try.sql';
 VACUUM;

 
 -- musica 60 tuplas
 
  schema |  name   |    size    | index | % data of total | total
--------+---------+------------+-------+-----------------+-------
 public | musica  | 8192 bytes | 40 kB |            16.7 | 49152
(2 filas)


maynor=# vacuum;
--musica 0 tuplas
 schema |  name   |    size    | index | % data of total | total
--------+---------+------------+-------+-----------------+-------
 public | musica  | 0 bytes    | 24 kB |             0.0 | 24576
(2 filas)

--musica 1 tupla
 schema |  name   |    size    | index | % data of total | total
--------+---------+------------+-------+-----------------+-------
 public | musica  | 8192 bytes | 40 kB |            16.7 | 49152
 
 --musica 241 tuplas
  schema |  name   |    size    | index | % data of total | total
--------+---------+------------+-------+-----------------+-------
 public | musica  | 16 kB      | 40 kB |            28.6 | 57344
 
 /*5-Cada vez que se le de click, a un tablespace el mismo deberá desplegar mediante un gráfico de pastel,
 todas aquellas tablas y objetos que son contenidos en dicho tablespace. Además deberá indicar el tamaño
 relativo de dichos objetos.TAMANO EN BYTES*/
 SELECT   c.relname,t.spcname,(pg_total_relation_size(c.oid))as TAM_EN_BYTES 
	FROM pg_class c,pg_tablespace t 
	WHERE t.spcname='pg_global'
	ORDER BY spcname,tam_en_bytes DESC;
	
 SELECT   t.spcname,pg_size_pretty(pg_tablespace_size(t.spcname))as TOTAL,
		  SUM(pg_total_relation_size(c.oid))as TAM_EN_BYTES,
		  pg_size_pretty(SUM(pg_total_relation_size(c.oid)))as TAM_EN_MB
	FROM pg_class c,pg_tablespace t WHERE t.spcname='pg_global'
	GROUP BY t.spcname;
	
	
SELECT 
  c.relname, 
  t.spcname 
FROM 
  pg_class c 
    JOIN pg_tablespace t ON c.reltablespace = t.oid 
WHERE 
  t.spcname = 'indexes_old';
  
  
/* HAY UN PROBLEMA GRANDE DE INCONSISTENCIA EN POSTGRES
postgres=# select c.relname,c.reltablespace from pg_class c;
                 relname                 | reltablespace
-----------------------------------------+---------------
 pg_statistic                            |             0
 pg_type                                 |             0
 pg_toast_16410                          |             0
 pg_toast_16410_index                    |             0
 musica                                  |             0
 lupe                                    |         16417
 pg_toast_2619                           |             0
 pg_toast_2619_index                     |             0
 pg_authid_rolname_index                 |          1664
 pg_authid_oid_index                     |          1664
 pg_attribute_relid_attnam_index         |             0
 pg_attribute_relid_attnum_index         |             0
 pg_toast_1255                           |             0


postgres=# select spcname,oid from pg_tablespace;
  spcname    |  oid
-------------+-------
pg_default   |  1663
pg_global    |  1664
tablaespacio | 16417


postgres=# select relname,reltablespace,t.oid from pg_class c,pg_tablespace t
postgres-# where c.reltablespace=t.oid;
                 relname                 | reltablespace |  oid
-----------------------------------------+---------------+-------
 lupe                                    |         16417 | 16417
 pg_authid_rolname_index                 |          1664 |  1664
 pg_authid_oid_index                     |          1664 |  1664
 pg_toast_2964                           |          1664 |  1664
 pg_toast_2964_index                     |          1664 |  1664
 pg_auth_members_role_member_index       |          1664 |  1664
 pg_auth_members_member_role_index       |          1664 |  1664
 pg_toast_2396                           |          1664 |  1664
 pg_toast_2396_index                     |          1664 |  1664
 pg_database_datname_index               |          1664 |  1664
 pg_database_oid_index                   |          1664 |  1664
 pg_tablespace_oid_index                 |          1664 |  1664
 pg_tablespace_spcname_index             |          1664 |  1664
 pg_pltemplate_name_index                |          1664 |  1664
 pg_shdepend_depender_index              |          1664 |  1664
 pg_shdepend_reference_index             |          1664 |  1664
 pg_shdescription_o_c_index              |          1664 |  1664
 pg_authid                               |          1664 |  1664
 pg_shseclabel_object_index              |          1664 |  1664
 pg_database                             |          1664 |  1664
 pg_db_role_setting                      |          1664 |  1664
 pg_tablespace                           |          1664 |  1664
 pg_pltemplate                           |          1664 |  1664
 pg_auth_members                         |          1664 |  1664
 pg_shdepend                             |          1664 |  1664
 pg_shdescription                        |          1664 |  1664
 pg_shseclabel                           |          1664 |  1664
 pg_db_role_setting_databaseid_rol_index |          1664 |  1664
(28 filas)



select spcname,SUM(pg_total_relation_size(c.oid))as TAM_EN_BYTES from pg_class c,pg_tablespace t
where c.reltablespace=t.oid group by spcname;

******* PROBANDO, NO APARECE NADA PARA PG_DEFAULT

postgres=# select SUM(pg_total_Relation_size(c.oid))as TAM from pg_class c,pg_ta
blespace t where t.oid=c.reltablespace and t.oid=1664;
  tam
--------
 688128
(1 fila)


postgres=# select SUM(pg_total_Relation_size(c.oid))as TAM from pg_class c,pg_ta
blespace t where t.oid=c.reltablespace and t.oid='1663';
 tam
-----

(1 fila)


postgres=# select SUM(pg_total_Relation_size(c.oid))as TAM from pg_class c,pg_ta
blespace t where t.oid=c.reltablespace and t.oid=16417;
 tam
------
 8192
(1 fila)

SELECT (spcname)as tablespace,
	    (pg_size_pretty(SUM(pg_total_Relation_size(c.oid))))as TAM_ACT,
		(pg_size_pretty(pg_tablespace_size(spcname)))as TAM_TOT
		FROM pg_class c,pg_tablespace t 
		WHERE t.oid=c.reltablespace
		GROUP BY tablespace;

  tablespace  |  tam_act   |  tam_tot
--------------+------------+------------
 tablaespacio | 8192 bytes | 8192 bytes
 pg_global    | 672 kB     | 469 kB*/
 
 
 
 
 SELECT (spcname)as tablespace,
	    SUM(pg_total_Relation_size(c.oid))as TAM_ACT,
		(pg_tablespace_size(spcname))as TAM_TOT,
		(pg_size_pretty(SUM(pg_total_Relation_size(c.oid))))as tam_act_mb,
		(pg_size_pretty(pg_tablespace_size(spcname)))as tam_tot_mb
		FROM pg_class c,pg_tablespace t 
		WHERE t.oid=c.reltablespace
		GROUP BY tablespace;



  