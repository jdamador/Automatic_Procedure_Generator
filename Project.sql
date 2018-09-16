/*****************************************************************\
 * Proyecto de Base de Datos. Generador automatico de los
 * procedimientos de insertar, modificar, eliminar, actualizar.
 * Author: Jose Daniel Amador Salas.
 *         Jose Pablo Brenes Alfaro.
 * Created: 02/08/2018.
 * Version: 1.0.
\*****************************************************************/

/*****************************************************************\
* Tablas de pruebas para verificar el funcionamiento del generador
* automatico.
\*****************************************************************/
--Tabla de pruebas 1
CREATE TABLE usuarios(
    cedula INT NOT NULL,
    nombre VARCHAR(30),
    apellido VARCHAR(30),
    genero CHAR(1),
    email VARCHAR(50),
    CONSTRAINT pk_cedula_usuarios PRIMARY KEY(cedula)
)
GO;
--Tabla de puebas 2
CREATE TABLE carros(
    placa INT,
    marca VARCHAR(30),
    modelo INT,
    numPuertas INT,
    CONSTRAINT pk_placa_carros PRIMARY KEY(placa)
)
GO;

/***************************************************************\
* Método que genera los procedimientos almacenados para las    *
* diferentes tablas seleccionadas.                             *
\***************************************************************/
CREATE PROCEDURE genInsert
(
    @prefijo VARCHAR (30),
    @nombre_tabla VARCHAR (50),
    @esquema_t VARCHAR (30),
    @esquema_p VARCHAR (30),
    @operacion INT
)
AS
DECLARE
    @sql Nvarchar (2000),
    @parametros VARCHAR(500),
    @lista_columnas VARCHAR(500),
    @lista_parametros VARCHAR(500),
    @columna varchar(50),
    @tipo_datos varchar(50),
    @largo varchar(50)
DECLARE c_columnas CURSOR FOR
    SELECT COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH 
        FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA=@esquema_t AND TABLE_NAME=LOWER(@nombre_tabla)
BEGIN

    SET @sql='CREATE PROCEDURE '+ @esquema_p+'.'+@prefijo+'_insertar_'+@nombre_tabla
    --Abre el curso
    OPEN c_columnas
        FETCH NEXT FROM c_columnas
            INTO @columna , @tipo_datos, @largo
    SET @parametros='('
    SET @lista_columnas='('
    SET @lista_parametros='('
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @largo IS NULL --Si no es un varchar.
                BEGIN
                    SET @parametros=@parametros+'@'+@columna+' '+@tipo_datos+', '
                END
            ELSE --Si, es varchar.
                BEGIN
                    SET @parametros=@parametros+'@'+@columna+' '+@tipo_datos+'('+@largo+'), '
                END
            SET @lista_columnas=@lista_columnas+@columna+', '
            SET @lista_parametros=@lista_parametros+'@'+@columna+', '
            FETCH NEXT FROM c_columnas
                INTO @columna , @tipo_datos, @largo
        END
    SET @parametros=SUBSTRING(@parametros,0,LEN(@parametros))+')'
    SET @lista_columnas=SUBSTRING(@lista_columnas,0,LEN(@lista_columnas))+')'
    SET @lista_parametros=SUBSTRING(@lista_parametros,0,LEN(@lista_parametros))+')'
    CLOSE c_columnas
    DEALLOCATE c_columnas;
    SET @sql=@sql+@parametros + ' AS BEGIN INSERT INTO '
    SET @sql=@sql+@esquema_t+'.'+@nombre_tabla+@lista_columnas+' values'+@lista_parametros+'; END'
    IF @operacion=1
        BEGIN
            EXECUTE sp_executesql @sql
        END
    SELECT @sql
END
GO
--Notice: script to delete de storage procedure.
DROP PROCEDURE genDelete;
GO
/***********************************************************************\
 * Método que genera los procedimientos que eliminan elementos de cual-*
 * quier tabla seleccionada.                                           *
\***********************************************************************/
--Notice: script to delete de storage procedure.
DROP PROCEDURE genDelete;
GO

CREATE PROCEDURE genDelete
(
    @prefijo VARCHAR (30),
    @nombre_tabla VARCHAR (50),
    @esquema_t VARCHAR (30),
    @esquema_p VARCHAR (30),
    @operacion INT
)
AS
DECLARE
    @sql NVARCHAR (2000),
    @parametros VARCHAR(500),
    @l_columnas VARCHAR(500),
    @l_parametros VARCHAR(500),
    @columna VARCHAR(50),
    @tipo_datos VARCHAR(50),
    @lenght INT
