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
WHERE netapa=2 AND netapassinbajada = 0 AND 
      paraderosubida_1era IS NOT NULL AND paraderobajada_1era IS NOT NULL AND tiemposubida_1era IS NOT NULL;

-- Se cambian algunos codigos para que coincidan con el de red paradas
UPDATE estaciones_metro SET codigotrx = upper(codigotrx);
UPDATE estaciones_metro SET codigotrx = 'FRANCISCO BILBAO' WHERE codigotrx = 'BILBAO';
UPDATE estaciones_metro SET codigotrx = 'LAS PARCELAS' WHERE codigotrx = 'LAS PARCELAS - L5';
UPDATE estaciones_metro SET codigotrx = 'BLANQUEADO' WHERE codigotrx = 'BLANQUEADO - L5';
UPDATE estaciones_metro SET codigotrx = 'LOS HEROES L1' WHERE codigotrx = 'LOS HEROES';
UPDATE estaciones_metro SET codigotrx = 'GRECIA' WHERE codigotrx = 'ROTONDA GRECIA';
UPDATE estaciones_metro SET codigotrx = 'CAMINO AGRICOLA' WHERE codigotrx = 'AGRICOLA';
UPDATE estaciones_metro SET codigotrx = 'BARRANCAS' WHERE codigotrx = 'BARRANCAS - L5';
UPDATE estaciones_metro SET codigotrx = 'SAN PABLO L1' WHERE codigotrx = 'SAN PABLO';
UPDATE estaciones_metro SET codigotrx = 'SAN PABLO L5' WHERE codigotrx = 'SAN PABLO - L5';
UPDATE estaciones_metro SET codigotrx = 'BELLAVISTA DE LA FLORIDA' WHERE codigotrx = 'LA FLORIDA';
UPDATE estaciones_metro SET codigotrx = 'HERNANDO DE MAGALLANES' WHERE codigotrx = 'HERNANDO DE MAGALLANES - L1';
UPDATE estaciones_metro SET codigotrx = 'TOBALABA L1' WHERE codigotrx = 'TOBALABA_L1';
UPDATE estaciones_metro SET codigotrx = 'TOBALABA L4' WHERE codigotrx = 'TOBALABA_L4';
UPDATE estaciones_metro SET codigotrx = 'DEL SOL' WHERE codigotrx = 'DEL SOL - L5';
UPDATE estaciones_metro SET codigotrx = 'MANQUEHUE' WHERE codigotrx = 'MANQUEHUE - L1';
UPDATE estaciones_metro SET codigotrx = 'UNION LATINO AMERICANA' WHERE codigotrx = 'LATINO AMERICANA';
UPDATE estaciones_metro SET codigotrx = 'LOS DOMINICOS' WHERE codigotrx = 'LOS DOMINICOS - L1';
UPDATE estaciones_metro SET codigotrx = 'VICUNA MACKENNA' WHERE codigotrx = 'VICU?A MACKENA';
UPDATE estaciones_metro SET codigotrx = 'MIRADOR' WHERE codigotrx = 'MIRADOR AZUL';
UPDATE estaciones_metro SET codigotrx = 'MONTE TABOR' WHERE codigotrx = 'MONTE TABOR - L5';
UPDATE estaciones_metro SET codigotrx = 'CRISTOBAL COLON' WHERE codigotrx = 'COLON';
UPDATE estaciones_metro SET codigotrx = 'QUILIN' WHERE codigotrx = 'ROTONDA QUILIN';
UPDATE estaciones_metro SET codigotrx = 'PEDRERO' WHERE codigotrx = 'PEDREROS';
UPDATE estaciones_metro SET codigotrx = 'CIUDAD DEL NINO' WHERE codigotrx = 'CIUDAD DEL NI?O';
UPDATE estaciones_metro SET codigotrx = 'CUMMING' WHERE codigotrx = 'RICARDO CUMMING';
UPDATE estaciones_metro SET codigotrx = 'PLAZA EGANA' WHERE codigotrx = 'PLAZA EGA?A';
UPDATE estaciones_metro SET codigotrx = 'LAGUNA SUR' WHERE codigotrx = 'LAGUNA SUR - L5';
UPDATE estaciones_metro SET codigotrx = 'LO PRADO' WHERE codigotrx = 'LO PRADO - L5';
UPDATE estaciones_metro SET codigotrx = 'LAS PARCELAS' WHERE codigotrx = 'LAS PARCELAS - L5';
UPDATE estaciones_metro SET codigotrx = 'NUBLE' WHERE codigotrx = '?UBLE';
UPDATE estaciones_metro SET codigotrx = 'PLAZA MAIPU' WHERE codigotrx = 'PLAZA MAIPU - L5';
UPDATE estaciones_metro SET codigotrx = 'PUDAHUEL' WHERE codigotrx = 'PUDAHUEL - L5';
UPDATE estaciones_metro SET codigotrx = 'GRUTA DE LOURDES' WHERE codigotrx = 'GRUTA DE LOURDES - L5';
UPDATE estaciones_metro SET codigotrx = 'SANTIAGO BUERAS' WHERE codigotrx = 'SANTIAGO BUERAS - L5';
UPDATE estaciones_metro SET codigotrx = 'CARLOS VALDOVINOS' WHERE codigotrx = 'CARLOS VALDOVINO';
UPDATE estaciones_metro SET codigotrx = 'SAN JOSE DE LA ESTRELLA' WHERE codigotrx = 'SAN JOSE DE LA ESTRELLA - L4';

