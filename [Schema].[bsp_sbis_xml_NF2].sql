ALTER procedure [Schema].[bsp_sbis_xml_NF2]
  @docvcode int = null	-- vcode документа
, @show int = 0			-- вывести xml на экран вместо отправки   
as
set nocount on;

/*comment 
Группа: Учет нефтепродуктов в рознице
Документ: Расход нефтепродуктов
Назначение: Создание XML-конверта для СБИС
Автор: Хабибуллин Д.М.
Дата создания: 20.10.2020
Описание: 
commentEnd*/

--{ Тестирование
--allsee 194
--declare @docvcode int = 1244260436
--	  , @show int = 1
--} Тестирование

declare @tdoc           varchar(3)
      , @getdate        datetime = getdate()
	  , @rdate          datetime
	  , @we             int
	  , @tmpf_im_sprxml xml
	  , @tmp0           nvarchar(max)
	  , @text           nvarchar(max)
	  --, @name           nvarchar(1000)
select @tdoc  = tdoc  from [Schema].[veco_prod] where VCode = @docvcode
select @rdate = rdate from [Schema].[veco_prod] where VCode = @docvcode
select @we = 19153530

--{ Проверка данных Получатель
declare @ПолучательИНН varchar(100)
      , @ПолучательКПП varchar(100)

select @ПолучательИНН = ltrim(rtrim(receiver.inn))
     , @ПолучательКПП = COALESCE(([dbo].[EFN_OrgKPP](mainTable.org, @getdate)),(ltrim(rtrim(receiver.kpp))))
from [Schema].[veco_prod] as mainTable 
join [dbo].[Spr_Org] as receiver on receiver.vcode = mainTable.org
where mainTable.VCode = @docvcode
--select @ПолучательИНН, @ПолучательКПП
if(@ПолучательИНН is null) raiserror('В справочнике организаций нет данных о "Получатель ИНН(Организация(дебет))"',16,1)
if(@ПолучательКПП is null) raiserror('В справочнике организаций нет данных о "Получатель КПП(Организация(дебет))"',16,1)
--} Проверка данных Получатель

--{ Проверка данных Отправитель
declare @ОтправительИНН varchar(100) 
      , @ОтправительКПП varchar(100)

declare @kppTable table(Podr int, KPP varchar(10))
insert into @kppTable (Podr, KPP)
values (16350886,'027801001') -- РО - Башкирия
	 , (16350916,'665845004') -- РО - Екатеринбург
	 , (16350946,'561045007') -- РО - Оренбург
	 , (16350976,'183145001') -- РО - Удмуртия
 	 , (33449386,'132745004') -- РО - Приволжье
 	 , (34318996,'745245002') -- РО - Челябинск

select @ОтправительИНН = ltrim(rtrim(sender.inn))
     , @ОтправительКПП = COALESCE(kpp.KPP, ([dbo].[EFN_OrgKPP](mainTable.we, @getdate)), (ltrim(rtrim(sender.kpp))))
from [Schema].[veco_prod] as mainTable 
join [dbo].[Spr_Org]				as sender	on sender.vcode = mainTable.we
left join @kppTable					as kpp		on kpp.Podr = mainTable.code_podr
where mainTable.VCode = @docvcode
--select @ОтправительИНН, @ОтправительКПП
if(@ОтправительИНН is null) raiserror('В справочнике организаций нет данных о "Отправитель ИНН(Своя организация)"',16,1)
if(@ОтправительКПП is null) raiserror('В справочнике организаций нет данных о "Отправитель КПП(Своя организация)"',16,1)
--} Проверка данных Отправитель

--{ Вложение ИмяФайла
declare @fileName table (Name varchar(1000), VCode bigint)
insert into @fileName(Name, VCode)
values ('ON_NSCHFDOPPR_' + @ПолучательИНН + @ПолучательКПП + '_' + @ОтправительИНН + @ОтправительКПП + '_' +  convert(varchar(10),@getdate,112), @docvcode)
     , ('DP_TOVTORGPR_' + @ПолучательИНН + @ПолучательКПП + '_' + @ОтправительИНН + @ОтправительКПП + '_' +  convert(varchar(10),@getdate,112), @docvcode)
--} Вложение ИмяФайла

--{ Проверка данных СвСчФакт НомерСчФ
declare @НомерСчФ varchar(1000)
select @НомерСчФ = ltrim(rtrim(mainTable.norder)) 
from [Schema].[veco_prod] as mainTable 
where mainTable.VCode = @docvcode
--select @НомерСчФ
if(@НомерСчФ is null) raiserror('В документе нет данных о "Счет-фактура №"',16,1)
--} Проверка данных СвСчФакт НомерСчФ

--{ ИспрСчФ
declare @НомИспрСчФ       varchar(3)
      , @ДатаИспрСчФ      datetime
	  , @ДефНомИспрСчФ    varchar(1)
	  , @ДефДатаИспрСчФ   varchar(1)
	  , @НомерИсправления varchar(3)

select @НомерИсправления = isnull(Text12,'') from [Schema].[veco_prod] where VCode = @docvcode
if (@НомерИсправления <> '')
begin
 select @НомИспрСчФ     = @НомерИсправления
      , @ДатаИспрСчФ    = convert(varchar(10),mainTable.[date],104)
	  , @ДефНомИспрСчФ  = '-'
	  , @ДефДатаИспрСчФ = '-'
from [Schema].[veco_prod] as mainTable 
where mainTable.VCode = @docvcode
end
--} ИспрСчФ

--{ Проверка данных СвЮЛУч (Своя организация)
declare @СвПродНаимОрг         nvarchar(500) 
      , @СвПродАдресИндекс     nvarchar(500)
	  , @СвПродАдресКодРегион  nvarchar(500)
	  , @СвПродАдресРайон      nvarchar(500)
	  , @СвПродАдресГород      nvarchar(500)
	  , @СвПродАдресНаселПункт nvarchar(500)
	  , @СвПродАдресУлица      nvarchar(500)
	  , @СвПродАдресДом        nvarchar(500)
	  , @СвПродАдресКорпус     nvarchar(500)
	  , @СвПродАдресКварт      nvarchar(500)
	  , @СвПродАдресКодСтр     nvarchar(500)
	  , @СвПродАдресАдрТекст   nvarchar(500)

select @СвПродНаимОрг         = dbo.EFN_Org_Fullname(mainTable.we, @getdate)
     , @СвПродАдресИндекс     = isnull(adr.SapPost,'')
	 , @СвПродАдресКодРегион  = isnull(adr.SapRegion,'')
	 , @СвПродАдресРайон      = ''
	 , @СвПродАдресГород      = isnull(adr.SapCity,'')
	 , @СвПродАдресНаселПункт = isnull(adr.SapCity,'')
	 , @СвПродАдресУлица      = isnull(adr.SapStreet,'')
	 , @СвПродАдресДом        = isnull(adr.SapDom,'')
	 , @СвПродАдресКорпус     = isnull(adr.SapKorp,'')
	 , @СвПродАдресКварт      = isnull(adr.SapKvart,'')
	 , @СвПродАдресКодСтр     = isnull(ourOrg.country,'643')
	 , @СвПродАдресАдрТекст   = ourOrg.adr1
from [Schema].[veco_prod] as mainTable
left join [dbo].[VLexOrg]           as ourOrg    on ourOrg.VCode = mainTable.we
outer apply (
             select top 1 SapPost, SapRegion, SapCity, SapStreet, SapDom, SapKorp, SapKvart
             from [dbo].[LexPdadr]
			 where pcode = mainTable.we
			 and cuser = 'Импорт из КСС'
             ) adr 
where mainTable.VCode = @docvcode

if(@СвПродНаимОрг is null) raiserror('В документе нет данных о НаимОрг организации в поле "Своя организация"',16,1)
if(@СвПродАдресКодРегион is null) raiserror('В справочнике организаций нет данных о КодРегион организации в поле "Своя организация"',16,1)
if(@СвПродНаимОрг is null) raiserror('В документе нет данных о НаимОрг организации в поле "Своя организация"',16,1)
if(@СвПродАдресАдрТекст is null) raiserror('В документе нет данных о АдрТекст организации в поле "Своя организация"',16,1)
--} Проверка данных СвЮЛУч (Своя организация)

--{ Проверка данных Грузоотправителя
declare @ГрузОтНаимОрг  nvarchar(500)
      , @ГрузОтИННЮЛ    nvarchar(500)
	  , @ГрузОтКПП      nvarchar(500)
	  , @ГрузОтАдрТекст nvarchar(500)
	  , @Вариант_реализации int
	  , @Грузоотправитель   int

select @Вариант_реализации = isnull(int4,0) from [Schema].[veco_prod] where VCode = @docvcode
select @Грузоотправитель   = gruzotp        from [Schema].[veco_prod] where VCode = @docvcode

-- Если Вариант реализации = 3113908(Реализация нефтепродуктов мелким оптом)
if(@Вариант_реализации = 3113908)
begin
 select  @ГрузОтНаимОрг  = case
                           when gruzotp.fullname is not null
						   then gruzotp.fullname
						   else 'ООО "Башнефть-Розница" ' + replace(ltrim(rtrim(podr.NamePodr)), '- ', '"') + '" ' + gruzotpUa.[Name]
						   end
       , @ГрузОтИННЮЛ    = case
                           when gruzotp.inn is not null
						   then gruzotp.inn
						   else ltrim(rtrim(sender.inn))
						   end
 	   , @ГрузОтКПП      = case 
	                       when gruzotp.kpp is not null
						   then	gruzotp.kpp
						   else COALESCE(([dbo].[EFN_OrgKPP](mainTable.we, @getdate)),(ltrim(rtrim(sender.kpp))))
						   end
 	   , @ГрузОтАдрТекст = case 
	                       when farm.factAddress is not null
						   then farm.factAddress
						   else podr.AddressTXT
						   end

 from [Schema].[veco_prod]    as mainTable
 left join [Schema].[vecotankfarm] as farm      on farm.vcode      = mainTable.gruzotp
 left join [dbo].[Spr_Org]              as gruzotp   on gruzotp.VCode   = farm.[owner]
 left join [dbo].[Spr_Org]              as sender    on sender.vcode    = mainTable.we
 left join [dbo].[UniAnalit]            as gruzotpUa on gruzotpUa.VCode = mainTable.gruzotp
 left join [Schema].[EFn_prod_AccessDocSubCodePodr](@getdate,194,null,null,null) as podr on podr.VCode = mainTable.gruzotp
 where mainTable.VCode = @docvcode
end
else
begin
 raiserror('"Вариант реализации" выбран НЕ "Реализация нефтепродуктов мелким оптом"',16,1)
 return
end
if(@ГрузОтНаимОрг  is null) raiserror('В справочнике организаций нет данных о наименовании организации в поле "Грузоотправитель"',16,1)
if(@ГрузОтИННЮЛ    is null) raiserror('В справочнике организаций нет данных о ИНН организации в поле "Грузоотправитель"',16,1)
if(@ГрузОтКПП      is null) raiserror('В справочнике организаций нет данных о КПП организации в поле "Грузоотправитель"',16,1)
if(@ГрузОтАдрТекст is null) raiserror('В справочнике организаций нет данных о адресе организации в поле "Грузоотправитель"',16,1)
--} Проверка данных Грузоотправителя

