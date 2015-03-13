#!/bin/bash

PATH=/home/cephei/Desktop/backup

# cambiamos al usuario postgres
su postgres 

# Se cargan los datos en la base de datos
psql -d memoria -a -f $PATH/backup_etapas
psql -d memoria -a -f $PATH/backup_viajes
psql -d memoria -a -f $PATH/backup_redparadas



#echo id

#psql sigge

#\q

# la opción -S de sudo permite leer la contraseña desde STD

#su root

