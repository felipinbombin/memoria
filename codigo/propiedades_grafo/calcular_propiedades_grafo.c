#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
#include <igraph.h>

void print_vector(igraph_vector_t *v, FILE *f) {
  long int i;
  for(i=0; i < igraph_vector_size(v); i++) {
    fprintf(f, " %f", VECTOR(*v)[i]);
  }
  fprintf(f, "\n");
}

int main(int argc, char *argv[])
{
  igraph_t grafo;
  // Vector con el pagerank de cada nodo
  igraph_vector_t resultado_degree;
  igraph_vector_t resultado_strength;
  igraph_real_t valor = 1;
  // Iterador
  long int i;
  // Vector con los pesos de cada arco
  igraph_vector_t pesos;
  // Archivo pajek
  FILE *archivo_pajek;
  
  // handler para manipular características del archivo pajek
  igraph_i_set_attribute_table(&igraph_cattribute_table);
  
  archivo_pajek= fopen(argv[1], "rt");
  /* "rt" significa abrir un archivo para leer texto */

  if(igraph_read_graph_pajek(&grafo, archivo_pajek) != 0) {
    printf("ERROR: no se pudo cargar el archivo.");
    return 1;
  }

  fclose(archivo_pajek);

  // ************************************************
  igraph_vector_t gtypes, vtypes, etypes;
  igraph_strvector_t gnames, vnames, enames;
  
  igraph_vector_init(&gtypes, 0);
  igraph_vector_init(&vtypes, 0);
  igraph_vector_init(&etypes, 0);

  igraph_strvector_init(&gnames, 0);
  igraph_strvector_init(&vnames, 0);
  igraph_strvector_init(&enames, 0);

  igraph_cattribute_list(&grafo, &gnames, &gtypes, &vnames, &vtypes, &enames, &etypes);

  igraph_vector_init(&pesos, 0);

  // se crea el vector de pesos
  for (i=0; i<igraph_ecount(&grafo); i++) {
     //printf("%s=", STR(enames, 0));
     //igraph_real_printf(EAN(&grafo, STR(enames, 0), i));
     //putchar('\n');
     // se agregan los pesos al vector
     igraph_vector_insert(&pesos, i, EAN(&grafo, STR(enames, 0), i));
  }

  igraph_vector_init(&resultado_degree, 0);
  igraph_vector_init(&resultado_strength, 0);

  // IGRAPH_ALL: cuenta los arcos de entrada como de salida
  if(igraph_degree(&grafo, &resultado_degree, igraph_vss_all(), IGRAPH_ALL, 0) != 0) {
    printf("ERROR: no se pudo calcular el strength");
    return 1;
  }

  // IGRAPH_ALL: la suma de todos los pesos de sus arcos incidentes (los arcos que llegan o salen del nodo)
  if(igraph_strength(&grafo, &resultado_strength, igraph_vss_all(), IGRAPH_ALL, 0, &pesos) != 0) {
    printf("ERROR: no se pudo calcular el strength");
    return 1;
  }

  //printf("El grafo tiene %d vertices y %d arcos\n", igraph_vcount(&grafo), igraph_ecount(&grafo));
  //printf("cantidad de pagerank: %d", igraph_vector_size(&resultado));
  //print_vector(&resultado, stdout);
  
  // Se imprime csv (id_paradero, pagerank)
  printf("paradero_id degree strength\n");
  for (i=0; i<igraph_vcount(&grafo); i++) {
    printf("\"%s\" %f %f\n", VAS(&grafo, STR(vnames,0), i), VECTOR(resultado_degree)[i], VECTOR(resultado_strength)[i]);
  }

  igraph_strvector_destroy(&enames);
  igraph_strvector_destroy(&vnames);
  igraph_strvector_destroy(&gnames);

  igraph_vector_destroy(&etypes);
  igraph_vector_destroy(&vtypes);
  igraph_vector_destroy(&gtypes);

  igraph_destroy(&grafo);

  return 0;
}
