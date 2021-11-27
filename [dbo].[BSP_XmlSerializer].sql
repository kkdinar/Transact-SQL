alter procedure [dbo].[BSP_XmlSerializer]
  @xml xml
, @insertTableName varchar(255)
, @tempTableName varchar(255) = ''
as

/*commentBegin 
Группа: ДеСериализация
Документ: ДеСериализация
Назначение: Берет данные из @xml и записывает по столбцам из @insertTableName во временную таблицу @tempTableName. Например @tempTableName = create table #table (id int identity)
Автор: Хабибуллин Д.М.
Дата создания: 21.03.2020
Описание: Процедура превращения xml документа в таблицу и заполнения полученными данными таблицы @tableName(временная таблица без полей, которая будет проальтарена нужными столбцами). XML должен быть вида <rows>...</rows><rows>...</rows>
commentEnd*/

--{ Тестирование
--declare @xml xml = ' <rows><menge>1000</menge><mesto>Москва</mesto><recntxt>2018-01-10</recntxt></rows><rows><menge>1001</menge><mesto>Уфа</mesto><recntxt>2018-01-11</recntxt></rows><rows><menge>1002</menge><mesto>Салават</mesto><recntxt>2018-01-12</recntxt></rows>', @insertTableName varchar(255) ='bn_StatusOC_h',  @tempTableName varchar(255) = '#table'

--if object_id ('TempDB..#table') IS not null drop table #table
--create table #table(id int identity)
--} Тестирование

if object_id ('TempDB..#tableInfo') IS not null drop table #tableInfo

declare @columnName       varchar(255)
      , @vcode            int
      , @sqlSelectColumns varchar(max) = ''
      , @sqlWith          varchar(max) = ''
	  , @sql              varchar(max) = ''

-- Информация о таблице, в котрую будем сохранять результат десериализации @xml
create table #tableInfo (   columnName varchar(255)
						  , columnType varchar(255))

--{ Собираем информацию о столбцах таблицы
insert into #tableInfo (columnName, columnType)
select distinct
       columnName = c.name
     , columnType = case 
					when t.name = 'varchar'
					then t.name + '(8000)'
					when t.name = 'nvarchar'
					then t.name + '(8000)'
					else t.name
					end
from sys.objects as o			
join sys.columns as c on c.object_id = o.object_id 
join sys.types   as t on c.user_type_id = t.system_type_id 
where o.name like (@insertTableName)
--} Собираем информацию о столбцах таблицы

--Собираем название полей через запятую
select @sqlSelectColumns =  STUFF ( (SELECT ',' + columnName  
                                     FROM #tableInfo
                                     FOR XML PATH ('')), 1, 1, '' )

--Собираем название полей и их типов через запятую
select @sqlWith = STUFF ( (SELECT ',' + columnName + ' ' + columnType
                           FROM #tableInfo 
                           FOR XML PATH ('')), 1, 1, '' )

--Добавляем '<n>' для корректной работы sp_xml_preparedocument
select @xml = '<n>'+convert(varchar(max), @xml)+'</n>'

--Добавляем поля во временную таблицу @tempTableName
select @sql = '
alter table ' + @tempTableName + '
add ' + @sqlWith
exec(@sql)

--Собираем окончательный запрос
select @sql = '
declare @xml  xml 
      , @xmlVarchar varchar(max) = ''' + convert(varchar(max), @xml) + '''
      , @hdoc int
select @xml = @xmlVarchar
EXEC sp_xml_preparedocument @hdoc OUTPUT, @xml
insert into ' + @tempTableName + ' ( ' + @sqlSelectColumns + ' )
SELECT ' + @sqlSelectColumns + ' 
FROM OPENXML (@hdoc, ''/n/rows'' , 2) 
WITH( ' + @sqlWith + ' ) 
EXEC sp_xml_removedocument @hdoc'

--select @sql
exec(@sql)

--select * from #table

/*
DROP FUNCTION [dbo].[BFN_XmlSerializer]
GO
drop ASSEMBLY XmlSerializer

create ASSEMBLY XmlSerializer
FROM 'C:\Temp\XmlSerializer.dll'
WITH PERMISSION_SET=UNSAFE;


CREATE FUNCTION [dbo].[BFN_XmlSerializer](@varcharXML [nvarchar](max))
RETURNS TABLE (
	  [A] nvarchar(2000) null
	, [B] nvarchar(2000) null
	, [C] nvarchar(2000) null
	, [D] nvarchar(2000) null
	, [E] nvarchar(2000) null
	, [F] nvarchar(2000) null
	, [G] nvarchar(2000) null
) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [XmlSerializer].[Functions].[GetXMLElements]

http://10.79.188.35 lexwcf
*/
