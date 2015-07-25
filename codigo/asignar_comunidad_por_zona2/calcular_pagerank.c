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
  for (tok = strtok(linea, ";"); 
      tok && *tok; 
      tok = strtok(NULL, ";\n")) { 
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
  // Matriz de comunidades. Una fila contiene todos los nodos presentes en una comunidad.
  igraph_matrix_t matriz;
  // las filas corresponden a la cantidad de comunidades presentes en el archivo par_nodos_zona.csv
  long int filas = 41; 
  // las columnas corresponde a la cantidad máxima de nodos que hay en una comunidad.
  long int columnas = 1926;
  // vector con las columnas usadas por cada comunidad (las zonas tienen cantidad de nodos variable)
  igraph_vector_t columnas_ocupadas;

  // Vector con los nodos de zona.
  igraph_vector_t nodos_de_zona;
  // Vector con el pagerank de cada nodo del subgrafo.
  igraph_vector_t resultado_pagerank;
  // parametro de entrada para el cálculo del pagerank.
  igraph_real_t valor;

  // Para iterar 
  long int i;
  long int j;
  char linea[1024];
  int zona;
  int nodo_id;
  int comunidad_id;
  char* linea_para_nodo_id;
  char* linea_para_zona;
  char* linea_para_comunidad;

  // Vector con los pesos de cada arco
  igraph_vector_t pesos;
  // Archivo pajek de la red completa. Lo importante es que contiene el grafo completo de la red.
  FILE *archivo_pajek;
  FILE *archivo_zonas;

  igraph_vector_t gtypes, vtypes, etypes;
  igraph_strvector_t gnames, vnames, enames;
  
  long indice_max_pagerank_local;

  /****************************************************************
   * Inicialización de variables                                  *
   ****************************************************************/
  valor = 1;
  // incialmente todas las comunidades tienen 0 nodos dentro de ella.
  igraph_vector_init(&columnas_ocupadas, filas);
  igraph_vector_fill(&columnas_ocupadas, 0);

  igraph_matrix_init(&matriz, filas, columnas);

  // Handler para manipular características del grafo
  igraph_i_set_attribute_table(&igraph_cattribute_table);

  // Se abren los archivos, "rt" significa abrir un archivo para leer texto.
  archivo_pajek= fopen(argv[1], "rt");
  archivo_zonas= fopen(argv[2], "rt");// nodo_id comienza desde cero.
  
  if(archivo_pajek == NULL) 
  {
    perror("Error al abrir archivo pajek.");
    return(-1);
  }

  if(archivo_zonas == NULL) 
  {
    perror("Error al abrir archivo de zonas.");
    return(-1);
  }

  // Generar grafo a partir de archivo pajek.
  if(igraph_read_graph_pajek(&grafo, archivo_pajek) != 0) {
    printf("ERROR: no se pudo cargar el archivo.");
    return 1;
  }

  // Llenado de la matriz.
  while (fgets(linea, 1024, archivo_zonas))
  {
    linea_para_nodo_id   = strdup(linea);
    linea_para_zona      = strdup(linea);
    linea_para_comunidad = strdup(linea);
    // Identificador de nodo.
    nodo_id = atoi(obtener_campo(linea_para_nodo_id, 1));
    // Zona en la que se encuentra el nodo.
    zona = atoi(obtener_campo(linea_para_zona, 2));
    // comunidad asociada al nodo
    comunidad_id = atoi(obtener_campo(linea_para_comunidad, 3));

    // se resta uno porque los vectores y matrices indexan desde 0.
    comunidad_id--;

    // Se inserta el nodo en la comunidad (fila) correspondiente.
    igraph_matrix_set(&matriz, comunidad_id, VECTOR(columnas_ocupadas)[comunidad_id], nodo_id);
    // Marcar columna ocupada para esa zona.
    VECTOR(columnas_ocupadas)[comunidad_id] = VECTOR(columnas_ocupadas)[comunidad_id] + 1;
    // se agrega el atributo "comunidad_id a cada vertice del grafo". 
    comunidad_id++; 
    SETVAN(&grafo, "comunidad_id", nodo_id, comunidad_id);
    // se agrega el atributo "zona_id a cada vertice del grafo". 
    SETVAN(&grafo, "zona_id", nodo_id, zona);
    // el nodo_id del grafo original
    SETVAN(&grafo, "nodo_id_grafo_original", nodo_id, nodo_id);

    free(linea_para_nodo_id);
    free(linea_para_zona);
    free(linea_para_comunidad);
  }

  // Se cierran los archivos.
  fclose(archivo_pajek);
  fclose(archivo_zonas);

  /****************************************************************
   * Procedimiento                                                *
   ****************************************************************/
  fprintf(stderr, "La matriz y el grafo han sido formados exitosamente.\n");

  // Se imprime csv (nodo_id, comunidad_id, zona_id, pagerank)
  fprintf(stdout, "nodo_id comunidad_id zona_id pagerank_por_comunidad\n");

  // por cada comunidad
  for (i=0; i<filas; i++) {

    igraph_vector_init(&resultado_pagerank, 0);
    igraph_vector_init(&nodos_de_zona, 0);
    igraph_vector_init(&pesos, 0);

    // Obtener subgrafo
    igraph_matrix_get_row(&matriz, &nodos_de_zona, i);
    igraph_vector_resize(&nodos_de_zona, VECTOR(columnas_ocupadas)[i]); 
    igraph_induced_subgraph(&grafo, &subgrafo, igraph_vss_vector(&nodos_de_zona), IGRAPH_SUBGRAPH_AUTO);

    // Obtener vector de atributos
    igraph_vector_init(&gtypes, 0);
    igraph_vector_init(&vtypes, 0);
    igraph_vector_init(&etypes, 0);
    igraph_strvector_init(&gnames, 0);
    igraph_strvector_init(&vnames, 0);
    igraph_strvector_init(&enames, 0);

    igraph_cattribute_list(&subgrafo, &gnames, &gtypes, &vnames, &vtypes, &enames, &etypes);

    for (j=0; j<igraph_ecount(&subgrafo); j++) {
      igraph_vector_insert(&pesos, j, EAN(&subgrafo, "weight", j));
    }

    // Calcular PageRank
    if(igraph_pagerank(&subgrafo, IGRAPH_PAGERANK_ALGO_PRPACK, 
          &resultado_pagerank, &valor, igraph_vss_all(), igraph_is_directed(&subgrafo), 0.85, &pesos, NULL) != 0) 
    {
      printf("ERROR: no se pudo calcular el pagerank.");
      return(-1);
    }

    for (j=0; j<igraph_vcount(&subgrafo); j++) {      
      igraph_real_fprintf(stdout, VAN(&subgrafo, "nodo_id_grafo_original", j)); 
      fprintf(stdout,";");
      igraph_real_fprintf(stdout, VAN(&subgrafo, "comunidad_id", j));
      fprintf(stdout,";");
      igraph_real_fprintf(stdout, VAN(&subgrafo, "zona_id", j));
      fprintf(stdout,";");
      fprintf(stdout, "%f\n", VECTOR(resultado_pagerank)[j]);
    }

    //printf("El grafo tiene %d vertices y %d arcos\n", igraph_vcount(&grafo), igraph_ecount(&grafo));
    //printf("cantidad de pagerank: %d", igraph_vector_size(&resultado));
    //print_vector(&resultado, stdout);

    igraph_destroy(&subgrafo);

    igraph_vector_destroy(&resultado_pagerank);
    igraph_vector_destroy(&nodos_de_zona);
    igraph_vector_destroy(&pesos);

    igraph_strvector_destroy(&enames);
    igraph_strvector_destroy(&vnames);
    igraph_strvector_destroy(&gnames);
    igraph_vector_destroy(&etypes);
    igraph_vector_destroy(&vtypes);
    igraph_vector_destroy(&gtypes);
  }

  igraph_destroy(&grafo);

  return 0;
}
