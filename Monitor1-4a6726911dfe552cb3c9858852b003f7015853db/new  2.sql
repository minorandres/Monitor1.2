CREATE TABLE REGISTROS(
	tabla varchar2(500),
	tablespace varchar2(500),
	fecha DATE,
	total_registros NUMBER,
	tamanio_total_mb NUMBER,
	nuevos_registros NUMBER,
	CONSTRAINT  PKREGISTROS PRIMARY KEY (tabla,tablespace,fecha)
	);



create table a(algo varchar(100));

BEGIN
DBMS_SCHEDULER.CREATE_JOB(job_name        => 'MANTENIMIENTO_DBA',
                          job_type        => 'PLSQL_BLOCK',
                          JOB_ACTION      => 'BEGIN PROCESO; END;',
                          start_date      => '10-SEP-13 03.22.00AM',
                          repeat_interval => 'FREQ=DAILY;',
                          end_date        => NULL,
                          enabled         => TRUE,
                          comments        => 'Calls PLSQL once');
END;
/

BEGIN
DBMS_SCHEDULER.RUN_JOB (
   'MANTENIMIENTO_DBA',TRUE);
   END;
/


CREATE OR REPLACE PROCEDURE P001
IS
	fecha timestamp;
BEGIN
	select cast(sysdate as timestamp) INTO fecha from dual;
	insert into prueba values(fecha);
   END;
/
BEGIN
DBMS_SCHEDULER.CREATE_JOB(job_name        => 'PR',
                          job_type        => 'PLSQL_BLOCK',
                          JOB_ACTION      => 'BEGIN P001; END;',
                          start_date      => '09-SEP-13 09.41.00PM',
                          repeat_interval => 'FREQ=MINUTELY;',
                          end_date        => NULL,
                          enabled         => TRUE,
                          comments        => 'Calls PLSQL once');
END;
/




exec dbms_scheduler.drop_job('yuri', TRUE);

SELECT JOB_NAME FROM DBA_SCHEDULER_JOBS;

set serveroutput on;
CREATE OR REPLACE PROCEDURE PROCESO
	IS
		 sql_str VARCHAR2(1000);
		 aaa VARCHAR2(100);
		 feza DATE;
	BEGIN
		--select count(*) into aaa from fechas;
		sql_str := 'SELECT COUNT(*) from fechas';--('''||aaa||''')';
		EXECUTE IMMEDIATE sql_str INTO aaa;
		sql_str := 'INSERT INTO bonito values('''||aaa||''')';
		EXECUTE IMMEDIATE sql_str;
		exception
			when no_data_found then 	
				sql_str := 'INSERT INTO bonito values(''kkkkkk'')';
				EXECUTE IMMEDIATE sql_str;
	END PROCESO;
/



















































BEGIN
  DBMS_SCHEDULER.create_job (
    job_name        => 'PRUEBALA',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN PPP; END;',
    start_date      => '4/09/13 9:59:00',
    repeat_interval => 'freq=secondly;',
    end_date        => NULL,
    enabled         => TRUE,
    comments        => 'Job defined entirely by the CREATE JOB procedure.');
END;
/

-- created the AQ code to do this is not included here
BEGIN
  dbms_scheduler.create_event_schedule(
			'TEST_EVENTS_SCHED', 
			SYSTIMESTAMP,
			event_condition => 'tab.user_data.event_type = ''ZERO_BALANCE''', 
  queue_spec => 'entry_events_q, entry_agent1');
END;
/

BEGIN
DBMS_SCHEDULER.CREATE_JOB (
   job_name             => 'my_job2',
   job_type             => 'PLSQL_BLOCK',
   job_action           => 'EXEC PPP; END;',
   start_date           => '04-SEP-13 10.16.00PM',
   repeat_interval      => 'FREQ=SECONDLY', 
   end_date             => '15-SEP-13 1.00.00AM',
   enabled              =>  TRUE,
   comments             => 'xxxxxxxxxxxxxxxxxxxxxxxxxxx');
END;
/


SELECT SEGMENT_NAME, SUM(BYTES)/1024/1024 
FROM DBA_EXTENTS 
WHERE TABLESPACE_NAME = 'ACADEMICO'
GROUP BY SEGMENT_NAME
ORDER BY 2 DESC;


