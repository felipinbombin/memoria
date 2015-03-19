<?php

if ($argc !== 3) {
  echo "USO: php poner_nombre_paradero.php <ruta archivo pajek> <ruta archivo nombre paraderos>".PHP_EOL;
  exit(1);
}

$ruta_pajek            = $argv[1]; // ruta al archivo a ser leído (incluye el nombre de éste).
$ruta_nombre_paraderos = $argv[2]; // archivo csv con dos columnas "código_paradero nombre"
$nombre_pajek          = $argv[3]; // nombre del archivo de salida

// indica si el archivo existe y si es posible leerlo
if (!is_readable($ruta_nombre_paraderos)) {
  echo "El archivo '$ruta_nombre_paraderos' no existe o no se puede leer".PHP_EOL;
  exit(1);
}

// indica si el archivo existe y si es posible leerlo
if (!is_readable($ruta_pajek_con_datos)) {
  echo "El archivo '$ruta_pajek_con_datos' no existe o no se puede leer".PHP_EOL;
  exit(1);
}

$contenido_pajek_con_datos = file_get_contents($ruta_pajek_con_datos, FILE_USE_INCLUDE_PATH);

$archivo_nombre_paraderos = fopen($ruta_nombre_paraderos, 'r');
$archivo_pajek = fopen($ruta_pajek, 'w');

if ($archivo_nombre_paraderos === false) {
  echo "No se pudo crear archivo $archivo_nombre_paraderos".PHP.EOL;
  exit(1);
}

if ($archivo_pajek === false) {
  echo "No se pudo crear archivo $ruta_pajek/$nombre_pajek".PHP.EOL;
  exit(1);
}

// se lee linea por linea
while (($linea = fgets($archivo_nombre_paraderos)) !== false) {
  $elementos = array_map("trim", split(";", $linea));

  $contenido_pajek_con_datos = str_replace($elementos[0], $elementos[3], $contenido_pajek_con_datos);
}

fclose($archivo_nombre_paraderos);

fwrite($archivo_pajek, $contenido_pajek_con_datos);
fclose($archivo_pajek);
?>
