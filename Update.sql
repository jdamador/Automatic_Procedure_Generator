CREATE  PROCEDURE genSelects(
    @prefijo VARCHAR (30),
    @nombre_tabla VARCHAR (50),
    @esquema_nombre VARCHAR (30),
    @tipo_operacion VARCHAR (30)
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
    SELECT COLUMN_NAME,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS
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
        EXECUTE sp_executesql @sql
	    PRINT @sql  
END
GO
EXECUTE dbo.genSelects 'GA','carros','dbo','dbo'