--{ Проверка данных Грузополучателя
declare @ГрузПолучНаимОрг  nvarchar(500)
      , @ГрузПолучИННЮЛ    nvarchar(500)
	  , @ГрузПолучКПП      nvarchar(500)
	  , @ГрузПолучИННФЛ    nvarchar(500)
	  , @ГрузПолучФамилия  nvarchar(500)
	  , @ГрузПолучИмя      nvarchar(500)
	  , @ГрузПолучОтчество nvarchar(500)
	  , @ГрузПолучАдрТекст nvarchar(500)
	  , @ГрузПолучКодСтр   nvarchar(500)
      , @Грузополучатель   int
	  , @ГрузополучательИП bit = 0

select @Грузополучатель = org from [Schema].[veco_prod] where VCode = @docvcode

if(isnull((select s.fl from vLexOrg s where s.vcode = @Грузополучатель), 0) <> 1) -- Грузополучатель Организация
begin
 select @ГрузПолучНаимОрг = case when mainTable.org = 3948992 
							then 'Филиал ООО "НОВАТЭК-АЗК" в г. Златоусте Челябинской области' 
							else dbo.EFN_Org_Fullname(case 
												when gruzpoluch.vcode in (1830322500,1830322290)
												then gruzpoluch.vcode
												 when dbo.LexGetPlatOrg(gruzpoluch.vcode) in (1512824,1812453180,5255458,1779365,1830322500) 
												 then gruzpoluch.vcode
												 when gruzpoluch.vcode in (1814880690) -- Транснефтепродукт АО
												 then isnull(mainTable.int12,mainTable.org)  -- Транснефтепродукт                
                                                 else dbo.LexGetPlatOrg(gruzpoluch.vcode) 
												 end
												 , mainTable.date) 
												 end

	, @ГрузПолучИННЮЛ     = gruzpoluch.inn
	, @ГрузПолучКПП       = case when mainTable.org=3948992 then '740443001' else dbo.EFN_OrgKPP(gruzpoluch.vcode, mainTable.date) end	
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as gruzpoluch on gruzpoluch.VCode= isnull(mainTable.int12, mainTable.org)
 where mainTable.VCode = @docvcode

 if(@ГрузПолучНаимОрг  is null) raiserror('В справочнике организаций нет данных о наименовании организации в поле "Грузополучатель"',16,1)
 if(@ГрузПолучИННЮЛ    is null) raiserror('В справочнике организаций нет данных о ИНН организации в поле "Грузополучатель"',16,1)
 if(@ГрузПолучКПП      is null) raiserror('В справочнике организаций нет данных о КПП организации в поле "Грузополучатель"',16,1)
end
if(isnull((select fl from vLexOrg s where s.vcode = @Грузополучатель), 0) = 1) -- Грузополучатель ИП
begin
 select @ГрузПолучИННФЛ   = org.inn
      , @ГрузПолучФамилия = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then 'ИП ' + flc.Fam 
							else left(org.name, CHARINDEX(' ', org.name))
							end	
	  , @ГрузПолучИмя     = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.im 
							else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
							end
	 , @ГрузПолучОтчество = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Otch
							else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
							end
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as org on org.VCode  = mainTable.org
 left join [dbo].[VBn_kadry_FLuni]   as flc on flc.treevc = org.code_fl
 where mainTable.VCode = @docvcode
 
 if(@ГрузПолучИННФЛ    is null) raiserror('В справочнике организаций нет данных о ИНН юрлица в поле "Грузополучатель"',16,1)
 if(@ГрузПолучФамилия  is null) raiserror('В справочнике организаций нет данных о Фамиилии юрлица в поле "Грузополучатель"',16,1)
 if(@ГрузПолучИмя      is null) raiserror('В справочнике организаций нет данных о Имени юрлица в поле "Грузополучатель"',16,1)
 if(@ГрузПолучОтчество is null) raiserror('В справочнике организаций нет данных об Отчестве юрлица в поле "Грузополучатель"',16,1)

 select @ГрузополучательИП = 1 -- для проверки в return
end

select @ГрузПолучАдрТекст = isnull(nullif([dbo].[efn_GetAdr] (org.vcode, @rdate, 11858, 0),''), [dbo].[efn_GetAdr] (org.vcode, @rdate, 11857, 0))
     , @ГрузПолучКодСтр   = case when isnull(org.country,0)=0 then '643' else org.country end
from [Schema].[veco_prod] as mainTable
left join [dbo].[VLexOrg]           as org on org.VCode = mainTable.org
where mainTable.VCode = @docvcode

if(@ГрузПолучАдрТекст is null) raiserror('В справочнике организаций нет данных о Адресе организации в поле "Грузополучатель"',16,1) 
--} Проверка данных Грузополучателя

--{ Проверка данных СвПРД
declare @tableSender table (norder nvarchar(500), date nvarchar(500))

insert into @tableSender (norder, date)
select norder = prd.norder 
     , date   = case 
	            when prd.datadoc is null or prd.datadoc = '19000101'
				then convert(varchar(10),mainTable.[Date],104)
				else convert(varchar(10),prd.datadoc,104)
				end
from [Schema].[veco_prod] as mainTable
outer apply [Schema].[bfn_platdocforreport_sbis](mainTable.VCode, @rdate) as prd
where mainTable.VCode = @docvcode

if not exists (select 1 from @tableSender) raiserror('В документе нет данных о СвПРД/НомерПРД или СвПРД/ДатаПРД',16,1)
--} Проверка данных СвПРД

--{ Проверка данных Сведения о покупателе
declare @СвПокупНаимОрг    nvarchar(500)
      , @СвПокупИННЮЛ      nvarchar(500)
	  , @СвПокупКПП        nvarchar(500)
	  , @СвПокупИННФЛ      nvarchar(500)
	  , @СвПокупФамилия    nvarchar(500)
	  , @СвПокупИмя        nvarchar(500)
	  , @СвПокупОтчество   nvarchar(500)
	  , @СвПокупАдрТекст   nvarchar(500)
	  , @СвПокупКодСтр     nvarchar(500)
      , @Покупатель        int
	  , @ПокупательИП      bit = 0

select @Покупатель = org from [Schema].[veco_prod] where VCode = @docvcode

if(isnull((select s.fl from vLexOrg s where s.vcode = @Покупатель), 0) <> 1) -- Покупатель Организация
begin
 select @СвПокупНаимОрг = dbo.EFN_Org_Fullname(case 
											   when dbo.LexGetPlatOrg(buyer.vcode) in (1512824,1812453180) 
											   then buyer.vcode 
											   else dbo.LexGetPlatOrg(buyer.vcode) 
											   end
											   , mainTable.date)
		, @СвПокупИННЮЛ = buyer.inn
		, @СвПокупКПП   = [dbo].[EFN_OrgKPP](buyer.vcode, mainTable.date)
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as buyer    on buyer.VCode    = (case when dbo.lexgetplatorg(mainTable.int12) = mainTable.org then isnull(mainTable.int12, mainTable.org) else isnull(mainTable.org, mainTable.int12) end)
 left join [dbo].[VLexOrg]           as buyerAdr on buyerAdr.vcode = isnull((select plat from spr_org where vcode = mainTable.org ),mainTable.org)--isnull([dbo].[EFN_Org_plat](mainTable.org), mainTable.org)
 where mainTable.VCode = @docvcode
 if(@СвПокупНаимОрг is null) raiserror('В справочнике организаций нет данных о наименовании организации в поле "Организация(дебет)"',16,1) 
 if(@СвПокупИННЮЛ   is null) raiserror('В справочнике организаций нет данных о ИНН организации в поле "Организация(дебет)"',16,1) 
 if(@СвПокупКПП     is null) raiserror('В справочнике организаций нет данных о КПП организации в поле "Организация(дебет)"',16,1) 
end

if(isnull((select s.fl from vLexOrg s where s.vcode = @Покупатель),0) = 1) -- Покупатель ИП
begin
 select @СвПокупИННФЛ   = org.inn
      , @СвПокупФамилия = case 
						  when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
						  then 'ИП ' + flc.Fam 
						  else left(org.name,CHARINDEX(' ',org.name))
						  end
	, @СвПокупИмя = case 
					when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
					then flc.im 
					else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
					end
	, @СвПокупОтчество = case 
						 when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
						 then flc.Otch
						 else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
						end
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as org on org.VCode  = mainTable.org
 left join [dbo].[VBn_kadry_FLuni]   as flc on flc.treevc = org.code_fl
 where mainTable.VCode = @docvcode
 if(@СвПокупИННФЛ    is null) raiserror('В справочнике организаций нет данных о ИНН юрлица в поле "Организация(дебет)"',16,1)
 if(@СвПокупФамилия  is null) raiserror('В справочнике организаций нет данных о Фамилии юрлица в поле "Организация(дебет)"',16,1)
 if(@СвПокупИмя      is null) raiserror('В справочнике организаций нет данных о Имени юрлица в поле "Организация(дебет)"',16,1)
 if(@СвПокупОтчество is null) raiserror('В справочнике организаций нет данных об Отчестве юрлица в поле "Организация(дебет)"',16,1)
 select @ПокупательИП = 1
end

select @СвПокупАдрТекст = isnull(buyerAdr.adr1, buyerAdr.adr2)
     , @СвПокупКодСтр   = case when isnull(buyerAdr.country,0)=0 then '643' else buyerAdr.country end --isnull(buyerAdr.country, '643')
from [Schema].[veco_prod] as mainTable
left join [dbo].[VLexOrg]           as buyerAdr on buyerAdr.vcode = isnull((select plat from spr_org where vcode = mainTable.org ), mainTable.org)--isnull([dbo].[EFN_Org_plat](mainTable.org), mainTable.org)
where mainTable.VCode = @docvcode

if(@СвПокупАдрТекст is null) raiserror('В справочнике организаций нет данных о Адресе организации в поле "Организация(дебет)"',16,1) 
--} Проверка данных Сведения о покупателе

--{ Документ подтверждения отгрузки
/*declare @tableDoc table (НаимДокОтгр nvarchar(500), НомДокОтгр nvarchar(500), ДатаДокОтгр nvarchar(500))

insert into @tableDoc (НаимДокОтгр, НомДокОтгр, ДатаДокОтгр)
select   НаимДокОтгр = '№ п/п ' + convert(nvarchar(500),ROW_NUMBER () OVER(ORDER BY m.vcode))
	   , НомДокОтгр = isnull(mainTable.Nomer,'')
	   , ДатаДокОтгр = convert(varchar(10), mainTable.Rdate,104)
from [Schema].[veco_prod] as mainTable
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode 
where mainTable.VCode = @docvcode*/
declare @docmatVcodeCount nvarchar(500) --Всего пунктов
select @docmatVcodeCount = count(*)
from [Schema].[veco_prodMat] as m           
where m.pcode = @docvcode

declare   @НаимДокОтгр nvarchar(500)
		, @НомДокОтгр nvarchar(500)
		, @ДатаДокОтгр nvarchar(500)

select   @НаимДокОтгр = '№ п/п 1-' + @docmatVcodeCount
	   , @НомДокОтгр = isnull(mainTable.Nomer,'')
	   , @ДатаДокОтгр = convert(varchar(10), mainTable.Rdate,104)
from [Schema].[veco_prod] as mainTable
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode 
where mainTable.VCode = @docvcode
--} Документ подтверждения отгрузки

