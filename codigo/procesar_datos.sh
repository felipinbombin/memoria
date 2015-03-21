#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen lo que se debe hacer

# ¿Crear base de datos y cargar datos?
CREAR_BD_Y_CARGAR_DATOS=false
# ¿Filtrar los datos? (esto llena elimina los registros existentes en las tablas etapa_util y viaje_util 
# y luego las llena nuevamente a partir de las tablas etapas y viajes. 
FILTRAR_DATOS=false
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

if [ "$CREAR_BD_Y_CARGAR_DATOS" = true ]; then
  ####################################################################################
  # Crear base de datos y usuario
  sudo -u postgres -i psql -f $RUTA_CODIGO/crear_db.sql

  # Crear la estructura de la base de datos.
  sudo -u postgres -i psql -d memoria -f $RUTA_CODIGO/estructura_db.sql

  ####################################################################################
  echo "Importando datos..."

  # Se cargan los datos en la base de datos memoria
  sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_etapas
  sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_viajes
  sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_redparadas
  sudo -u postgres -i psql -d memoria -a -f $RUTA_BACKUP/backup_estaciones_metro 

  echo "Datos importados exitosamente."
fi

if [ "$FILTRAR_DATOS" = true ]; then
  ####################################################################################
  # Se lleva a cabo el filtrado de datos, lo que inserta registros en
  # las tablas etapa_util, viaje_util y parada_util

  sudo -u postgres -i psql -d memoria -f $RUTA_CODIGO/filtrar_datos.sql

  echo "Tablas etapa_util, viaje_util y parada_util tienen datos."
fi

if [ "$GENERAR_ETAPA_CSV" = true ]; then
  ####################################################################################
  echo "Eliminando archivos CSV de etapas existentes..."
  rm -f $RUTA_DATOS_CSV/*etapa.csv

  echo "Generando archivos CSV a partir de la tabla etapa_util..."

  # IMPORTANTE: para que el archivo pueda ser guardado en el path señalado el usuario postgres
  #             debe tener permisos sobre ese directorio por lo que nos aseguramos de dárselo
  #             cada vez que ejecutamos esta instrucción.
  chown -R cephei:postgres $RUTA_DATOS
  chmod 775 -R $RUTA_DATOS

  # Define los tramos horarios que se van a procesar 
  # Estos deben tener la siguiente sintaxis XX-YY [XX-YY ...]
  # donde XX e YY son números enteros de dos dígitos en el rango [00-23]
  # y pueden ser iguales. Para concatenar varios tramos se usa el espacio. Ej: XX-YY ZZ-TT
  TRAMOS=(05-11)
  
  # para filtrar por hora usar        : extract(hour from tiempo_subida)
  # para filtrar por fecha y hora usar: (date_trunc('hour', tiempo_subida))
  # para diltrar por fecha usar       : (date_trunc('day', tiempo_subida))

  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(factor_exp_etapa) AS peso 
                    FROM etapa_util 
                    WHERE extract(hour from tiempo_subida) BETWEEN $CONDICION 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_etapa.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done

  echo "Archivos csv generados exitosamente"
  ####################################################################################
fi

if [ "$GENERAR_VIAJE_CSV" = true ]; then
  ####################################################################################
  echo "Eliminando archivos CSV de viajes existentes..."
  rm -f $RUTA_DATOS_CSV/*viaje.csv

  echo "Generando archivos CSV a partir de la tabla viaje_util..."

  # ... ...
  
  echo "Archivos csv generados exitosamente"
  ####################################################################################
fi

# Genera un csv con los datos de parada_util. Es usado al final del proceso para actualizar
# los códigos de paraderos e insertar su respectiva posición geográfica.
NOMBRE_PARADAS_CSV="PARADAS"
PARADAS_CSV="copy (SELECT * FROM parada_util) To '$RUTA_DATOS/$NOMBRE_PARADAS_CSV.csv' WITH DELIMITER ';' CSV;"
sudo -u postgres -i psql -d memoria -c "$PARADAS_CSV"

if [ "$GENERAR_PAJEK" = true ]; then
  ####################################################################################
  echo "Eliminando archivos PAJEK existentes..."
  rm -f $RUTA_DATOS_PAJEK/*.net

  echo "Generando archivos pajek a partir de csv's generados..."

  # por cada csv existente
  for ARCHIVO_CSV in $RUTA_DATOS_CSV/*.csv; do
    echo "Procesando $ARCHIVO_CSV"
    # se quita la extensión y ruta 
    NOMBRE_PAJEK=$(echo "$ARCHIVO_CSV" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

    php crear_archivo_pajek.php $ARCHIVO_CSV $RUTA_DATOS_PAJEK/ $NOMBRE_PAJEK    
  done

  echo "Archivos pajek generados exitosamente."
fi

if [ "$GENERAR_COMUNIDADES" = true ]; then
  ####################################################################################
  echo "Eliminando archivos TREE existentes..."
  rm -f $RUTA_DATOS_INFOMAP/*.tree

  echo "Generando comunidades a partir de archivo pajek..."

  for ARCHIVO_NET in $RUTA_DATOS_PAJEK/*.net; do
    echo "Procesando $ARCHIVO_NET"

    NOMBRE_INFOMAP=$(echo "$ARCHIVO_NET" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

    # -i 'pajek'  Indica el formato de archivo de entrada
    # --two-level Optimiza una partición de dos niveles de la red
    # -d          Asume que los arcos tienen dirección
    $RUTA_INFOMAP/Infomap -i 'pajek' --two-level -d "$ARCHIVO_NET" "$RUTA_DATOS_INFOMAP"

    # dado el código de parada agrega el nombre, latitud y longitud.
    php tree2csv.php "$RUTA_DATOS/$NOMBRE_PARADAS_CSV.csv" "$RUTA_DATOS_INFOMAP/$NOMBRE_INFOMAP.tree" $NOMBRE_INFOMAP "$RUTA_DATOS_CARTODB"
  done

  echo "Archivos de comunidades generados exitosamente"
  ####################################################################################
fi

# cambiamos el dueño de los archivos para poder verlos en el entorno de escritorio
chown -R cephei $RUTA_MEMORIA


