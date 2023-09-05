CREATE DATABASE GYM;
USE GYM;
														-- Creando las tablas
create table CLIENTES (
ID_CLIENTES	INT  AUTO_INCREMENT not null unique,
NOMBRE	VARCHAR (100)  not null,
APELLIDO	VARCHAR(100) not null,
DOCUMENT_TYPE	VARCHAR(100) not null default "DNI",
NUMERO_DOCUMENTO	INT not null unique ,
FECHA_DE_NACIMIENTO	DATE not null,
DIRECCION	VARCHAR(100),
TELEFONO	VARCHAR(100) not null,
PRIMARY KEY (ID_CLIENTES, NUMERO_DOCUMENTO));

create table profesores (
ID_profesor	INT primary key AUTO_INCREMENT not null unique,
NOMBRE	VARCHAR(100) not null,
Apellido	VARCHAR(100) not null,
DOCUMENT_TYPE	VARCHAR(100) not null default "DNI",
NUMERO_DOCUMENTO	INT not null,
ESPECIALIDAD	VARCHAR(100) not null,
TELEFONO	VARCHAR(100) not null,
CORREO	VARCHAR(100) not null );

create table Clases (
ID_CLASE INT	primary key AUTO_INCREMENT not null unique,
NOMBRE_CLASE	VARCHAR	(100),
DESCRIPCION	VARCHAR	(100) ,
DURACION	INT	,
HORARIO	TIME	,
DIAS	VARCHAR	(100),
ID_profesor INT,
foreign key (ID_profesor) references profesores (ID_profesor),
CUPOS	INT	);

create table rutinas (
ID_RUTINA	INT	primary key AUTO_INCREMENT not null unique,
NOMBRE_RUTINA	VARCHAR(100) not null,
ID_profesor INT,
foreign key (ID_profesor) references profesores (ID_profesor),
DESCRIPCION	VARCHAR(250)not null,
DIFICULTAD	VARCHAR(100)not null,
EJERCICIO_1	VARCHAR(100),
EJERCICIO_2	VARCHAR(100),
EJERCICIO_3	VARCHAR(100),
EJERCICIO_4	VARCHAR(100),
EJERCICIO_5	VARCHAR(100),
EJERCICIO_6	VARCHAR(100));

CREATE TABLE Ejercicios (
    ID_ejercicio INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(255),
    Musculo VARCHAR(255),
    Maquina VARCHAR(255),
    Repeticiones INT
);

create table INDUMENTARIA_MAQUINARIA(
ID_EQUIPOS	INT	primary key AUTO_INCREMENT not null unique,
NOMBRE	VARCHAR(100),
FUNCION	VARCHAR(100),
ESTADO	VARCHAR(100),
FECHA_COMPRA	DATE,
PRECIO	INT,
REPARAR	BOOLEAN default false);

create table USUARIO (
ID_USUARIO	INT primary key AUTO_INCREMENT not null unique,
ID_CLIENTES INT not null,
NUMERO_DOCUMENTO INT not null unique,
CONTRASEÑA	VARCHAR (6)  not null DEFAULT "123456",
SUSCRIPTO	BOOLEAN  not null DEFAULT TRUE, 
ID_RUTINA	INT,		
ID_CLASE INT,
ID_profesor int,
foreign key (ID_CLIENTES, NUMERO_DOCUMENTO) references CLIENTES (ID_CLIENTES, NUMERO_DOCUMENTO),
foreign key (ID_RUTINA) references RUTINAS (ID_RUTINA),
foreign key (ID_clase) references CLASES (ID_clase),
foreign key (ID_profesor) references PROFESORES (ID_profesor)
);

CREATE TABLE AuditoriaEjercicios (
    ID INT AUTO_INCREMENT PRIMARY KEY,
    Fecha DATETIME,
    Accion VARCHAR(255),
--    ID_profesor INT,
	usuario_modificador varchar (500)
--    FOREIGN KEY (ID_profesor) REFERENCES Profesores(ID_profesor)
);
-- esta ultima table tiene como comentario la modificacion a futuro cuando la app este funcional donde el registro que quedará será de los profesores que hagan modificaciones 
														-- Creando trigguers de tablas usuarios y auditoria