SELECT SEGMENT_NAME, (SUM(BYTES)/1024/1024) tam
FROM DBA_EXTENTS
WHERE TABLESPACE_NAME = 'ACADEMICO'
AND segment_name='PANCHOS'
GROUP BY SEGMENT_NAME;

select count(*) 
from user_tab_columns
where table_name='BONITO'

CREATE TABLE REGISTROS(
	tabla varchar2(100),
	tablespace varchar2(100),
	fecha DATE,
	total_registros number,
	tamanio_total_mb NUMBER,
	nuevos_registros number
	);
set serveroutput on;	
CREATE OR REPLACE PROCEDURE REGISTRAR	
	IS
		 sql_str VARCHAR2(1000);
		 tam NUMBER;
		 tam_act NUMBER;
		 nuevos_reg int;
	BEGIN
		FOR tablespace IN (SELECT NAME from V$TABLESPACE)	
		LOOP
			dbms_output.put_line(''||tablespace.name||'');
			FOR tabla IN (select SEGMENT_NAME,SUM(BYTES)/1024/1024 from dba_EXTENTS where TABLESPACE_NAME=tablespace.NAME group by SEGMENT_NAME)
			LOOP dbms_output.put_line('''TABLA: '||tablespace.name||'');
				---total individuos
				sql_str := 'SELECT COUNT(*) into tam_act FROM '||tabla.SEGMENT_NAME;	
				EXECUTE IMMEDIATE sql_str;				
				--proc devuelve el valor de nuevos reg buscando el ultimo reg existente y restando el total act y el del existente
				NUEVOS_INDIVIDUOS(tam_act,nuevos_reg);
				--tamanio
				SELECT SUM(BYTES)/1024/1024 INTO tam FROM DBA_EXTENTS WHERE TABLESPACE_NAME = tablespace.name  AND segment_name=tabla.SEGMENT_NAME GROUP BY SEGMENT_NAME;--tamanio
				--insertando todo en tabla de registro
				sql_str := 'INSERT INTO REGISTRO VALUES(
							'''||tabla.SEGMENT_NAME||
							''','''||tablespace.NAME||
							''','''||SYSDATE||''','''
							||tam_act||''','''||tam||
							''','''||nuevos_reg||''')';
				EXECUTE IMMEDIATE sql_str;
			END LOOP;
		END LOOP;
		EXCEPTION
			WHEN no_data_found THEN--- si es el primer registro
					sql_str := 'INSERT INTO bonito values(''ERRORMALDITO'')';
				EXECUTE IMMEDIATE sql_str;
	   END REGISTRAR;
 /	
 EXEC REGISTRAR;
 
 
 CREATE OR REPLACE PROCEDURE NUEVOS_INDIVIDUOS(actual_total IN INT,nuevos OUT INT)
	IS
		anterior_total int;		
	BEGIN
		-- obtiener total_registros de la ultima fecha registrada(anterior)
		select total_registros INTO anterior_total 
		from (select total_registros 
				from registros order by fecha desc)
				where rownum=1;
		--obteniendo total de nuevos registros
		nuevos:= actual_total-anterior_total;--(RETURN)
		EXCEPTION
			WHEN no_data_found THEN--- si es el primer registro
				nuevos:= actual_total;--(RETURN)
	END NUEVOS_INDIVIDUOS;
/
		
		
		
		
		
		
		select nuevos_registros into AUXNUM 
		from (select nuevos_registros 
				from registro where fecha<fecha_act
				and registro.tabla=tabla.SEGMENT_NAME order by fecha desc) where rownum=1;
		EXCEPTION
			WHEN no_data_found THEN
				RETURN 0;
	END NUEVOS_INDIVIDUOS;
/



bysecond_clause = "BYSECOND" "=" second_list
   second_list = second ( "," second)*
   second = 0 through 59
   
   
DROP USER miusuario CASCADE;

CREATE USER miusuario IDENTIFIED BY miclavesecreta
       DEFAULT TABLESPACE ACADEMICO 
       TEMPORARY TABLESPACE temp
       QUOTA UNLIMITED ON ACADEMICO;

CREATE ROLE programador;

GRANT CREATE session, CREATE table, CREATE view, 
      CREATE procedure,CREATE synonym,
      ALTER table, ALTER view, ALTER procedure,ALTER synonym,
      DROP table, DROP view, DROP procedure,DROP synonym,
      TO miusuario;

GRANT programador TO miusuario;