#!/bin/bash

# se detiene si ocurre un error
set -o errexit 

####################################################################################
# Variables que definen las distintas tareas que se pueden llevar a cabo. Entiendanse 
# como procedimientos 

# crea los archivos csv usados para generar los archivos csv con los arcos y su peso.
GENERAR_VIAJE_CSV=false
# convierte los archivos csv en formato pajek para generar ids, conocer cantidad de nodos y 
# además obtener una secuenta de arcos codificada.
GENERAR_PAJEK=false
# crea el csv de paradas con toda su información (nombre, longitud, latitud, ...)
GENERAR_CSV_PARADAS=false
# calcula el pagerank para cada nodo del grafo por medio de la libraria igraph
CALCULAR_PAGERANK=true
# concatena los archivos creados por hora en un solo archivo para mostrar una secuencia en cartodb.com
CONCATENAR_HORAS=false
# genera un csv a partir del archivo de generado por igraph para poder ser mostrado en la herramienta cartodb.com 
GENERAR_CARTODB=true

####################################################################################
# Ruta de los directorios usados por el script
RUTA_MEMORIA=/home/cephei/Desktop/memoria
RUTA_CODIGO=$RUTA_MEMORIA/codigo
RUTA_DATOS=$RUTA_MEMORIA/datos/pagerank
RUTA_DATOS_CSV=$RUTA_DATOS/csv
RUTA_DATOS_PAJEK=$RUTA_DATOS/pajek
RUTA_DATOS_IGRAPH=$RUTA_DATOS/igraph
RUTA_DATOS_CARTODB=$RUTA_DATOS/cartodb

RUTA_IGRAPH_H=/usr/local/include/igraph
RUTA_IGRAPH_LIB=/usr/local/lib
####################################################################################

# IMPORTANTE: Los módulos posteriores hacen uso de la manipulación de archivos por lo 
#             que es importante dar los permisos correspondientes al usuario postgres. 
chown -R cephei:postgres $RUTA_DATOS
chmod 775 -R $RUTA_DATOS

# Define los tramos horarios que se van a procesar y generar los csv 
# Estos deben tener la siguiente sintaxis XX-YY [XX-YY ...]
# donde XX e YY son números enteros de dos dígitos en el rango [00-23]
# y pueden ser iguales. Para concatenar varios tramos se usa el espacio. Ej: XX-YY ZZ-TT
TRAMOS=(01-01 02-02 03-03 04-04 05-05 06-06 07-07 08-08 09-09 10-10 11-11 12-12 13-13 14-14 15-15 16-16 17-17 18-18 19-19 20-20 21-21 22-22 23-23 00-00 06-09 18-21)

# para filtrar por hora usar        : extract(hour from tiempo_subida)
# para filtrar por fecha y hora usar: (date_trunc('hour', tiempo_subida))
# para diltrar por fecha usar       : (date_trunc('day', tiempo_subida))

