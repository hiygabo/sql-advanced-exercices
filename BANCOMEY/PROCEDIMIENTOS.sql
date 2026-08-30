--PROCEDIMIENTOS--
--1. DADO EL NÚMERO DE UNA CUENTA ORIGEN, EL NÚMERO DE UNA CUENTA DESTINO Y UN MONTO, 
--TRANSFERIR EL MONTO DE LA CUENTA ORIGEN A LA CUENTA DESTINO. 
--DEBE VALIDAR QUE LA CUENTA ORIGEN TENGA SALDO SUFICIENTE 
--ANTES DE REALIZAR EL MOVIMIENTO
--SI NO LO TIENE INFORMAR EL PROBLEMA (EXCEPCIONES) 
--SIN MODIFICAR NINGUN SALDO.


CREATE OR REPLACE PROCEDURE sp_ejercicio_1 (num_cuenta_origen NUMBER, num_cuenta_destino NUMBER, monto NUMBER )
AS
	saldo_origen NUMBER;
	existe_cuenta_destino NUMBER;
BEGIN
	
	IF monto <= 0 THEN
		DBMS_OUTPUT.PUT_LINE('EL MONTO ES INSUFICIENTE');		
	END IF;
	
	SELECT saldo 
	INTO saldo_origen 
	FROM cuenta
	WHERE numero_cuenta = num_cuenta_origen;
	
	SELECT COUNT(*)
	INTO existe_cuenta_destino
	FROM cuenta
	WHERE numero_cuenta = num_cuenta_destino;
	
	IF existe_cuenta_destino = 0 THEN
		DBMS_OUTPUT.PUT_LINE('ERROR: La cuenta destino' || ' ' ||num_cuenta_destino || ' ' || 'no existe');
	END IF;
	
	IF saldo_origen >= 0 THEN
		UPDATE cuenta 
		SET saldo = saldo - monto
		WHERE numero_cuenta = num_cuenta_origen;
	
		UPDATE cuenta
		SET saldo = saldo + monto
		WHERE numero_cuenta = num_cuenta_destino;
		
		COMMIT;
		
		DBMS_OUTPUT.PUT_LINE('EXITO EN LA TRANSFERENCIA');
	END IF;
EXCEPTION
	WHEN NO_DATA_FOUND THEN 
		DBMS_OUTPUT.PUT_LINE('ERROR:SIN DATOS ENCONTRADOS');
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('ERROR' || SQLERRM);
		ROLLBACK;
	
END;

BEGIN
	sp_ejercicio_1(100001, 100002, 500);
END;

--2. DADO UN NUMERO DE CUENTA, EL NOMBRE DE UNA
--SUCURSAL, UN SALDO INICIAL, EL NOMBRE DE
--UN CLIENTE TITULAR Y EL SEGUNDO CLIENTE COTITULAR OPCIONAL
-- REGISTRAR LA NUEVA CUENTA Y CREAR EL
-- O LAS RELACIONES CORRESPONDIENTES
--SI ALGUN CLIENTE INDICADO NO EXISTE
-- REGISTRARLO PREVIAMENTE SOLICITANDO
-- SU CALLE Y CIUDAD

CREATE OR REPLACE PROCEDURE sp_ejercicio_2(
	num_cuenta NUMBER,
	nom_sucursal VARCHAR2,
	saldo_inicial NUMBER,
	nom_cliente1 VARCHAR2,
	calle_1 VARCHAR2,
	ciudad_1 VARCHAR,
	nom_cliente2 VARCHAR2 DEFAULT NULL ,
	calle_2 VARCHAR2 DEFAULT NULL ,
	ciudad_2 VARCHAR2 DEFAULT NULL 
)
AS
	existe_sucursal NUMBER;
	existe_cliente_1 NUMBER;
	existe_cliente_2 NUMBER;
BEGIN
	SELECT COUNT(*) INTO existe_sucursal
	FROM sucursal 
	WHERE nombre_sucursal = nom_sucursal;

	IF existe_sucursal = 0 THEN 
		DBMS_OUTPUT.PUT_LINE('Error: La sucursal : ' || ' ' || nom_sucursal || ' ' ||'no existe');
		RETURN;
	END IF;
	
	INSERT INTO cuenta (numero_cuenta, nombre_sucursal, saldo)
	VALUES (num_cuenta, nom_sucursal, saldo_inicial);
	
	
	SELECT COUNT(*) INTO existe_cliente_1
	FROM cliente
	WHERE nombre_cliente = nom_cliente1;
	
	IF existe_cliente_1 = 0 THEN
		INSERT INTO cliente (nombre_cliente, calle_cliente, ciudad_cliente)
		VALUES (nom_cliente1, calle_1, ciudad_1);
	END IF;
	
	INSERT INTO impositor (nombre_cliente, numero_cuenta)
	VALUES (nom_cliente1, num_cuenta);
	
	IF nom_cliente2 IS NOT NULL THEN
		SELECT COUNT(*) INTO existe_cliente_2
		FROM cliente 
		WHERE nombre_cliente = nom_cliente2;
	
		IF existe_cliente_2 = 0 THEN 
			INSERT INTO cliente (nombre_cliente, calle_cliente, ciudad_cliente)
			VALUES (nom_cliente2, calle_2, ciudad_2);
		END IF;
		
		INSERT INTO impositor (nombre_cliente, numero_cuenta)
		VALUES (nom_cliente2, num_cuenta);
	END IF;
	COMMIT; 
	DBMS_OUTPUT.PUT_LINE('EXITO DATOS REGISTRADOS CORRECTAMENTE');
	
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN 
		DBMS_OUTPUT.PUT_LINE('ERROR: la cuenta' || num_cuenta || 'ya existe');
		ROLLBACK;
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('ERROR CRITICO' || SQLERRM);
		ROLLBACK;
