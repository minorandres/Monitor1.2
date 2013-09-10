set serveroutput on;	

CREATE TABLE REGISTROS(
	tabla varchar2(500),
	tablespace varchar2(500),
	fecha DATE,
	total_registros NUMBER,
	tamanio_total_mb NUMBER,
	nuevos_registros NUMBER,
	CONSTRAINT  PKREGISTROS PRIMARY KEY (tabla,tablespace,fecha)
	);

-- CONSULTA PARA OBTENER DATOS: SELECT * FROM REGISTROS ORDER BY TABLA,FECHA;

CREATE TABLE ERROR(
    DESCRIPCION VARCHAR2(1000);
);

CREATE TABLE LLENADO( --- TABLA FINAL TIEMPO RESTANTE EN DIAS P/llenarse
	TABLESPACE VARCHAR2(500),
	DIAS VARCHAR2(500)
	);
	
CREATE TABLE TAM_MAX_TABLA(
	TABLA VARCHAR2(500),
	DIAS NUMBER,
	TABLESPACE VARCHAR2(500)
	);

 
 --algunas tablas tienen el num_rows vacio que es necesario para hacer la estimacion de crecimiento, este proceso hace que aparezcan  
CREATE OR REPLACE PROCEDURE DESBLOQUEAR_ESTADISTICAS
	IS 	
	begin
		FOR e IN(select DISTINCT owner from dba_tab_statistics where stattype_locked is not null)
		LOOP
			dbms_stats.unlock_schema_stats(ownname => e.owner);
		END LOOP;	
		dbms_utility.analyze_database('COMPUTE');--dura como 2 min
	END;
/