--{ Сбор данных Текст Добавил Вадим 20.01.2020 по заявке о пропадании штрихкода в с/ф
declare @ИдВизуализации nvarchar(500)
      , @ОснованиеДата  nvarchar(500)
	  , @ОснованиеНомер nvarchar(500)
	  , @ШтрихКод		nvarchar(500)
	  , @ИнфПередТабл	nvarchar(500)
	  , @НаимПокуп		nvarchar(500)
	  , @НаимГрузПолуч	nvarchar(500)
	  , @ТоварНаклНомер nvarchar(500)
	  , @ТоварНаклДата	nvarchar(500)

declare @textInf table(id varchar(100), vl varchar (500))

select @ИдВизуализации = case 
                         when @Вариант_реализации = 3113908 -- Вариант реализации (Реализация нефтепродуктов мелким оптом)
                         then 'Башнефть-Розница_МО' 
		                 else 'Башнефть-Розница' 
		                 end
	 , @ОснованиеДата  = convert(varchar(10),mainTable.[date],104)
	 , @ОснованиеНомер = mainTable.norder
	 , @ШтрихКод       = (
	                      select top 1 bar.barcode
						  from [sea_schema].[eco_barCodes_mat_h] bar                 
                          where bar.DocVcode = mainTable.vcode and bar.DocTdoc = 'NF2' and bar.SEATdoc = 'SA'                                
                          order by DocWdate desc 
	                     )
	 , @ИнфПередТабл   = 'Договор(контракт):'+isnull(d.text4,'') + case when d.text4 is null then '' else '/' end + u.Name
	 , @НаимПокуп      = isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  isnull([dbo].[EFN_Org_plat](mainTable.org),mainTable.org)),'')
	 , @НаимГрузПолуч  =  case when mainTable.org=3948992 then 'Филиал ООО "НОВАТЭК-АЗК" в г. Златоусте Челябинской области' else isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  isnull([dbo].[EFN_Org_plat](mainTable.int12),mainTable.int12)),'') end
	 , @ТоварНаклНомер = mainTable.nomer
	 , @ТоварНаклДата = convert(varchar(10), mainTable.Rdate,104)
from [Schema].[veco_prod] as mainTable
left join [dbo].[lexdogovor]        as d on d.treevc = mainTable.dogovor
left join [dbo].[unianalit]         as u on u.VCode  = d.treevc
where mainTable.VCode = @docvcode

insert into @textInf (id, vl) 
values ('ИдВизуализации', @ИдВизуализации)
     , ('ОснованиеДата',  @ОснованиеДата )
	 , ('ОснованиеНомер', @ОснованиеНомер)
	 , ('ШтрихКод',       @ШтрихКод      )
	 , ('ИнфПередТабл',   @ИнфПередТабл  )
	 , ('НаимПокуп',      @НаимПокуп     )
	 , ('НаимГрузПолуч',  @НаимГрузПолуч ) 
	 , ('ТоварНаклНомер', @ТоварНаклНомер) 
	 , ('ТоварНаклДата',  @ТоварНаклДата )
if(@ИдВизуализации is null) raiserror('В документе нет данных в поле "Вариант реализации"',16,1) 
if(@ОснованиеДата  is null) raiserror('В документе не заполнена дата',16,1) 
if(@ОснованиеНомер is null) raiserror('В документе нет данных в поле "Счет-фактура №"',16,1) 
if(@ШтрихКод       is null) raiserror('В справочнике нет данных о Штрихкоде',16,1) 
if(@ИнфПередТабл   is null) raiserror('В справочнике договоров нет данных о договоре',16,1) 
if(@НаимПокуп      is null) raiserror('В справочнике организаций нет данных о Наименовании организации в поле "Организация(дебет)"',16,1) 
if(@НаимГрузПолуч  is null) raiserror('В справочнике организаций нет данных о Наименовании организации в поле "Грузополучатель"',16,1) 
--} Сбор данных Текст



--{ Сбор данных Сведения о товаре
declare @productInformation table (  id             nvarchar(500)
                                   , name           nvarchar(500)
								   , OKEI           varchar(3)
								   , number         nvarchar(500)
								   , price          nvarchar(500)
								   , rateWithoutNDS nvarchar(500)
								   , rate           nvarchar(500)
								   , rateSum        nvarchar(500)
								   , excise         nvarchar(500)
								   , sumexcise      nvarchar(500)
								   , sumWithoutNDS  nvarchar(500)
								   , sumCash        nvarchar(500)
								   , НаимЕдИзм      nvarchar(500)
                                  )
insert into @productInformation (id, name, OKEI, number, price, rateWithoutNDS, rate, rateSum, excise, sumexcise, sumWithoutNDS, sumCash, НаимЕдИзм)
select 
   id             = ROW_NUMBER() over(order by m.MatCode, m.text1, m.Text5,  m.pnds, m.OZena2)
 , name           = case      --дублируется гост в продуктах    
                    when m.text1 like '%'+( select top 1 gost_vid  from bn_product where vcode = m.matcode)+'%' and ( select top 1 gost_vid  from bn_product where vcode = m.matcode) is not null    
                    then substring(m.text1,0,CHARINDEX(( select top 1 gost_vid  from bn_product where vcode = m.matcode),m.text1))    
                    else m.text1    
                    end  
                    + isnull((select top 1 full_gost=' '+isnull(gost_vid,'')+' '+isnull(gost,'')  from bn_product where vcode = m.matcode),'') 
 , OKEI           = case when @Вариант_реализации = 3113908 then '168' else '112' end 
 , number         = case 
                    when @Вариант_реализации = 3113908 
 				    then rtrim(ltrim(convert(varchar(50),convert(float,round(m.kolvo1,3)))))               
                    else rtrim(ltrim(convert(varchar(50),convert(money,round(m.kolvo,2))))) 
 				    end 
 , price          = rtrim(ltrim(convert(varchar(50),convert(money,round(convert(money,m.ozena2*100/120),2))))) 
 , rateWithoutNDS = rtrim(ltrim(convert(varchar(50),round(m.SumBNDSRsh,2)))) 
 , rate           = convert(varchar(8), m.PNDS) + '%' 
 , rateSum        = rtrim(ltrim(convert(varchar(50),round(m.SumSNDSRsh,2))))
 , excise         = case when round(isnull(m.summa,0),2) = 0 then 'без акциза' else null end
 , sumexcise      = case when round(isnull(m.summa,0),2) <> 0 then rtrim(ltrim(convert(varchar(50), round(isnull(m.summa,0),2)))) else null end 
 , sumWithoutNDS  = case when round(isnull(m.SumNDSRsh,0),2) = 0 then 'без НДС' else null end
 , sumCash        = case when round(isnull(m.SumNDSRsh,0),2) <> 0 then rtrim(ltrim(convert(varchar(50),round(isnull(m.SumNDSRsh,0),2)))) else null end
 , НаимЕдИзм      = case when @Вариант_реализации = 3113908 then 'т' else 'л' end 

from [Schema].[veco_prod]    as mainTable                                
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode
where mainTable.vcode = @docvcode
if not exists(select 1 from @productInformation) raiserror('В табличной части документа нет данных о товаре',16,1)

declare @СтТовУчНалВсего  nvarchar(500)
      , @СтТовБезНДС      nvarchar(500)
      , @СтТовСумНал      nvarchar(500)
	  , @СтТовБезНДСВсего nvarchar(500)
select @СтТовУчНалВсего = rtrim(ltrim(convert(varchar(50),round(sum(m.SumSNDSRsh),2))))
     , @СтТовБезНДС = case when round(sum(isnull(m.SumNDSRsh,0)),2) = 0 then 'без НДС' else null end 
     , @СтТовСумНал = case when round(sum(isnull(m.SumNDSRsh,0)),2) <> 0 then rtrim(ltrim(convert(varchar(50),round(sum(isnull(m.SumNDSRsh,0)),2)))) else null end
	 , @СтТовБезНДСВсего = rtrim(ltrim(convert(varchar(50),round(sum(m.SumBNDSRsh),2))))
from [Schema].[veco_prod]    as mainTable                               
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode                                
where mainTable.vcode = @docvcode
if(@СтТовУчНалВсего is null) raiserror('В табличной части документа нет данных о сумме',16,1) 
if(@СтТовСумНал is null and @СтТовБезНДС is null) raiserror('В табличной части документа нет данных о сумме',16,1)
--} Сбор данных Сведения о товаре

