SELECT * FROM IMPOSITOR I ;
SELECT * FROM CLIENTE C ;
SELECT * FROM cuenta;
SELECT * FROM sucursal;
SELECT * FROM prestamo;

--PROCEDIMIENTOS--
--1. Dado el número de una cuenta origen, el número de una cuenta destino y un monto, 
--transferir el monto de la cuenta origen a la cuenta destino. 
--Debe validar que la cuenta origen tenga saldo suficiente antes 
--de realizar el movimiento; 
--si no lo tiene, informar el problema 
--sin modificar ningún saldo.


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
		DBMS_OUTPUT.PUT_LINE('NO EXISTE LA CUENTA DESTINO' || num_cuenta_destino);
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
		DBMS_OUTPUT.PUT_LINE('ERROR SIN DATOS ENCONTRADOS');
	WHEN OTHERS THEN
		DBMS_OUTPUT.PUT_LINE('ERROR');
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
		DBMS_OUTPUT.PUT_LINE('La sucursal : ' || ' ' || nom_sucursal || ' no existe');
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
		DBMS_OUTPUT.PUT_LINE('ERROR EL NUMERO DE CUENTA' || num_cuenta || 'YA EXISTE');
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


