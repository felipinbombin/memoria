
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


-- se obtienen los campos requeridos para los paraderos
INSERT INTO parada_util
SELECT codigo, nombre, latitud, longitud 
FROM redparadas 
WHERE codigo   IS NOT NULL AND 
      nombre   IS NOT NULL AND 
      latitud  IS NOT NULL AND
      longitud IS NOT NULL;

-- Se ponen los nombres de los paraderos en las tablas etapa_util y viaje_util.
UPDATE etapa_util SET
  nombre_par_subida = parada_subida.nombre, 
  nombre_par_bajada = parada_bajada.nombre 
FROM parada_util AS parada_subida, 
     parada_util AS parada_bajada 
WHERE par_subida = parada_subida.codigo AND 
      par_bajada = parada_bajada.codigo;