DECLARE c_columnas CURSOR FOR
    SELECT c.DATA_TYPE, c.CHARACTER_MAXIMUM_LENGTH,kcu.COLUMN_NAME
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc, INFORMATION_SCHEMA.COLUMNS AS c, INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS kcu
            WHERE kcu.CONSTRAINT_NAME=tc.CONSTRAINT_NAME AND tc.TABLE_SCHEMA=@esquema_t AND tc.TABLE_NAME=@nombre_tabla AND tc.CONSTRAINT_TYPE='PRIMARY KEY' AND 
                kcu.COLUMN_NAME =c.COLUMN_NAME;
BEGIN   
    SET @sql='CREATE PROCEDURE '+ @esquema_p+'.'+@prefijo+'_eliminar_'+@nombre_tabla
    OPEN c_columnas
        FETCH NEXT FROM c_columnas
            INTO @tipo_datos,@lenght,@columna
    SET @parametros=' '
    IF @lenght IS NULL --Si no es un varchar.
        BEGIN
            SET @parametros=@parametros+'(@'+@columna+' '+@tipo_datos+')'
        END
    ELSE --Si, es varchar.
        BEGIN
            SET @parametros=@parametros+'(@'+@columna+' '+@tipo_datos+'('+@lenght+'))'
        END
	SET @parametros = @parametros+' AS BEGIN DELETE FROM '+@esquema_t+'.'+@nombre_tabla+' WHERE '+@columna+' = @'+@columna+'; END;'
    SET @sql = @sql+' '+@parametros
    CLOSE c_columnas
    DEALLOCATE c_columnas;
    IF @operacion=1
        BEGIN
            EXECUTE sp_executesql @sql
        END
    SELECT @sql
END
GO

/*******************************************************************************\
 * Procedimiento almacenado que permite crear el un el procedimiento de modifica-
 * cion para cada tabla.
\*******************************************************************************/
--DROP PROCEDURE genUpdate
CREATE PROCEDURE genUpdate(
    @prefijo VARCHAR (30),
    @nombre_tabla VARCHAR (50),
    @esquema_tabla VARCHAR (30),
    @esquema_procedure VARCHAR (30),
    @operacion INT
)
AS
DECLARE
    @sql NVARCHAR (2000), --Query para ejecutar.
    @parametros VARCHAR(500), --    
    @valores_modificar VARCHAR(500), --Columnas de la tabla.
    @atributo VARCHAR(30),
    @tipo_datos VARCHAR(30),
    @size VARCHAR(30),
    @columna_key varchar(30)
DECLARE cursor_cols CURSOR FOR 
    SELECT COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA=@esquema_tabla AND TABLE_NAME = LOWER(@nombre_tabla)
DECLARE cursor_key CURSOR FOR 
    SELECT kcu.COLUMN_NAME 
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc INNER JOIN  INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
                ON (kcu.CONSTRAINT_NAME=tc.CONSTRAINT_NAME)
            WHERE tc.TABLE_SCHEMA=@esquema_tabla AND tc.TABLE_NAME=@nombre_tabla AND tc.CONSTRAINT_TYPE='PRIMARY KEY'
BEGIN
    SET @sql='CREATE PROCEDURE '+@esquema_procedure+'.'+@prefijo+'_modificar_'+@nombre_tabla
    OPEN cursor_cols
        FETCH NEXT FROM cursor_cols
            INTO @atributo,@tipo_datos,@size
    OPEN cursor_key
        FETCH NEXT FROM cursor_key
            INTO @columna_key
    SET @parametros='('
    SET @valores_modificar='SET '
    WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @size IS NULL --Si no es un varchar.
                BEGIN
                    SET @parametros=@parametros+'@'+@atributo+' '+@tipo_datos+', '
                END
            ELSE --Si, es varchar.
                BEGIN
                    SET @parametros=@parametros+'@'+@atributo+' '+@tipo_datos+'('+@size+'), '
                END

            SET @valores_modificar=@valores_modificar+@atributo+' = @'+@atributo+', '
                FETCH NEXT FROM cursor_cols
                    INTO @atributo , @tipo_datos, @size
        END 
    SET @parametros=SUBSTRING(@parametros,0,LEN(@parametros))+')'
    SET @valores_modificar=SUBSTRING(@valores_modificar,0,LEN(@valores_modificar))
    CLOSE cursor_cols
    DEALLOCATE cursor_cols; 
    SET @sql=@sql+@parametros + ' AS BEGIN  UPDATE ' 
    SET @sql=@sql+@esquema_tabla+'.'+@nombre_tabla+' '+@valores_modificar+' WHERE '+ @columna_key+'=@'+@columna_key+'; END;'
    CLOSE cursor_key
    DEALLOCATE cursor_key; 
    IF @operacion=1
        BEGIN
            EXECUTE sp_executesql @sql
        END
    SELECT @sql  
