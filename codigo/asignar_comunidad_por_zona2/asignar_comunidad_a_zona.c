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
  // grafo presente en una zona
  igraph_t subgrafo;
  // Matriz de zonas. 
  igraph_matrix_t matriz;
  // las filas corresponden a la cantidad de zonas presentes en el archivo par_nodos_zona_comunidad.csv
  long int filas = 866; 
  // las columnas corresponde a la cantidad máxima de nodos que hay en una zona.
  long int columnas = 107;
  // vector con las columnas (nodos) usadas por cada zona (las zonas tienen cantidad de nodos variable)
  igraph_vector_t columnas_ocupadas;

  // Vector con los nodos de zona.
  igraph_vector_t nodos_de_zona;
  // Vector con el pagerank de cada nodo del subgrafo.
  igraph_vector_t resultado_pagerank;

  // Para iterar 
  long int i;
  long int j;
  char linea[1024];
  int zona;
  int nodo_id;
  int comunidad_id;
  float pagerank;
  char* linea_para_nodo_id;
  char* linea_para_zona;
  char* linea_para_comunidad;
  char* linea_para_pagerank;

  // Archivo pajek de la red completa. Lo importante es que contiene el grafo completo de la red.
  FILE *archivo_pajek;
  FILE *archivo_zonas;

  igraph_vector_t vtypes;
  igraph_strvector_t vnames;
  
  long indice_max_pagerank_local;

  /****************************************************************
   * Inicialización de variables                                  *
   ****************************************************************/
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
    return 1;
  }

  // Generar grafo a partir de archivo pajek.
  if(igraph_read_graph_pajek(&grafo, archivo_pajek) != 0) {
    perror("ERROR: no se pudo cargar el archivo.");
    return 1;
  }

  // se ignora la primera línea
  fgets(linea, 1024, archivo_zonas);

  // Llenado de la matriz.
  while (fgets(linea, 1024, archivo_zonas))
  {

    linea_para_nodo_id   = strdup(linea);
    linea_para_zona      = strdup(linea);
    linea_para_comunidad = strdup(linea);
    linea_para_pagerank  = strdup(linea);

    // Identificador de nodo.
    nodo_id = atoi(obtener_campo(linea_para_nodo_id, 1));
    // comunidad asociada al nodo
    comunidad_id = atoi(obtener_campo(linea_para_comunidad, 2));
    // Zona en la que se encuentra el nodo.
    zona = atoi(obtener_campo(linea_para_zona, 3));
    pagerank = atof(obtener_campo(linea_para_pagerank, 4));

    // se resta uno porque los vectores y matrices indexan desde 0.
    zona--;

    // Se inserta el nodo en la zona (fila) correspondiente.
    igraph_matrix_set(&matriz, zona, VECTOR(columnas_ocupadas)[zona], nodo_id);
    // Marcar columna ocupada para esa zona.
    VECTOR(columnas_ocupadas)[zona] = VECTOR(columnas_ocupadas)[zona] + 1;
    // se agrega el atributo "comunidad_id a cada vertice del grafo". 
    zona++; 
    SETVAN(&grafo, "comunidad_id", nodo_id, comunidad_id);
    // se agrega el atributo "zona_id a cada vertice del grafo". 
    SETVAN(&grafo, "zona_id", nodo_id, zona);
    // el nodo_id del grafo original
    SETVAN(&grafo, "nodo_id_grafo_original", nodo_id, nodo_id);
    SETVAN(&grafo, "pagerank", nodo_id, pagerank);

    free(linea_para_nodo_id);
    free(linea_para_zona);
    free(linea_para_comunidad);
    free(linea_para_pagerank);
  }

  // Se cierran los archivos.
  fclose(archivo_pajek);
  fclose(archivo_zonas);

  /****************************************************************
   * Procedimiento                                                *
   ****************************************************************/
  fprintf(stderr, "La matriz y el grafo han sido formados exitosamente.\n");

  // por cada zona
  for (i=0; i<filas; i++) {

    igraph_vector_init(&resultado_pagerank, 0);
    igraph_vector_init(&nodos_de_zona, 0);

    // Obtener subgrafo
    igraph_matrix_get_row(&matriz, &nodos_de_zona, i);
    igraph_vector_resize(&nodos_de_zona, VECTOR(columnas_ocupadas)[i]); 
    igraph_induced_subgraph(&grafo, &subgrafo, igraph_vss_vector(&nodos_de_zona), IGRAPH_SUBGRAPH_AUTO);

    // Obtener vector de atributos
    igraph_vector_init(&vtypes, 0);
    igraph_strvector_init(&vnames, 0);

    igraph_cattribute_list(&subgrafo, 0, 0, &vnames, &vtypes, 0, 0);

    // obtener el atributo pagerank de todos los nodos del subgrafo
    VANV(&subgrafo, "pagerank", &resultado_pagerank);
    indice_max_pagerank_local = igraph_vector_which_max(&resultado_pagerank);

    fprintf(stdout, "UPDATE eod2012 SET comunidad_id2 = ");
    if (indice_max_pagerank_local != -1)
      igraph_real_fprintf(stdout, VAN(&subgrafo, "comunidad_id", indice_max_pagerank_local));
    else
      fprintf(stdout, " -1");
    fprintf(stdout, " WHERE zona = %d;\n", i + 1);

    igraph_destroy(&subgrafo);

    igraph_vector_destroy(&resultado_pagerank);
    igraph_vector_destroy(&nodos_de_zona);

    igraph_strvector_destroy(&vnames);
    igraph_vector_destroy(&vtypes);
  }

  igraph_destroy(&grafo);

  return 0;
}
