<?php
// calcula el valor de la centralidad de intermediación para cada paradero con los datos provistos por el archivo de entrada.

if ($argc !== 4) {
  echo "Uso: calcular_centralidad_de_intermediacion <CSV_PARADAS> <CSV_VIAJES> <RUTA_SALIDA>".PHP_EOL;
  exit(1);
}

$paradas_csv      = $argv[1]; // ruta del csv de paradas.
$viajes_csv       = $argv[2]; // ruta del csv de los viajes.
$ruta_salida      = $argv[3]; // ruta donde irá el archivo de salida.
$nombre_viajes_csv = array_shift(explode('.', array_pop(explode('/', $viajes_csv)))).'.csv';

// indica si el archivo existe y si es posible leerlo
if (!is_readable($paradas_csv)) {
  echo "El archivo $paradas_csv no existe o no se puede leer".PHP_EOL;
  exit(1);
}

if (!is_readable($viajes_csv)) {
  echo "El archivo $viajes_csv no existe o no se puede leer".PHP_EOL;
  exit(1);
}

$contenido_viajes = file_get_contents($viajes_csv);
$archivo_paradas  = fopen($paradas_csv, 'r');
$archivo_salida   = fopen($ruta_salida . $nombre_viajes_csv, 'w');

if ($archivo_salida === false) {
  echo "No se pudo crear archivo $ruta_salida/$nombre_viajes_csv".PHP.EOL;
  exit(1);
}

$contenido_salida = Array();
$viajes_total = 0;
$cantidad_paraderos = 0;

// iterar sobre los paraderos
while (($linea = fgets($archivo_paradas)) !== false) {
  $linea = explode(';', $linea);
  $paradero_id = $linea[0];

  $cantidad_paraderos++;

  // se escapan carácteres especiales
  $paradero_id = preg_quote($paradero_id, '/');

  $patron= "/.*$paradero_id.*/m";
   
  $contar = 0;
  $viajes = 0;

  // buscar y almacenar todas las ocurrencias en $resultado
  if(preg_match_all($patron, $contenido_viajes, $resultado)) {
    // recorremos la lista de resultados(= viajes que tienen paradero_id dentro de su ruta)
    foreach ($resultado[0] as $viaje) {
      //quitar campos vacios
      $viaje = preg_replace('/;;+/i', ';', $viaje); 
      $viaje = explode(';', $viaje);
      
      $viajes_total += $viaje[count($viaje)-1];
      $viajes += $viaje[count($viaje)-1];
      
      // si el paradero no es de llegada o subida
      if (!($viaje[0] == $paradero_id || $viaje[count($viaje)-2] == $paradero_id)) {
        $contar += $viaje[count($viaje)-1];
      }
    }
    
    $contenido_salida[] = Array($paradero_id, $contar/$viajes);
  }
}

fclose($archivo_paradas);

// se construye archivo salida
fwrite($archivo_salida, "paradero_id cdi" . PHP_EOL);
foreach($contenido_salida as $fila) {
  $fila[1] = $fila[1]/$cantidad_paraderos; 
  fwrite($archivo_salida, implode(' ', $fila) . PHP_EOL);
}

fclose($archivo_salida);
?>
