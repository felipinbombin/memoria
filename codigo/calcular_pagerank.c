#include <igraph.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define true 1
#define false 0

int main(int argc, char *argv[])
{
  /* 
   * Se lee archivo pajek.
   * Desde aquí se obtiene la cantidad de nodos, 
   * sus ids y los arcos entre ellos con su respectivo peso.
   */
  igraph_integer_t num_nodos;
  igraph_vector_t arcos;

  FILE* archivo_pajek;
  
  archivo_pajek= fopen(argv[1], "rt");
  /* "rt" significa abrir un archivo para leer texto */

  int n_linea = 0;
  int n_nodos = 0;
  int n_arcos = 0;
  int fila_es_nodo = true;

  // ids de nodos
  int nodo, nodo1, nodo2;
  float peso;

  char linea[80];

  while(fgets(linea, 80, archivo_pajek) != NULL)
  {
    // la primera linea contiene la cantidad de nodos.
    if (n_linea == 0) 
    {
      sscanf (linea, "%*[^0-9]%d", &n_nodos);
      printf("nodos: %d\n", n_nodos);
    // llegamos al encabezado de los arcos
    } 
    else if (n_linea == 1 + n_nodos) 
    {
      sscanf (linea, "%*[^0-9]%d", &n_arcos);
      fila_es_nodo = false;
      printf("arcos: %d\n", n_arcos);
    } 
    else 
    {
      if (fila_es_nodo) 
      {
        sscanf (linea, "%d ", &nodo);
        printf("nodo: %d\n", nodo);
      } 
      else 
      {
        sscanf (linea, "%d %d %f", &nodo1, &nodo2, &peso);
        printf("arco (%d,%d)=%f\n", nodo1, nodo2, peso);
      }
    }

    // vamos a la siguiente línea del archivo
    n_linea++;
  }

  fclose(archivo_pajek);
  return 0;

  /*
   * Creación de grafo en igraph
   */
/*
  igraph_t grafo;



  // se crea un grado vacío
  igraph_empty(&grafo, num_nodos, IGRAPH_DIRECTED);

  // se crea un vector de arcos.
  igraph_add_edges(&grafo, &arcos);

  // se destruye el grafo
  igraph_destroy(&grafo);
  return 0;

  // tipo de dato entero para igraph
  igraph_integer_t diameter;
  // tipo de dato real para igraph
  igraph_real_t a;
  // vector de arcos
  igraph_vector_t dimension;
  igraph_vector_t arcos;

  // crea los vectores
  igraph_vector_init(&dimension, 2);
  igraph_vector_init(&arcos, 10000);

  VECTOR(dimension)[0]=30;
  VECTOR(dimension)[1]=30;

  igraph_vector_size(&arcos);
  igraph_add_edges();

  // configura la semilla usada para la generación de números aleatorios
  igraph_rng_seed(igraph_rng_default(), 42);


  // crea un grafo
  igraph_erdos_renyi_game(&graph, IGRAPH_ERDOS_RENYI_GNP, 1000, 5.0/1000, IGRAPH_UNDIRECTED, IGRAPH_NO_LOOPS);
  igraph_diameter(&graph, &diameter, 0, 0, 0, IGRAPH_UNDIRECTED, 1);

  printf("Diameter of a random graph with average degree 5: %d\n", (int) diameter);

  igraph_vector_destroy(&arcos);
  igraph_vector_destroy(&dimension);
  // destruye un grafo (liberando memoria)
  igraph_destroy(&graph);
  return 0;
  */
}