--{ Сбор данных Товарная накладная ГрузОтпр
declare @СвДокПТПрГрузОтпрОКПО        nvarchar(500)
      , @СвДокПТПрГрузОтпрСвЮЛНаимОрг nvarchar(500)
	  , @СвДокПТПрГрузОтпрСвЮЛИННЮЛ   nvarchar(500)
	  , @СвДокПТПрГрузОтпрСвЮЛКПП     nvarchar(500)
	  , @СвДокПТПрГрузОтпрАдрТекст    nvarchar(500)
	  , @СвДокПТПрГрузОтпрКодСтр      nvarchar(500)
	  , @СвДокПТПрГрузОтпрТлф         nvarchar(500)
	  , @СвДокПТПрГрузОтпрНомерСчета  nvarchar(500)
	  , @СвДокПТПрГрузОтпрНаимБанк    nvarchar(500)
	  , @СвДокПТПрГрузОтпрБИК         nvarchar(500)
	  , @СвДокПТПрГрузОтпрКорСчет     nvarchar(500)
declare @OwrNeftebaza table(vcode int)
insert into @OwrNeftebaza(vcode)
select t.UA5
from Schema.Eco_prod_SprNoFilter t
where t.UA5 is not null and t.ChCode = 'SubFilials2' and t.CodePlan = 6

select @СвДокПТПрГрузОтпрОКПО = case 
                       when @Вариант_реализации = 3113908 -- Вариант реализации (Реализация нефтепродуктов мелким оптом)
					        and @Грузоотправитель not in (select vcode from @OwrNeftebaza)--(104579626,101026606,104579176,16354456,16368886,16370056,16370866,16370986,16371286,104556886,104557126,104557336,104567326,104567476,104569876,104579386,104579746,104582476,104582656,16368436) -- 104579626 - Мурсалимкинская нефтебаза (okpo своей организации)  и др. НЕФТЕБАЗЫ
					   then (select s.okpo 
					         from Spr_Org s 
							 join Schema.EFn_TankFarmsFull (@rdate, 194, mainTable.gruzotp) as p1 on s.vcode = p1.[owner])
                       else (select okpo from vLexOrg where vcode = @we) 
					   end
from [Schema].[veco_prod] as mainTable 
where mainTable.vcode = @docvcode 
if(@СвДокПТПрГрузОтпрОКПО is null) raiserror('В справочнике организаций нет данных о ОКПО организации в поле "Грузоотправитель"',16,1)

--select @Вариант_реализации = isnull(int4,0) from [Schema].[veco_prod] where VCode = @docvcode
--select @Грузоотправитель   = gruzotp from [Schema].[veco_prod] where VCode = @docvcode 
if(@Вариант_реализации = 3113908 and exists ( select 1 from dbo.UniAnalit where VCode = @Грузоотправитель and AType = 'Склад' ))
begin
 select @СвДокПТПрГрузОтпрСвЮЛНаимОрг = o.fullname
	  , @СвДокПТПрГрузОтпрСвЮЛИННЮЛ   = ltrim(rtrim(o.inn))
	  , @СвДокПТПрГрузОтпрСвЮЛКПП     = ltrim(rtrim(o.kpp))
	  , @СвДокПТПрГрузОтпрАдрТекст    = farm.factAddress
	  , @СвДокПТПрГрузОтпрКодСтр      = '643'
	  , @СвДокПТПрГрузОтпрНомерСчета  = ltrim(rtrim(acc.account))
	  , @СвДокПТПрГрузОтпрНаимБанк    = ltrim(rtrim(acc.bankname))
	  , @СвДокПТПрГрузОтпрБИК         = ltrim(rtrim(sb.MFO))
	  , @СвДокПТПрГрузОтпрКорСчет     = ltrim(rtrim(sb.ksch))
 from [Schema].[veco_prod] as mainTable 
 left join Schema.vecotankfarm  as p    on p.vcode = mainTable.gruzotp
 left join spr_org                   as o    on p.[owner] = o.vcode 
 left join Schema.vecotankfarm  as farm on farm.vcode = mainTable.gruzotp
 left join vLexorg_accounts          as acc  on o.vcode = acc.pcode and acc.active = 1
 left loop join spr_bank             as sb   on acc.bank = sb.code
 where mainTable.vcode = @docvcode
 if(@СвДокПТПрГрузОтпрСвЮЛНаимОрг is null) raiserror('В справочнике организаций нет данных о наименовани организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрСвЮЛИННЮЛ   is null) raiserror('В справочнике организаций нет данных о ИНН организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрСвЮЛКПП     is null) raiserror('В справочнике организаций нет данных о КПП организации в поле "Грузоотправитель"',16,1) 
 if(@СвДокПТПрГрузОтпрАдрТекст    is null) raiserror('В справочнике организаций нет данных о адресе организации в поле "Грузоотправитель"',16,1) 
 if(@СвДокПТПрГрузОтпрНомерСчета  is null) raiserror('В справочнике организаций нет данных о Номере счёта организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрНаимБанк    is null) raiserror('В справочнике нет данных о Наименовании банка организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрБИК         is null) raiserror('В справочнике нет данных о БИК банка организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрКорСчет     is null) raiserror('В справочнике нет данных о Кор счёте банка организации в поле "Грузоотправитель"',16,1)
end

else
begin
 select @СвДокПТПрГрузОтпрСвЮЛНаимОрг = 'ООО "Башнефть-Розница" '+replace(ltrim(rtrim(p.NamePodr)), '- ', '"') + '" ' + gruzotpUa.Name    
      , @СвДокПТПрГрузОтпрСвЮЛИННЮЛ = (select s.inn from vLexOrg s where s.vcode = @we) 
      , @СвДокПТПрГрузОтпрСвЮЛКПП = 
	   (
	     select top 1 kpp = coalesce (p.KPP, ss.KPP, '')                
         from Schema.EFn_prod_AccessDocCodePodr (@getdate, 194, 0, null) as p                
         join dbo.Spr_Org as ss with (nolock) on ss.VCode = p.OrgCode                
         where p.VCode = mainTable.Code_Podr
        )
	   , @СвДокПТПрГрузОтпрАдрТекст = p.AddressTXT
	   , @СвДокПТПрГрузОтпрКодСтр = (select case when isnull(s.country,'643')=0 then '643' else s.country end from  vLexOrg s where s.vcode = @we) 
	   , @СвДокПТПрГрузОтпрНомерСчета = (   
                                         select top 1 acc.account    
                                         from vLexorg_accounts acc     
                                         where acc.vcode  = (case 
										                     when @Вариант_реализации = 3113908     
                                                             then 808278226     
                                                             else (select p.account    
                                                                   from Schema.EFn_prod_AccessDocSubCodePodr(@getdate,194,null,null,null) as p              
                                                                   where p.VCode = (case 
																                    when @Вариант_реализации = 3113908 
																					then @Грузоотправитель 
																					else mainTable.Code_Podr 
																					end)      
                                                                         and p.CodePodr = mainTable.Code_Podr --!!!!!!!!!!!!       
                                                                  )    
															end)
	                                     )
	  , @СвДокПТПрГрузОтпрНаимБанк = oa.bankName
	  , @СвДокПТПрГрузОтпрБИК      = oa.bik
	  , @СвДокПТПрГрузОтпрКорСчет  = oa.korSchet
 from [Schema].[veco_prod] as mainTable
 join [Schema].[EFn_prod_AccessDocSubCodePodr](@getdate,194,null,null,null) as p on p.VCode = (case when @Вариант_реализации = 3113908 then mainTable.gruzotp else mainTable.Code_Podr end)  
 left join [dbo].[unianalit] as gruzotpUa on gruzotpUa.VCode = mainTable.gruzotp
 outer apply ( 
              select top 1 bankName = acc.bankname + ' г. ' + sb.gorod
                         , bik      = acc.bik
						 , korSchet = sb.ksch              
               from vLexorg_accounts acc     
               left loop JOIN spr_bank sb on acc.bank=sb.code       
               where acc.vcode  = (case 
			                       when @Вариант_реализации = 3113908     
                                   then 808278226     
                                   else (select p.account    
                                        from Schema.EFn_prod_AccessDocSubCodePodr(@getdate,194,null,null,null) as p                where p.VCode = (case 
										                 when @Вариант_реализации = 3113908 
														 then mainTable.gruzotp 
														 else mainTable.Code_Podr 
														 end)      
                                         and p.CodePodr = mainTable.Code_Podr --!!!!!!!!!!!!!!!!!       
                                         )  
									end) 
                 ) as oa
 where mainTable.vcode = @docvcode                                     
 if(@СвДокПТПрГрузОтпрСвЮЛНаимОрг is null) raiserror('В справочнике организаций нет данных о наименовани организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрСвЮЛИННЮЛ   is null) raiserror('В справочнике организаций нет данных о ИНН организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрСвЮЛКПП     is null) raiserror('В справочнике организаций нет данных о КПП организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрАдрТекст    is null) raiserror('В справочнике организаций нет данных о адресе организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрНомерСчета  is null) raiserror('В справочнике организаций нет данных о Номере счёта организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрНаимБанк    is null) raiserror('В справочнике нет данных о Наименовании банка организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрБИК         is null) raiserror('В справочнике нет данных о БИК банка организации в поле "Грузоотправитель"',16,1)
 if(@СвДокПТПрГрузОтпрКорСчет     is null) raiserror('В справочнике нет данных о Кор счёте банка организации в поле "Грузоотправитель"',16,1)
end
select @СвДокПТПрГрузОтпрТлф = case when mainTable.deban in (3920308,3920728,3920788) then ' '  else '-' end
from [Schema].[veco_prod] as mainTable 
where mainTable.vcode = @docvcode 
--} Сбор данных Товарная накладная ГрузОтпр

--{ Сбор данных Товарная накладная ГрузПолуч
declare @СвДокПТПрГрузПолучОКПО        nvarchar(500)
      , @СвДокПТПрГрузПолучСвЮЛНаимОрг nvarchar(500)
	  , @СвДокПТПрГрузПолучСвЮЛИННЮЛ   nvarchar(500)
	  , @СвДокПТПрГрузПолучСвЮЛКПП     nvarchar(500)
	  , @СвДокПТПрГрузПолучИННФЛ       nvarchar(500)
	  , @СвДокПТПрГрузПолучФамилия     nvarchar(500)
	  , @СвДокПТПрГрузПолучИмя         nvarchar(500)
	  , @СвДокПТПрГрузПолучОтчество    nvarchar(500)
	  , @СвДокПТПрГрузПолучАдрТекст    nvarchar(500)
	  , @СвДокПТПрГрузПолучКодСтр      nvarchar(500)
	  , @СвДокПТПрГрузПолучТлф         nvarchar(500)
	  , @СвДокПТПрГрузПолучНомерСчета  nvarchar(500)
	  , @СвДокПТПрГрузПолучНаимБанк    nvarchar(500)
	  , @СвДокПТПрГрузПолучБИК         nvarchar(500)
	  , @СвДокПТПрГрузПолучКорСчет     nvarchar(500)
	  , @ГрузПолуч                     int

select @СвДокПТПрГрузПолучОКПО = nullif((select okpo from vLexOrg where vcode = isnull(mainTable.int12,mainTable.org)),'')
from [Schema].[veco_prod] as mainTable 
where mainTable.vcode = @docvcode 
--if(@СвДокПТПрГрузПолучОКПО is null) raiserror('В справочнике организаций нет данных о ОКПО организации в поле "Грузополучатель"',16,1)

select @ГрузПолуч = isnull(int12, org) from [Schema].[veco_prod] where VCode = @docvcode
if( isnull((select fl from vLexOrg where vcode = @ГрузПолуч),0) <> 1 ) -- Покупатель Организация
begin
  select @СвДокПТПрГрузПолучСвЮЛНаимОрг = dbo.EFN_Org_Fullname(s.vcode, @rdate)
       , @СвДокПТПрГрузПолучСвЮЛИННЮЛ = s.inn
	   , @СвДокПТПрГрузПолучСвЮЛКПП = dbo.EFN_OrgKPP(s.vcode, mainTable.date)
 from [Schema].[veco_prod] as mainTable 
 left join vLexOrg                   as s on s.vcode = isnull(mainTable.int12, mainTable.org)
 where mainTable.vcode = @docvcode
 
 if(@СвДокПТПрГрузПолучСвЮЛНаимОрг is null) raiserror('В справочнике организаций нет данных о наименовании организации в поле "Грузополучатель"',16,1)
 if(@СвДокПТПрГрузПолучСвЮЛИННЮЛ   is null) raiserror('В справочнике организаций нет данных о ИНН организации в поле "Грузополучатель"',16,1)
 if(@СвДокПТПрГрузПолучСвЮЛКПП     is null) raiserror('В справочнике организаций нет данных о КПП организации в поле "Грузополучатель"',16,1)
end

if(isnull((select fl from vLexOrg where vcode = @ГрузПолуч),0) = 1) -- Покупатель ИП
begin
 select @СвДокПТПрГрузПолучИННФЛ = org.inn
      , @СвДокПТПрГрузПолучФамилия = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Fam 
							else left(org.name, CHARINDEX(' ', org.name))
							end	
	  , @СвДокПТПрГрузПолучИмя = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.im 
							else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
							end
	 , @СвДокПТПрГрузПолучОтчество = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Otch
							else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
							end
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as org on org.VCode  = isnull(mainTable.int12,mainTable.org)
 left join [dbo].[VBn_kadry_FLuni]   as flc on flc.treevc = org.code_fl
 where mainTable.VCode = @docvcode
 
 if(@СвДокПТПрГрузПолучИННФЛ    is null) raiserror('В справочнике организаций нет данных о ИНН физлица в поле "Грузополучатель"',16,1)
 if(@СвДокПТПрГрузПолучФамилия  is null) raiserror('В справочнике организаций нет данных о Фамиилии физлица в поле "Грузополучатель"',16,1)
 if(@СвДокПТПрГрузПолучИмя      is null) raiserror('В справочнике организаций нет данных о Имени физлица в поле "Грузополучатель"',16,1)
 if(@СвДокПТПрГрузПолучОтчество is null) raiserror('В справочнике организаций нет данных об Отчестве физлица в поле "Грузополучатель"',16,1)
end

select @СвДокПТПрГрузПолучАдрТекст = isnull(nullif([dbo].[efn_GetAdr](s.vcode, @rdate, 11858, 0),''), [dbo].[efn_GetAdr] (s.vcode, @rdate, 11857, 0))
     , @СвДокПТПрГрузПолучКодСтр = case when s.country=0 then '643' else isnull(s.country,'643') end
from [Schema].[veco_prod] as mainTable
left join [dbo].[vLexOrg]           as s on s.vcode = isnull(mainTable.int12,mainTable.org) 
where mainTable.VCode = @docvcode

if(@СвДокПТПрГрузПолучАдрТекст is null) raiserror('В справочнике организаций нет данных о Адресе организации в поле "Грузополучатель"',16,1)

select @СвДокПТПрГрузПолучТлф = case 
                                when len(o.Phone) = 0 
								then case 
								     when len(o.fax) = 0 
									 then '-' 
									 else left(o.fax,20) 
									 end                  
                                else left(o.Phone,20) 
								end                                
from vLexOrg as o where o.vcode = @ГрузПолуч

select top 1 @СвДокПТПрГрузПолучНомерСчета = ac.account
           , @СвДокПТПрГрузПолучНаимБанк = ac.bankname + ' г. ' + sb.gorod
		   , @СвДокПТПрГрузПолучБИК = ac.bik   
		   , @СвДокПТПрГрузПолучКорСчет = ltrim(rtrim(sb.ksch))
from [dbo].[VLexorg_accounts]   as ac               
left loop join [dbo].[spr_bank] as sb on ac.bank = sb.code  
where ac.pcode = @ГрузПолуч  
  and ac.active = 1
--} Сбор данных Товарная накладная ГрузПолуч

--{Сбор данных Продавец
declare @ПродавецОКПО       nvarchar(500)
      , @ПродавецНаимОрг    nvarchar(500)
	  , @ПродавецИННЮЛ      nvarchar(500)
	  , @ПродавецКПП        nvarchar(500)
	  , @ПродавецАдрТекст   nvarchar(500)
	  , @ПродавецКодСтр     nvarchar(500)
	  , @ПродавецТлф        nvarchar(500)
	  , @ПродавецНомерСчета nvarchar(500)
	  , @ПродавецНаимБанк   nvarchar(500)
	  , @ПродавецБИК 	    nvarchar(500)
	  , @ПродавецКорСчет    nvarchar(500)

select @ПродавецОКПО     = o.okpo 
     , @ПродавецНаимОрг  = dbo.EFN_Org_Fullname(o.vcode, @rdate)
	 , @ПродавецИННЮЛ    = o.inn
	 , @ПродавецКПП      = (select kpp from [dbo].[VLex_own_org] where vcode = @we)
	 , @ПродавецАдрТекст = isnull(o.adr2, o.adr1)
	 , @ПродавецКодСтр   = case when o.country=0 then '643' else isnull(o.country, '643') end
from [dbo].[vLexOrg] as o 
where vcode = @we

if(@ПродавецНаимОрг  is null) raiserror('В справочнике организаций нет данных о наименовании Продавца',16,1)
if(@ПродавецИННЮЛ    is null) raiserror('В справочнике организаций нет данных о ИНН Продавца',16,1)
if(@ПродавецКПП      is null) raiserror('В справочнике организаций нет данных о КПП Продавца',16,1)
if(@ПродавецАдрТекст is null) raiserror('В справочнике организаций нет данных о адресе Продавца',16,1)
 
select @ПродавецТлф = case when mainTable.deban in (3920308,3920728,3920788) then ' '  else '-' end
from [Schema].[veco_prod] as mainTable
where mainTable.VCode = @docvcode

select top 1 
  @ПродавецНомерСчета = acc.account
, @ПродавецНаимБанк   = (select top 1 acc.bankname + ' г. ' + sb.gorod)
, @ПродавецБИК        = acc.bik
, @ПродавецКорСчет    = sb.ksch
from [Schema].[veco_prod] as mainTable
left join [dbo].[vLexorg_accounts]  as acc on acc.vcode  = (case 
                    when @Вариант_реализации = 3113908     
                    then 808278226     
                    else (select p.account    
                          from Schema.EFn_prod_AccessDocSubCodePodr(@getdate,194,null,null,null) as p    
                          where p.VCode = (case when @Вариант_реализации = 3113908 then mainTable.gruzotp else mainTable.Code_Podr end)      
                          and p.CodePodr = mainTable.Code_Podr --!!!!!!!!!!!!!!
                         ) 
				    end)     
left loop join [dbo].[spr_bank] as sb on acc.bank = sb.code       
where mainTable.VCode = @docvcode  
--}Сбор данных Продавец

--{ Сбор данных Покупатель
declare @ПокупательОКПО       nvarchar(500)
      , @ПокупательНаимОрг    nvarchar(500)
	  , @ПокупательИННЮЛ      nvarchar(500)
	  , @ПокупательКПП        nvarchar(500)
	  , @ПокупательИННФЛ      nvarchar(500)
	  , @ПокупательФамилия    nvarchar(500)
	  , @ПокупательИмя        nvarchar(500)
	  , @ПокупательОтчество   nvarchar(500)
	  , @ПокупательАдрТекст   nvarchar(500)
	  , @ПокупательКодСтр     nvarchar(500)
	  , @ПокупательТлф        nvarchar(500)
	  , @ПокупательНомерСчета nvarchar(500)
	  , @ПокупательНаимБанк   nvarchar(500)
	  , @ПокупательБИК 	      nvarchar(500)
	  , @ПокупательКорСчет    nvarchar(500)
      , @Org_plat             int

select @Org_plat = isnull([dbo].[EFN_Org_plat](@Грузополучатель), @Грузополучатель)

if(isnull((select fl from vLexOrg s where s.vcode = @Org_plat),0) <> 1) -- Покупатель организация
begin
 select @ПокупательОКПО = nullif((org.okpo),'')
      , @ПокупательНаимОрг = dbo.EFN_Org_Fullname(org.vcode,@rdate)
	  , @ПокупательИННЮЛ = org.inn
	  , @ПокупательКПП = dbo.EFN_OrgKPP(org.vcode, @rdate)
 from  [dbo].[VLexOrg] as org  
 where org.VCode  = @Org_plat
end

if(isnull((select fl from vLexOrg s where s.vcode = @Org_plat),0) = 1 ) -- Покупатель физлицо
begin
  select @ПокупательОКПО = nullif((org.okpo),'')
      , @ПокупательИННФЛ = org.inn
      , @ПокупательФамилия = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Fam 
							else left(org.name, CHARINDEX(' ', org.name))
							end	
	  , @ПокупательИмя = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.im 
							else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
							end
	 , @ПокупательОтчество = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Otch
							else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
							end
 from [dbo].[VLexOrg] as org 
 left join [dbo].[VBn_kadry_FLuni] as flc on flc.treevc = org.code_fl
 where org.VCode  = @Org_plat
end

select @ПокупательАдрТекст = case 
                             when @Грузополучатель in (1812971700, 1812566220) 
							 then s.adr2
                             when @Грузополучатель in (33439906) and @rdate between '20160909' and '20161231' 
							 then s.adr2
                             else s.adr1 
							 end           
       , @ПокупательКодСтр = case when s.country=0 then '643' else isnull(s.country,'643') end
	   , @ПокупательТлф = case 
                          when len(s.Phone) = 0 
						  then case 
						       when len(s.fax) = 0 
						  	 then '-' 
						  	 else left(s.fax,20) 
						  	 end                  
                           else left(s.Phone,20) 
						   end 
from vLexOrg s
where s.vcode = @Org_plat  


select top 1 @ПокупательНомерСчета = account
           , @ПокупательНаимБанк = ac.bankname
		   , @ПокупательБИК = ac.bik
		   , @ПокупательКорСчет = ltrim(rtrim(sb.ksch)) 
from  [dbo].[VLexorg_accounts]  as ac       
left loop JOIN [dbo].[spr_bank] as sb on ac.bank = sb.code      
where ac.pcode =  @Org_plat and active = 1  
--} Сбор данных Покупатель

--{ Сбор данных Основание
declare @НаимОсн nvarchar(500)
      , @НомОсн  nvarchar(500)
	  , @ДатаОсн nvarchar(500)
select @НаимОсн = isnull(d.text4,'') + case when d.text4 is null then '' else '/' end + u.Name
     , @НомОсн = d.nomer
	 , @ДатаОсн = convert(varchar(10),d.[rdate],104)
from [Schema].[veco_prod] as mainTable
left join [dbo].[lexdogovor]        as d on d.treevc = mainTable.dogovor
left join [dbo].[unianalit]         as u on u.VCode  = d.treevc
where mainTable.VCode = @docvcode
--} Сбор данных Основание

--{ Сбор данных ИнфПолФХЖ1
declare @ИдВизуализации1 nvarchar(500)
      , @ДоговорДата1    nvarchar(500)
	  , @ДоговорНомер1   nvarchar(500)
	  , @ШтрихКод1		 nvarchar(500)
	  , @НаимПокуп1		 nvarchar(500)
	  , @НаимГрузПолуч1	 nvarchar(500)
	  
declare @textInf1 table(id varchar(100), vl varchar (500))

select @ИдВизуализации1 = case 
                         when @Вариант_реализации = 3113908 -- Вариант реализации (Реализация нефтепродуктов мелким оптом)
                         then 'Башнефть-Розница_МО' 
		                 else 'Башнефть-Розница' 
		                 end
	 , @ДоговорДата1  = convert(varchar(10),d.[rdate],104)
	 , @ДоговорНомер1 = d.nomer
	 , @ШтрихКод1       = (
	                      select top 1 bar.barcode
						  from [sea_schema].[eco_barCodes_mat_h] bar                 
                          where bar.DocVcode = mainTable.vcode and bar.DocTdoc = 'NF2' and bar.SEATdoc = 'TN'
                          order by DocWdate desc 
	                     )
	 , @НаимПокуп1 = isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  @Org_plat),'')
	 , @НаимГрузПолуч1 = isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  @Org_plat),'')
	 
