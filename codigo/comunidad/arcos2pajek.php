<?php
// crea un archivo de texto con formato pajek a partir de un csv.

if ($argc !== 3) {
  echo "Error: Debe ingresar la ruta (absoluta o relativa) del archivo CSV y la ruta de salida.".PHP_EOL;
  exit(1);
}

$ruta_csv     = $argv[1]; // ruta del csv requerido para crear el archivo pajek.
$ruta_pajek   = $argv[2]; // ruta donde se almacenará el archivo de salida.
$nombre_pajek = array_shift(explode('.', array_pop(explode('/', $ruta_csv)))).'.net';

// indica si el archivo existe y si es posible leerlo
if (!is_readable($ruta_csv)) {
  echo "El archivo no existe o no se puede leer".PHP_EOL;
  exit(1);
}

$archivo_csv   = fopen($ruta_csv, 'r');
$archivo_pajek = fopen($ruta_pajek . $nombre_pajek, 'w');

if ($archivo_pajek === false) {
  echo "No se pudo crear archivo $nombre_pajek".PHP.EOL;
  exit(1);
}

// paraderos encontrados
$paraderos = Array();

$total_arcos = 0;

// cadena de texto
$arcos    = '';
$vertices = '';

// se lee linea por linea
while (($linea = fgets($archivo_csv)) !== false) {

  $elementos = array_map("trim", split(";", $linea));

  // si no está en el arreglo => se agrega y se obtiene el indice
  if (($indice_par_subida = array_search($elementos[0], $paraderos)) === false) {
    $paraderos[] = $elementos[0];
    // se resta uno porque los índices comienzan desde cero
    $indice_par_subida = count($paraderos);
    
    $vertices .= $indice_par_subida . ' "' . $elementos[0] . '"'. PHP_EOL;
  } else {
    $indice_par_subida++;
  }

  if (($indice_par_bajada = array_search($elementos[1], $paraderos)) === false) {
    $paraderos[] = $elementos[1];
    // se resta uno porque los índices comienzan desde cero
    $indice_par_bajada = count($paraderos);
    
    $vertices .= $indice_par_bajada . ' "' . $elementos[1] . '"'. PHP_EOL;
  } else {
    $indice_par_bajada++;
  }
  
  $arcos .= $indice_par_subida . ' ' . $indice_par_bajada . ' ' . $elementos[2] . PHP_EOL;
  $total_arcos++;
}

fclose($archivo_csv);

$total_nodos = count($paraderos);

// se construye archivo pajek
fwrite($archivo_pajek, "*Vertices " . $total_nodos . PHP_EOL);
fwrite($archivo_pajek, $vertices);
fwrite($archivo_pajek, "*Arcs " . $total_arcos . PHP_EOL);
fwrite($archivo_pajek, $arcos);

fclose($archivo_pajek);
?>