CREATE OR REPLACE PROCEDURE NUEVOS_INDIVIDUOS(actual_total IN NUMBER,nombre_tabla IN VARCHAR2,nuevos OUT NUMBER)
	IS
		anterior_total NUMBER;
		query VARCHAR2(1000);
	BEGIN
		-- obtiener total_registros de la ultima fecha registrada en tabla(nombre_tabla)(anterior)
		select total_registros INTO anterior_total 
		from (select total_registros 
				from registros WHERE tabla=nombre_tabla order by fecha desc)
				where rownum=1;
		--obteniendo total de nuevos registros
		nuevos:= actual_total-anterior_total;--(RETURN)
		EXCEPTION
			WHEN no_data_found THEN--- si es el primer registro
				nuevos:= actual_total;--(RETURN)
			WHEN OTHERS THEN
				query:='INSERT INTO ERROR VALUES(''ERROR DATA NOT FOUND ON SYS.NUEVOS_INDIVIDUOS PROC-->'||nombre_tabla||''')';
				EXECUTE IMMEDIATE query;
				nuevos:= actual_total;				
	END NUEVOS_INDIVIDUOS;
/

--dura alrededor de 5 minutos
CREATE OR REPLACE PROCEDURE REGISTRAR	
	IS
		 sql_str VARCHAR2(1000);
		 tam NUMBER;
		 gente_act NUMBER;
		 nuevos_reg NUMBER;
	BEGIN
		gente_act:=0;
		DESBLOQUEAR_ESTADISTICAS;
		FOR tablespace IN (SELECT NAME from V$TABLESPACE)	
		LOOP
			--FOR TODAS LAS TABLAS EN EL TABLESPACE, HAY QUE HACER UNION CON ALL_TABLES PORQUE LOS EXTENTS PUEDEN SER OTRAS COSAS ADEMAS DE TABLAS
			FOR tabla IN (SELECT SEGMENT_NAME,SUM(BYTES)/1024/1024 FROM ALL_TABLES,DBA_EXTENTS WHERE ALL_TABLES.TABLESPACE_NAME=TABLESPACE.NAME AND SEGMENT_NAME=TABLE_NAME GROUP BY SEGMENT_NAME)
			LOOP
				---total individuos
				FOR e IN (select distinct num_rows from all_tables where table_name=TABLA.SEGMENT_NAME)
				LOOP
					gente_act:=e.num_rows;
				END LOOP;				
				--tamanio
				SELECT SUM(BYTES)/1024/1024 INTO tam FROM DBA_EXTENTS WHERE TABLESPACE_NAME = tablespace.name  AND segment_name=tabla.SEGMENT_NAME GROUP BY SEGMENT_NAME;--tamanio
				--proc devuelve el valor de nuevos reg buscando el ultimo reg existente y restando el total act y el del existente
				NUEVOS_INDIVIDUOS(gente_act,tabla.segment_name,nuevos_reg);
				--insertando todo en tabla de registro
				sql_str := 'INSERT INTO REGISTROS VALUES(
							'''||tabla.SEGMENT_NAME||
							''','''||tablespace.NAME||
							''','''||SYSDATE||''','''
							||gente_act||''','''||tam||
							''','''||nuevos_reg||''')';
				EXECUTE IMMEDIATE sql_str;
			END LOOP;
		END LOOP;
		EXCEPTION
			WHEN no_data_found THEN--- si es el primer registro
				dbms_output.put_line('ERROR DATA NOT FOUND ON SYS.REGISTRAR PROC');
	   END REGISTRAR;
 /	



	-- total registros en X tabla en la ultima fecha registrada-- debe ser ejecutado despues de registrar(recoleccion datos)
CREATE OR REPLACE PROCEDURE CALC_NUM_COLS(nombre_tabla IN VARCHAR2,columnas OUT NUMBER)
	IS	
		 CURSOR micursor IS
           select COUNT(*) from registros where tabla=nombre_tabla;	
		num_cols NUMBER;
	BEGIN
		IF NOT micursor%ISOPEN
		THEN
          OPEN micursor;
		END IF;
		LOOP		  
		   FETCH micursor INTO num_cols;
			 EXIT WHEN micursor%NOTFOUND;
		END LOOP;
       CLOSE micursor;	
		columnas:=num_cols;
	END;
/

CREATE OR REPLACE PROCEDURE CALC_TABLESPACE(ESPACIO IN VARCHAR2)
	IS	
		suma NUMBER;
		contador NUMBER;
		query VARCHAR2(500);
		r NUMBER;
	BEGIN
		SELECT SUM(tam) INTO suma FROM TAM_MAX_TABLA WHERE TABLESPACE=ESPACIO;
		SELECT COUNT(*) INTO contador FROM TAM_MAX_TABLA WHERE TABLESPACE=ESPACIO;--N tablas
		IF contador > 0 THEN -- hay tablespace sin actividad de ningun tipo
			r:=ROUND((SUMA/contador));		
			dbms_output.put_line(ESPACIO||'x'||r);
			query :='INSERT INTO LLENADO VALUES('''||ESPACIO||''','''||r||''')';
			EXECUTE IMMEDIATE query;	
		ELSE
			query :='INSERT INTO LLENADO VALUES('''||ESPACIO||''','''||'INDEFINIDO'')';
			EXECUTE IMMEDIATE query;	
		END IF;
	END;
/

CREATE OR REPLACE PROCEDURE	CALC_DIAS_LLENADO(espacio_libre IN NUMBER,numero_a IN NUMBER,numero_b IN NUMBER,prom_crec_tabla IN NUMBER ,dias_lleno OUT NUMBER,tablon in varchar2)
	IS	
		suma NUMBER;
	BEGIN
		suma:= (espacio_libre+numero_b)/numero_a;
		dias_lleno:=suma/prom_crec_tabla;
	END;
/

CREATE OR REPLACE PROCEDURE CALC_VARIANZA(prom_gente IN NUMBER,num_cols IN NUMBER,la_tabla IN VARCHAR2,varianza OUT NUMBER)
	IS	
		suma NUMBER;
	BEGIN
		select sum((total_registros-prom_gente)*(total_registros-prom_gente)) INTO suma
						from registros  where tabla=la_tabla;
		varianza:=suma/num_cols;
	END;
/