from [Schema].[veco_prod] as mainTable
left join [dbo].[lexdogovor]        as d on d.treevc = mainTable.dogovor
left join [dbo].[unianalit]         as u on u.VCode  = d.treevc
where mainTable.VCode = @docvcode

insert into @textInf1 (id, vl) 
values ('ИдВизуализации', @ИдВизуализации1)
     , ('ДоговорДата',    @ДоговорДата1   )
	 , ('ДоговорНомер',   @ДоговорНомер1  )
	 , ('ШтрихКод',       @ШтрихКод1      )
	 , ('НаимПокуп',      @НаимПокуп1     )
	 , ('НаимГрузПолуч',  @НаимГрузПолуч1 ) 
 
--if(@ИдВизуализации is null) raiserror('В документе нет данных в поле "Вариант реализации"',16,1) 
--if(@ОснованиеДата  is null) raiserror('В документе не заполнена дата',16,1) 
--if(@ОснованиеНомер is null) raiserror('В документе нет данных в поле "Счет-фактура №"',16,1) 
--if(@ШтрихКод       is null) raiserror('В справочнике нет данных о Штрихкоде',16,1) 
--if(@ИнфПередТабл   is null) raiserror('В справочнике договоров нет данных о договоре',16,1) 
--if(@НаимПокуп      is null) raiserror('В справочнике организаций нет данных о Наименовании организации в поле "Организация(дебет)"',16,1) 
--if(@НаимГрузПолуч  is null) raiserror('В справочнике организаций нет данных о Наименовании организации в поле "Грузополучатель"',16,1) 
--} Сбор данных ИнфПолФХЖ1

