#!/bin/bash

####################################################################################
# Variables que definen lo que se debe hacer

# ¿Crear base de datos y cargar datos?
CREAR_BD_Y_CARGAR_DATOS=true
# ¿Filtrar los datos? (esto llena elimina los registros existentes en las tablas etapa_util y viaje_util 
# y luego las llena nuevamente a partir de las tablas etapas y viajes. 
FILTRAR_DATOS=true
# crea los archivos csv usados para generar los archivos pajek
GENERAR_CSV=false
# crea los archivos pajek a partir de los archivos csv
GENERAR_PAJEK=false

####################################################################################
# Ruta de los directorios usados por el script
RUTA_BACKUP=/home/cephei/Desktop/backup
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo
RUTA_DATOS=$RUTA_MEMORIA/datos
RUTA_CSV=$RUTA_DATOS/CSV
RUTA_PAJEK=$RUTA_DATOS/PAJEK
####################################################################################


# Activar medición de tiempo para la ejecución de las consultas en postgres
sudo -u postgres -i psql -c "\\timing on"

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

  echo "Datos importados exitosamente."
fi

if [ "$FILTRAR_DATOS" = true ]; then
  ####################################################################################
  # Se lleva a cabo el filtrado de datos, lo que completa 
  # las tablas etapa_util y viaje_util

  sudo -u postgres -i psql -d memoria -f $RUTA_CODIGO/filtrar_datos.sql

  echo "Tablas etapa_util y viaje_util con datos."
fi

if [ "$GENERAR_CSV" = true ]; then
####################################################################################
echo "Generando archivos CSV..."

# IMPORTANTE: para que el archivo pueda ser guardado en el path señalado el usuario postgres
#             debe tener permisos sobre ese directorio por lo que nos aseguramos de darselo
#             cada vez que ejecutamos ésta instrucción.
chown -R cephei:postgres $RUTA_DATOS
chmod 775 -R $RUTA_DATOS

# define los tramos horarios que se van a procesar 
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
                  To '$RUTA_CSV/$TRAMO.csv' with CSV;"

  sudo -u postgres -i psql -d memoria -c "$CONSULTA"
done

echo "Archivos csv generados exitosamente"
fi

if [ "$GENERAR_PAJEK" = true ]; then
####################################################################################
echo "Generando archivos pajek a partir de csv's generados..."

for ARCHIVO_CSV in $RUTA_CSV/*.csv; do
  echo "Procesando $ARCHIVO_CSV"
  # se quita la extensión y ruta 
  nombre_pajek=$(echo "$ARCHIVO_CSV" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

  php crear_archivo_pajek.php $ARCHIVO_CSV $RUTA_PAJEK/ $nombre_pajek
done

echo "Archivos pajek generados exitosamente."
fi