delimiter $$
CREATE TRIGGER carga_automatica
AFTER INSERT ON clientes
for each row
INSERT INTO usuario (ID_CLIENTES, NUMERO_DOCUMENTO) values (NEW.ID_CLIENTES, NEW.NUMERO_DOCUMENTO);

$$
CREATE TRIGGER control_cambios_ejercicios
after INSERT ON Ejercicios
FOR EACH ROW
INSERT INTO AuditoriaEjercicios (Fecha, Accion, usuario_modificador)
VALUES (NOW(), 'Inserción', user());
$$
														-- creando vistas 
-- esta vista nos dice que profesor creo la rutina que se esta viendo
CREATE VIEW Rutina_Profe AS
SELECT p.nombre, p.Apellido, r.NOMBRE_RUTINA
FROM profesores as p
JOIN rutinas as r ON p.ID_profesor = r.ID_profesor;
$$
CREATE VIEW vista_rutina AS 
SELECT u.ID_USUARIO, r.EJERCICIO_1, r.EJERCICIO_2, r.EJERCICIO_3, r.EJERCICIO_4, r.EJERCICIO_5, r.EJERCICIO_6
FROM rutinas as r
JOIN usuario as u ON r.ID_RUTINA = u.ID_RUTINA;
$$
-- esta vista permite ver que profesor tiene asignado cada alumno
CREATE VIEW alumnos_profesores AS 
SELECT p.NOMBRE as nombre_profesor, c.nombre AS nombre_cliente
FROM USUARIO u
LEFT JOIN CLIENTES c ON u.ID_CLIENTES = c.ID_CLIENTES
LEFT JOIN profesores p ON u.ID_profesor = p.ID_profesor;
$$
-- esta vista permite ver el nombre del profesor a cargo de la clase en vez de su ID
CREATE VIEW Quien_da_la_clase AS 
SELECT c.NOMBRE_CLASE, p.NOMBRE, p.Apellido
FROM clases as c
JOIN profesores as p ON c.ID_profesor = p.ID_profesor;
$$
-- esta vista es para control de si la persona tiene la cuota paga
CREATE VIEW Esta_activo AS 
SELECT c.NOMBRE, c.APELLIDO, u.SUSCRIPTO as "1=suscripto"
FROM usuario as u
JOIN clientes as c ON u.ID_CLIENTES = c.ID_CLIENTES;
$$
														-- creando funciones
-- Esta funcion cumple la idea de la frase de saludo cuando uno inicie sesion en la app
CREATE FUNCTION `Saludo`(nombre varchar (100), apellido varchar (100)) RETURNS varchar(100) CHARSET utf8mb4
    DETERMINISTIC
BEGIN
Declare nombre_completo varchar (150);
set nombre_completo = concat(nombre, " ", apellido);
RETURN concat ("Bienvenido al gimnasio ", nombre_completo);
END;
$$
-- Esta funcion tiene como objetivo brindar una pequeña descripcion de que musculos trabajara el usuario 
CREATE FUNCTION `Hoy_toca`(nombre_rutina varchar (100)) RETURNS varchar(100)
    DETERMINISTIC
BEGIN
Declare ejercicio_hoy varchar (150);
RETURN concat("Hola, hoy toca:", " ", nombre_rutina);
END;
$$
														-- Creando store procedures
-- el primer procedure consistira en un contador simple que dira cuantas rutinas armo un profesor, esto servira para el control sobre el trabajo de los prefesores.
CREATE PROCEDURE Buscador_ID (IN dni_param INT, OUT id_result INT)
BEGIN
    SELECT ID_USUARIO INTO id_result
    FROM usuario
    WHERE NUMERO_DOCUMENTO = dni_param;
END ;
$$
-- el segundo es para actualizar la contraseña de los usuarios en caso de olvidarla (solo podran hacerlo desde el gym)
CREATE PROCEDURE actualizar_contrasena(
    IN ID_USUARIO_param INT,
    IN nueva_contrasena VARCHAR(6)
)
BEGIN
    UPDATE USUARIO
    SET CONTRASEÑA = nueva_contrasena
    WHERE ID_USUARIO = ID_USUARIO_param;
END;

