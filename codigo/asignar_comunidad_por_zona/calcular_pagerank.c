#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <igraph.h>

/**
 *  Imprime los datos de un vector
 * */
void print_vector(igraph_vector_t *v, FILE *f) {
  long int i;
  for(i=0; i < igraph_vector_size(v); i++) {
    fprintf(f, " %f", VECTOR(*v)[i]);
  }
  fprintf(f, "\n");
}

/**
 *  Obtiene dato de un campo en un string separado por comas.
 *  Ocupado para leer el csv que contiene los datos de los paraderos con comas.
 * */
const char* obtener_campo(char* linea, int num) {
  const char* tok;
  for (tok = strtok(linea, ","); 
      tok && *tok; 
      tok = strtok(NULL, ",\n")) { 
    if (!--num)
      return tok;
  }
  return NULL;
}

int main(int argc, char *argv[])
{
  /****************************************************************
   * Definición de variables                                      *
   ****************************************************************/

  // Grafo completo cargado desde el archivo pajek.
  igraph_t grafo;
  // subgrafo presente en una zona eod2012
  igraph_t subgrafo;
  // Matriz de zonas. Una fila contiene todos los nodos presentes en una zona.
  igraph_matrix_t matriz;
  // las filas corresponden a la cantidad de zonas presentes en la eod2012
  long int filas = 866; 
  // las columnas corresponde a la cantidad máxima de nodos que hay en una zona.
  long int columnas = 107;
  // vector con las columnas usadas por cada zona (las zonas tienen cantidad de nodos variable)
  igraph_vector_t columnas_ocupadas;

  // Vector con los nodos de zona.
  igraph_vector_t nodos_de_zona;
  // Vector con el pagerank de cada nodo del subgrafo.
  igraph_vector_t resultado_pagerank;
  // parametro de entrada para el cálculo del pagerank.
  igraph_real_t valor;

  // Para iterar 
  long int i;
  char linea[1024];
  int zona;
  int nodo_id;
  char* linea_para_nodo_id;
  char* linea_para_zona;

  // Vector con los pesos de cada arco
  igraph_vector_t pesos;
  // Archivo pajek de la red completa. Lo importante es que contiene el grafo completo de la red.
  FILE *archivo_pajek;
  // Archivo con los nodos asociados a su zona eod 2012. Ese archivo fue hecho en CartoDB.com mesclando las
  // capas de eod2012 con uno de comunidades. Es importante señalar que hubieron puntos que no están sobre una 
  // zona de la eod por lo que se consireda el siguiente criterio: zona cercana más pequeña->zona mas cercana con inclinación a actividad. 
  // Si lo anterior es ambiguo se tomó una decisión arbitraria. Los puntos son:
  // NODO_ID  ZONA_ASIGNADA
  // 420      539
  // 925      386      
  // 1514     67
  // 1338     254
  // 1671     725
  // 6        470
  // 55       470
  // 955      265
  // 552      93
  FILE *archivo_zonas;

  igraph_vector_t gtypes, vtypes, etypes;
  igraph_strvector_t gnames, vnames, enames;

  /****************************************************************
   * Inicialización de variables                                  *
   ****************************************************************/
  valor = 1;
  // incialmente todas las zonas tienen 0 nodos dentro de ella.
  igraph_vector_init(&columnas_ocupadas, filas);
  igraph_vector_fill(&columnas_ocupadas, 0);

  igraph_matrix_init(&matriz, filas, columnas);

  // Handler para manipular características del archivo pajek..
  igraph_i_set_attribute_table(&igraph_cattribute_table);

  // Se abren los archivos, "rt" significa abrir un archivo para leer texto.
  archivo_pajek= fopen(argv[1], "rt");
  archivo_zonas= fopen(argv[2], "rt");

  if(archivo_zonas == NULL) 
  {
    perror("Error al abrir archivo de zonas.");
    return(-1);
  }

  // Saltamos el encabezado.
  fgets(linea, 1024, archivo_zonas);
  // Llenado de la matriz.
  while (fgets(linea, 1024, archivo_zonas))
  {
    linea_para_nodo_id = strdup(linea);
    linea_para_zona    = strdup(linea);
    // Identificador de nodo.
    //nodo_id = atoi(obtener_campo(linea_para_nodo_id, 2));
    
    /* loop until null is found */
    //char* a = strdup(obtener_campo(linea_para_nodo_id, 2));
    //char* b = strdup(obtener_campo(linea_para_zona, 12));

    //for(i = 0; a[ i ]; i++)
    //  printf("%c", a[ i ]);
    fprintf(stderr, "%s\n", linea);
    fprintf(stderr, "%d %d\n", atoi(obtener_campo(linea_para_nodo_id, 2)), atoi(obtener_campo(linea_para_zona, 12)));
    /*
       char* a = obtener_campo(linea_para_nodo_id, 2);
       char* b = obtener_campo(linea_para_zona, 12);
       sscanf(a, "%d", &nodo_id);
       sscanf(b, "%d", &zona);
       nodo_id = 1; zona = 1;
       fprintf(stderr, "%s=%d %s=%d\n", a, nodo_id, b, zona);
       */
    // Zona en la que se encuentra el nodo.
    //zona = atoi(obtener_campo(linea_para_zona, 12));
    // Se inserta el nodo en la zona (fila) correspondiente.
    //igraph_matrix_set(&matriz, zona, VECTOR(columnas_ocupadas)[zona], nodo_id);
    // Marcar columna ocupada para esa zona.
    //igraph_vector_set (&columnas_ocupadas, zona, VECTOR(columnas_ocupadas)[zona] + 1);

    //printf("Field 3 would be %s\n", );
    // NOTE strtok clobbers tmp
    free(linea_para_nodo_id);
    free(linea_para_zona);
  }

  /*
  // Generar grafo a partir de archivo pajek.
  if(igraph_read_graph_pajek(&grafo, archivo_pajek) != 0) {
  printf("ERROR: no se pudo cargar el archivo.");
  return 1;
  }

  // Se cierran los archivos.
  fclose(archivo_pajek);
  fclose(archivo_zonas);
  */

  /****************************************************************
   * Procedimiento                                                *
   ****************************************************************/
  /*
     printf("La matriz y el grafo han sido formados exitosamente.\n");

     for (i=0; i<filas; i++) {

     igraph_vector_init(&resultado_pagerank, 0);
     igraph_vector_init(&nodos_de_zona, 0);
     igraph_vector_init(&pesos, 0);

  // Obtener subgrafo
  igraph_matrix_get_row(&matriz, &nodos_de_zona, i);
  igraph_vector_resize(&nodos_de_zona, VECTOR(columnas_ocupadas)[i]);
  igraph_subgraph(&grafo, &subgrafo, igraph_vss_vector(&nodos_de_zona));

  // Obtener vector de pesos
  igraph_vector_init(&gtypes, 0);
  igraph_vector_init(&vtypes, 0);
  igraph_vector_init(&etypes, 0);
  igraph_strvector_init(&gnames, 0);
  igraph_strvector_init(&vnames, 0);
  igraph_strvector_init(&enames, 0);

  igraph_cattribute_list(&subgrafo, &gnames, &gtypes, &vnames, &vtypes, &enames, &etypes);

  for (i=0; i<igraph_ecount(&subgrafo); i++) {
  igraph_vector_insert(&pesos, i, EAN(&subgrafo, STR(enames, 0), i));
  }

  // Calcular PageRank
  if(igraph_pagerank(&subgrafo, IGRAPH_PAGERANK_ALGO_PRPACK, 
  &resultado_pagerank, &valor, igraph_vss_all(), igraph_is_directed(&subgrafo), 0.85, &pesos, NULL) != 0) 
  {
  printf("ERROR: no se pudo calcular el pagerank.");
  return 1;
  }

  // Se imprime csv (id_paradero, pagerank)
  printf("paradero_id pagerank\n");
  for (i=0; i<igraph_vcount(&subgrafo); i++) {
  printf("\"%s\" %f\n", VAS(&subgrafo, STR(vnames,0), i), VECTOR(resultado_pagerank)[i]);
  }

  //printf("El grafo tiene %d vertices y %d arcos\n", igraph_vcount(&grafo), igraph_ecount(&grafo));
  //printf("cantidad de pagerank: %d", igraph_vector_size(&resultado));
  //print_vector(&resultado, stdout);

  igraph_destroy(&subgrafo);

  igraph_vector_destroy(&resultado_pagerank);
  igraph_vector_destroy(&nodos_de_zona);

  igraph_strvector_destroy(&enames);
  igraph_strvector_destroy(&vnames);
  igraph_strvector_destroy(&gnames);
  igraph_vector_destroy(&etypes);
  igraph_vector_destroy(&vtypes);
  igraph_vector_destroy(&gtypes);
  }

  igraph_destroy(&grafo);
  */
  return 0;
}