END
GO
/********************************************************************************\
 * Procedimiento para generar los procedimientos de consulta  para las tablas
 * selecionadas para la base de datos.
\********************************************************************************/
CREATE  PROCEDURE genSelects(
    @prefijo VARCHAR (30),
    @nombre_tabla VARCHAR (50),
    @esquema_nombre VARCHAR (30),
    @tipo_operacion VARCHAR (30),
    @operacion INT
)
AS
DECLARE
    @sql NVARCHAR (2000), --Query para ejecutar.
    @parametros VARCHAR(500), --    
    @valores_filtro VARCHAR(500), --Columnas de la tabla.
    @atributo VARCHAR(30),
    @tipo_datos VARCHAR(30),
    @size VARCHAR(30)
DECLARE cursor_cols CURSOR FOR 
    SELECT COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH 
        FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA=@esquema_nombre AND TABLE_NAME = LOWER(@nombre_tabla)
BEGIN 
    SET @sql='CREATE PROCEDURE '+@esquema_nombre+'.'+@prefijo+'_consultar_'+@nombre_tabla
    OPEN cursor_cols
        FETCH NEXT FROM cursor_cols 
            INTO @atributo,@tipo_datos,@size
    SET @parametros = '('
    SET @valores_filtro= ''
    WHILE @@FETCH_STATUS =0
        BEGIN
            IF @size IS NULL --Si no es un varchar.
                BEGIN
                    SET @parametros=@parametros+'@'+@atributo+' '+@tipo_datos+', '
                END
            ELSE --Si, es varchar.
                BEGIN
                    SET @parametros=@parametros+'@'+@atributo+' '+@tipo_datos+'('+@size+'), '
                END
            SET @valores_filtro=@valores_filtro+'(('+@atributo+' IS NULL) OR ('+@atributo+'=@'+@atributo+')) OR '
            FETCH NEXT FROM cursor_cols
                INTO @atributo , @tipo_datos, @size
        END
    SET @valores_filtro=SUBSTRING(@valores_filtro,0,LEN(@valores_filtro)-4)
    SET @parametros=SUBSTRING(@parametros,0,LEN(@parametros))+')'
    CLOSE cursor_cols
    DEALLOCATE cursor_cols; 
    SET @sql=@sql+@parametros + ' AS BEGIN  SELECT * FROM ' 
    SET @sql=@sql+@esquema_nombre+'.'+@nombre_tabla+' WHERE '+ @valores_filtro+')); END;'
    IF @operacion=1
        BEGIN
            EXECUTE sp_executesql @sql
        END
    SELECT @sql
END
GO
/*****************************************************************************\
 * Procedimiento almacenado que permite crear los esquemas.                  *
\*****************************************************************************/
CREATE PROC createSchema
(
    @nombre NVARCHAR(30)
)
AS
DECLARE
    @SQL VARCHAR(100)
BEGIN 
    SET @SQL= 'CREATE SCHEMA '+@nombre
    EXECUTE sp_executesql @SQL
END;
GO
/*******************************************************************************\
 * Vista que permite consultar los nombres de los esquemas existentes en la 
 * base de datos.
\*******************************************************************************/
CREATE VIEW get_schemas AS
SELECT TABLE_SCHEMA FROM INFORMATION_SCHEMA.COLUMNS;
GO
/*******************************************************************************\
 * Vista que permite consultar los nombres de los esquemas existentes en la 
 * base de datos.
\*******************************************************************************/
CREATE VIEW get_table_names AS
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.COLUMNS;
GO

/********************************************************************************\
 *Datos de prueba para la generación de los scripts.
\********************************************************************************/

EXECUTE dbo.genDelete 'GA','usuarios','dbo','dbo', 1; 

/* Ejecuta el procedimiento generador de insertar en tablas*/
EXECUTE dbo.genUpdate 'GA','carros','dbo','dbo';
GO;

/* Ejecuta el procedimiento generador de insertar en tablas*/
EXECUTE dbo.genSelects 'GA','carros','dbo','dbo'
GO;

