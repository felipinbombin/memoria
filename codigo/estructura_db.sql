\timing on

-- crear tabla etapas
CREATE TABLE etapas (
  tiempo_subida timestamp without time zone,
  id bigint,
  pago smallint,
  x_subida double precision,
  y_subida double precision,
  tipo_transporte character varying(20),
  serviciosentidovariante character varying(500),
  tipo_dia character varying(10),
  nviaje integer,
  netapa integer,
  x_bajada double precision,
  y_bajada double precision,
  tiempo_bajada timestamp without time zone,
  par_subida character varying(30),
  par_bajada character varying(30),
  comuna_subida character varying(20),
  comuna_bajada character varying(20),
  zona_subida character varying(10),
  zona_bajada character varying(10),
  distonroutesubidabajada integer,
  disteuclidsubidabajada integer,
  distonrouteparsubidaparbajada integer,
  disteuclidparsubidaparbajada integer,
  serv_un_zp2 character varying(500),
  sitio2 character varying(50),
  tiempo2 timestamp without time zone,
  media_hora time without time zone,
  tiempo_trasbordo double precision,
  dist_trasbordo double precision,
  tiempo_caminata double precision,
  tiempo_espera double precision,
  tiempo_etapa double precision,
  tiempo_espera_estimado double precision,
  adulto integer,
  factor_exp_etapa double precision,
  nbusesanteriores integer,
  tiempo_busanterior timestamp without time zone,
  busanterior1er integer,
  busanterior2do integer,
  busanterior3er integer,
  tipocorte character varying(100),
  proposito character varying(100)
);

ALTER TABLE public.etapas OWNER TO felipe;

-- crear tabla de viajes
CREATE TABLE viajes (
  id character varying(20),
  nviaje integer,
  netapa integer,
  etapas character varying(1000),
  netapassinbajada integer,
  ultimaetapaconbajada integer,
  tviaje_seg double precision,
  tviaje_min double precision,
  dviajeeuclidiana_mts double precision,
  dviajeenruta_mts double precision,
  paraderosubida character varying(50),
  paraderobajada character varying(50),
  comunasubida character varying(20),
  comunabajada character varying(20),
  diseno777subida character varying(20),
  diseno777bajada character varying(20),
  tiemposubida timestamp without time zone,
  tiempobajada timestamp without time zone,
  periodosubida character varying(100),
  periodobajada character varying(100),
  tipodia character varying(10),
  mediahora time without time zone,
  contrato character varying(50),
  factorexpansion double precision,
  tiempomediodeviaje timestamp without time zone,
  periodomediodeviaje character varying(200),
  mediahoramediodeviaje time without time zone,
  tipodiamediodeviaje character varying(10),
  t_1era_etapa double precision,
  d_1era_etapa double precision,
  tespera_1era_etapa double precision,
  ttrasbordo_1era_etapa double precision,
  tcaminata_1era_etapa double precision,
  t_2da_etapa double precision,
  d_2da_etapa double precision,
  tespera_2da_etapa double precision,
  ttrasbordo_2da_etapa double precision,
  tcaminata_2da_etapa double precision,
  t_3era_etapa double precision,
  d_3era_etapa double precision,
  tespera_3era_etapa double precision,
  ttrasbordo_3era_etapa double precision,
  tcaminata_3era_etapa double precision,
  t_4ta_etapa double precision,
  d_4ta_etapa double precision,
  tespera_4ta_etapa double precision,
  ttrasbordo_4ta_etapa double precision,
  tcaminata_4ta_etapa double precision,
  op_1era_etapa character varying(10),
  op_2da_etapa character varying(10),
  op_3era_etapa character varying(10),
  op_4ta_etapa character varying(10),
  tipoop_1era_etapa character varying(15),
  tipoop_2da_etapa character varying(15),
  tipoop_3era_etapa character varying(15),
  tipoop_4ta_etapa character varying(15),
  serv_1era_etapa character varying(500),
  serv_2da_etapa character varying(500),
  serv_3era_etapa character varying(500),
  serv_4ta_etapa character varying(500),
  linea_metro_subida_1 character varying(100),
  linea_metro_subida_2 character varying(100),
  linea_metro_subida_3 character varying(100),
  linea_metro_subida_4 character varying(100),
  linea_metro_bajada_1 character varying(100),
  linea_metro_bajada_2 character varying(100),
  linea_metro_bajada_3 character varying(100),
  linea_metro_bajada_4 character varying(100),
  paraderosubida_1era character varying(50),
  paraderosubida_2da character varying(50),
  paraderosubida_3era character varying(50),
  paraderosubida_4ta character varying(50),
  tiemposubida_1era timestamp without time zone,
  tiemposubida_2da timestamp without time zone,
  tiemposubida_3era timestamp without time zone,
  tiemposubida_4ta timestamp without time zone,
  zona777subida_1era character varying(50),
  zona777subida_2da character varying(50),
  zona777subida_3era character varying(50),
  zona777subida_4ta character varying(50),
  paraderobajada_1era character varying(50),
  paraderobajada_2da character varying(50),
  paraderobajada_3era character varying(50),
  paraderobajada_4ta character varying(50),
  tiempobajada_1era timestamp without time zone,
  tiempobajada_2da timestamp without time zone,
  tiempobajada_3era timestamp without time zone,
  tiempobajada_4ta timestamp without time zone,
  zona777bajada_1era character varying(50),
  zona777bajada_2da character varying(50),
  zona777bajada_3era character varying(50),
  zona777bajada_4ta character varying(50),
  tipotransporte_1era character varying(50),
  tipotransporte_2da character varying(50),
  tipotransporte_3era character varying(50),
  tipotransporte_4ta character varying(50),
  tespera_estimada_1era double precision,
  tespera_estimada_2da double precision,
  tespera_estimada_3era double precision,
  tespera_estimada_4ta double precision,
  escolar character varying(10),
  tviaje_en_vehiculo_min double precision,
  tipo_corte_etapa_viaje character varying(50),
  proposito character varying(50),
  dviaje_buses double precision
);

