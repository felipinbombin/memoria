<?php
// calcula el valor de la centralidad de intermediación para cada paradero con los datos provistos por el archivo de entrada.

if ($argc !== 3) {
  echo "Uso: calcular_centralidad_de_intermediacion <CSV_VIAJES> <RUTA_SALIDA>".PHP_EOL;
  exit(1);
}

$viajes_csv       = $argv[1]; // ruta del csv de los viajes.
$ruta_salida      = $argv[2]; // ruta donde irá el archivo de salida.
$nombre_viajes_csv = array_shift(explode('.', array_pop(explode('/', $viajes_csv)))).'.csv';

if (!is_readable($viajes_csv)) {
  echo "El archivo $viajes_csv no existe o no se puede leer".PHP_EOL;
  exit(1);
}

$archivo_viajes  = fopen($viajes_csv, 'r');
$archivo_salida  = fopen($ruta_salida . $nombre_viajes_csv, 'w');

if ($archivo_salida === false) {
  echo "No se pudo crear archivo $ruta_salida/$nombre_viajes_csv".PHP.EOL;
  exit(1);
}

// Matriz origen-destino con todos los viajes por cada origen-destino
$orig_dest = Array();

// cargar matriz origen-destino
while (($linea = fgets($archivo_viajes)) !== false) {
  $linea = preg_replace('/;;+/i', ';', $linea); 
  $viaje = explode(';', $linea);

  $orig_dest[$viaje[0]][$viaje[count($viaje)-2]][] = $viaje;
}

fclose($archivo_viajes);

$resultado = Array();

$par_ij = 0;

// recorremos la matriz
foreach($orig_dest as $origen_id => $destinos) {
  foreach($destinos as $destino_id => $viajes) {
    // $viajes tiene todos los viajes que van desde 'origen_id' a 'destino_id'

    $num_viajes = count($viajes);

    foreach($viajes as $viaje) {
      for($i=1;$i<(count($viaje)-2);$i++) {
        $resultado[$viaje[$i]][$par_ij] = isset($resultado[$viaje[$i]][$par_ij])?floatval($resultado[$viaje[$i]][$par_ij]+$viaje[count($viaje)-1]/$num_viajes):floatval($viaje[count($viaje)-1]/$num_viajes);
      }
    }
  }
  $par_ij++;
}

$resultado_map = Array();

// sumar cada arreglo  con el indicador de cada para origen-destino
foreach($resultado as $paradero_id => $indicadores) {
  $resultado_map[$paradero_id] = array_sum($indicadores);
}

// se construye archivo salida
fwrite($archivo_salida, "paradero_id cdi" . PHP_EOL);
foreach($resultado_map as $paradero_id => $centralidad_de_intermediacion) {
  fwrite($archivo_salida, "\"$paradero_id\" $centralidad_de_intermediacion" . PHP_EOL);
}

fclose($archivo_salida);
?>
