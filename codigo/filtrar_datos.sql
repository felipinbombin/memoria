\timing on

-- Se eliminan todos los datos que esten presentes en las tablas etapa_util y viaje_util
DELETE FROM etapa_util;
DELETE FROM viaje_util;
DELETE FROM parada_util;

-- Se quitan etapas sin paradero de subida o bajada y se guardan
-- en tabla etapa_util
INSERT INTO etapa_util
SELECT id, nviaje, netapa, tiempo_subida, par_subida, par_bajada, factor_exp_etapa
FROM etapas 
WHERE par_subida IS NOT NULL AND 
      par_bajada IS NOT NULL AND 
      tiempo_subida IS NOT NULL AND 
      factor_exp_etapa IS NOT NULL;  

-- Se quitan viajes con falta de información
-- y se guardan en tabla viaje_util.
-- Restricciones:
--    Identificar los viajes con N etapas (netapa=N)
--    Deben estar identificadas todas las bajadas. (netapassinbajada = 0)

-- Viajes con 4 etapas
INSERT INTO viaje_util
SELECT id, nviaje, netapa,
       paraderosubida_1era, paraderobajada_1era, tiemposubida_1era, 
       paraderosubida_2da,  paraderobajada_2da, 
       paraderosubida_3era, paraderobajada_3era,
       paraderosubida_4ta,  paraderobajada_4ta, 
       factorexpansion
FROM viajes
WHERE netapa=4 AND netapassinbajada = 0 AND 
      paraderosubida_1era IS NOT NULL AND paraderobajada_1era IS NOT NULL AND tiemposubida_1era IS NOT NULL AND  
      paraderosubida_2da  IS NOT NULL AND paraderobajada_2da  IS NOT NULL AND 
      paraderosubida_3era IS NOT NULL AND paraderobajada_3era IS NOT NULL AND 
      paraderosubida_4ta  IS NOT NULL AND paraderobajada_4ta  IS NOT NULL;

-- Viajes con 3 etapas
INSERT INTO viaje_util
SELECT id, nviaje, netapa, 
       paraderosubida_1era, paraderobajada_1era,tiemposubida_1era, 
       paraderosubida_2da,  paraderobajada_2da, 
       paraderosubida_3era, paraderobajada_3era, 
       factorexpansion
FROM viajes
WHERE netapa=3 AND netapassinbajada = 0 AND 
      paraderosubida_1era IS NOT NULL AND paraderobajada_1era IS NOT NULL AND tiemposubida_1era IS NOT NULL AND  
      paraderosubida_2da  IS NOT NULL AND paraderobajada_2da  IS NOT NULL AND 
      paraderosubida_3era IS NOT NULL AND paraderobajada_3era IS NOT NULL;

-- Viajes con 2 etapas
INSERT INTO viaje_util
SELECT id, nviaje, netapa, 
       paraderosubida_1era, paraderobajada_1era, tiemposubida_1era,  
       paraderosubida_2da,  paraderobajada_2da, 
       factorexpansion
FROM viajes
WHERE netapa=2 AND netapassinbajada = 0 AND 
      paraderosubida_1era IS NOT NULL AND paraderobajada_1era IS NOT NULL AND tiemposubida_1era IS NOT NULL AND  
      paraderosubida_2da  IS NOT NULL AND paraderobajada_2da  IS NOT NULL;

-- Viajes con 1 etapa
INSERT INTO viaje_util
SELECT id, nviaje, netapa, 
       paraderosubida_1era, paraderobajada_1era, tiemposubida_1era,  
       factorexpansion
FROM viajes
WHERE netapa=1 AND netapassinbajada = 0 AND 
      paraderosubida_1era IS NOT NULL AND paraderobajada_1era IS NOT NULL AND tiemposubida_1era IS NOT NULL;

