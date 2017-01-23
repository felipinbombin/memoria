#!/bin/bash

# Se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo en este script. 

# Crea la base de datos y carga los datos.
GENERAR_BD_Y_CARGAR_DATOS=true
# Elimina los registros existentes en las tablas etapa_util, viaje_util, parada_util
# y luego las llena nuevamente a partir de las tablas etapas, viajes, redparadas y estaciones_metro
# (esta última primero se modifica para que haga el match con los datos en las tablas etapa_util y viaje_util). 
FILTRAR_DATOS=false

RUTA_BACKUP=/mnt/volume-sfo2-01/source
RUTA_ARCHIVOS=/home/memoria
RUTA_CODIGO=$RUTA_ARCHIVOS/codigo/db
NOMBRE_BD="memoria"

if [ "$GENERAR_BD_Y_CARGAR_DATOS" = true ]; then
  
  sudo -u postgres -i psql -f $RUTA_CODIGO/crear_db.sql
  sudo -u postgres -i psql -d $NOMBRE_BD -f $RUTA_CODIGO/estructura_db.sql

  sudo -u postgres -i psql -d $NOMBRE_BD -a -f $RUTA_BACKUP/backup_etapas
  sudo -u postgres -i psql -d $NOMBRE_BD -a -f $RUTA_BACKUP/backup_viajes
  sudo -u postgres -i psql -d $NOMBRE_BD -a -f $RUTA_BACKUP/backup_redparadas
  sudo -u postgres -i psql -d $NOMBRE_BD -a -f $RUTA_BACKUP/backup_estaciones_metro
  sudo -u postgres -i psql -d $NOMBRE_BD -a -c "ALTER TABLE public.viajes OWNER TO felipe;"
fi

if [ "$FILTRAR_DATOS" = true ]; then
  sudo -u postgres -i psql -d $NOMBRE_BD -f $RUTA_CODIGO/filtrar_normalizar_datos.sql
fi

