Este módulo asigna una comunidad a una zona (eod2012) de la siguiente forma:

1- Por cada zona:
  a- Se obtiene el subgrafo presente en ella (grafo donde todos los nodos están dentro de la zona mas los arcos que los unen).
  b- Se calcula el pagerank de cada nodo del subgrafo.
  c- La comunidad asociada al nodo con mayor pagerank es la comunidad de la zona.