$$
														-- Cargando base de datos
														-- Aplicando Savepoints como vimos en clase sobre la carga de clientes y profesores
select @@autocommit;
set autocommit =0;
$$
START TRANSACTION;
SAVEPOINT sp1;
INSERT INTO Clientes (ID_CLIENTES, NOMBRE, APELLIDO, DOCUMENT_TYPE, NUMERO_DOCUMENTO, FECHA_DE_NACIMIENTO, DIRECCION, TELEFONO)
VALUES 
	(null, 'Mace', 'Windu', 'DNI', '33888660', '2000-01-01', 'Araoz 5567', '1534567890'),
	(null, 'Anakin', 'Skywalker', 'DNI', '33888661', '1979-02-02', 'Juncal 5312', '1545678901'),
	(null, 'Darth', 'Vader', 'DNI', '33888662', '1978-03-03', 'Austria 789', '1556789012'),
	(null, 'Yoda', 'Jedi', 'DNI', '33888663', '1986-04-04', 'Gallo 7898', '1567890123');
SAVEPOINT sp2;
INSERT INTO Clientes (ID_CLIENTES, NOMBRE, APELLIDO, DOCUMENT_TYPE, NUMERO_DOCUMENTO, FECHA_DE_NACIMIENTO, DIRECCION, TELEFONO)
VALUES 
	(null, 'Han', 'Solo', 'DNI', '12555690', '1988-05-05', 'French 664', '1578901234'),
	(null, 'Leia', 'Skywalker', 'DNI', '12555691', '1987-06-06', 'Peña 3564', '1589012345'),
	(null, 'Clark', 'Kent', 'DNI', '12555692', '1959-07-07', 'Beruti 943', '1590123456'),
	(null, 'Neville', 'Longbottom', 'DNI', '12555693', '1986-08-08', 'Arenales 123', '1501234567');
SAVEPOINT sp3;
INSERT INTO Clientes (ID_CLIENTES, NOMBRE, APELLIDO, DOCUMENT_TYPE, NUMERO_DOCUMENTO, FECHA_DE_NACIMIENTO, DIRECCION, TELEFONO)
VALUES
(null, 'Draco', 'Malfoy', 'DNI', '12987563', '1955-09-09', 'Armenia 126', '1512345678'),
(null, 'Minerva', 'Maga', 'DNI', '12987562', '1960-10-10', 'Gurruchaga 1234', '1523456789'),
(null, 'Severus', 'Snape', 'DNI', '12987561', '1999-11-11', ' Thames 666', '1534567890'),
(null, 'Albus', 'Dombuldore', 'DNI', '12987560', '2000-12-12', 'Uriarte 1234', '1545678901');
SAVEPOINT sp4;
INSERT INTO Clientes (ID_CLIENTES, NOMBRE, APELLIDO, DOCUMENT_TYPE, NUMERO_DOCUMENTO, FECHA_DE_NACIMIENTO, DIRECCION, TELEFONO)
VALUES 
(null, 'Tom', 'Ridle', 'DNI', '25698555', '1980-01-01', 'Guemes 685', '1556789012'),
(null, 'Hermione', 'Smith', 'DNI', '25698553', '2000-02-02', 'Nicaragua 598', '1567890123'),
(null, 'Harry', 'Potter', 'DNI', '25698554', '1995-03-03', 'Cramer 888', '1578901234'),
(null, 'Ron', 'Wisley', 'DNI', '25698559', '1996-04-04', 'Olleros 668', '1589012345');

$$
START TRANSACTION;
SAVEPOINT Prof1;
INSERT INTO profesores (ID_profesor, NOMBRE, APELLIDO, DOCUMENT_TYPE, NUMERO_DOCUMENTO, ESPECIALIDAD, TELEFONO, CORREO)
VALUES (null, 'Juan', 'Pérez', 'DNI', '12345678', 'Musculacion', '1234567890', 'juan@example.com');
SAVEPOINT Prof2;
INSERT INTO profesores (ID_profesor, NOMBRE, APELLIDO, DOCUMENT_TYPE, NUMERO_DOCUMENTO, ESPECIALIDAD, TELEFONO, CORREO)
VALUES (null, 'María', 'Gómez', 'DNI', '98765432', 'Yoga', '9876543210', 'maria@example.com');
SAVEPOINT Prof3;
INSERT INTO profesores (ID_profesor, NOMBRE, APELLIDO, DOCUMENT_TYPE, NUMERO_DOCUMENTO, ESPECIALIDAD, TELEFONO, CORREO)
VALUES (null, 'Pedro', 'López', 'DNI', '35777888', 'Boxeo', '5555555555', 'pedro@example.com');
Commit
$$
select @@autocommit;
set autocommit =1
$$
														-- Continuamos la carga sin savepoints
