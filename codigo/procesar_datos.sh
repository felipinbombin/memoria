#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo. Entiendanse 
# como módulos

# Crea la base de datos y cargar los datos base.
GENERAR_BD_Y_CARGAR_DATOS=true
# ¿Filtrar los datos? (esto llena elimina los registros existentes en las tablas etapa_util y viaje_util 
# y luego las llena nuevamente a partir de las tablas etapas y viajes. 
FILTRAR_DATOS=true
# crea los archivos csv usados para generar los archivos pajek
GENERAR_ETAPA_CSV=true
GENERAR_VIAJE_CSV=true
# crea los archivos pajek a partir de los archivos csv
GENERAR_PAJEK=true
# genera las comunidades en dos niveles, por medio del framework infomap
GENERAR_COMUNIDADES=true

####################################################################################
# Ruta de los directorios usados por el script
RUTA_BACKUP=/home/cephei/Desktop/backup
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo
RUTA_DATOS=$RUTA_MEMORIA/datos
RUTA_DATOS_CSV=$RUTA_DATOS/CSV
RUTA_DATOS_PAJEK=$RUTA_DATOS/PAJEK
RUTA_DATOS_INFOMAP=$RUTA_DATOS/INFOMAP
RUTA_DATOS_IGRAPH=$RUTA_DATOS/IGRAPH
RUTA_DATOS_CARTODB=$RUTA_DATOS/CARTODB
RUTA_INFOMAP=/home/cephei/Desktop/Infomap
RUTA_IGRAPH=/home/cephei/Desktop/igraph-0.7.1
####################################################################################

if [ "$GENERAR_BD_Y_CARGAR_DATOS" = true ]; then
  ####################################################################################
  # Configura las acciones que se pueden realizar dentro de esta sección
  ####################################################################################
  CREAR_BD=true
  CARGAR_ETAPAS=true
  CARGAR_VIAJES=true
  CARGAR_REDPARADAS=true
  CARGAR_ESTACIONESMETRO=true
  ####################################################################################

  # Crear base de datos
  if [ "$CREAR_BD" = true ]; then
    sudo -u postgres -i psql -f $RUTA_CODIGO/crear_db.sql
    sudo -u postgres -i psql -d memoria -f $RUTA_CODIGO/estructura_db.sql
  fi

  # Se cargan los datos en la base de datos 'memoria'
  if [ "$CARGAR_ETAPAS"          = true ]; then sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_etapas; fi
  if [ "$CARGAR_VIAJES"          = true ]; then sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_viajes; fi
  if [ "$CARGAR_REDPARADAS"      = true ]; then sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_redparadas; fi
  if [ "$CARGAR_ESTACIONESMETRO" = true ]; then sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_estaciones_metro; fi 
fi

if [ "$FILTRAR_DATOS" = true ]; then
  ####################################################################################
  # Se llenan las tablas etapa_util, viaje_util, parada_util y se normalizan los 
  # nombres de las estaciones de metro.
  sudo -u postgres -i psql -d memoria -f $RUTA_CODIGO/filtrar_datos.sql
fi

# IMPORTANTE: Los módulos posteriores hacen uso de la manipulación de archivos por lo 
#             que es importante dar los permisos correspondientes al usuario postgres. 
chown -R cephei:postgres $RUTA_DATOS
chmod 775 -R $RUTA_DATOS

if [ "$GENERAR_ETAPA_CSV" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_CSV/*etapa.csv

  # Define los tramos horarios que se van a procesar 
  # Estos deben tener la siguiente sintaxis XX-YY [XX-YY ...]
  # donde XX e YY son números enteros de dos dígitos en el rango [00-23]
  # y pueden ser iguales. Para concatenar varios tramos se usa el espacio. Ej: XX-YY ZZ-TT
  TRAMOS=(01-01 02-02 03-03 04-04 05-05 06-06 07-07 08-08 09-09 10-10 11-11 12-12 13-13 14-14 15-15 16-16 17-17 18-18 19-19 20-20 21-21 22-22 23-23 00-00)
  # Tramos transantiago
  #TRAMOS=(XX-XX XX-XX XX-XX)

  # para filtrar por hora usar        : extract(hour from tiempo_subida)
  # para filtrar por fecha y hora usar: (date_trunc('hour', tiempo_subida))
  # para diltrar por fecha usar       : (date_trunc('day', tiempo_subida))

  # CALCULO POR HORA DE LA SEMANA COMPLETA
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_exp_etapa) AS peso 
                    FROM etapa_util 
                    WHERE extract(hour from tiempo_subida) BETWEEN $CONDICION 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_etapa.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done

  # Hora para el tramo lunes-jueves (14-04-2013 al 17-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_exp_etapa) AS peso, '2013-04-17T$HORA:00:00Z' AS fecha
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
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_exp_etapa) AS peso, '2013-04-18T$HORA:00:00Z' AS fecha
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
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_exp_etapa) AS peso, '2013-04-19T$HORA:00:00Z' AS fecha
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
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_exp_etapa) AS peso, '2013-04-20T$HORA:00:00Z' AS fecha 
                    FROM etapa_util 
                    WHERE extract(hour from tiempo_subida) BETWEEN $CONDICION AND 
                          (date_trunc('day', tiempo_subida)) = '2013-04-20' 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_domingo_etapa.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done

fi

if [ "$GENERAR_VIAJE_CSV" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_CSV/*viaje.csv

  # ... ...
fi

if [ "$GENERAR_PAJEK" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_PAJEK/*.net

  for ARCHIVO_CSV in $RUTA_DATOS_CSV/*.csv; do
    echo "Procesando $ARCHIVO_CSV"
    php crear_archivo_pajek.php $ARCHIVO_CSV $RUTA_DATOS_PAJEK/  
  done
fi

# Genera un csv con los datos de la tabla parada_util. Es usado al final del proceso para actualizar
# los códigos de paraderos e insertar su respectiva posición geográfica.
NOMBRE_PARADAS_CSV="PARADAS.csv"
PARADAS_CSV="copy (SELECT * FROM parada_util) To '$RUTA_DATOS/$NOMBRE_PARADAS_CSV' WITH DELIMITER ';' CSV;"
sudo -u postgres -i psql -d memoria -c "$PARADAS_CSV"

if [ "$GENERAR_COMUNIDADES" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_INFOMAP/*.tree

  for ARCHIVO_NET in $RUTA_DATOS_PAJEK/*.net; do
    echo "Procesando $ARCHIVO_NET"

    NOMBRE_INFOMAP=$(echo "$ARCHIVO_NET" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

    # -i 'pajek'  Indica el formato de archivo de entrada
    # --two-level Optimiza una partición de dos niveles de la red
    # -d          Asume que los arcos tienen dirección
    $RUTA_INFOMAP/Infomap -i 'pajek' --two-level -d "$ARCHIVO_NET" "$RUTA_DATOS_INFOMAP"
    php tree2csv.php $RUTA_DATOS/$NOMBRE_PARADAS_CSV $RUTA_DATOS_INFOMAP/$NOMBRE_INFOMAP.tree $RUTA_DATOS_CARTODB
  done 
fi

# cambiamos el dueño de los archivos para poder verlos en el entorno de escritorio
chown -R cephei $RUTA_MEMORIA

