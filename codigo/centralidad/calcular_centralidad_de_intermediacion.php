<?php
/*
 * Calcula el valor de la centralidad de intermediación para cada paradero con los datos provistos por el archivo de entrada.
 * El símil con el betweenness centrality es el siguiente:
 *  1 - Los viajes más cortos para nosotros son los viajes hechos por la gente (todas las configuraciones registradas).
 *  2 - El cálculo del indicador para un nodo k es la cantidad de veces que aparece éste en los viajes.
 */

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

// cargar matriz origen-destino. Cada elemento ij contiene un arreglo con todos los viajes realizados
// con la respectiva cantidad de gente que lo hizo (factor de expansión)
while (($linea = fgets($archivo_viajes)) !== false) {
  // se quitan etapas no ocupadas en el viaje (puede tener 1, 2, 3 o 4).
  $linea = preg_replace('/;;+/i', ';', $linea); 
  // el viaje se divide entre todos sus paraderos de subida y bajada más el factor de expansión formando un arreglo.
  $viaje = explode(';', $linea);

  // $viaje[0] = 'paradero de subida inicial del viaje'
  // count($viaje)-2 = 'paradero de bajada final del viaje, se resta 2 porque los arreglos indexan desde 0 y 
  //                    porque el último elemento es la cantidad de gente que realizó el viaje.'
  $orig_dest[$viaje[0]][$viaje[count($viaje)-2]][] = $viaje;
}

fclose($archivo_viajes);

$resultado = Array();

$par_ij = 0;

// recorremos la matriz
foreach($orig_dest as $origen_id => $destinos) {
  foreach($destinos as $destino_id => $viajes) {
    // $viajes tiene todos los viajes que van desde 'origen_id' a 'destino_id', distintos.

    $num_viajes = count($viajes);

    // Variante considerando el factor de expansión.
    /*
    $num_viajes = 0;
    foreach($viajes as $viaje) {
      $num_viajes = $num_viajes + $viaje[count($viaje)-1];
    }
    */
    foreach($viajes as $viaje) {

      //$volumen = $viaje[count($viaje)-1]; // Variante considerando el factor de expansión
      $volumen = 1;

      $fraccion = $num_viajes==0?0:$volumen/$num_viajes;

      // Recorremos cada paradero intermedio entre el origen y destino
      for($i=1;$i<(count($viaje)-2);$i++) {
        if (isset($resultado[$viaje[$i]][$par_ij])) {
          $resultado[$viaje[$i]][$par_ij] = floatval($resultado[$viaje[$i]][$par_ij] + $fraccion);
        } else {
          $resultado[$viaje[$i]][$par_ij] = floatval($fraccion);
        }
      }
    }
  }
  $par_ij++;
}

$resultado_map = Array();

// sumar cada arreglo  con el indicador de cada par origen-destino
foreach($resultado as $paradero_id => $indicadores) {
  $resultado_map[$paradero_id] = array_sum($indicadores);
}

// se construye archivo salida
fwrite($archivo_salida, "paradero_id,cdi" . PHP_EOL);
foreach($resultado_map as $paradero_id => $centralidad_de_intermediacion) {
  fwrite($archivo_salida, "\"$paradero_id\",$centralidad_de_intermediacion" . PHP_EOL);
}

fclose($archivo_salida);
?>