-- Se cambian algunos codigos para que coincidan con el de red paradas
UPDATE estaciones_metro SET codigotrx = upper(codigotrx);
UPDATE estaciones_metro SET codigotrx = 'BARRANCAS' WHERE codigotrx = 'BARRANCAS - L5';
UPDATE estaciones_metro SET codigotrx = 'BELLAVISTA DE LA FLORIDA' WHERE codigotrx = 'LA FLORIDA';
UPDATE estaciones_metro SET codigotrx = 'BLANQUEADO' WHERE codigotrx = 'BLANQUEADO - L5';
UPDATE estaciones_metro SET codigotrx = 'CAMINO AGRICOLA' WHERE codigotrx = 'AGRICOLA';
UPDATE estaciones_metro SET codigotrx = 'CARLOS VALDOVINOS' WHERE codigotrx = 'CARLOS VALDOVINO';
UPDATE estaciones_metro SET codigotrx = 'CIUDAD DEL NINO' WHERE codigotrx = 'CIUDAD DEL NI?O';
UPDATE estaciones_metro SET codigotrx = 'CRISTOBAL COLON' WHERE codigotrx = 'COLON';
UPDATE estaciones_metro SET codigotrx = 'CUMMING' WHERE codigotrx = 'RICARDO CUMMING';
UPDATE estaciones_metro SET codigotrx = 'DEL SOL' WHERE codigotrx = 'DEL SOL - L5';
--UPDATE estaciones_metro SET codigotrx = 'EM LA CISTERNA' WHERE codigotrx = 'LA CISTERNA L4A';
UPDATE estaciones_metro SET codigotrx = 'FRANCISCO BILBAO' WHERE codigotrx = 'BILBAO';
UPDATE estaciones_metro SET codigotrx = 'GRECIA' WHERE codigotrx = 'ROTONDA GRECIA';
UPDATE estaciones_metro SET codigotrx = 'GRUTA DE LOURDES' WHERE codigotrx = 'GRUTA DE LOURDES - L5';
UPDATE estaciones_metro SET codigotrx = 'HERNANDO DE MAGALLANES' WHERE codigotrx = 'HERNANDO DE MAGALLANES - L1';
UPDATE estaciones_metro SET codigotrx = 'LAGUNA SUR' WHERE codigotrx = 'LAGUNA SUR - L5';
UPDATE estaciones_metro SET codigotrx = 'LAS PARCELAS' WHERE codigotrx = 'LAS PARCELAS - L5';
--UPDATE estaciones_metro SET codigotrx = 'LA CISTERNA' WHERE codigotrx = 'LA CISTERNA L2';
UPDATE estaciones_metro SET codigotrx = 'LOS DOMINICOS' WHERE codigotrx = 'LOS DOMINICOS - L1';
UPDATE estaciones_metro SET codigotrx = 'LO PRADO' WHERE codigotrx = 'LO PRADO - L5';
UPDATE estaciones_metro SET codigotrx = 'MANQUEHUE' WHERE codigotrx = 'MANQUEHUE - L1';
UPDATE estaciones_metro SET codigotrx = 'MIRADOR' WHERE codigotrx = 'MIRADOR AZUL';
UPDATE estaciones_metro SET codigotrx = 'MONTE TABOR' WHERE codigotrx = 'MONTE TABOR - L5';
UPDATE estaciones_metro SET codigotrx = 'NUBLE' WHERE codigotrx = '?UBLE';
UPDATE estaciones_metro SET codigotrx = 'QUILIN' WHERE codigotrx = 'ROTONDA QUILIN';
UPDATE estaciones_metro SET codigotrx = 'PEDRERO' WHERE codigotrx = 'PEDREROS';
UPDATE estaciones_metro SET codigotrx = 'PLAZA EGANA' WHERE codigotrx = 'PLAZA EGA?A';
UPDATE estaciones_metro SET codigotrx = 'PLAZA MAIPU' WHERE codigotrx = 'PLAZA MAIPU - L5';
UPDATE estaciones_metro SET codigotrx = 'PUDAHUEL' WHERE codigotrx = 'PUDAHUEL - L5';
UPDATE estaciones_metro SET codigotrx = 'SANTIAGO BUERAS' WHERE codigotrx = 'SANTIAGO BUERAS - L5';
UPDATE estaciones_metro SET codigotrx = 'SAN JOSE DE LA ESTRELLA' WHERE codigotrx = 'SAN JOSE DE LA ESTRELLA - L4';
UPDATE estaciones_metro SET codigotrx = 'SAN PABLO L1' WHERE codigotrx = 'SAN PABLO';
UPDATE estaciones_metro SET codigotrx = 'SAN PABLO L5' WHERE codigotrx = 'SAN PABLO - L5';
UPDATE estaciones_metro SET codigotrx = 'TOBALABA L1' WHERE codigotrx = 'TOBALABA_L1';
UPDATE estaciones_metro SET codigotrx = 'TOBALABA L4' WHERE codigotrx = 'TOBALABA_L4';
UPDATE estaciones_metro SET codigotrx = 'UNION LATINO AMERICANA' WHERE codigotrx = 'LATINO AMERICANA';
UPDATE estaciones_metro SET codigotrx = 'VICUNA MACKENNA' WHERE codigotrx = 'VICU?A MACKENA';

