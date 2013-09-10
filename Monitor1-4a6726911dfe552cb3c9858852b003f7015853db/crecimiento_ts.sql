CREATE TABLE LLENADO(
	TABLESPACE VARCHAR2(500),
	DIAS VARCHAR2(500)
	);
	
CREATE TABLE TAM_MAX_TABLA(
	TABLA VARCHAR2(500),
	DIAS NUMBER,
	TABLESPACE VARCHAR2(500)
	);	
	
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

CREATE OR REPLACE PROCEDURE	CALC_TABLESPACE(ESPACIO IN VARCHAR2)
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
			