if [ "$GENERAR_VIAJE_CSV" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_CSV/*.csv

  # CALCULO POR HORA DE LA SEMANA COMPLETA
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(peso) 
                    FROM (SELECT par_subida_1 AS par_subida, par_bajada_1 AS par_bajada, SUM(factor_expansion) AS peso
                          FROM viaje_util 
                          WHERE netapa=1 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION 
                          GROUP BY par_subida_1, par_bajada_1  
                          UNION 
                          SELECT par_subida_1, par_bajada_2, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=2 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION 
                          GROUP BY par_subida_1, par_bajada_2 
                          UNION 
                          SELECT par_subida_1, par_bajada_3, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=3 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION 
                          GROUP BY par_subida_1, par_bajada_3 
                          UNION 
                          SELECT par_subida_1, par_bajada_4, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=4 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION 
                          GROUP BY par_subida_1, par_bajada_4) AS viaje 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_semana_viaje.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done

  # Hora para el tramo lunes-jueves (14-04-2013 al 17-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(peso) AS peso 
                    FROM (SELECT par_subida_1 AS par_subida, par_bajada_1 AS par_bajada, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=1 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) BETWEEN '2013-04-14' AND '2013-04-17' 
                          GROUP BY par_subida_1, par_bajada_1  
                          UNION 
                          SELECT par_subida_1, par_bajada_2, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=2 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) BETWEEN '2013-04-14' AND '2013-04-17' 
                          GROUP BY par_subida_1, par_bajada_2 
                          UNION 
                          SELECT par_subida_1, par_bajada_3, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=3 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) BETWEEN '2013-04-14' AND '2013-04-17'  
                          GROUP BY par_subida_1, par_bajada_3 
                          UNION 
                          SELECT par_subida_1, par_bajada_4, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=4 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) BETWEEN '2013-04-14' AND '2013-04-17'  
                          GROUP BY par_subida_1, par_bajada_4) AS viaje 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_lunes_a_jueves_viaje.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done
  
  # Hora para el tramo viernes (18-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(peso) AS peso 
                    FROM (SELECT par_subida_1 AS par_subida, par_bajada_1 AS par_bajada, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=1 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-18' 
                          GROUP BY par_subida_1, par_bajada_1  
                          UNION 
                          SELECT par_subida_1, par_bajada_2, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=2 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-18' 
                          GROUP BY par_subida_1, par_bajada_2 
                          UNION 
                          SELECT par_subida_1, par_bajada_3, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=3 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-18'  
                          GROUP BY par_subida_1, par_bajada_3 
                          UNION 
                          SELECT par_subida_1, par_bajada_4, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=4 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-18'  
                          GROUP BY par_subida_1, par_bajada_4) AS viaje 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_viernes_viaje.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done

  # Hora para el tramo sábado (19-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(peso) AS peso  
                    FROM (SELECT par_subida_1 AS par_subida, par_bajada_1 AS par_bajada, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=1 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-19' 
                          GROUP BY par_subida_1, par_bajada_1  
                          UNION 
                          SELECT par_subida_1, par_bajada_2, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=2 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-19' 
                          GROUP BY par_subida_1, par_bajada_2 
                          UNION 
                          SELECT par_subida_1, par_bajada_3, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=3 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-19'  
                          GROUP BY par_subida_1, par_bajada_3 
                          UNION 
                          SELECT par_subida_1, par_bajada_4, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=4 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-19'  
                          GROUP BY par_subida_1, par_bajada_4) AS viaje 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_sabado_viaje.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done
  
  # Hora para el tramo domingo (20-04-2013)
  for TRAMO in ${TRAMOS[@]}; do
    CONDICION=$(echo "$TRAMO" | sed -r 's/-/ AND /g')
    HORA=$(echo "$TRAMO" | cut -d '-' -f 1)
    CONSULTA="copy (SELECT par_subida, par_bajada, SUM(peso) AS peso 
                    FROM (SELECT par_subida_1 AS par_subida, par_bajada_1 AS par_bajada, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=1 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-20' 
                          GROUP BY par_subida_1, par_bajada_1  
                          UNION 
                          SELECT par_subida_1, par_bajada_2, SUM(factor_expansion) AS peso 
                          FROM viaje_util 
                          WHERE netapa=2 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-20' 
                          GROUP BY par_subida_1, par_bajada_2 
                          UNION 
                          SELECT par_subida_1, par_bajada_3, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=3 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-20'  
                          GROUP BY par_subida_1, par_bajada_3 
                          UNION 
                          SELECT par_subida_1, par_bajada_4, SUM(factor_expansion) AS peso   
                          FROM viaje_util 
                          WHERE netapa=4 AND extract(hour from tiempo_subida_1) BETWEEN $CONDICION AND 
                                (date_trunc('day', tiempo_subida_1)) = '2013-04-20'  
                          GROUP BY par_subida_1, par_bajada_4) AS viaje 
                    GROUP BY par_subida, par_bajada) 
                    To '$RUTA_DATOS_CSV/${TRAMO}_domingo_viaje.csv' WITH DELIMITER ';' CSV;"

    sudo -u postgres -i psql -d memoria -c "$CONSULTA"
  done

fi

NOMBRE_PARADAS_CSV="PARADAS.csv"

if [ "$GENERAR_CSV_PARADAS" = true ]; then

  # Genera un csv con los datos de la tabla parada_util. Es usado al final del proceso para reemplazar
  # los códigos de paraderos e insertar su respectiva posición geográfica, nombre, etc...
  PARADAS_CSV="copy (SELECT * FROM parada_util) To '$RUTA_DATOS/$NOMBRE_PARADAS_CSV' WITH DELIMITER ';' CSV;"
  rm -f $RUTA_DATOS/$NOMBRE_PARADAS_CSV
  sudo -u postgres -i psql -d memoria -c "$PARADAS_CSV"
fi 

if [ "$GENERAR_PAJEK" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_PAJEK/*.net

  for ARCHIVO_CSV in $RUTA_DATOS_CSV/*.csv; do
    echo "Procesando $ARCHIVO_CSV"
    php $RUTA_CODIGO/arcos2pajek.php $ARCHIVO_CSV $RUTA_DATOS_PAJEK/  
  done
fi

if [ "$CALCULAR_PAGERANK" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_IGRAPH/*.csv

  # IMPORTANTE: si no encuentra lib en share files al compilar hacer lo siguiente
  # Hay que agregar la línea 'include /usr/local/lib' en el archivo '/etc/ld.so.conf'
  # y luego cargar el archivo ejecutando el comando 'ldconfig'
  
  NOMBRE_EJECUTABLE="calcular_pagerank"
    
  # Compilar código
  gcc $RUTA_CODIGO/calcular_pagerank.c -I$RUTA_IGRAPH_H -L$RUTA_IGRAPH_LIB -ligraph -o $NOMBRE_EJECUTABLE

  for ARCHIVO_PAJEK in $RUTA_DATOS_PAJEK/*.net; do
    echo "Procesando $ARCHIVO_PAJEK"

    NOMBRE_CSV=$(echo "$ARCHIVO_PAJEK" | cut -d '.' -f 1 | rev | cut -d '/' -f 1 | rev)

    # Ejecutar código
    $RUTA_CODIGO/$NOMBRE_EJECUTABLE $ARCHIVO_PAJEK > $RUTA_DATOS_IGRAPH/$NOMBRE_CSV.csv

    break
  done 

  # se elimina ejecutable
  rm -f $RUTA_CODIGO/$NOMBRE_EJECUTABLE
fi

if [ "$CONCATENAR_HORAS" = true ]; then
  ####################################################################################
  rm -f $RUTA_DATOS_CARTODB/*.csv

  ENCABEZADO="1er_nivel 2do_nivel PageRank Nombre latitud longitud fecha"
  ARCHIVOS=("lunes_a_jueves" "viernes" "sabado" "domingo" "semana")

  for ARCHIVO in ${ARCHIVOS[@]}; do

    # los archivos con ese tramo horario no me interesa concatenarlos
    if [[ $ARCHIVO == *06-09* ]] || [[ $ARCHIVO == *18-21* ]] ; then
      continue
    fi

    echo "Procesando datos $ARCHIVO ..."
    cat $RUTA_DATOS_CARTODB/${ARCHIVO}_etapa/*.csv >> $RUTA_DATOS_CARTODB/$ARCHIVO.csv
    # se eliminan los encabezados del archivo(uno por archivo concatenado)
    sed -i '/^1er_nivel/d' $RUTA_DATOS_CARTODB/$ARCHIVO.csv
    # se agrega encabezado
    echo "$ENCABEZADO" | cat - $RUTA_DATOS_CARTODB/$ARCHIVO.csv > $RUTA_DATOS_CARTODB/tmp && mv $RUTA_DATOS_CARTODB/tmp $RUTA_DATOS_CARTODB/$ARCHIVO.csv
  done
  
  rm -f $RUTA_DATOS_CARTODB/tmp
fi 

if [ "$GENERAR_CARTODB" = true ]; then
  ####################################################################################
  rm -f -R $RUTA_DATOS_CARTODB/*.csv

  for ARCHIVO_CSV in $RUTA_DATOS_IGRAPH/*.csv; do
    echo "Procesando $ARCHIVO_CSV"

    php $RUTA_CODIGO/pagerank2cartodb.php $RUTA_DATOS/$NOMBRE_PARADAS_CSV $ARCHIVO_CSV $RUTA_DATOS_CARTODB/ 
  done
fi

# cambiamos el dueño de los archivos para poder verlos en el entorno de escritorio
chown -R cephei $RUTA_DATOS