INSERT INTO estaciones_metro VALUES ('SANTA ANA', -33.4383079999999993, -70.6601100000000031, 345682, 6298888, 'L5', 'SANTA ANA L5', 'TRASBORDO', 'SANTA ANA', NULL, 'SANTIAGO', 162, 274, 'SANTIAGO', NULL, 184, 242, 260, 340, 1);
INSERT INTO estaciones_metro VALUES ('LOS HEROES L1', -33.446474000000002, -70.660499999999999, 345660, 6297982, 'L1', 'LOS HEROES L1', 'TRASBORDO', 'LOS HEROES', 'SANTIAGO', 'SANTIAGO', 249, 282, NULL, NULL, 180, 249, 256, 341, 1);
INSERT INTO estaciones_metro VALUES ('BAQUEDANO', -33.437185999999997, -70.6351669999999956, 347999, 6299049, 'L1', 'BAQUEDANO L1', 'TRASBORDO', 'BAQUEDANO', 'PROVIDENCIA', 'PROVIDENCIA', 89, 306, 'PROVIDENCIA', 'PROVIDENCIA', 217, 224, 231, 501, 1);

-- UPDATE estaciones_metro SET codigotrx = '' WHERE codigotrx = '';

-- Se actualizan las estaciones de metro en las tablas etapa_util y viaje_util debido
-- a que una estación puede aparecer con varios nombres 

--UPDATE etapa_util SET 
--  par_subida = estaciones_metro1.codigosinlinea,
--  par_bajada = estaciones_metro2.codigosinlinea 
--FROM estaciones_metro AS estaciones_metro1, 
--     estaciones_metro AS estaciones_metro2 
--WHERE etapa_util.par_subida = estaciones_metro1.codigotrx AND 
--      etapa_util.par_bajada = estaciones_metro2.codigotrx;

--UPDATE viaje_util SET
--  par_subida_1 = estaciones_metro1.codigosinlinea, 
--  par_bajada_1 = estaciones_metro2.codigosinlinea,
--  par_subida_2 = estaciones_metro3.codigosinlinea, 
--  par_bajada_2 = estaciones_metro4.codigosinlinea,
--  par_subida_3 = estaciones_metro5.codigosinlinea, 
--  par_bajada_3 = estaciones_metro6.codigosinlinea,
--  par_subida_4 = estaciones_metro7.codigosinlinea, 
--  par_bajada_4 = estaciones_metro8.codigosinlinea 
--FROM estaciones_metro AS estaciones_metro1, 
--     estaciones_metro AS estaciones_metro2,
--     estaciones_metro AS estaciones_metro3,
--     estaciones_metro AS estaciones_metro4,
--     estaciones_metro AS estaciones_metro5,
--     estaciones_metro AS estaciones_metro6,
--     estaciones_metro AS estaciones_metro7,
--     estaciones_metro AS estaciones_metro8 
--WHERE viaje_util.par_subida_1 = estaciones_metro1.codigotrx AND 
--      viaje_util.par_bajada_1 = estaciones_metro2.codigotrx AND 
--      viaje_util.par_subida_2 = estaciones_metro3.codigotrx AND 
--      viaje_util.par_bajada_2 = estaciones_metro4.codigotrx AND 
--      viaje_util.par_subida_3 = estaciones_metro5.codigotrx AND 
--      viaje_util.par_bajada_3 = estaciones_metro6.codigotrx AND 
--      viaje_util.par_subida_4 = estaciones_metro7.codigotrx AND 
--      viaje_util.par_bajada_4 = estaciones_metro8.codigotrx;

-- se obtienen los campos requeridos para los paraderos
INSERT INTO parada_util
SELECT codigo, nombre, latitud, longitud 
FROM redparadas 
WHERE codigo   IS NOT NULL AND 
      nombre   IS NOT NULL AND 
      latitud  IS NOT NULL AND
      longitud IS NOT NULL;

-- se agregan los datos de metro dentro de la tabla parada_util
INSERT INTO parada_util
SELECT codigosinlinea, codigosinlinea, latitud, longitud 
FROM estaciones_metro 
WHERE codigosinlinea IS NOT NULL AND 
      latitud        IS NOT NULL AND 
      longitud       IS NOT NULL;
      
