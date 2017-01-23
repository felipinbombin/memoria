\timing on

-- se elimina la base de datos existente.
DROP DATABASE IF EXISTS memoria;
DROP USER IF EXISTS felipe;

-- Se crea usuario y base de datos
CREATE USER felipe WITH PASSWORD 'tesis';
CREATE DATABASE memoria OWNER felipe;