INSERT INTO CLASES (ID_CLASE, NOMBRE_CLASE, DESCRIPCION, DURACION, HORARIO, DIAS, ID_profesor, CUPOS)
VALUES 
	(null, 'Pilates', 'Clase personalizada por el profesor a cargo donde se realizan ejercicios de pilates!', 60, '15:00:00', 'Lunes y Jueves', 1, 15),
	(null, 'Pilates', 'Clase personalizada por el profesor a cargo donde se realizan ejercicios de pilates!', 60, '18:00:00', 'Lunes y Jueves', 1, 15);
$$
INSERT INTO RUTINAS (ID_RUTINA, NOMBRE_RUTINA, ID_profesor, DESCRIPCION, Dificultad, EJERCICIO_1, EJERCICIO_2, EJERCICIO_3, EJERCICIO_4, EJERCICIO_5, EJERCICIO_6)
VALUES 
(null, 'Pecho y Bicep', 2, 'Rutina para principiantes, enfocada a desarrollar fuerza mediante muchas repeticiones y poco peso', 'Principiante', 'Pecho Plano 3X15', 'Pecho Inclinado con mancuernas 3X15', 'Pecho con polea baja 3x15', 'Bicep con mancuerna 3X15', 'Bicep con barra W 3x15', '20 Minutos de caminata o correr en la cinta'),
(null, 'Espalda y Tricep', 3, 'Rutina para intermedios, enfocada en desarrollar fuerza y masa muscular en la espalda y tríceps', 'Intermedio', 'Remo con barra 4X10', 'Jalones en polea alta 4X12', 'Peso muerto 3x8', 'Press de banca cerrado 3X10', 'Fondos en paralelas 3X12', '20 Minutos de bicicleta estática'),
(null, 'Piernas y Hombros', 1, 'Rutina avanzada enfocada en el desarrollo de piernas y hombros', 'Avanzado', 'Sentadillas con barra 4X8', 'Prensa de piernas 3X10', 'Extensiones de piernas 3x12', 'Press de hombros con mancuernas 4X10', 'Elevaciones laterales 3X12', '20 Minutos de elíptica');
$$
INSERT INTO indumentaria_maquinaria (ID_EQUIPOS, NOMBRE, FUNCION, ESTADO, FECHA_COMPRA, PRECIO, REPARAR)
VALUES 
	(null, 'Mancuerna de 10 kg', 'Pesa', 'Nuevo', '2023-02-12', 10000, 0),
	(null, 'Mancuerna de 10 kg', 'Pesa', 'Nuevo', '2023-02-12', 10000, 0),
	(null, 'Mancuerna de 10 kg', 'Pesa', 'Nuevo', '2023-02-12', 10000, 0),
	(null, 'Máquina de remo', 'Equipo para ejercitar la espalda y brazos', 'Nuevo', '2022-10-15', 180000, 0),
    (null, 'Máquina de remo', 'Equipo para ejercitar la espalda y brazos', 'Nuevo', '2022-10-15', 180000, 0),
    (null, 'Máquina de remo', 'Equipo para ejercitar la espalda y brazos', 'Nuevo', '2022-10-15', 180000, 0),
    (null, 'Bicicleta estática', 'Equipo para ejercitar las piernas y cardio', 'Nuevo', '2023-06-20', 50000, 0),
    (null, 'Bicicleta estática', 'Equipo para ejercitar las piernas y cardio', 'Nuevo', '2023-06-20', 50000, 0),
    (null, 'Bicicleta estática', 'Equipo para ejercitar las piernas y cardio', 'Nuevo', '2023-06-20', 50000, 0),
    (null, 'Barra para dominadas', 'Equipo para trabajar la espalda y brazos', 'Nuevo', '2022-09-10', 18000, 0),
    (null, 'Barra para dominadas', 'Equipo para trabajar la espalda y brazos', 'Nuevo', '2022-09-10', 18000, 0),
    (null, 'Barra para dominadas', 'Equipo para trabajar la espalda y brazos', 'Nuevo', '2022-09-10', 18000, 0),
    (null, 'Máquina de abdominales', 'Equipo para trabajar los músculos abdominales', 'Nuevo', '2023-05-05', 12000, 0),
    (null, 'Máquina de abdominales', 'Equipo para trabajar los músculos abdominales', 'Nuevo', '2023-05-05', 12000, 0),
    (null, 'Máquina de abdominales', 'Equipo para trabajar los músculos abdominales', 'Nuevo', '2023-05-05', 12000, 0),
    (null, 'Pesas rusas', 'Equipo para entrenamiento funcional', 'Nuevo', '2022-08-25', 6000, 0),
    (null, 'Pesas rusas', 'Equipo para entrenamiento funcional', 'Nuevo', '2022-08-25', 6000, 0),
    (null, 'Pesas rusas', 'Equipo para entrenamiento funcional', 'Nuevo', '2022-08-25', 6000, 0),
    (null, 'Máquina de press de piernas', 'Equipo para ejercitar las piernas', 'Nuevo', '2022-07-18', 16000, 0),
    (null, 'Máquina de press de piernas', 'Equipo para ejercitar las piernas', 'Nuevo', '2022-07-18', 16000, 0),
    (null, 'Máquina de press de piernas', 'Equipo para ejercitar las piernas', 'Nuevo', '2022-07-18', 16000, 0),
    (null, 'Pelotas de ejercicio', 'Equipo para entrenamiento de equilibrio', 'Nuevo', '2023-04-12', 5000, 0),
    (null, 'Pelotas de ejercicio', 'Equipo para entrenamiento de equilibrio', 'Nuevo', '2023-04-12', 5000, 0);