CREATE OR REPLACE PROCEDURE CALC_A(prom_gente IN NUMBER,prom_mb IN NUMBER,num_cols IN NUMBER,la_tabla IN VARCHAR2,varianza IN NUMBER,numero_a OUT NUMBER)
	IS
		suma NUMBER;
	BEGIN
		SELECT SUM((TOTAL_REGISTROS-prom_gente)*(TAMANIO_TOTAL_MB-prom_mb)) INTO suma 
		FROM REGISTROS WHERE TABLA=la_tabla;
		numero_a:=suma/(num_cols*varianza);
	END;
/

CREATE OR REPLACE PROCEDURE CALC_B(prom_gente IN NUMBER,prom_mb IN NUMBER,numero_a IN NUMBER,numero_b OUT NUMBER)
	IS
	BEGIN
		numero_b:=prom_mb-(numero_a*prom_gente);
	END;
/


/* debe ejecutarse despues de haber hecho el analisis en registrar*/
CREATE OR REPLACE PROCEDURE TIEMPO_LLENADO
	IS
		num_cols NUMBER;
		prom_mb NUMBER;
		prom_gente NUMBER;
		varianza NUMBER;
		numero_a NUMBER;
		numero_b NUMBER;
		prom_crec_tabla NUMBER;
		dias_lleno NUMBER;
		query VARCHAR2(500);
	BEGIN	
		FOR espacio_tabla IN( select df.tablespace_name as Tablespace,(df.totalspace - tu.totalusedspace) as Free_MB,
								df.totalspace as Total_MB from (select tablespace_name,(sum(bytes) / 1048576) TotalSpace
																from dba_data_files group by tablespace_name) df,
																(select (sum(bytes)/(1024*1024)) totalusedspace, 
																tablespace_name from dba_segments group by tablespace_name) tu
																where df.tablespace_name = tu.tablespace_name )
		LOOP
		--FOR CADA TABLA en tablespace
			FOR elemento IN (select r1.tabla as tabla,sum(r1.tamanio_total_mb) as sum_mb,SUM(r1.total_registros)as  sum_gente 
							from registros r1,registros	r2 
							where r1.tabla=r2.tabla and r1.tablespace=espacio_tabla.Tablespace group by r1.tabla)
			LOOP
					CALC_NUM_COLS(elemento.tabla,num_cols);
					IF num_cols > 0 THEN -- ELSE NO SE TOMAN EN CUENTA
						prom_mb:=elemento.sum_mb/num_cols;
						prom_gente:=elemento.sum_gente/num_cols;
						CALC_VARIANZA(prom_gente,num_cols,elemento.tabla,varianza);
						IF varianza>0 THEN -- ELSE NO SE TOMAN EN CUENTA NO SE PUEDE /0
							CALC_A(prom_gente,prom_mb,num_cols,elemento.tabla,varianza,numero_a);
							CALC_B(prom_gente,prom_mb,numero_a,numero_b);
							select (sum(nuevos_registros)/num_cols) into prom_crec_tabla 
								from registros where tabla=elemento.tabla AND TABLESPACE=espacio_tabla.Tablespace;
							IF prom_crec_tabla<>0 THEN
								CALC_DIAS_LLENADO(espacio_tabla.Free_MB,numero_a,numero_b,prom_crec_tabla,dias_lleno,elemento.tabla);
								query := 'INSERT INTO TAM_MAX_TABLA VALUES
										('''||elemento.tabla||''','''||dias_lleno||''','''||espacio_tabla.Tablespace||''')';
								EXECUTE IMMEDIATE query;
							END IF;
						END IF;
					END IF;									
			END LOOP;
			CALC_TABLESPACE(espacio_tabla.Tablespace);
		END LOOP;
	END TIEMPO_LLENADO;
/


BEGIN
DBMS_SCHEDULER.CREATE_JOB(job_name        => 'MANTENIMIENTO_DBA',
                          job_type        => 'PLSQL_BLOCK',
                          JOB_ACTION      => 'BEGIN REGISTRAR; END;',
                          start_date      => '10-SEP-13 03.22.00AM',
                          repeat_interval => 'FREQ=DAILY;',
                          end_date        => NULL,
                          enabled         => TRUE,
                          comments        => 'Calls PLSQL once');
END;
/

--exec dbms_scheduler.dro