-- Se actualizan las estaciones de metro en las tablas etapa_util y viaje_util debido
-- a que una estación puede aparecer con varios nombres 
UPDATE etapa_util SET 
  par_subida = estaciones_metro1.codigosinlinea,
  par_bajada = estaciones_metro2.codigosinlinea 
FROM estaciones_metro AS estaciones_metro1, 
     estaciones_metro AS estaciones_metro2 
WHERE etapa_util.par_subida = estaciones_metro1.codigotrx AND 
      etapa_util.par_bajada = estaciones_metro2.codigotrx;

UPDATE viaje_util SET
  paraderosubida_1era = estaciones_metro1.codigosinlinea, 
  paraderobajada_1era = estaciones_metro2.codigosinlinea,
  paraderosubida_2da = estaciones_metro3.codigosinlinea, 
  paraderobajada_2da = estaciones_metro4.codigosinlinea,
  paraderosubida_3era = estaciones_metro5.codigosinlinea, 
  paraderobajada_3era = estaciones_metro6.codigosinlinea,
  paraderosubida_4ta = estaciones_metro7.codigosinlinea, 
  paraderobajada_4ta = estaciones_metro8.codigosinlinea 
FROM estaciones_metro AS estaciones_metro1, 
     estaciones_metro AS estaciones_metro2,
     estaciones_metro AS estaciones_metro3,
     estaciones_metro AS estaciones_metro4,
     estaciones_metro AS estaciones_metro5,
     estaciones_metro AS estaciones_metro6,
     estaciones_metro AS estaciones_metro7,
     estaciones_metro AS estaciones_metro8 
WHERE viaje_util.paraderosubida_1era = estaciones_metro1.codigotrx AND 
      viaje_util.paraderobajada_1era = estaciones_metro2.codigotrx AND 
      viaje_util.paraderosubida_2da  = estaciones_metro3.codigotrx AND 
      viaje_util.paraderobajada_2da  = estaciones_metro4.codigotrx AND 
      viaje_util.paraderosubida_3era = estaciones_metro5.codigotrx AND 
      viaje_util.paraderobajada_3era = estaciones_metro6.codigotrx AND 
      viaje_util.paraderosubida_4ta  = estaciones_metro7.codigotrx AND 
      viaje_util.paraderobajada_4ta  = estaciones_metro8.codigotrx;

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
      latitud   IS NOT NULL AND 
      longitud  IS NOT NULL;
      