$$
INSERT INTO Ejercicios (Nombre, Musculo, Maquina, Repeticiones)
VALUES    
	('Ejercicio 1', 'Pecho', 'Máquina de pecho', 10),
    ('Ejercicio 2', 'Espalda', 'Máquina de remo', 12),
    ('Ejercicio 3', 'Piernas', 'Máquina de sentadillas', 8),
    ('Ejercicio 4', 'Brazos', 'Máquina de bíceps', 15),
    ('Ejercicio 5', 'Hombros', 'Máquina de hombros', 10),
    ('Ejercicio 6', 'Abdominales', 'Banco de abdominales', 20),
    ('Ejercicio 7', 'Pecho', 'Máquina de press de pecho', 12),
    ('Ejercicio 8', 'Espalda', 'Barra de dominadas', 10),
    ('Ejercicio 9', 'Piernas', 'Máquina de extensiones', 15),
    ('Ejercicio 10', 'Brazos', 'Máquina de tríceps', 12);
$$
														-- Aplicando las funciones
select id_clientes, Nombre , apellido, saludo (Nombre , apellido) as saludo from clientes;
$$
SELECT 
    nombre_rutina AS tu_rutina, HOY_TOCA(nombre_rutina) AS HOY_TOCA
FROM
    rutinas
$$
														-- Aplicando el Store procedure del buscador
CALL Buscador_ID (33888662, @id_resultado);
select @id_resultado as "Tu id es:"
$$
														-- aplicando segundo store procedure
CALL actualizar_contrasena(4, 'nueva1');
$$
Select * from rutina_profe;
$$
-- el siguiente codigo es neceario para que la view de "vista_rutina" y alumnos_profesores funcionen, ya que la idea es que te asignen la rutina y el profe en tu primer dia y no por default
UPDATE usuario SET ID_RUTINA = "2", ID_CLASE = "1", ID_PROFESOR = 1 where ID_USUARIO =1;
$$
select * from Rutina_Profe;
$$
select * from vista_rutina;
$$
select * from alumnos_profesores;
$$
select * from Quien_da_la_clase;
$$
select * from Esta_activo;

$$
-- chequeando que los triggers funcionen correctamente
select * from AuditoriaEjercicios
$$
select * from usuario
