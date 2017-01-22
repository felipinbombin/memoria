#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo. Entiendanse 
# como procedimientos 

# crea los archivos csv usados para generar los archivos csv con los arcos y su peso.
GENERAR_VIAJE_CON_ETAPAS_CSV=true
# crea el csv de paradas con toda su información (nombre, longitud, latitud, ...)
GENERAR_CSV_PARADAS=false
# calcula la centralidad de intermediación  para cada nodo del grafo
CALCULAR_CENTRALIDAD_DE_INTERMEDIACION=true
# genera un csv a partir del archivo de generado por el calculo de la centralidad para poder ser mostrado en la herramienta cartodb.com 
GENERAR_CARTODB=true

####################################################################################
# Ruta de los directorios usados por el script
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo/centralidad
RUTA_DATOS=$RUTA_MEMORIA/datos/centralidad_de_intermediacion
RUTA_DATOS_CSV=$RUTA_DATOS/csv
RUTA_DATOS_CENTRALIDAD=$RUTA_DATOS/CdI
RUTA_DATOS_CARTODB=$RUTA_DATOS/cartodb

####################################################################################

# IMPORTANTE: Los módulos posteriores manipulan archivos por lo 
#             que es importante dar los permisos correspondientes al usuario postgres. 
chown -R cephei:postgres $RUTA_DATOS
chmod 775 -R $RUTA_DATOS

# Define los tramos horarios que se van a procesar y generar los csv 
# Estos deben tener la siguiente sintaxis XX-YY [XX-YY ...]
# donde XX e YY son números enteros de dos dígitos en el rango [00-23]
# y pueden ser iguales. Para concatenar varios tramos se usa el espacio. Ej: XX-YY ZZ-TT
#TRAMOS=(01-01 02-02 03-03 04-04 05-05 06-06 07-07 08-08 09-09 10-10 11-11 12-12 13-13 14-14 15-15 16-16 17-17 18-18 19-19 20-20 21-21 22-22 23-23 00-00 06-09 18-21)
TRAMOS=(00-23 06-09 18-21)

# para filtrar por hora usar        : extract(hour from tiempo_subida)
# para filtrar por fecha y hora usar: (date_trunc('hour', tiempo_subida))
# para diltrar por fecha usar       : (date_trunc('day', tiempo_subida))

if [ "$GENERAR_VIAJE_CON_ETAPAS_CSV" = true ]; then
  rm -f $RUTA_DATOS_CSV/*viaje_con_etapas.csv

  # CALCULO POR HORA DE LA SEMANA COMPLETA
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    CONSULTA="copy (SELECT par_subida_1, par_bajada_1, par_subida_2, par_bajada_2, 
                           par_subida_3, par_bajada_3, par_subida_4, par_bajada_4, SUM(factor_expansion) AS peso 
                    FROM viaje_util 
                    WHERE extract(hour from tiempo_subida_1) BETWEEN $CONDICION 
                    GROUP BY par_subida_1, par_bajada_1, par_subida_2, par_bajada_2, 
                             par_subida_3, par_bajada_3, par_subida_4, par_bajada_4)  
                    To '$RUTA_DATOS_CSV/${TRAMO}_semana_viaje_con_etapas.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done
fi

NOMBRE_PARADAS_CSV="PARADAS.csv"

if [ "$GENERAR_CSV_PARADAS" = true ]; then
  echo "GENERANDO CSV PARADA"
  # Genera un csv con los datos de la tabla parada_util. Es usado al final del proceso para reemplazar
  # los códigos de paraderos e insertar su respectiva posición geográfica, nombre, etc...
  PARADAS_CSV="copy (SELECT * FROM parada_util) To '$RUTA_DATOS/$NOMBRE_PARADAS_CSV' WITH DELIMITER ';' CSV;"
  rm -f $RUTA_DATOS/$NOMBRE_PARADAS_CSV
  sudo -u postgres -i psql -d memoria -c "$PARADAS_CSV"
fi 

if [ "$CALCULAR_CENTRALIDAD_DE_INTERMEDIACION" = true ]; then
  rm -f $RUTA_DATOS_CENTRALIDAD/*.csv

  # Para cada archivo con datos
  for ARCHIVO_CSV in $RUTA_DATOS_CSV/*.csv; do
    echo "CALCULAR CENTRALIDAD DE INTERMEDIACION: Procesando $ARCHIVO_CSV"

    NOMBRE_CSV=$(echo "$ARCHIVO_CSV" | rev | cut -d '/' -f 1 | rev)
    
    php calcular_centralidad_de_intermediacion.php $ARCHIVO_CSV $RUTA_DATOS_CENTRALIDAD/
  done 
fi

if [ "$GENERAR_CARTODB" = true ]; then
  rm -f -R $RUTA_DATOS_CARTODB/*.csv

  for ARCHIVO_CSV in $RUTA_DATOS_CENTRALIDAD/*.csv; do
    echo "GENERANDO CARTODB: Procesando $ARCHIVO_CSV"
    HORA=$(echo "$ARCHIVO_CSV" | cut -d '-' -f 1 | rev | cut -d '/' -f 1 | rev)
    php $RUTA_CODIGO/centralidad2cartodb.php $RUTA_DATOS/$NOMBRE_PARADAS_CSV $ARCHIVO_CSV $RUTA_DATOS_CARTODB/ $HORA
  done
fi

# cambiamos el dueño de los archivos para poder verlos en el entorno de escritorio
chown -R cephei $RUTA_DATOS

