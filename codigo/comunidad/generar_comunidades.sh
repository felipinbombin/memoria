#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo. Entiendanse 
# como procedimientos 

# crea los archivos csv usados para generar los archivos pajek y para el cálculo de la centralidad de intermediación.
GENERAR_CSV=false
# crea los archivos pajek a partir de los archivos csv
GENERAR_PAJEK=false
# crea el csv de paradas con toda su información (nombre, longitud, latitud, ...)
GENERAR_CSV_PARADAS=false
# genera las comunidades en dos niveles, por medio del framework infomap
GENERAR_COMUNIDADES=true
# genera un csv a partir del archivo de comunidades para poder ser mostrado en la herramienta cartodb.com 
GENERAR_CARTODB=true

####################################################################################
# Ruta de los directorios usados por el script
RUTA_ARCHIVOS=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_ARCHIVOS/codigo/comunidad
RUTA_DATOS=$RUTA_ARCHIVOS/datos/comunidades
RUTA_DATOS_CSV=$RUTA_DATOS/csv
RUTA_DATOS_PAJEK=$RUTA_DATOS/pajek
RUTA_DATOS_INFOMAP=$RUTA_DATOS/infomap
RUTA_DATOS_CARTODB=$RUTA_DATOS/cartodb
RUTA_DATOS_POLIGONO=$RUTA_DATOS/poligono

RUTA_INFOMAP=/home/cephei/Desktop/Infomap
####################################################################################

# IMPORTANTE: Los acciones posteriores hacen uso de la manipulación de archivos por lo 
#             que es importante dar los permisos correspondientes al usuario postgres. 
chown -R cephei:postgres $RUTA_DATOS
chmod 775 -R $RUTA_DATOS

if [ "$GENERAR_CSV" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_CSV/*.csv

  # Se ocupan los datos de toda la semana de la tabla de viajes 
  CONSULTA="COPY (SELECT par_subida, par_bajada, SUM(peso) 
                  FROM (SELECT par_subida_1 AS par_subida, par_bajada_1 AS par_bajada, SUM(factor_expansion) AS peso
                        FROM viaje_util 
                        WHERE netapa=1  
                        GROUP BY par_subida_1, par_bajada_1  
                        UNION 
                        SELECT par_subida_1, par_bajada_2, SUM(factor_expansion)  
                        FROM viaje_util 
                        WHERE netapa=2  
                        GROUP BY par_subida_1, par_bajada_2 
                        UNION 
                        SELECT par_subida_1, par_bajada_3, SUM(factor_expansion)  
                        FROM viaje_util 
                        WHERE netapa=3  
                        GROUP BY par_subida_1, par_bajada_3 
                        UNION 
                        SELECT par_subida_1, par_bajada_4, SUM(factor_expansion) 
                        FROM viaje_util 
                        WHERE netapa=4 
                        GROUP BY par_subida_1, par_bajada_4) AS viaje 
                  GROUP BY par_subida, par_bajada) 
            To '$RUTA_DATOS_CSV/semana_viaje.csv' WITH DELIMITER ';' CSV;"

  sudo -u postgres -i psql -d memoria -c "$CONSULTA"
fi

if [ "$GENERAR_PAJEK" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_PAJEK/*.net

  for ARCHIVO_CSV in $RUTA_DATOS_CSV/*.csv; do
    echo "Procesando $ARCHIVO_CSV"
    php $RUTA_CODIGO/arcos2pajek.php $ARCHIVO_CSV $RUTA_DATOS_PAJEK/  
  done
fi

NOMBRE_PARADAS_CSV="PARADAS.csv"

if [ "$GENERAR_CSV_PARADAS" = true ]; then
  ####################################################################################

  # Genera un csv con los datos de la tabla parada_util. Es usado al final del proceso para reemplazar
  # los códigos de paraderos e insertar su respectiva posición geográfica, nombre, etc...
  PARADAS_CSV="copy (SELECT * FROM parada_util) To '$RUTA_DATOS/$NOMBRE_PARADAS_CSV' WITH DELIMITER ';' CSV;"
  rm -f $RUTA_DATOS/$NOMBRE_PARADAS_CSV
  sudo -u postgres -i psql -d memoria -c "$PARADAS_CSV"
fi 

if [ "$GENERAR_COMUNIDADES" = true ]; then
  ####################################################################################
  #rm -f $RUTA_DATOS_INFOMAP/*.tree

  for ARCHIVO_NET in $RUTA_DATOS_PAJEK/*.net; do
    echo "Procesando $ARCHIVO_NET"

    #NOMBRE_INFOMAP=$(echo "$ARCHIVO_NET" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

    # -i 'pajek'   Indica el formato de archivo de entrada
    # --two-level  Optimiza una partición de dos niveles de la red
    # -d           Asume que los arcos tienen dirección
    # --zero-based Considera que la enumeración de los indices comienza desde cero.
    # --code-rate cantidad de pasos que realiza el peatón antes de ser codificada su acción.
    $RUTA_INFOMAP/Infomap --code-rate 1 -i 'pajek' --two-level -d "$ARCHIVO_NET" "$RUTA_DATOS_INFOMAP"
  done 
fi

if [ "$GENERAR_CARTODB" = true ]; then
  ####################################################################################
  #rm -f -R $RUTA_DATOS_CARTODB/*.csv

  for ARCHIVO_TREE in $RUTA_DATOS_INFOMAP/*.tree; do
    echo "Procesando $ARCHIVO_TREE"

    php $RUTA_CODIGO/tree2cartodb.php $RUTA_DATOS/$NOMBRE_PARADAS_CSV $ARCHIVO_TREE $RUTA_DATOS_CARTODB/ 
  done
fi

# cambiamos el dueño de los archivos para poder verlos en el entorno de escritorio
chown -R cephei $RUTA_DATOS

