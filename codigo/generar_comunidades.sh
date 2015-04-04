#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo. Entiendanse 
# como procedimientos 

# crea los archivos csv usados para generar los archivos pajek y para el cálculo de la centralidad de intermediación.
GENERAR_ETAPA_CSV=false
# crea los archivos pajek a partir de los archivos csv
GENERAR_PAJEK=false
# crea el csv de paradas con toda su información (nombre, longitud, latitud, ...)
GENERAR_CSV_PARADAS=false
# genera las comunidades en dos niveles, por medio del framework infomap
GENERAR_COMUNIDADES=false
# genera un csv a partir del archivo de comunidades para poder ser mostrado en la herramienta cartodb.com 
GENERAR_CARTODB=true

####################################################################################
# Ruta de los directorios usados por el script
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo
RUTA_DATOS=$RUTA_MEMORIA/datos/comunidades
RUTA_DATOS_CSV=$RUTA_DATOS/csv
RUTA_DATOS_PAJEK=$RUTA_DATOS/pajek
RUTA_DATOS_INFOMAP=$RUTA_DATOS/infomap
RUTA_DATOS_CARTODB=$RUTA_DATOS/cartodb
RUTA_INFOMAP=/home/cephei/Desktop/Infomap
####################################################################################

# IMPORTANTE: Los acciones posteriores hacen uso de la manipulación de archivos por lo 
#             que es importante dar los permisos correspondientes al usuario postgres. 
chown -R cephei:postgres $RUTA_DATOS
chmod 775 -R $RUTA_DATOS

# Define los tramos horarios que se van a procesar y generar los csv 
# Estos deben tener la siguiente sintaxis XX-YY [XX-YY ...]
# donde XX e YY son números enteros de dos dígitos en el rango [00-23]
# y pueden ser iguales. Para concatenar varios tramos se usa el espacio. Ej: XX-YY ZZ-TT
#TRAMOS=(01-01 02-02 03-03 04-04 05-05 06-06 07-07 08-08 09-09 10-10 11-11 12-12 13-13 14-14 15-15 16-16 17-17 18-18 19-19 20-20 21-21 22-22 23-23 00-00 06-09 18-21)

# para filtrar por hora usar        : extract(hour from tiempo_subida)
# para filtrar por fecha y hora usar: (date_trunc('hour', tiempo_subida))
# para diltrar por fecha usar       : (date_trunc('day', tiempo_subida))

if [ "$GENERAR_ETAPA_CSV" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_CSV/*etapa.csv

  # Se ocupan los datos de toda la semana. 
  CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_expansion) AS peso 
                  FROM etapa_util 
                  GROUP BY par_subida, par_bajada) 
                  To '$RUTA_DATOS_CSV/semana_etapa.csv' WITH DELIMITER ';' CSV;"

  sudo -u postgres -i psql -d memoria -c "$CONSULTA"

# inicio comentario
<<'COMENTARIO1'
  # Hora para el tramo lunes-jueves (14-04-2013 al 17-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_expansion) AS peso 
                    FROM etapa_util 
                    WHERE extract(hour from tiempo_subida) BETWEEN $CONDICION AND 
                          (date_trunc('day', tiempo_subida)) BETWEEN '2013-04-14' AND '2013-04-17' 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_lunes_a_jueves_etapa.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done
  
  # Hora para el tramo viernes (18-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_expansion) AS peso 
                    FROM etapa_util 
                    WHERE extract(hour from tiempo_subida) BETWEEN $CONDICION AND 
                          (date_trunc('day', tiempo_subida)) = '2013-04-18' 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_viernes_etapa.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done

  # Hora para el tramo sábado (19-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_expansion) AS peso 
                    FROM etapa_util 
                    WHERE extract(hour from tiempo_subida) BETWEEN $CONDICION AND 
                          (date_trunc('day', tiempo_subida)) = '2013-04-19' 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_sabado_etapa.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done
  
  # Hora para el tramo domingo (20-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_expansion) AS peso 
                    FROM etapa_util 
                    WHERE extract(hour from tiempo_subida) BETWEEN $CONDICION AND 
                          (date_trunc('day', tiempo_subida)) = '2013-04-20' 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_domingo_etapa.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done
COMENTARIO1
# fin comentario

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
  rm -f $RUTA_DATOS_INFOMAP/*.tree

  for ARCHIVO_NET in $RUTA_DATOS_PAJEK/*.net; do
    echo "Procesando $ARCHIVO_NET"

    #NOMBRE_INFOMAP=$(echo "$ARCHIVO_NET" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

    # -i 'pajek'   Indica el formato de archivo de entrada
    # --two-level  Optimiza una partición de dos niveles de la red
    # -d           Asume que los arcos tienen dirección
    # --zero-based Considera que la enumeración de los indices comienza desde cero.
    $RUTA_INFOMAP/Infomap -i 'pajek' --two-level -d "$ARCHIVO_NET" "$RUTA_DATOS_INFOMAP"
  done 
fi

if [ "$GENERAR_CARTODB" = true ]; then
  ####################################################################################
  rm -f -R $RUTA_DATOS_CARTODB/*.csv

  for ARCHIVO_TREE in $RUTA_DATOS_INFOMAP/*.tree; do
    echo "Procesando $ARCHIVO_TREE"

    php $RUTA_CODIGO/tree2csv.php $RUTA_DATOS/$NOMBRE_PARADAS_CSV $ARCHIVO_TREE $RUTA_DATOS_CARTODB/ 
  done
fi

# cambiamos el dueño de los archivos para poder verlos en el entorno de escritorio
chown -R cephei $RUTA_DATOS