ALTER TABLE public.viajes OWNER TO felipe;

-- crear tabla de paraderos (no incluye estaciones de metro)
CREATE TABLE redparadas (
  codigo character varying(20),
  codigousuario character varying(20),
  comuna character varying(100),
  nombre character varying(500),
  sentido character varying(500),
  fila_superior character varying(500),
  fila_inferior character varying(500),
  grupo_parada character varying(500),
  x integer,
  y integer,
  latitud double precision,
  longitud double precision,
  censal_1992 character varying(20),
  comunas character varying(20),
  diseno_563 character varying(20),
  diseno_777 character varying(20),
  eod_2001 character varying(20),
  eod_2006 character varying(20),
  estraus_264 character varying(20),
  estraus_404 character varying(20),
  estraus_410 character varying(20),
  estraus_618 character varying(20),
  zonas_6 character varying(20)
);

ALTER TABLE public.redparadas OWNER TO felipe;

-- crear tabla de estaciones de metro
CREATE TABLE estaciones_metro (
  codigotrx character varying(100),
  latitud double precision,
  longitud double precision,
  x integer,
  y integer,
  linea character varying(100),
  codigoestandar character varying(100),
  tipo character varying(100),
  codigosinlinea character varying(100),
  censal_1992 character varying(20),
  comunas character varying(20),
  diseno_563 character varying(20),
  diseno_777 character varying(20),
  eod_2001 character varying(20),
  eod_2006 character varying(20),
  estraus_264 character varying(20),
  estraus_404 character varying(20),
  estraus_410 character varying(20),
  estraus_618 character varying(20),
  zonas_6 character varying(20)
);

ALTER TABLE public.estaciones_metro OWNER TO felipe;

-- crear tabla etapa_util
CREATE TABLE etapa_util (
  id bigint,
  nviaje integer,
  netapa integer,
  tiempo_subida timestamp without time zone,
  par_subida character varying(30),
  par_bajada character varying(30),
  factor_exp_etapa double precision
);

ALTER TABLE public.etapa_util OWNER TO felipe;

-- crear tabla de viaje_util
CREATE TABLE viaje_util (
  id character varying(20),
  nviaje integer,
  netapa integer,
  paraderosubida_1era character varying(50),
  paraderobajada_1era character varying(50),
  tiemposubida_1era timestamp without time zone,
  paraderosubida_2da character varying(50),
  paraderobajada_2da character varying(50),
  paraderosubida_3era character varying(50),
  paraderobajada_3era character varying(50),
  paraderosubida_4ta character varying(50),
  paraderobajada_4ta character varying(50),
  factorexpansion double precision,
);

ALTER TABLE public.viaje_util OWNER TO felipe;

-- crear tabla de parada_util
CREATE TABLE parada_util (
  codigo character varying(30),
  nombre character varying(500),
  latitud double precision,
  longitud double precision
);

ALTER TABLE public.parada_util OWNER TO felipe;

-- indice único 
CREATE UNIQUE INDEX codigo_unico ON parada_util (codigo);

-- indice para filtrar por hora
CREATE INDEX hora_subida ON etapa_util (extract(hour from tiempo_subida));
-- indice para filtrar por día y hora 
CREATE INDEX fecha_hora_subida ON etapa_util (date_trunc('hour', tiempo_subida));
-- indice para filtrar por día
CREATE INDEX fecha_subida ON etapa_util (date_trunc('day', tiempo_subida));