--{ Сбор данных СодФХЖ2
declare @НеттоВс    varchar (500)
      , @СтБезНДСВс varchar (500)
	  , @СумНДСВс	varchar (500)
	  , @СтУчНДСВс	varchar (500)
declare @productInfo table(НомТов        int
                         , НаимТов       varchar (500)
						 , КодТов        varchar (500)
						 , НаимЕдИзм     varchar (500)
						 , ОКЕИ_Тов      varchar (500)
						 , НеттоПередано varchar (500)
						 , Цена          varchar (500)
						 , СтБезНДС      varchar (500)
						 , НалСт         varchar (500)
						 , СумНДС        varchar (500)
						 , СтУчНДС       varchar (500))
insert into @productInfo (НомТов, НаимТов, КодТов, НаимЕдИзм, ОКЕИ_Тов, НеттоПередано, Цена, СтБезНДС, НалСт, СумНДС, СтУчНДС)
select               
 НомТов = ROW_NUMBER() over(order by m3.MatCode, m3.text1, m3.Text5,  m3.pnds, m3.PNDS)
--дублируется гост в продуктах 
,НаимТов = case 
	          when m3.text1 like '%'+( select top 1 gost_vid  from bn_product where vcode = m3.matcode)+'%' 
				   and ( select top 1 gost_vid  from bn_product where vcode = m3.matcode) is not null      
              then substring(m3.text1,0,CHARINDEX(( select top 1 gost_vid  from bn_product where vcode=m3.matcode),m3.text1))  
              else m3.text1    
              end     
              + isnull((select top 1 full_gost=' '+isnull(gost_vid,'')+' '+isnull(gost,'')  
			             from bn_product where vcode = m3.matcode),'')
,КодТов = m3.MatCode 
,НаимЕдИзм = case when @Вариант_реализации = 3113908 then 'т' else 'л' end 
,ОКЕИ_Тов = case when @Вариант_реализации = 3113908 then '168' else '112' end 
,НеттоПередано = case 
                    when @Вариант_реализации = 3113908 
					then rtrim(ltrim(convert(varchar(50),convert(float,round(m3.kolvo1,3)))))
					else rtrim(ltrim(convert(varchar(50),convert(money,round(m3.kolvo ,2))))) 
					end 
,Цена = rtrim(ltrim(convert(varchar(50),convert(money,round(m3.OZena2*100/120,2))))) 
,СтБезНДС = rtrim(ltrim(convert(varchar(50),round(m3.SumBNDSRsh,2)))) 
,НалСт = rtrim(ltrim(convert(varchar(50),m3.PNDS)))+'%'
,СумНДС = rtrim(ltrim(convert(varchar(50),round(isnull(m3.SumNDSRsh,0),2)))) 
,СтУчНДС = rtrim(ltrim(convert(varchar(50),round(m3.SumSNDSRsh,2))))                        
from [Schema].[veco_prod]    as mainTable
join [Schema].[veco_prodMat] as m3 on mainTable.vcode = m3.pcode
where mainTable.VCode = @docvcode

select @НеттоВс = case 
                  when isnull(mainTable.int4,0) = 3113908 
				  then rtrim(ltrim(convert(varchar(50),convert(float,round(sum(m3.kolvo1),3)))))
				  else rtrim(ltrim(convert(varchar(50),convert(money,round(sum(m3.kolvo),2))))) 
				  end 
	, @СтБезНДСВс = rtrim(ltrim(convert(varchar(50),round(sum(m3.SumBNDSRsh),2)))) 
	, @СумНДСВс = rtrim(ltrim(convert(varchar(50),round(sum(isnull(m3.SumNDSRsh,0)),2))))
	, @СтУчНДСВс = rtrim(ltrim(convert(varchar(50),round(sum(m3.SumSNDSRsh),2))))            
from [Schema].[veco_prod]   as mainTable 
join [Schema].[veco_prodMat] as m3 on mainTable.vcode = m3.pcode                                
where mainTable.VCode = @docvcode             
group by mainTable.int4
--} Сбор данных СодФХЖ2

--{ Сбор данных СодФХЖ3
declare @НомТранНакл     varchar (500)
      , @ДатаТранНакл    varchar (500)
	  , @ДолжностьДир    varchar (500)
	  , @ФИОДир          varchar (500) 
	  , @ДолжностьБух    varchar (500)
	  , @НомерДов        varchar (500)
	  , @ДатаДов         varchar (500)
	  , @ВыдалДов        varchar (500)
	  , @ДолжностьПринял varchar (500)
	  , @ФИОПринял       varchar (500)
	  , @МассаПрописью   varchar (500)
	  , @НакладнаяДиректор int

declare @orgInfo table (id varchar(100), vl varchar (500))
select
  @НомТранНакл = case 
                 when @Вариант_реализации = 3113908 
				 then coalesce(t.inputnomer,mainTable.nomer) 
				 else null 
				 end
, @ДатаТранНакл = case 
                  when @Вариант_реализации = 3113908 
				  then convert(varchar(10),(coalesce (t.rdate, @rdate)),104)
				  else null 
				  end
from [Schema].[veco_prod] as mainTable               
left join [Schema].[Eco_TTN]   as t on t.prcode2 = mainTable.vcode                              
where mainTable.VCode = @docvcode

select @НакладнаяДиректор = isnull(ua9,0) from [Schema].[veco_prod] where VCode = @docvcode

--if(@НакладнаяДиректор <> 0)
--begin
 if(@Вариант_реализации = 3113908)
 begin
  select
  @ДолжностьДир =  isnull([Schema].[efn_prod_Podpisi_dolg]('Руководитель накладной для реализации на УСН', mainTable.gruzotp, @rdate, mainTable.we, mainTable.ua9), ' ')              
  , @ФИОДир = isnull(u.Name + (select top 1 '(' + pd.text3 + ')'              
                                  from eco_mtr_komissia_all p 
								  join eco_mtr_komissia_mat_all pd on p.vcode = pd.pcode              
                                  where p.tdoc = 'NRP' 
								   and pd.rcode = mainTable.ua9 
								   and pd.code = 19153530 
								   and isnull(pd.text3,'') <> ''
								   and @rdate between isnull(pd.date1,'19000101') 
								   and isnull(pd.date2,'30000101')
								), ' ') 
  , @ДолжностьБух = isnull(u1.Name + (select [Schema].[efn_prod_Podpisi]('Бухгалтер накладной для реализации на УСН', mainTable.gruzotp, @rdate, mainTable.we, mainTable.ua10))    , ' ') 
  , @НомерДов = isnull(mainTable.text1,' ') 
  , @ДатаДов =  isnull(convert(varchar(10),mainTable.DPD,104), ' ')
  , @ВыдалДов = isnull(o.fullname, ' ') 
  , @ДолжностьПринял = isnull(mainTable.text13,' ') 
  , @ФИОПринял =isnull(mainTable.text2,' ') 
  , @МассаПрописью = isnull(dbo.LexNumeralKolvo_rezTnKg((select sum(m.kolvo1) from Schema.eco_prodmat as m where m.pcode = mainTable.vcode)), ' ') 
  from [Schema].[veco_prod] as mainTable
  left join [dbo].[unianalit]         as u  on u.VCode  = mainTable.ua9
  left join [dbo].[unianalit]         as u1 on u1.VCode = mainTable.ua10
  left join [dbo].[Spr_Org]           as o  on o.vcode  = mainTable.org
  where mainTable.VCode = @docvcode

  insert into @orgInfo (id, vl) 
  values ('ДолжностьДир',    @ДолжностьДир   )
       , ('ФИОДир',          @ФИОДир         )
  	   , ('ДолжностьБух',    @ДолжностьБух   )
	   , ('НомерДов',        @НомерДов       )
	   , ('ДатаДов',         @ДатаДов        )
	   , ('ВыдалДов',        @ВыдалДов       ) 
	   , ('ДолжностьПринял', @ДолжностьПринял)
	   , ('ФИОПринял',       @ФИОПринял      )
	   , ('МассаПрописью',   @МассаПрописью  )

 end
--} Сбор данных СодФХЖ3

--{ Настройка роуминга, если роуминг не через СБИС
declare @КодФилиала nvarchar(500) 
select @КодФилиала = case 
						when @ПолучательИНН='0277067012' and  @ПолучательКПП='027701001'  then '1' 
						when @ПолучательИНН='0277090269' and  @ПолучательКПП='027701001'  then '1'
						when @ПолучательИНН='1644040406' and  @ПолучательКПП='164901001'  then '10' 
						else null 
						end 
--} Настройка роуминга, если роуминг не через СБИС   

-- Если какое-то из обязательных полей пустое - прекращаем выполнение процедуры
if( @ПолучательИНН      is null
 or @ПолучательКПП      is null
 or @ОтправительИНН     is null
 or @ОтправительКПП     is null
 or @НомерСчФ           is null
 or @СвПродНаимОрг      is null
 or @ГрузОтНаимОрг      is null
 or @ГрузОтИННЮЛ        is null
 or @ГрузОтКПП          is null
 or @ГрузОтАдрТекст     is null
 or (@ГрузПолучНаимОрг  is null and @ГрузополучательИП = 0)
 or (@ГрузПолучИННЮЛ    is null and @ГрузополучательИП = 0)
 or (@ГрузПолучКПП      is null and @ГрузополучательИП = 0)
 or (@ГрузПолучИННФЛ    is null and @ГрузополучательИП = 1)
 or (@ГрузПолучФамилия  is null and @ГрузополучательИП = 1)
 or (@ГрузПолучИмя      is null and @ГрузополучательИП = 1)
 or (@ГрузПолучОтчество is null and @ГрузополучательИП = 1)
 or @ГрузПолучАдрТекст  is null
 or not exists (select 1 from @tableSender)
 or (@СвПокупНаимОрг    is null and @ПокупательИП = 0)
 or (@СвПокупИННЮЛ      is null and @ПокупательИП = 0)
 or (@СвПокупКПП        is null	and @ПокупательИП = 0)
 or (@СвПокупИННФЛ      is null	and @ПокупательИП = 1)
 or (@СвПокупФамилия    is null	and @ПокупательИП = 1)
 or (@СвПокупИмя        is null	and @ПокупательИП = 1)
 or (@СвПокупОтчество   is null	and @ПокупательИП = 1)
 or @СвПокупАдрТекст    is null
 or @СтТовУчНалВсего    is null
 or (@СтТовСумНал       is null 
     and @СтТовБезНДС   is null)
  ) return

  --ДопСведТов/НаимЕдИзм