END;

--EJECUCION SIN COTITULAR--
BEGIN
	sp_ejercicio_2(100031, 'San Pedro', 1500, 'Gabriel Andia', 'Nicolas Acosta', 'La Paz');
END;
--EJECUCICON CON COTITULAR--
BEGIN 
	sp_ejercicio_2(100032, 'Zona Sur', 1800, 'Josue Terrazas', 'Calle 34', 'La Paz');
END;


--3. DADO EL NOMBRE DE UNA SUCURSAL, EL NOMBRE DE UN CLIENTE
-- Y UN IMPORTE SOLICITADO, OTORGAR UN NUEVO PRESTAMO
-- SIEMPRE QUE LA SUMA DE LOS IMPORTES YA OTORGADOS EN ESA SUCURSAL
--INCLUYENDO EL NUEVO NO SUPERE EL 80% DEL ACTIVO DE LA SUCURSAL
-- CASO CONTRARIO INFORMAR QUE EL PRESTAMO NO PUEDE OTORGARSE

CREATE OR REPLACE PROCEDURE sp_ejercicio_3 (p_nombre_sucursal VARCHAR2, p_nombre_cliente VARCHAR2, p_importe NUMBER)
AS
	existe_sucursal NUMBER;
	existe_cliente NUMBER;
	nuevo_id_prestamo NUMBER;
	suma_importe NUMBER;
	activo_sucursal NUMBER;
BEGIN
	SELECT COUNT(*) INTO existe_sucursal
	FROM sucursal
	WHERE nombre_sucursal = p_nombre_sucursal;

	IF existe_sucursal = 0 THEN
		DBMS_OUTPUT.PUT_LINE('ERROR: La sucursal: ' || ' ' || p_nombre_sucursal || '' || 'no existe');
		RETURN;
	END IF;
	
	SELECT COUNT(*) INTO existe_cliente
	FROM cliente
	WHERE nombre_cliente = p_nombre_cliente;
	
	IF existe_cliente = 0 THEN
		DBMS_OUTPUT.PUT_LINE('ERROR: El cliente: ' || ' ' || p_nombre_cliente || ' ' || 'no existe' );
		RETURN;
	END IF;
	
	SELECT NVL(SUM(importe),0) INTO suma_importe
	FROM prestamo
	WHERE nombre_sucursal = p_nombre_sucursal;
	
	SELECT activo INTO activo_sucursal
	FROM sucursal 
	WHERE nombre_sucursal = p_nombre_sucursal;
	
	IF (suma_importe + p_importe ) <=  (activo_sucursal * 0.8) THEN 
		SELECT NVL(MAX(numero_prestamo),0) + 1 INTO nuevo_id_prestamo 
		FROM prestamo;
	
		INSERT INTO prestamo (numero_prestamo, nombre_sucursal, importe)
		VALUES (nuevo_id_prestamo, p_nombre_sucursal, p_importe);
	
		INSERT INTO prestatario(nombre_cliente, numero_prestamo)
		VALUES (p_nombre_cliente, nuevo_id_prestamo); 
		COMMIT;
		DBMS_OUPUT.PUT_LINE('PRESTAMO REGISTRADO EXITOSAMENTE');
	ELSE 
		DBMS_OUTPUT.PUT_LINE('El prestamo no puede otorgarse');
		RETURN;
	END IF;
		
		
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
		DBMS_OUTPUT.PUT_LINE('ERROR: SIN DATOS ENCONTRADOS');
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('ERROR CRITICO: ' || SQLERRM);
		ROLLBACK;
	
END;


--EJECUCION--
BEGIN
	sp_ejercicio_3('San Pedro','Gabriel Andia', 20000);
END;

--4. DADO UN NÚMERO DE CUENTA, CERRARLA:
-- VERIFICAR QUE EL SALDO SEA IGUAL A CERO, ELIMINAR
-- SUS RELACIONES CON LOS CLIENTES TITULARES Y
-- FINALMENTE ELIMINAR EL REGISTRO DE LA CUENTA
-- SI EL SALDO NO ES CERO, INFORMAR QUE LA CUENTA 
-- NO PUEDE CERRARSE

CREATE OR REPLACE PROCEDURE sp_ejercicio_4 (p_numero_cuenta NUMBER)
AS
	saldo_verificado NUMBER;
	existe_cuenta NUMBER;
BEGIN
	SELECT COUNT(*) INTO existe_cuenta
	FROM cuenta 
	WHERE numero_cuenta = p_numero_cuenta;

	IF existe_cuenta = 0 THEN
		DBMS_OUTPUT.PUT_LINE('ERROR: La cuenta ' || ' ' || p_numero_cuenta || ' no existe');
		RETURN;
	END IF;
	
	SELECT saldo INTO saldo_verificado
	FROM cuenta
	WHERE numero_cuenta = p_numero_cuenta;
	
	IF saldo_verificado = 0 THEN
		DELETE FROM impositor 
		WHERE numero_cuenta = p_numero_cuenta;
	
		DELETE FROM cuenta
		WHERE numero_cuenta = p_numero_cuenta;
		COMMIT;
		DBMS_OUTPUT.PUT_LINE('Exito: la cuenta ' || p_numero_cuenta || ' fue cerrada y eliminada');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Error: no se puede eliminar la cuenta, esta tiene un saldo');
		RETURN;
	END IF;
		
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			DBMS_OUTPUT.PUT_LINE('ERROR: SIN DATOS ENCONTRADOS');
		WHEN OTHERS THEN 
			DBMS_OUTPUT.PUT_LINE('ERROR CRITICO: '|| SQLERRM);
			ROLLBACK;
END;
--EJECUCION--


