<?php
// convierte un archivo .csv (paradero_id centralidad) a un csv para ser mostrado en cartodb.

if ($argc < 3) {
  echo "USO: php centralidad2cartodb.php <ruta archivo nombre paraderos> <ruta archivo csv> <ruta archivo salida> <hora datos>".PHP_EOL;
  exit(1);
}

// archivo csv con columnas codigo, nombre, longitud, latitud
$ruta_nombre_paraderos = $argv[1]; 
// ruta al archivo a ser leído.
$ruta_csv_centralidad  = $argv[2]; 
// nombre del archivo de salida
$nombre_csv            = array_shift(explode('.', array_pop(explode('/', $ruta_csv_centralidad)))).'.csv'; 
// ruta donde se almacena el archivo de salida
$ruta_salida           = $argv[3]; 
// hora de los datos (opcional)
$hora                  = (isset($argv[4])?$argv[4]:'');

// indica si el archivo existe y si es posible leerlo
if (!is_readable($ruta_nombre_paraderos)) {
  echo "El archivo '$ruta_nombre_paraderos' no existe o no se puede leer".PHP_EOL;
  exit(1);
}

// indica si el archivo existe y si es posible leerlo
if (!is_readable($ruta_csv_centralidad)) {
  echo "El archivo '$ruta_csv_centralidad' no existe o no se puede leer".PHP_EOL;
  exit(1);
}

$contenido_csv = file_get_contents($ruta_csv_centralidad, FILE_USE_INCLUDE_PATH);

$archivo_nombre_paraderos = fopen($ruta_nombre_paraderos, 'r');
$archivo_csv = fopen($ruta_salida.'/'.$nombre_csv, 'w');

if ($archivo_nombre_paraderos === false) {
  echo "No se pudo abrir archivo $archivo_nombre_paraderos".PHP_EOL;
  exit(1);
}

if ($archivo_csv === false) {
  echo "No se pudo crear archivo $ruta_salida/$nombre_csv.csv".PHP_EOL;
  exit(1);
}

// se quita la primera linea y se agrega encabezado de csv
$lineas = explode("\n", $contenido_csv);
$lineas = array_slice($lineas, 1);
$lineas = array_merge(array("Nombre latitud longitud".($hora==''?'':' hora')." centralidad"), $lineas);
$contenido_csv = implode("\n", $lineas);

// se lee linea por linea
while (($linea = fgets($archivo_nombre_paraderos)) !== false) {
  $elementos = array_map("trim", split(";", $linea));
  
  $patron = '/"'.$elementos[0].'"/i';
  $nuevo_texto = '"'.$elementos[1].'" '.$elementos[2].' '.$elementos[3].($hora==''?'':' '.$hora);

  $contenido_csv = preg_replace($patron, $nuevo_texto, $contenido_csv);
}

fclose($archivo_nombre_paraderos);

fwrite($archivo_csv, $contenido_csv);
fclose($archivo_csv);
?>
