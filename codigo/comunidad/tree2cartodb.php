<?php
// convierte un archivo .tree a un csv para ser mostrado en cartodb.

if ($argc < 3) {
  echo "USO: php tree2cartodb.php <ruta archivo nombre paraderos> <ruta archivo tree> <ruta archivo salida> <hora datos>".PHP_EOL;
  exit(1);
}

// archivo csv con columnas codigo, nombre, longitud, latitud
$ruta_nombre_paraderos = $argv[1]; 
// ruta al archivo a ser leído.
$ruta_infomap_tree     = $argv[2]; 
// nombre del archivo de salida
$nombre_tree           = array_shift(explode('.', array_pop(explode('/', $ruta_infomap_tree)))).'.csv'; 
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
if (!is_readable($ruta_infomap_tree)) {
  echo "El archivo '$ruta_infomap_tree' no existe o no se puede leer".PHP_EOL;
  exit(1);
}

$contenido_tree = file_get_contents($ruta_infomap_tree, FILE_USE_INCLUDE_PATH);

$archivo_nombre_paraderos = fopen($ruta_nombre_paraderos, 'r');
$archivo_tree = fopen($ruta_salida.'/'.$nombre_tree, 'w');

if ($archivo_nombre_paraderos === false) {
  echo "No se pudo abrir archivo $archivo_nombre_paraderos".PHP_EOL;
  exit(1);
}

if ($archivo_tree === false) {
  echo "No se pudo crear archivo $ruta_salida/$nombre_tree.csv".PHP_EOL;
  exit(1);
}

// se quita la primera linea y se agrega encabezado de csv
$lineas = explode("\n", $contenido_tree);
$lineas = array_slice($lineas, 1);
$lineas = array_merge(array("1er_nivel 2do_nivel PageRank Nombre latitud longitud".($hora==''?'':' hora')." id_nodo_pajek"), $lineas);
$contenido_tree = implode("\n", $lineas);

// se reemplaza el : por un espacio para que el archivo cumpla con el estandar csv
$contenido_tree = str_replace(':', ' ', $contenido_tree);

// se lee linea por linea
while (($linea = fgets($archivo_nombre_paraderos)) !== false) {
  $elementos = array_map("trim", split(";", $linea));
  $patron = '/"'.$elementos[0].'" /i';
  $nuevo_texto = '"'.$elementos[1].'" '.$elementos[2].' '.$elementos[3].($hora==''?'':" $hora").' ';

  $contenido_tree = preg_replace($patron, $nuevo_texto, $contenido_tree);
}

fclose($archivo_nombre_paraderos);

fwrite($archivo_tree, $contenido_tree);
fclose($archivo_tree);
?>
