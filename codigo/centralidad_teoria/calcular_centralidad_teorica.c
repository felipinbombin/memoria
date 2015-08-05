#include <stdio.h>
#include <igraph.h>

void print_vector(igraph_vector_t *v, FILE *f) {
  long int i;
  for(i=0; i < igraph_vector_size(v); i++) {
    // se imprime solo valores negativos
    if (VECTOR(*v)[i] <= 0)
      fprintf(f, "valor: %f | indice: %d", VECTOR(*v)[i], i);
  }
  fprintf(f, "\n");
}

int main(int argc, char *argv[])
{
  igraph_t grafo;
  // Vector con el betweeness centrality de cada nodo
  igraph_vector_t resultado;
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
  igraph_strvector_t vnames, enames;
  
  igraph_strvector_init(&vnames, 0);
  igraph_strvector_init(&enames, 0);

  igraph_cattribute_list(&grafo, 0, 0, &vnames, 0, &enames, 0);

  igraph_vector_init(&pesos, 0);

  // se crea el vector de pesos
  for (i=0; i<igraph_ecount(&grafo); i++) {
     igraph_vector_insert(&pesos, i, EAN(&grafo, STR(enames, 0), i));
  }
  
  // obtener peso máximo
  igraph_real_t max_peso = igraph_vector_max(&pesos);

  // vector con pesos contrarrestados para que aquellos pesos más altos sean los más bajos y
  // viceversa dado que el algoritmo betweeness centrality considera el peso como una medida
  // negativa.
  igraph_vector_t peso_complemento;
  igraph_vector_init(&peso_complemento, igraph_vector_size(&pesos));
  // se suma 1 porque el 0.00 queda como -0.00 y se lanza error por peso negativo
  igraph_vector_fill(&peso_complemento, max_peso+1);
  // restar elemento a elemento
  igraph_vector_sub(&pesos, &peso_complemento);
  // para que los valores queden positivo
  igraph_vector_scale(&pesos, -1);

  //fprintf(stderr, "El indice con peso máximo (%f) es %d\n", max_peso, igraph_vector_which_max(&pesos));
  //print_vector(&pesos, stderr);

  igraph_vector_init(&resultado, 0);

  if(igraph_betweenness(&grafo, &resultado, igraph_vss_all(), igraph_is_directed(&grafo), &pesos, 1) != 0) {
    printf("ERROR: no se pudo calcular el betweeness centrality.");
    return 1;
  }

  //printf("El grafo tiene %d vertices y %d arcos\n", igraph_vcount(&grafo), igraph_ecount(&grafo));
  //printf("cantidad de elementos en vector de resultados: %d", igraph_vector_size(&resultado));
  //print_vector(&resultado, stdout);
  
  // Se imprime csv (id_paradero, CdI)
  printf("paradero_id,CdI\n");
  for (i=0; i<igraph_vcount(&grafo); i++) {
    printf("\"%s\",%f\n", VAS(&grafo, STR(vnames,0), i), VECTOR(resultado)[i]);
  }

  // da lo mismo porque se termina el script 
  
  igraph_strvector_destroy(&enames);
  igraph_strvector_destroy(&vnames);

  igraph_destroy(&grafo);

  return 0;
}
