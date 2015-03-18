#!/bin/bash

# Ruta de los archivos con los datos de la base de datos abril-2013.
RUTA_DATOS=/home/cephei/Desktop/backup
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo

# Crear base de datos y usuario
sudo -u postgres -i psql -f $RUTA_CODIGO/crear_db.sql

# Crear la estructura de la base de datos.
sudo -u postgres -i psql -d memoria -f $RUTA_CODIGO/estructura_db.sql

echo "Importando datos..."

# Se cargan los datos en la base de datos
sudo -u postgres -i psql -d memoria -a -f $RUTA_DATOS/backup_etapas
sudo -u postgres -i psql -d memoria -a -f $RUTA_DATOS/backup_viajes
sudo -u postgres -i psql -d memoria -a -f $RUTA_DATOS/backup_redparadas

echo "Datos importados exitosamente."

# Se lleva a cabo el filtrado de datos

#sudo -u postgres -i psql -d memoria -f $RUTA_CODIGO/filtrar_datos.sql
