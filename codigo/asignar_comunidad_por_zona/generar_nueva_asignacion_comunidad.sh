#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo. Entiendanse 
# como procedimientos 

# crea una tabla con todos los objetos del shapefile de la eod2012
CARGAR_EOD2012=false
# crea una tabla con la información de cada nodo obtenida del csv.
CARGAR_NODOS_CON_ZONA=false
# calcula la zona en la que se encuentra cada nodo
CALCULAR_ZONA=false
# genera un csv con dos columnas, una contiene el id del nodo en el pajek y el otro la zona eod2012 que la intersecta.
GENERAR_PAR_NODO_ZONA=false
# calcula el pagerank para cada nodo del grafo por medio de la libraria igraph. Crea una archivo sql con la asignación.
CALCULAR_PAGERANK=true
# Asigna la comunidad a cada zona.
ASIGNAR_COMUNIDAD_A_ZONA=true
# Crea una columna en la tabla eod2012 para asignar la comunidad, lo anterior usando el script generado en el paso anterior.
ASIGNAR_COMUNIDAD_A_SHAPEFILE=true

####################################################################################
# Ruta de los directorios usados por el script
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo/asignar_comunidad_por_zona2
RUTA_DATOS=$RUTA_MEMORIA/datos/asignar_comunidad_por_zona2
RUTA_DATOS_CSV=$RUTA_DATOS/csv
RUTA_DATOS_PAJEK=$RUTA_DATOS/pajek
RUTA_DATOS_SQL=$RUTA_DATOS/sql
RUTA_DATOS_SHAPE=$RUTA_DATOS/shape
RUTA_DATOS_EOD2012=$RUTA_DATOS/eod2012

RUTA_IGRAPH_H=/usr/local/include/igraph
RUTA_IGRAPH_LIB=/usr/local/lib
####################################################################################

# IMPORTANTE: Los módulos posteriores hacen uso de la manipulación de archivos por lo 
#             que es importante dar los permisos correspondientes al usuario postgres. 
chown -R cephei:postgres $RUTA_DATOS
chmod 775 -R $RUTA_DATOS

if [ "$CARGAR_EOD2012" = true ]; then
  ####################################################################################
  sudo -u postgres -i psql -d memoria -c "DROP TABLE IF EXISTS eod2012"
  sudo -u postgres -i shp2pgsql -I -s 4326 $RUTA_DATOS_EOD2012/zonificacion_eod2012.shp eod2012 | sudo -u postgres -i psql -d memoria
fi

if [ "$CARGAR_NODOS_CON_ZONA" = true ]; then
  ####################################################################################
  sudo -u postgres -i psql -d memoria -c "DROP TABLE IF EXISTS nodos_con_zona"
  sudo -u postgres -i psql -d memoria -c "CREATE TABLE nodos_con_zona
  (
  _1er_nivel    INTEGER,
  _2do_nivel    INTEGER,
  pagerank      FLOAT,
  nombre        VARCHAR(256),
  latitud       FLOAT,                                            
  longitud      FLOAT,
  nodo_id_pajek INTEGER PRIMARY KEY,
  zona_id       INTEGER, 
  the_geom      geometry,
  CONSTRAINT enforce_dims_the_geom CHECK (st_ndims(the_geom) = 2),
  CONSTRAINT enforce_geotype_geom  CHECK (geometrytype(the_geom) = 'POINT'::text OR the_geom IS NULL),
  CONSTRAINT enforce_srid_the_geom CHECK (st_srid(the_geom) = 4326)
  )"
  sudo -u postgres -i psql -d memoria -c "copy nodos_con_zona(_1er_nivel,_2do_nivel,pagerank,nombre,latitud,longitud,nodo_id_pajek) FROM '$RUTA_DATOS/comunidades_10000_iteraciones_con_zona.csv' DELIMITERS ' ' CSV HEADER"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET the_geom = ST_GeomFromText('POINT(' || longitud || ' ' || latitud || ')',4326)"
fi

if [ "$CALCULAR_ZONA" = true ]; then
  ####################################################################################
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = (SELECT zona 
                                          FROM eod2012 
                                          WHERE  ST_Intersects(nodos_con_zona.the_geom, eod2012.geom) limit 1)"
  # paraderos no intersectados por una zona
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 527 WHERE nodo_id_pajek = 7150"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 386 WHERE nodo_id_pajek = 519"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 67  WHERE nodo_id_pajek = 8366"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 254 WHERE nodo_id_pajek = 9967"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 725 WHERE nodo_id_pajek = 1483"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 470 WHERE nodo_id_pajek = 31"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 470 WHERE nodo_id_pajek = 6033"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 265 WHERE nodo_id_pajek = 9894"
  sudo -u postgres -i psql -d memoria -c "UPDATE nodos_con_zona SET zona_id = 93  WHERE nodo_id_pajek = 8740"
