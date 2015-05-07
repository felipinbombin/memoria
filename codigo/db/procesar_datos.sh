#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo. Entiendanse 
# como procedimientos 

# Crea la base de datos y cargar los datos base.
GENERAR_BD_Y_CARGAR_DATOS=false
# Elimina los registros existentes en las tablas etapa_util, viaje_util, parada_util
# y luego las llena nuevamente a partir de las tablas etapas, viajes, redparadas y estaciones_metro
# (esta última primero se modifica para que haga el match con los datos en las tablas etapa_util y viaje_util). 
FILTRAR_DATOS=false

####################################################################################
# Ruta de los directorios usados por el script
RUTA_BACKUP=/home/cephei/Desktop/backup
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo/db
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