-- Собираем пакет XML
SELECT @tmpf_im_sprxml = (
select 
  '@ИдДок' = @tdoc + convert(varchar(255),@docvcode)
, 'Получатель/@ИНН'  = @ПолучательИНН
, 'Получатель/@КПП'  = @ПолучательКПП
, 'Получатель/@КодФилиала' = @КодФилиала
, 'Отправитель/@ИНН' = @ОтправительИНН
, 'Отправитель/@КПП' = @ОтправительКПП
, cast((select 
   '@ИмяФайла' = fileName.Name + '.xml'
 , 'Файл/@ИдФайл' = fileName.Name
 , 'Файл/@ВерсФорм' = '5.01'
 , 'Файл/@ВерсПрог' = 'СБиС3'
 , 'Файл/СвУчДокОбор/@ИдПол' = ''
 , 'Файл/СвУчДокОбор/@ИдОтпр' = ''
 , 'Файл/СвУчДокОбор/СвОЭДОтпр/@НаимОрг' = 'ООО "Компания "Тензор"'
 , 'Файл/СвУчДокОбор/СвОЭДОтпр/@ИННЮЛ' = '7605016030'
 , 'Файл/СвУчДокОбор/СвОЭДОтпр/@ИдЭДО' = '2BE'
 , 'Файл/Документ/@КНД' = '1115131'
 , 'Файл/Документ/@Функция' = 'СЧФ'
 , 'Файл/Документ/@ДатаИнфПр' = convert(varchar(10),mainTable.[date],104)
 , 'Файл/Документ/@ВремИнфПр' = replace(convert(varchar(8), mainTable.[date], 108),':','.')
 , 'Файл/Документ/@НаимЭконСубСост' = 'Башнефть-Розница'
 , 'Файл/Документ/СвСчФакт/@НомерСчФ' = @НомерСчФ
 , 'Файл/Документ/СвСчФакт/@ДатаСчФ' = convert(varchar(10),mainTable.[date],104)--dbo.DateToStr(mainTable.[date])
 , 'Файл/Документ/СвСчФакт/@КодОКВ' = '643'
 , 'Файл/Документ/СвСчФакт/ИспрСчФ/@НомИспрСчФ' = @НомИспрСчФ
 , 'Файл/Документ/СвСчФакт/ИспрСчФ/@ДефНомИспрСчФ' = case when @НомИспрСчФ is null then @ДефНомИспрСчФ end
 , 'Файл/Документ/СвСчФакт/ИспрСчФ/@ДатаИспрСчФ'= @ДатаИспрСчФ 
 , 'Файл/Документ/СвСчФакт/ИспрСчФ/@ДефДатаИспрСчФ' = case when @ДатаИспрСчФ is null then @ДефДатаИспрСчФ end
 , 'Файл/Документ/СвСчФакт/СвПрод/ИдСв/СвЮЛУч/@НаимОрг' = @СвПродНаимОрг
 , 'Файл/Документ/СвСчФакт/СвПрод/ИдСв/СвЮЛУч/@ИННЮЛ' = @ОтправительИНН
 , 'Файл/Документ/СвСчФакт/СвПрод/ИдСв/СвЮЛУч/@ДефИННЮЛ' = case when @ОтправительИНН is null then '-' end
 , 'Файл/Документ/СвСчФакт/СвПрод/ИдСв/СвЮЛУч/@КПП' = @ОтправительКПП
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@Индекс' = @СвПродАдресИндекс   
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@КодРегион' = @СвПродАдресКодРегион
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@Район' = @СвПродАдресРайон     
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@Город' = @СвПродАдресГород     
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@НаселПункт' = @СвПродАдресНаселПункт
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@Улица' = @СвПродАдресУлица     
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@Дом' = @СвПродАдресДом       
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@Корпус' = @СвПродАдресКорпус    
 --, 'Документ/СвСчФакт/СвПрод/Адрес/АдрРФ/@Кварт' = @СвПродАдресКварт     
 , 'Файл/Документ/СвСчФакт/СвПрод/Адрес/АдрИнф/@КодСтр' = @СвПродАдресКодСтр    
 , 'Файл/Документ/СвСчФакт/СвПрод/Адрес/АдрИнф/@АдрТекст' = @СвПродАдресАдрТекст 
 , 'Файл/Документ/СвСчФакт/ГрузОт/ГрузОтпр/ИдСв/СвЮЛУч/@НаимОрг' = @ГрузОтНаимОрг 
 , 'Файл/Документ/СвСчФакт/ГрузОт/ГрузОтпр/ИдСв/СвЮЛУч/@ИННЮЛ' = @ГрузОтИННЮЛ 
 , 'Файл/Документ/СвСчФакт/ГрузОт/ГрузОтпр/ИдСв/СвЮЛУч/@ДефИННЮЛ' = case when @ГрузОтИННЮЛ is null then '-' end
 , 'Файл/Документ/СвСчФакт/ГрузОт/ГрузОтпр/ИдСв/СвЮЛУч/@КПП' = @ГрузОтКПП
 , 'Файл/Документ/СвСчФакт/ГрузОт/ГрузОтпр/Адрес/АдрИнф/@АдрТекст' = @ГрузОтАдрТекст
 , 'Файл/Документ/СвСчФакт/ГрузОт/ГрузОтпр/Адрес/АдрИнф/@КодСтр' = '643'
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/ИдСв/СвЮЛУч/@НаимОрг' = @ГрузПолучНаимОрг
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/ИдСв/СвЮЛУч/@ИННЮЛ' = @ГрузПолучИННЮЛ
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/ИдСв/СвЮЛУч/@КПП' = @ГрузПолучКПП
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/ИдСв/СвИП/@ИННФЛ' = @ГрузПолучИННФЛ
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/ИдСв/СвИП/ФИО/@Фамилия' = @ГрузПолучФамилия
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/ИдСв/СвИП/ФИО/@Имя' = @ГрузПолучИмя
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/ИдСв/СвИП/ФИО/@Отчество' = @ГрузПолучОтчество
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/Адрес/АдрИнф/@АдрТекст' = @ГрузПолучАдрТекст
 , 'Файл/Документ/СвСчФакт/ГрузПолуч/Адрес/АдрИнф/@КодСтр' = @ГрузПолучКодСтр
 , 'Файл/Документ/СвСчФакт' = (
                                select '@НомерПРД' = s.norder
    							     , '@ДатаПРД'  = s.date
								from @tableSender as s
								FOR XML PATH('СвПРД'), type
                               )
 , 'Файл/Документ/СвСчФакт/СвПокуп/ИдСв/СвЮЛУч/@НаимОрг' = @СвПокупНаимОрг
 , 'Файл/Документ/СвСчФакт/СвПокуп/ИдСв/СвЮЛУч/@ИННЮЛ' = @СвПокупИННЮЛ
 , 'Файл/Документ/СвСчФакт/СвПокуп/ИдСв/СвЮЛУч/@КПП' = @СвПокупКПП
 , 'Файл/Документ/СвСчФакт/СвПокуп/ИдСв/СвИП/@ИННФЛ' = @СвПокупИННФЛ
 , 'Файл/Документ/СвСчФакт/СвПокуп/ИдСв/СвИП/ФИО/@Фамилия' = @СвПокупФамилия
 , 'Файл/Документ/СвСчФакт/СвПокуп/ИдСв/СвИП/ФИО/@Имя' = @СвПокупИмя
 , 'Файл/Документ/СвСчФакт/СвПокуп/ИдСв/СвИП/ФИО/@Отчество' = @СвПокупОтчество
 , 'Файл/Документ/СвСчФакт/СвПокуп/Адрес/АдрИнф/@АдрТекст' = @СвПокупАдрТекст
 , 'Файл/Документ/СвСчФакт/СвПокуп/Адрес/АдрИнф/@КодСтр' = @СвПокупКодСтр
 , 'Файл/Документ/СвСчФакт/ДокПодтвОтгр/@НаимДокОтгр' = @НаимДокОтгр
 , 'Файл/Документ/СвСчФакт/ДокПодтвОтгр/@НомДокОтгр' = @НомДокОтгр
 , 'Файл/Документ/СвСчФакт/ДокПодтвОтгр/@ДатаДокОтгр' = @ДатаДокОтгр
 /*, 'Файл/Документ/СвСчФакт' = (
                                select '@НаимДокОтгр' = НаимДокОтгр
    							     , '@НомДокОтгр'  = НомДокОтгр
									 , '@ДатаДокОтгр' = ДатаДокОтгр
								from @tableDoc as t
								FOR XML PATH('ДокПодтвОтгр'), type
                               )*/
 , 'Файл/Документ/СвСчФакт/ИнфПолФХЖ1' = (                               --Добавил Вадим 20.01.2020 по заявке о пропадании штрихкода в с/ф
                                          select '@Идентиф' = i.id
                                               , '@Значен'  = i.vl
                                          from @textInf as i
                                          FOR XML PATH('ТекстИнф'), type
										  )
 , 'Файл/Документ/ТаблСчФакт' = (
                            select '@НомСтр'      = pinf.id
							     , '@НаимТов'     = pinf.name
							     , '@ОКЕИ_Тов'    = pinf.OKEI
							     , '@ДефОКЕИ_Тов' = case when pinf.OKEI is null then '-' end
							     , '@КолТов'      = pinf.number
							     , '@ЦенаТов'     = pinf.price
							     , '@СтТовБезНДС' = pinf.rateWithoutNDS
							     , '@НалСт'       = pinf.rate
							     , '@СтТовУчНал'  = pinf.rateSum
								 , 'Акциз/БезАкциз' =  pinf.excise        
								 , 'Акциз/СумАкциз' =  pinf.sumexcise     
								 , 'СумНал/БезНДС'  =  pinf.sumWithoutNDS 
								 , 'СумНал/СумНал'  =  pinf.sumCash
								 , 'ДопСведТов/@НаимЕдИзм' = case when pinf.OKEI is not null then pinf.НаимЕдИзм else '-' end
							from @productInformation as pinf
							FOR XML PATH('СведТов'), type
                            )				
 , 'Файл/Документ/ТаблСчФакт/ВсегоОпл/@СтТовУчНалВсего' = @СтТовУчНалВсего
 , 'Файл/Документ/ТаблСчФакт/ВсегоОпл/@ДефСтТовУчНалВсего' = case when @СтТовУчНалВсего is null then '-' end
 , 'Файл/Документ/ТаблСчФакт/ВсегоОпл/@СтТовБезНДСВсего' = @СтТовБезНДСВсего
 , 'Файл/Документ/ТаблСчФакт/ВсегоОпл/СумНалВсего/СумНал' = @СтТовСумНал
 , 'Файл/Документ/ТаблСчФакт/ВсегоОпл/СумНалВсего/БезНДС' = @СтТовБезНДС
 , 'Файл/Документ/СвПродПер/СвПер/@СодОпер' = 'Товары переданы'
 , 'Файл/Документ/СвПродПер/СвПер/ОснПер/@НаимОсн' = 'Без документа-основания'
 , 'Файл/Документ/СвПродПер/СвПер/ОснПер/@ДатаОсн' = convert(varchar(10),mainTable.[date],104)
 , 'Файл/Документ/Подписант/@ОблПолн' = 0
 , 'Файл/Документ/Подписант/@Статус' = 1 
 , 'Файл/Документ/Подписант/@ОснПолн' = 'Должностные обязанности'
 , 'Файл/Документ/Подписант/ЮЛ/@ИННЮЛ' = ''
 , 'Файл/Документ/Подписант/ЮЛ/@Должн' = ''
 , 'Файл/Документ/Подписант/ЮЛ/ФИО/@Фамилия' = ''
 , 'Файл/Документ/Подписант/ЮЛ/ФИО/@Имя' = ''
 , 'Файл/Документ/Подписант/ЮЛ/ФИО/@Отчество' = ''
 from [Schema].[veco_prod] as mainTable
 join @fileName                      as fileName on fileName.VCode = mainTable.VCode
 where mainTable.VCode = @docvcode and fileName.Name like '%ON_NSCHFDOPPR_%'
 FOR XML PATH('Вложение')) AS XML)

 , cast((select 
   '@ИмяФайла' = fileName.Name + '.xml'
 , 'Файл/@ИдФайл' = fileName.Name
 , 'Файл/@ВерсФорм' = '5.01'
 , 'Файл/СвУчДокОбор/@ИдПол' = ''
 , 'Файл/СвУчДокОбор/@ИдОтпр' = ''
 , 'Файл/СвУчДокОбор/СвОЭДОтпр/@НаимОрг' = 'ООО "Компания "Тензор"'
 , 'Файл/СвУчДокОбор/СвОЭДОтпр/@ИННЮЛ' = '7605016030'
 , 'Файл/СвУчДокОбор/СвОЭДОтпр/@ИдЭДО' = '2BE'
 , 'Файл/Документ/@КНД' = '1175010'
 , 'Файл/Документ/@ДатаИнфПр' = convert(varchar(10),mainTable.[date],104)
 , 'Файл/Документ/@ВремИнфПр' = replace(convert(varchar(8), mainTable.[date], 108),':','.')
 , 'Файл/Документ/@НаимЭконСубСост' = 'Башнефть-Розница'
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/НаимДок/@ПоФактХЖ' = 'Документ о передаче товара при торговых операциях'
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/НаимДок/@НаимДокОпр' = 'Товарная накладная'
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/ИдентДок/@НомДокПТ' = mainTable.Nomer
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/ИдентДок/@ДатаДокПТ' =convert(varchar(10),mainTable.[date],104)
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/ДенИзм/@КодОКВ' = '643'
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/@ОКПО' = @СвДокПТПрГрузОтпрОКПО
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/ИдСв/СвОрг/СвЮЛ/@НаимОрг' = @СвДокПТПрГрузОтпрСвЮЛНаимОрг
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/ИдСв/СвОрг/СвЮЛ/@ИННЮЛ' = @СвДокПТПрГрузОтпрСвЮЛИННЮЛ
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/ИдСв/СвОрг/СвЮЛ/@КПП' = @СвДокПТПрГрузОтпрСвЮЛКПП
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/Адрес/АдрИнф/@АдрТекст' = @СвДокПТПрГрузОтпрАдрТекст
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/Адрес/АдрИнф/@КодСтр' = @СвДокПТПрГрузОтпрКодСтр
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/Контакт/@Тлф' = @СвДокПТПрГрузОтпрТлф
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/БанкРекв/@НомерСчета' = @СвДокПТПрГрузОтпрНомерСчета
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/БанкРекв/СвБанк/@НаимБанк' = @СвДокПТПрГрузОтпрНаимБанк
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/БанкРекв/СвБанк/@БИК' = @СвДокПТПрГрузОтпрБИК     
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузОтпр/БанкРекв/СвБанк/@КорСчет' =	@СвДокПТПрГрузОтпрКорСчет 
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/@ОКПО' = @СвДокПТПрГрузПолучОКПО
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/ИдСв/СвОрг/СвЮЛ/@НаимОрг' = @СвДокПТПрГрузПолучСвЮЛНаимОрг
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/ИдСв/СвОрг/СвЮЛ/@ИННЮЛ' = @СвДокПТПрГрузПолучСвЮЛИННЮЛ
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/ИдСв/СвОрг/СвЮЛ/@КПП' = @СвДокПТПрГрузПолучСвЮЛКПП
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/ИдСв/СвФЛ/@ИННФЛ' = @СвДокПТПрГрузПолучИННФЛ
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/ИдСв/СвФЛ/ФИО/@Фамилия' = @СвДокПТПрГрузПолучФамилия
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/ИдСв/СвФЛ/ФИО/@Имя' = @СвДокПТПрГрузПолучИмя
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/ИдСв/СвФЛ/ФИО/@Отчество' = @СвДокПТПрГрузПолучОтчество
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/Адрес/АдрИнф/@АдрТекст' = @СвДокПТПрГрузПолучАдрТекст
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/Адрес/АдрИнф/@КодСтр' = @СвДокПТПрГрузПолучКодСтр
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/Контакт/@Тлф' = @СвДокПТПрГрузПолучТлф
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/БанкРекв/@НомерСчета' = @СвДокПТПрГрузПолучНомерСчета
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/БанкРекв/СвБанк/@НаимБанк' = @СвДокПТПрГрузПолучНаимБанк
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/БанкРекв/СвБанк/@БИК' = @СвДокПТПрГрузПолучБИК
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ГрузПолуч/БанкРекв/СвБанк/@КорСчет' = @СвДокПТПрГрузПолучКорСчет
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/@ОКПО' = @ПродавецОКПО
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/ИдСв/СвОрг/СвЮЛ/@НаимОрг' =  @ПродавецНаимОрг
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/ИдСв/СвОрг/СвЮЛ/@ИННЮЛ' = @ПродавецИННЮЛ  
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/ИдСв/СвОрг/СвЮЛ/@КПП' = @ПродавецКПП    
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/Адрес/АдрИнф/@АдрТекст' = @ПродавецАдрТекст
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/Адрес/АдрИнф/@КодСтр'  = @ПродавецКодСтр  
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/Контакт/@Тлф' = @ПродавецТлф
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/БанкРекв/@НомерСчета' = @ПродавецНомерСчета
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/БанкРекв/СвБанк/@НаимБанк' = @ПродавецНаимБанк  
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/БанкРекв/СвБанк/@БИК' = @ПродавецБИК 	   
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Продавец/БанкРекв/СвБанк/@КорСчет' = @ПродавецКорСчет   
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/@ОКПО' = @ПокупательОКПО
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/ИдСв/СвОрг/СвЮЛ/@НаимОрг' = @ПокупательНаимОрг
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/ИдСв/СвОрг/СвЮЛ/@ИННЮЛ' = @ПокупательИННЮЛ
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/ИдСв/СвОрг/СвЮЛ/@КПП' = @ПокупательКПП
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/ИдСв/СвФЛ/@ИННФЛ' = @ПокупательИННФЛ
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/ИдСв/СвФЛ/ФИО/@Фамилия' = @ПокупательФамилия 
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/ИдСв/СвФЛ/ФИО/@Имя' = @ПокупательИмя     
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/ИдСв/СвФЛ/ФИО/@Отчество' = @ПокупательОтчество
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/Адрес/АдрИнф/@АдрТекст' = @ПокупательАдрТекст
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/Адрес/АдрИнф/@КодСтр'  = @ПокупательКодСтр
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/Контакт/@Тлф' = @ПокупательТлф
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/БанкРекв/@НомерСчета' = @ПокупательНомерСчета
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/БанкРекв/СвБанк/@НаимБанк' = @ПокупательНаимБанк    
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/БанкРекв/СвБанк/@БИК' = @ПокупательБИК 	     
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Покупатель/БанкРекв/СвБанк/@КорСчет' = @ПокупательКорСчет     
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Основание/@НаимОсн' = @НаимОсн
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Основание/@НомОсн' = @НомОсн 
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/Основание/@ДатаОсн' = @ДатаОсн
 , 'Файл/Документ/СвДокПТПрКроме/СвДокПТПр/СодФХЖ1/ИнфПолФХЖ1' = (
                                                                 select '@Идентиф' = i.id
                                                                      , '@Значен'  = i.vl
                                                                 from @textInf1 as i
                                                                 FOR XML PATH('ТекстИнф'), type
										                         )
 , 'Файл/Документ/СвДокПТПрКроме/СодФХЖ2' = (
                                               select   '@НомТов'        = i.НомТов       
                                                      , '@НаимТов'       = i.НаимТов      
							                 		  , '@КодТов'        = i.КодТов       
							                 		  , '@НаимЕдИзм'     = i.НаимЕдИзм    
							                 		  , '@ОКЕИ_Тов'      = i.ОКЕИ_Тов     
							                 		  , '@НеттоПередано' = i.НеттоПередано
							                 		  , '@Цена'          = i.Цена         
							                 		  , '@СтБезНДС'      = i.СтБезНДС     
							                 		  , '@НалСт'         = i.НалСт        
							                 		  , '@СумНДС'        = i.СумНДС       
							                 		  , '@СтУчНДС'       = i.СтУчНДС      
                                               from @productInfo as i
                                               FOR XML PATH('СвТов'), type
							                 )
 , 'Файл/Документ/СвДокПТПрКроме/СодФХЖ2/Всего/@НеттоВс' =  @НеттоВс    
 , 'Файл/Документ/СвДокПТПрКроме/СодФХЖ2/Всего/@СтБезНДСВс' = @СтБезНДСВс 
 , 'Файл/Документ/СвДокПТПрКроме/СодФХЖ2/Всего/@СумНДСВс' =  @СумНДСВс	
 , 'Файл/Документ/СвДокПТПрКроме/СодФХЖ2/Всего/@СтУчНДСВс' = @СтУчНДСВс	
 , 'Файл/Документ/СодФХЖ3/@СодОпер' = 'Перечисленные в документе ценности переданы'
 , 'Файл/Документ/СодФХЖ3/ТранНакл/@НомТранНакл' = @НомТранНакл
 , 'Файл/Документ/СодФХЖ3/ТранНакл/@ДатаТранНакл' = @ДатаТранНакл
 , 'Файл/Документ/СодФХЖ3' = (
                             select '@Идентиф' = i.id
                                  , '@Значен'  = i.vl
                             from @orgInfo as i
                             FOR XML PATH('ИнфПолФХЖ3'), type
							 )
 , 'Файл/Документ/Подписант/@ОблПолн' = 1
 , 'Файл/Документ/Подписант/@Статус' = 1
 , 'Файл/Документ/Подписант/@ОснПолн' = ''
 , 'Файл/Документ/Подписант/@ОснПолнОрг' = ''
 , 'Файл/Документ/Подписант/ЮЛ/@ИННЮЛ' = ''
 , 'Файл/Документ/Подписант/ЮЛ/@Должн' = ''
 , 'Файл/Документ/Подписант/ЮЛ/ФИО/@Фамилия' = ''
 , 'Файл/Документ/Подписант/ЮЛ/ФИО/@Имя' = ''
 , 'Файл/Документ/Подписант/ЮЛ/ФИО/@Отчество' = ''
   from [Schema].[veco_prod] as mainTable
   join @fileName                      as fileName on fileName.VCode = mainTable.VCode
   where mainTable.VCode = @docvcode and fileName.Name like '%DP_TOVTORGPR_%'
   FOR XML PATH('Вложение')) AS XML)

 FOR XML PATH('Пакет'), ROOT('Реестр')
 )