fi


if [ "$GENERAR_PAR_NODO_ZONA" = true ]; then
  ####################################################################################
  sudo -u postgres -i psql -d memoria -c "copy (SELECT nodo_id_pajek, zona_id, _1er_nivel FROM nodos_con_zona) To '$RUTA_DATOS_CSV/par_nodo_zona.csv' WITH DELIMITER ';' CSV"
fi

if [ "$CALCULAR_PAGERANK" = true ]; then
  ####################################################################################

  # IMPORTANTE: si no encuentra lib en share files al compilar hacer lo siguiente
  # Hay que agregar la línea 'include /usr/local/lib' en el archivo '/etc/ld.so.conf'
  # y luego cargar el archivo ejecutando el comando 'ldconfig'

  NOMBRE_EJECUTABLE="calcular_pagerank"

  # Compilar código
  gcc $RUTA_CODIGO/calcular_pagerank.c -I$RUTA_IGRAPH_H -L$RUTA_IGRAPH_LIB -ligraph -o $NOMBRE_EJECUTABLE

  for ARCHIVO_PAJEK in $RUTA_DATOS_PAJEK/*.net; do
    echo "CALCULAR PAGERANK POR COMUNIDAD: Procesando $ARCHIVO_PAJEK"

    NOMBRE_CSV=$(echo "$ARCHIVO_PAJEK" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

    # Ejecutar código
    $RUTA_CODIGO/$NOMBRE_EJECUTABLE $ARCHIVO_PAJEK $RUTA_DATOS_CSV/par_nodo_zona.csv > $RUTA_DATOS_CSV/par_nodo_zona_comunidad.csv

  done 

  # se elimina ejecutable
  rm -f $RUTA_CODIGO/$NOMBRE_EJECUTABLE
fi

if [ "$ASIGNAR_COMUNIDAD_A_ZONA" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_SQL/*.sql

  # IMPORTANTE: si no encuentra lib en share files al compilar hacer lo siguiente
  # Hay que agregar la línea 'include /usr/local/lib' en el archivo '/etc/ld.so.conf'
  # y luego cargar el archivo ejecutando el comando 'ldconfig'

  NOMBRE_EJECUTABLE="asignar_comunidad_a_zona"

  # Compilar código
  gcc $RUTA_CODIGO/$NOMBRE_EJECUTABLE.c -I$RUTA_IGRAPH_H -L$RUTA_IGRAPH_LIB -ligraph -o $NOMBRE_EJECUTABLE

  for ARCHIVO_PAJEK in $RUTA_DATOS_PAJEK/*.net; do
    echo "ASIGNAR COMUNIDAD A ZONA: Procesando $ARCHIVO_PAJEK"

    NOMBRE_CSV=$(echo "$ARCHIVO_PAJEK" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)
    
    # Ejecutar código
    $RUTA_CODIGO/$NOMBRE_EJECUTABLE $ARCHIVO_PAJEK $RUTA_DATOS_CSV/par_nodo_zona_comunidad.csv > $RUTA_DATOS_SQL/$NOMBRE_CSV.sql

  done 

  # se elimina ejecutable
  rm -f $RUTA_CODIGO/$NOMBRE_EJECUTABLE
fi

if [ "$ASIGNAR_COMUNIDAD_A_SHAPEFILE" = true ]; then
  ####################################################################################
  rm -f -R $RUTA_DATOS_SHAPE/*.csv

  sudo -u postgres -i psql -d memoria -c "ALTER TABLE eod2012 DROP COLUMN IF EXISTS comunidad_id2"
  sudo -u postgres -i psql -d memoria -c "ALTER TABLE eod2012 ADD COLUMN comunidad_id2 INTEGER NOT NULL DEFAULT -1"

  for ARCHIVO_SQL in $RUTA_DATOS_SQL/*.sql; do
    echo "ACTUALIZANDO SHAPE EOD2012: Procesando $ARCHIVO_SQL"
    
    sudo -u postgres -i psql -d memoria -f $ARCHIVO_SQL
  done

  sudo -u postgres -i pgsql2shp -f $RUTA_DATOS_SHAPE/zona_con_comunidad2 memoria "SELECT zona, comuna, area, comunidad_id2, geom FROM eod2012"
fi

# cambiamos el dueño de los archivos para poder verlos en el entorno de escritorio
chown -R cephei $RUTA_DATOS