-- select @tmpf_im_sprxml

 -- вывести xml на экран вместо отправки                
if @show = 1                
begin
 select convert(xml,@tmpf_im_sprxml)
 return                
end 

declare @tmpf_im_spr varchar(max)
      , @inn         varchar(255) = @ОтправительИНН
      , @kpp         varchar(255) = @ОтправительКПП
	  , @inn_pokup   varchar(255) = @ПолучательИНН
	  , @kpp_pokup   varchar(255) = @ПолучательКПП

-- Добавляем в начало служебную информацию
SELECT @tmp0 = (SELECT CAST(@tmpf_im_sprxml AS NVARCHAR(MAX)))                                
SELECT @tmpf_im_spr = '<?xml version='+'"'+'1.0'+'"'+' encoding='+'"'+'windows-1251'+'"'+'?>'+@tmp0 

--Уникальный id
declare @myid varchar(255) 
SELECT @myid = CONVERT(CHAR(255), NEWID()) 

--Отправляем в папку
exec lexdt '##t'
create table ##t(text varchar(max))
insert into ##t(text)
select @tmpf_im_spr

declare @patchFull varchar(max)
, @file varchar(max) = 'KONVERT_' 
               + @inn_pokup 
			   + @kpp_pokup
			   + '_'
			   + @inn
			   + @kpp
			   + '_'
			   + dbo.dtos(@getdate)
			   + '_' 
			   + RTRIM (@myid)
			   + '.sbis.xml'
, @SQL varchar(max)
, @userVcode int

--Определяем наименование папки пользователя
select @userVcode = vcode from [Schema].[VBN_uzdo_sbis_user] where userName = user_name()

select @patchFull = '\\sbis_.ru\UZDO_SBIS_Connect\' 
					+ convert(varchar(255),@userVcode) 
					+ '\Exchange\Отправляемые\' 

select @SQL='BCP.exe "SELECT top (1) text FROM serv.tempdb..##t" queryout ' + @patchFull+@file + ' -c -C 1251 -S -T'

--select @SQL

exec dbo.bsp_cmdshell @SQL

/*
delete from nalog_schema.bn_sbis_int                                 
INSERT INTO nalog_schema.bn_sbis_int (stroka, name)                                
SELECT @tmpf_im_spr, @name                                

declare @puth varchar(2000)      
select @puth = '\\sbis_.ru\UZDO_SBIS_Connect\1\Exchange\Отправляемые\' 
--SBIS_Connect\1 - Шарапов Владимир Петрович
                    
select @text = ''                                
                        
exec lexdt '#ttt_mass'                              
create table #ttt_mass (name varchar(max))                                
                                
select @text = @text
 + 'insert into #ttt_mass exec dbo.bsp_cmdshell ''BCP.EXE "select stroka from schema.bn_sbis_int where id = ' 
 + convert(varchar(max),ID) + '" queryout '
 + @puth 
 + name 
 + '.sbis.xml' 
 + ' -c -C 1251 -S '
 + @@ServerName
 + case 
   when dbo.code() = 194 
   then ',65425' 
   else '' 
   end                                
 + ' -T'' WAITFOR DELAY ''00:00:00.010'''                 
from nalog_schema.bn_sbis_int                              
exec (@text)
*/
/*
exec lexdt '##t'
create table ##t(vcode int)
insert into ##t(vcode)
select 1

declare @patchFull varchar(max) = '\\sbis_.ru\UZDO_SBIS_Connect\1\Exchange\Отправляемые\' 
, @file varchar(max) = '1.txt'
, @SQL varchar(max)

select @SQL='BCP.exe "SELECT top (1) vcode FROM serv.tempdb..##t" queryout ' + @patchFull+@file + ' -c -C 1251 -S -T'

select @SQL

exec dbo.bsp_cmdshell @SQL

*/