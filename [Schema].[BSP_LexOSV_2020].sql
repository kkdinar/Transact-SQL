ALTER procedure [Schema].[BSP_prodOSV_2020]
as
set nocount on;
set ANSI_WARNINGS off;

/*commentBegin
������: ������������� ���� 
��������: ��������-��������� ��������� 2020
����������: ��������-��������� ��������� 2020
�����: ���������� �.�.
���� ��������: 20.05.2020
��������: ��������-��������� ��������� 2020
commentEnd*/

----{������������
--exec proddt '#OSV_param,#printObo'
--create table #OSV_param(
-- bdate datetime         -- ���� ������
--,edate datetime         -- ���� �����
--,schet varchar(500)     -- ����� ����� �������
--,schetkor varchar(500)  -- �������� ����� �������
--,code varchar(500)  -- code ����� �������
--,gcode varchar(500)     -- gcode ����� �������
--,params varchar(500)	-- �������������� ��������� ����� �������
---- analitCode - ��������� ���� ��������
---- hideSchet  - ������ ����
---- schetkorShow - �������� �������
---- koranal		- �������� ��������� ��������
--)
--insert into #OSV_param(bdate,edate,schet,schetkor,code,gcode,params)
--values (
-- '20210801'		-- @bdate datetime
--,'20210831'		-- @edate datetime
--,'23%'	-- @schet varchar(512)
--,null	-- '02%' @schetkor varchar(512)
--,'249'--'5,26,187,190,191,194,196,201,240,246,247,249,250'	-- @code varchar(512)--
--,'12312,12270'	-- @gcode varchar(512)  30641015,12271,12857,241260,20760
---- 12311 ��������� ��������		aType = ��������� ���������
---- 12312 ����������				aType = ��������� ���������
---- 12271 �������������
---- 12319 �����
---- 20774 ����������� �������������
---- 12270 �������
--,'analitCode,schetkorShow'
--)
----��������� ������� � ��������� ��������
--exec proddt '#AnaliticsFilter' 
--create table #AnaliticsFilter(gcode int, filtr int)
----insert into #AnaliticsFilter (gcode,filtr)
----values (12312,17909832)--19153530
--	 --, (12270,3342870)  

----������� � �������������� �����
--exec proddt '#ColumnSetupprodOSV_2020'
--CREATE TABLE [#ColumnSetupprodOSV_2020] (
--       [VCode] [int] IDENTITY (1, 1) NOT NULL ,
---- ������������ ����
--       [FieldName] [varchar] (50) NULL ,
--       [Label] [varchar] (50) NULL ,
--       [Width] [varchar] (50) NULL ,
---- �������������� ����
--       -- [Readonly] [bit],
--       [SprType] [varchar] (50) NULL ,
--       [Properties] [varchar] (50) NULL ,
--       [GroupFlag] [integer] NULL,
--       [PageIndex] [integer] NULL,      -- ���� ��������� ����
--       [ViewName] [varchar] (50) NULL,  -- ���� ����������� ���� ViewName,
--       -- ������ �������� ����� �������� ������� �� "���" (ViewName)
--       [SetCode] int NULL               -- ���� ����������� ���� SetCode,
--       -- ���. ��������� ������������� ������� ����� ������� �� ������� ����
--) ON [PRIMARY]
----}������������

if (object_id('Tempdb..#OSV_param') is null)
begin
 raiserror('�� ������� ������� � ����������� "#OSV_param"',16,1)
 return
end

declare
  @bdate datetime        = null -- ���� ������
, @edate datetime        = null -- ���� �����
, @schet varchar(512)    = null -- ����� ����� �������
, @schetkor varchar(512) = null -- �������� ����� �������
, @code varchar(255) = null -- code ����� �������
, @gcode varchar(255)    = null -- gcode ����� �������
, @params varchar(500)	 = null	-- �������������� ��������� ����� �������
, @analitCode bit		 = 0	-- ��������� ���� ��������
, @hideSchet  bit		 = 0	-- �������� ���� ��� ������ ������
, @schetkorShow bit		 = 0	-- �������� �������
, @sql nvarchar(max)

select top 1
 @bdate = bdate
,@edate = edate
,@schet = schet
,@schetkor = schetkor
,@code = code 
,@gcode = gcode
,@params = params
from #OSV_param

if(@params like '%analitCode%')		set @analitCode = 1 
if(@params like '%hideSchet%')		set @hideSchet = 1 
if(@params like '%schetkorShow%')	set @schetkorShow = 1

exec proddt '#printObo'
create table #printObo ( schet     varchar(10)  not null
						, korSchet varchar(10)  not null
						, code varchar(30)  not null
						, anal     varchar(500) null
						, koranal  varchar(500)	null
						, acode0 varchar(500), acode1 varchar(500), acode2 varchar(500), acode3 varchar(500), acode4 varchar(500)
						, acode5 varchar(500), acode6 varchar(500), acode7 varchar(500), acode8 varchar(500), acode9 varchar(500)
						, acode10 varchar(500), acode11 varchar(500), acode12 varchar(500), acode13 varchar(500), acode14 varchar(500)
						, acode15 varchar(500), acode16 varchar(500), acode17 varchar(500), acode18 varchar(500), acode19 varchar(500)
						, ostnd money null
						, ostnk money null
						, dobo money null
						, kobo money null
						, ostkd money null
						, ostkk money null)

if (@schet is null)
begin
 raiserror ('�� ������� ����', 16, -1)
 return
end

if (@code is null)
begin
 raiserror ('�� ������� code', 16, -1)
 return
end

if (@bdate is null)  select @bdate = getdate()
if (@edate is null)  select @edate = @bdate  
if (@edate < @bdate) select @edate = @bdate  
 
-- ������ ���������� gcode
exec proddt '#gcode'
create table #gcode (vcode int identity(0,1), gcode int null)  
if isnull(@gcode,'') <> ''  
begin
 insert into #gcode (gcode)  
 select partstring from dbo.prodStringToList (@gcode, ',', 0) 
end 
--select * from #gcode

--������ ������� � code
exec proddt '#code'
create table #code (code int not null)
insert into #code(code)
select distinct partstring
from [dbo].[prodstringtolist](@code,',',1)
where isnull(@code,'')<>''

--������ ������� � codeplan
exec proddt '#codeplan'
create table #codeplan (codeplan varchar(100) not null, code int not null)
insert into #codeplan(codeplan, code)
select distinct s.vcode, s.code
from [dbo].[prodsetup_h] as s
join #code as u on u.code = s.code

--������ ������� � ������������� � ��������� �������
exec proddt '#incomingSchet'
create table #incomingSchet (schet varchar(100) not null)
insert into #incomingSchet(schet)
select distinct partstring
from [dbo].[prodstringtolist](@schet,',',1)

--������ ������� � ��������� ������� �� prodPlans
exec proddt '#schet'
create table #schet (schet varchar(100) primary key, obdoc int not null)
insert into #schet(schet, obdoc)
select distinct 
  p.schet
  -- � ����� ����� ���� ������ ��������� �� ������ ������� ����������, ������� max()
, obdoc = max(coalesce(p.valuta, p.obdoc, 0)) --������������� ������(valuta), ������������ ���������(obdoc)
from [Schema].[prodPlans_h] as p
join #codeplan as c on c.codeplan = p.codeplan
join #incomingSchet as i on p.schet like i.schet
where isnull(p.bdate,'19000101') <= @bdate
  and isnull(p.edate,'21000101') >= @edate
group by p.schet

--������ ������� � ������������� � ��������� ����������
truncate table #incomingSchet
insert into #incomingSchet(schet)
select distinct partstring
from [dbo].[prodstringtolist](@schetkor,',',1)
where isnull(@schetkor,'')<>''

exec proddt '#korSchet'
create table #korSchet (schet varchar(100) primary key)
insert into #korSchet(schet)
select distinct p.schet
from [Schema].[prodPlans_h] as p
join #incomingSchet as i on p.schet like i.schet
where isnull(p.bdate,'19000101') <= @bdate
  and isnull(p.edate,'21000101') >= @edate
group by p.schet

--������ ������� ������ � �� gcode, vcode - ���������� ����� gcode ��� ������
exec proddt '#schet_gcode'
create table #schet_gcode (vcode int not null
							, schet varchar(50) not null
							, gcode int not null
							, saldo bit not null
							, main  bit not null default 0 -- ������� ��������� �� ����� schet
							, code int not null
							, primary key (schet, gcode, code)) 
insert into #schet_gcode(vcode, schet, gcode, saldo, main, code)
select
  vcode = row_number() over (partition by g.schet,g.code order by g.typeanal) - 1  
, schet = g.schet
, gcode = g.typeanal
, saldo = g.saldo		-- ������������� ������	
, main = g.main
, code = g.code
from(
      /*select 
	    p.schet
	  , a.typeanal
	  -- � ����� ����� ���� ������ ��������� �� ������ ������� ����������, ������� max()
	  , saldo = max( case 
	                 when a.typeanal = 386842 and isnull(a.ostanal,0) = 1 -- 386842(���� ������� � ��������) / ostanal-���������� ���������
			      	 then 1 
			      	 else isnull(a.saldo,0) -- ������������� ������
			      	 end)
      from [Schema].[prodPlans_h] as p
      join #schet as s on s.schet = p.schet
	  join #codeplan as c on c.codeplan = p.codeplan
      join [Schema].[prodAnPlans_h] as a on a.pcode = p.vcode
	  where not exists (select 1 from #gcode as g where g.gcode = a.typeanal)
	  group by p.schet, a.typeanal

	  union

	  select    --��������� gcode ������� ������� � ���������
	    p.schet
	  , a.typeanal
	  , saldo = 1	  -- ��� ���������� gcode ����������� ������������� ������
      from [Schema].[prodPlans_h] as p
      join #schet as s on s.schet = p.schet
	  join #codeplan as c on c.codeplan = p.codeplan
      join [Schema].[prodAnPlans_h] as a on a.pcode = p.vcode
	  join #gcode as g on g.gcode = a.typeanal
	  group by p.schet, a.typeanal*/
	  select 
		p.schet
	  , typeanal = p.code_anal
	  , main = 1					-- ����������� ������� ������� ���������
	  , code = c.code
	  , saldo = 0					-- ������������� ������
	  from [Schema].[prodPlans_h] as p
      join #schet as s on s.schet = p.schet
	  join #codeplan as c on c.codeplan = p.codeplan
	  --join #gcode as g on g.gcode = p.code_anal
	  where p.code_anal is not null
	    --and(exists (select 1 from #gcode as g where g.gcode = p.code_anal)
		   -- or @gcode is null)

	  union

	  select   
	    p.schet
	  , a.typeanal
	  , main = 0
	  , code = c.code
	  , saldo = isnull(a.saldo,0) -- ������������� ������
      from [Schema].[prodPlans_h] as p
      join #schet as s on s.schet = p.schet
	  join #codeplan as c on c.codeplan = p.codeplan
      join [Schema].[prodAnPlans_h] as a on a.pcode = p.vcode	  
	  --join #gcode as g on g.gcode = a.typeanal
	   --where (exists (select 1 from #gcode as g where g.gcode = a.typeanal)
		  --    or @gcode is null)
     ) as g

--�������� �� ������� ���������� gcode
exec proddt '#gcodeList'
create table #gcodeList(id int identity(0,1), gcode int not null)
insert into #gcodeList(gcode)
select distinct gcode from #schet_gcode order by gcode

--������ �� ����� �������� � ����� ��������
exec proddt '#acodeFilter'
create table #acodeFilter(gcode		int not null
						, filtr		int not null
						, main		bit not null default 0
						, code	int not null)
insert into #acodeFilter (gcode, filtr, main, code)
select a.gcode, a.filtr, s.main, s.code
from #AnaliticsFilter as a 
left join #schet_gcode as s on s.gcode = a.gcode

--select * from  #code
--select * from  #acodeFilter
--select * from  #schet
--select * from  #korSchet
--select * from  #codeplan
--select * from  #schet_gcode where gcode = 12271 order by code,vcode
--select * from  #schet_gcode order by code, gcode
--select * from [Schema].[prodPlans_h] where schet = '230000000'
--select * from [Schema].[prodAnPlans_h] where typeanal = 386842
--select * from [dbo].[prodbuhALL] where pcode = 1182486476
--select * from [dbo].[prodostatkiALL] where vcode = 129522276 --rdate >= '20210801'
--select * from [dbo].[prodVaOstatkiALL] where pcode = 129522276
--select * from #gcodeList

--{ �������� ������� �� ��������� ������
--������ ������� ��� ����� ������ � ���������� @bdate and @edate �� ������ prodbuhALL, prodVADdataALL, prodVAKdataALL
exec proddt '#turnovers'
create table #turnovers (  kind     varchar(20) not null  -- ��� �����: debet, kredit
 				         , schet    varchar(10) not null
 						 , korSchet varchar(10)     null
 				         , gcode    int             null
 				         , acode    int             null
 				         , summa    money       not null
 						 , code int         not null
 						 , pcode	int             null
 						 , rdate    datetime        null
						 , anal     int         not null
						 , koranal  int         not null
						 ,gcodeAnal int			not null )

insert into #turnovers (kind,schet,korSchet,gcode,acode,summa,code,pcode,rdate,anal,koranal,gcodeAnal) 
--�������� ��������� �������
select kind     = 'debet'
	 , schet	= isnull(b.debet,0)
	 , korSchet	= isnull(b.kredit,0)
	 , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , code = b.code	 
	 , pcode	= b.pcode
	 , rdate    = b.rdate
	 , anal		= b.danal
	 , koranal	= b.kanal
	 , gcodeAnal= isnull(main.gcode,0)
	 --, gcodeKoranal	= 0
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.DEBET
join #code as u on u.code = b.code
join [dbo].[prodVADdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.danal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVADdataALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate between @bdate and @edate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)

--�������� ���������� �������
insert into #turnovers (kind,schet,korSchet,gcode,acode,summa,code,pcode,rdate,anal,koranal,gcodeAnal) 
select kind     = 'kredit'
	 , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , code = b.code
	 , pcode	= b.pcode
	 , rdate    = b.rdate
	 , anal		= b.kanal
	 , koranal	= b.danal
	 , gcodeAnal= isnull(main.gcode,0)
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.KREDIT
join #code as u on u.code = b.code
join [dbo].[prodVAKdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.kanal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVADdataALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate between @bdate and @edate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)

--select * from #turnovers where gcode = 12270 order by acode (12270,3342870)
--select sum(summa) from #turnovers where gcode = 12270 and kind = 'kredit'
--select * from #turnovers where anal = 19153530 order by anal (12312,19153530)
--select sum(summa) from #turnovers where  kind = 'debet'
--select * from #turnovers where gcodeanal <> 12271 12312
--select * from #turnovers where code = 26 and gcode = 12312

--���� ���� �������� �������� �� codeplan, ��� ���� �� ������� � ��������� prodOstatki_H
exec proddt '#odate'
create table #odate (code int not null, odate datetime not null)
insert into #odate(code, odate)
select code = s.code
     , odate = case 
	           when s.bdate > @bdate
			   then @bdate
			   when datepart(day,s.bdate) <> 1					   -- ���� s.bdate �� ������ ���� ������
			   then dateadd(day,1-(datepart(day,s.bdate)),s.bdate) -- �� �������� ������ ���� ������
			   else s.bdate
			   end
from [dbo].[prodsetup_h] as s 
join #codeplan as c on c.codeplan = s.vcode

--{ ������ �� ������
--������ ������� ��� ����� ������ �� ������ �� ������ prodbuhALL, prodVADdataALL, prodVAKdataALL, prodostatkiALL
exec proddt '#beginSaldo'
create table #beginSaldo ( kind     varchar(20) not null  -- ��� �����: debet, kredit, ost
				         , schet    varchar(10) not null
						 , korSchet varchar(10)     null
				         , gcode    int             null
				         , acode    int             null
				         , summa    money       not null
				         , rdate    datetime        null
						 , code int         not null
						 , pcode	int             null
						 , anal     int         not null
						 , koranal  int         not null
				         ,gcodeAnal int			not null )

--�������� ��������� ������� ��� ������ �� ������ � ���������� ����� odate � @bdate
insert into #beginSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,pcode,anal,koranal,gcodeAnal)  
select kind     = 'beginSaldo_debet'
	 , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , pcode	= b.pcode
	 , anal		= b.danal
	 , koranal	= b.kanal
	 , gcodeAnal= isnull(main.gcode,0)
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.DEBET
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVADdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.danal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVADdataALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate >= o.odate and b.rdate < @bdate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)

--�������� ���������� ������� ��� ������ �� ������ � ���������� ����� odate � @bdate
insert into #beginSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,pcode,anal,koranal,gcodeAnal)
select kind     = 'beginSaldo_kredit'
	 , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = -b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , pcode	= b.pcode
	 , anal		= b.kanal
	 , koranal	= b.danal
	 , gcodeAnal= isnull(main.gcode,0)
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.KREDIT
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVAKdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.kanal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVAKdataALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate >= o.odate and b.rdate < @bdate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)

--�������� ������� ��� ������ �� ������ �� ���� odate
insert into #beginSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,pcode,anal,koranal,gcodeAnal)
select kind     = 'beginSaldo_ost'
     , schet    = b.schet
	 , korSchet = 0
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , pcode	= b.vcode
	 , anal		= b.anal
	 , koranal	= 0
	 , gcodeAnal= isnull(main.gcode,0)
from [dbo].[prodostatkiALL] as b
join #schet as s on s.schet = b.SCHET
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVaOstatkiALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.anal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVaOstatkiALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate = o.odate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)


--select * from #odate where code = 249
--select * from #beginSaldo where acode = 16915396
--} ������ �� ������

--{ ������ �� �����
--������ ������� ��� ����� ������ �� ����� �� ������ prodbuhALL, prodVADdataALL, prodVAKdataALL, prodostatkiALL
exec proddt '#endSaldo'
create table #endSaldo ( kind		varchar(20) not null  -- ��� �����: debet, kredit, ost
				       , schet		varchar(10) not null
					   , korSchet	varchar(10)     null
				       , gcode		int             null
				       , acode		int             null
				       , summa		money       not null
				       , rdate		datetime        null
					   , code	int			not null
					   , pcode		int             null
					   , anal		int         not null
					   , koranal	int         not null
				       ,gcodeAnal int			not null)

--�������� ��������� ������� ��� ������ �� ������ � ���������� ����� odate � @edate
insert into #endSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,pcode,anal,koranal,gcodeAnal)  
select kind     = 'endSaldo_debet'
     , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , pcode	= b.pcode
	 , anal		= b.danal
	 , koranal	= b.kanal
	 , gcodeAnal= isnull(main.gcode,0)
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.DEBET
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVADdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.danal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVADdataALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate >= o.odate and b.rdate <= @edate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)

--�������� ���������� ������� ��� ������ �� ������ � ���������� ����� odate � @edate
insert into #endSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,pcode,anal,koranal,gcodeAnal)
select kind     = 'endSaldo_kredit'
     , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = -b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , pcode	= b.pcode
	 , anal		= b.kanal
	 , koranal	= b.danal
	 , gcodeAnal= isnull(main.gcode,0)
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.KREDIT
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVAKdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.kanal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVAKdataALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate >= o.odate and b.rdate <= @edate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)

--�������� ������� ��� ������ �� ������ �� ���� odate
 insert into #endSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,pcode,anal,koranal,gcodeAnal)
select kind		= 'endSaldo_ost'
     , schet	= b.schet
	 , korSchet = 0
     , gcode	= isnull(v.gcode,0)
	 , acode	= isnull(v.acode,0)
	 , summa	= b.summa
	 , rdate	= b.rdate
	 , code = b.code
	 , pcode	= b.vcode
	 , anal		= b.anal
	 , koranal	= 0
	 , gcodeAnal= isnull(main.gcode,0)
from [dbo].[prodostatkiALL] as b
join #schet as s on s.schet = b.SCHET
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVaOstatkiALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate
left join #schet_gcode as main on main.main = 1 and main.code = b.code
outer apply (select filtr = case when exists (select 1 
												from #acodeFilter as f 
												where f.main = 1 
												  and f.code = b.code 
												  and f.filtr = b.anal)
									then 1 else 0 end) as acodeFilterMain
outer apply (select filtr = case when exists (select 1 
												from [dbo].[prodVaOstatkiALL] as vv
												join #acodeFilter as f on f.main <> 1 
																		and f.code = b.code
																		and f.filtr = v.acode
												where b.vcode=vv.pcode 
												  and b.rdate=vv.vrdate)
									then 1 else 0 end) as acodeFilter
where b.rdate = o.odate
--���� ����������� acode, ���� ������ �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main = 1 and f.code = b.code)
				then acodeFilterMain.filtr
				else 1 end)
--���� ����������� acode, ���� ������ �� �� ������� ���������
and (1 = case when exists (select 1 from #acodeFilter as f where f.main <> 1 and f.code = b.code)
				then acodeFilter.filtr
				else 1 end)

--select * from #endSaldo
--} ������ �� �����

--{ ������������ �������, ������������ �� �������� acode � gcode
exec proddt '#ag_turnovers'
create table #ag_turnovers ( 
 	 kind     varchar(20) not null  -- ��� �����: debet, kredit, ost
   , schet    varchar(10) not null
   , korSchet varchar(10)     null
   , summa    money       not null
   , rdate    datetime        null
   , code int         not null
   , pcode	  int             null	
   , anal     int         not null
   , koranal  int         not null  
   , acode0 int, acode1 int, acode2 int, acode3 int, acode4 int, acode5 int, acode6 int, acode7 int, acode8 int, acode9 int
   , acode10 int,acode11 int,acode12 int,acode13 int,acode14 int,acode15 int,acode16 int,acode17 int,acode18 int,acode19 int
   , gcode0 int, gcode1 int, gcode2 int, gcode3 int, gcode4 int, gcode5 int, gcode6 int, gcode7 int, gcode8 int, gcode9 int
   , gcode10 int,gcode11 int,gcode12 int,gcode13 int,gcode14 int,gcode15 int,gcode16 int,gcode17 int,gcode18 int,gcode19 int
   )

insert into #ag_turnovers (
     kind, schet, korSchet, summa, rdate, code, pcode, anal, koranal
   , acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9
   , acode10,acode11,acode12,acode13,acode14,acode15,acode16,acode17,acode18,acode19
   , gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9
   , gcode10,gcode11,gcode12,gcode13,gcode14,gcode15,gcode16,gcode17,gcode18,gcode19 
   )
select kind     = t.kind
     , schet    = t.schet
	 , korSchet = t.korSchet
	 , summa    = t.summa
	 , rdate    = t.rdate
	 , code = t.code
	 , pcode	= t.pcode
	 , anal		= t.anal
	 , koranal	= t.koranal
	 , acode0 =  max(case when l.id=0  and l.gcode=t.gcode		then t.acode
				 		  when l.id=0  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode1 =  max(case when l.id=1  and l.gcode=t.gcode		then t.acode
				 		  when l.id=1  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode2 =  max(case when l.id=2  and l.gcode=t.gcode		then t.acode
				 		  when l.id=2  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode3 =  max(case when l.id=3  and l.gcode=t.gcode		then t.acode
				 		  when l.id=3  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode4 =  max(case when l.id=4  and l.gcode=t.gcode  	then t.acode
				 		  when l.id=4  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode5 =  max(case when l.id=5  and l.gcode=t.gcode  	then t.acode
				 		  when l.id=5  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode6 =  max(case when l.id=6  and l.gcode=t.gcode		then t.acode
				 		  when l.id=6  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode7 =  max(case when l.id=7  and l.gcode=t.gcode		then t.acode
				 		  when l.id=7  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode8 =  max(case when l.id=8  and l.gcode=t.gcode		then t.acode
				 		  when l.id=8  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode9 =  max(case when l.id=9  and l.gcode=t.gcode		then t.acode
						  when l.id=9  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode10 = max(case when l.id=10 and l.gcode=t.gcode		then t.acode
						  when l.id=10 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode11 = max(case when l.id=11 and l.gcode=t.gcode		then t.acode
						  when l.id=11 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode12 = max(case when l.id=12 and l.gcode=t.gcode		then t.acode
						  when l.id=12 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode13 = max(case when l.id=13 and l.gcode=t.gcode		then t.acode
						  when l.id=13 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode14 = max(case when l.id=14 and l.gcode=t.gcode		then t.acode
						  when l.id=14 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode15 = max(case when l.id=15 and l.gcode=t.gcode		then t.acode
						  when l.id=15 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode16 = max(case when l.id=16 and l.gcode=t.gcode		then t.acode
						  when l.id=16 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode17 = max(case when l.id=17 and l.gcode=t.gcode		then t.acode
						  when l.id=17 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode18 = max(case when l.id=18 and l.gcode=t.gcode		then t.acode
						  when l.id=18 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode19 = max(case when l.id=19 and l.gcode=t.gcode		then t.acode
						  when l.id=19 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , gcode0 =  max(case when l.id=0  and l.gcode=t.gcode		then t.gcode  
						  when l.id=0  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode1 =  max(case when l.id=1  and l.gcode=t.gcode		then t.gcode 
						  when l.id=1  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode2 =  max(case when l.id=2  and l.gcode=t.gcode		then t.gcode 
						  when l.id=2  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode3 =  max(case when l.id=3  and l.gcode=t.gcode		then t.gcode 
						  when l.id=3  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode4 =  max(case when l.id=4  and l.gcode=t.gcode		then t.gcode 
						  when l.id=4  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode5 =  max(case when l.id=5  and l.gcode=t.gcode		then t.gcode			
						  when l.id=5  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode6 =  max(case when l.id=6  and l.gcode=t.gcode		then t.gcode 
						  when l.id=6  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode7 =  max(case when l.id=7  and l.gcode=t.gcode		then t.gcode 
						  when l.id=7  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode8 =  max(case when l.id=8  and l.gcode=t.gcode		then t.gcode 
						  when l.id=8  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode9 =  max(case when l.id=9  and l.gcode=t.gcode		then t.gcode 
						  when l.id=9  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode10 = max(case when l.id=10 and l.gcode=t.gcode		then t.gcode 
						  when l.id=10 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode11 = max(case when l.id=11 and l.gcode=t.gcode		then t.gcode 
						  when l.id=11 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode12 = max(case when l.id=12 and l.gcode=t.gcode		then t.gcode 
						  when l.id=12 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode13 = max(case when l.id=13 and l.gcode=t.gcode		then t.gcode 
						  when l.id=13 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode14 = max(case when l.id=14 and l.gcode=t.gcode		then t.gcode 
						  when l.id=14 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode15 = max(case when l.id=15 and l.gcode=t.gcode		then t.gcode 
						  when l.id=15 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode16 = max(case when l.id=16 and l.gcode=t.gcode		then t.gcode 
						  when l.id=16 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode17 = max(case when l.id=17 and l.gcode=t.gcode		then t.gcode 
						  when l.id=17 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode18 = max(case when l.id=18 and l.gcode=t.gcode		then t.gcode 
						  when l.id=18 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode19 = max(case when l.id=19 and l.gcode=t.gcode		then t.gcode 
						  when l.id=19 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
from #gcodeList as l
join #turnovers as t on l.gcode = case when l.gcode = t.gcode then t.gcode else t.gcodeAnal end
join #schet_gcode as s on s.schet = t.schet and s.code = t.code 
	and s.gcode = case when l.gcode = t.gcode then t.gcode else t.gcodeAnal end
group by t.kind, t.schet, t.korSchet, t.summa, t.rdate, t.code, t.pcode, t.anal, t.koranal 

insert into #ag_turnovers (
     kind, schet, korSchet, summa, rdate, code, pcode, anal, koranal
   , acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9
   , acode10,acode11,acode12,acode13,acode14,acode15,acode16,acode17,acode18,acode19
   , gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9
   , gcode10,gcode11,gcode12,gcode13,gcode14,gcode15,gcode16,gcode17,gcode18,gcode19 
   )
select kind     = t.kind
     , schet    = t.schet
	 , korSchet = t.korSchet
	 , summa    = t.summa
	 , rdate    = t.rdate
	 , code = t.code
	 , pcode	= t.pcode
	 , anal		= t.anal
	 , koranal	= t.koranal
	 , acode0 =  max(case when l.id=0  and l.gcode=t.gcode		then t.acode
				 		  when l.id=0  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode1 =  max(case when l.id=1  and l.gcode=t.gcode		then t.acode
				 		  when l.id=1  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode2 =  max(case when l.id=2  and l.gcode=t.gcode		then t.acode
				 		  when l.id=2  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode3 =  max(case when l.id=3  and l.gcode=t.gcode		then t.acode
				 		  when l.id=3  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode4 =  max(case when l.id=4  and l.gcode=t.gcode  	then t.acode
				 		  when l.id=4  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode5 =  max(case when l.id=5  and l.gcode=t.gcode  	then t.acode
				 		  when l.id=5  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode6 =  max(case when l.id=6  and l.gcode=t.gcode		then t.acode
				 		  when l.id=6  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode7 =  max(case when l.id=7  and l.gcode=t.gcode		then t.acode
				 		  when l.id=7  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode8 =  max(case when l.id=8  and l.gcode=t.gcode		then t.acode
				 		  when l.id=8  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode9 =  max(case when l.id=9  and l.gcode=t.gcode		then t.acode
						  when l.id=9  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode10 = max(case when l.id=10 and l.gcode=t.gcode		then t.acode
						  when l.id=10 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode11 = max(case when l.id=11 and l.gcode=t.gcode		then t.acode
						  when l.id=11 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode12 = max(case when l.id=12 and l.gcode=t.gcode		then t.acode
						  when l.id=12 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode13 = max(case when l.id=13 and l.gcode=t.gcode		then t.acode
						  when l.id=13 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode14 = max(case when l.id=14 and l.gcode=t.gcode		then t.acode
						  when l.id=14 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode15 = max(case when l.id=15 and l.gcode=t.gcode		then t.acode
						  when l.id=15 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode16 = max(case when l.id=16 and l.gcode=t.gcode		then t.acode
						  when l.id=16 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode17 = max(case when l.id=17 and l.gcode=t.gcode		then t.acode
						  when l.id=17 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode18 = max(case when l.id=18 and l.gcode=t.gcode		then t.acode
						  when l.id=18 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode19 = max(case when l.id=19 and l.gcode=t.gcode		then t.acode
						  when l.id=19 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , gcode0 =  max(case when l.id=0  and l.gcode=t.gcode		then t.gcode  
						  when l.id=0  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode1 =  max(case when l.id=1  and l.gcode=t.gcode		then t.gcode 
						  when l.id=1  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode2 =  max(case when l.id=2  and l.gcode=t.gcode		then t.gcode 
						  when l.id=2  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode3 =  max(case when l.id=3  and l.gcode=t.gcode		then t.gcode 
						  when l.id=3  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode4 =  max(case when l.id=4  and l.gcode=t.gcode		then t.gcode 
						  when l.id=4  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode5 =  max(case when l.id=5  and l.gcode=t.gcode		then t.gcode			
						  when l.id=5  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode6 =  max(case when l.id=6  and l.gcode=t.gcode		then t.gcode 
						  when l.id=6  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode7 =  max(case when l.id=7  and l.gcode=t.gcode		then t.gcode 
						  when l.id=7  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode8 =  max(case when l.id=8  and l.gcode=t.gcode		then t.gcode 
						  when l.id=8  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode9 =  max(case when l.id=9  and l.gcode=t.gcode		then t.gcode 
						  when l.id=9  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode10 = max(case when l.id=10 and l.gcode=t.gcode		then t.gcode 
						  when l.id=10 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode11 = max(case when l.id=11 and l.gcode=t.gcode		then t.gcode 
						  when l.id=11 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode12 = max(case when l.id=12 and l.gcode=t.gcode		then t.gcode 
						  when l.id=12 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode13 = max(case when l.id=13 and l.gcode=t.gcode		then t.gcode 
						  when l.id=13 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode14 = max(case when l.id=14 and l.gcode=t.gcode		then t.gcode 
						  when l.id=14 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode15 = max(case when l.id=15 and l.gcode=t.gcode		then t.gcode 
						  when l.id=15 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode16 = max(case when l.id=16 and l.gcode=t.gcode		then t.gcode 
						  when l.id=16 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode17 = max(case when l.id=17 and l.gcode=t.gcode		then t.gcode 
						  when l.id=17 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode18 = max(case when l.id=18 and l.gcode=t.gcode		then t.gcode 
						  when l.id=18 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode19 = max(case when l.id=19 and l.gcode=t.gcode		then t.gcode 
						  when l.id=19 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
from #gcodeList as l
join #beginSaldo as t on l.gcode = case when l.gcode = t.gcode then t.gcode else t.gcodeAnal end
join #schet_gcode as s on s.schet = t.schet and s.code = t.code 
	and s.gcode = case when l.gcode = t.gcode then t.gcode else t.gcodeAnal end
group by t.kind, t.schet, t.korSchet, t.summa, t.rdate, t.code, t.pcode, t.anal, t.koranal 

insert into #ag_turnovers (
     kind, schet, korSchet, summa, rdate, code, pcode, anal, koranal
   , acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9
   , acode10,acode11,acode12,acode13,acode14,acode15,acode16,acode17,acode18,acode19
   , gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9
   , gcode10,gcode11,gcode12,gcode13,gcode14,gcode15,gcode16,gcode17,gcode18,gcode19 
   )
select kind     = t.kind
     , schet    = t.schet
	 , korSchet = t.korSchet
	 , summa    = t.summa
	 , rdate    = t.rdate
	 , code = t.code
	 , pcode	= t.pcode
	 , anal		= t.anal
	 , koranal	= t.koranal
	 , acode0 =  max(case when l.id=0  and l.gcode=t.gcode		then t.acode
				 		  when l.id=0  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode1 =  max(case when l.id=1  and l.gcode=t.gcode		then t.acode
				 		  when l.id=1  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode2 =  max(case when l.id=2  and l.gcode=t.gcode		then t.acode
				 		  when l.id=2  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode3 =  max(case when l.id=3  and l.gcode=t.gcode		then t.acode
				 		  when l.id=3  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode4 =  max(case when l.id=4  and l.gcode=t.gcode  	then t.acode
				 		  when l.id=4  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode5 =  max(case when l.id=5  and l.gcode=t.gcode  	then t.acode
				 		  when l.id=5  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode6 =  max(case when l.id=6  and l.gcode=t.gcode		then t.acode
				 		  when l.id=6  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode7 =  max(case when l.id=7  and l.gcode=t.gcode		then t.acode
				 		  when l.id=7  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode8 =  max(case when l.id=8  and l.gcode=t.gcode		then t.acode
				 		  when l.id=8  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode9 =  max(case when l.id=9  and l.gcode=t.gcode		then t.acode
						  when l.id=9  and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode10 = max(case when l.id=10 and l.gcode=t.gcode		then t.acode
						  when l.id=10 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode11 = max(case when l.id=11 and l.gcode=t.gcode		then t.acode
						  when l.id=11 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode12 = max(case when l.id=12 and l.gcode=t.gcode		then t.acode
						  when l.id=12 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode13 = max(case when l.id=13 and l.gcode=t.gcode		then t.acode
						  when l.id=13 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode14 = max(case when l.id=14 and l.gcode=t.gcode		then t.acode
						  when l.id=14 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode15 = max(case when l.id=15 and l.gcode=t.gcode		then t.acode
						  when l.id=15 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode16 = max(case when l.id=16 and l.gcode=t.gcode		then t.acode
						  when l.id=16 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode17 = max(case when l.id=17 and l.gcode=t.gcode		then t.acode
						  when l.id=17 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode18 = max(case when l.id=18 and l.gcode=t.gcode		then t.acode
						  when l.id=18 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , acode19 = max(case when l.id=19 and l.gcode=t.gcode		then t.acode
						  when l.id=19 and l.gcode=t.gcodeAnal	then t.anal else 0 end)
	 , gcode0 =  max(case when l.id=0  and l.gcode=t.gcode		then t.gcode  
						  when l.id=0  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode1 =  max(case when l.id=1  and l.gcode=t.gcode		then t.gcode 
						  when l.id=1  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode2 =  max(case when l.id=2  and l.gcode=t.gcode		then t.gcode 
						  when l.id=2  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode3 =  max(case when l.id=3  and l.gcode=t.gcode		then t.gcode 
						  when l.id=3  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode4 =  max(case when l.id=4  and l.gcode=t.gcode		then t.gcode 
						  when l.id=4  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode5 =  max(case when l.id=5  and l.gcode=t.gcode		then t.gcode			
						  when l.id=5  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode6 =  max(case when l.id=6  and l.gcode=t.gcode		then t.gcode 
						  when l.id=6  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode7 =  max(case when l.id=7  and l.gcode=t.gcode		then t.gcode 
						  when l.id=7  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode8 =  max(case when l.id=8  and l.gcode=t.gcode		then t.gcode 
						  when l.id=8  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode9 =  max(case when l.id=9  and l.gcode=t.gcode		then t.gcode 
						  when l.id=9  and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode10 = max(case when l.id=10 and l.gcode=t.gcode		then t.gcode 
						  when l.id=10 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode11 = max(case when l.id=11 and l.gcode=t.gcode		then t.gcode 
						  when l.id=11 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode12 = max(case when l.id=12 and l.gcode=t.gcode		then t.gcode 
						  when l.id=12 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode13 = max(case when l.id=13 and l.gcode=t.gcode		then t.gcode 
						  when l.id=13 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode14 = max(case when l.id=14 and l.gcode=t.gcode		then t.gcode 
						  when l.id=14 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode15 = max(case when l.id=15 and l.gcode=t.gcode		then t.gcode 
						  when l.id=15 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode16 = max(case when l.id=16 and l.gcode=t.gcode		then t.gcode 
						  when l.id=16 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode17 = max(case when l.id=17 and l.gcode=t.gcode		then t.gcode 
						  when l.id=17 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode18 = max(case when l.id=18 and l.gcode=t.gcode		then t.gcode 
						  when l.id=18 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
	 , gcode19 = max(case when l.id=19 and l.gcode=t.gcode		then t.gcode 
						  when l.id=19 and l.gcode=t.gcodeAnal	then t.gcodeAnal else 0 end)
from #gcodeList as l
join #endSaldo as t on l.gcode = case when l.gcode = t.gcode then t.gcode else t.gcodeAnal end
join #schet_gcode as s on s.schet = t.schet and s.code = t.code 
	and s.gcode = case when l.gcode = t.gcode then t.gcode else t.gcodeAnal end
group by t.kind, t.schet, t.korSchet, t.summa, t.rdate, t.code, t.pcode, t.anal, t.koranal 
--select * from #gcodeList
--select * from #schet_gcode

--select * from #ag_turnovers where code = 249
--select * from #turnovers where anal =12312 code = 249

--select * from #ag_turnovers where summa =644420  acode1 = 16915396 
--} ������������ �������, ������������ �� �������� acode � gcode

--{ �������� ������ � ������� � ������� #obo
exec proddt '#obo'
create table #obo (schet    varchar(10) not null
				 , korSchet varchar(10)     null
                 , rdate    datetime        null
                 , code int         not null
				 , anal     int         not null	
				 , koranal  int			not	null
                 , acode0 int, acode1 int, acode2 int, acode3 int, acode4 int, acode5 int, acode6 int, acode7 int, acode8 int, acode9 int
				 , acode10 int,acode11 int,acode12 int,acode13 int,acode14 int,acode15 int,acode16 int,acode17 int,acode18 int,acode19 int
				 , gcode0 int, gcode1 int, gcode2 int, gcode3 int, gcode4 int, gcode5 int, gcode6 int, gcode7 int, gcode8 int, gcode9 int
				 , gcode10 int,gcode11 int,gcode12 int,gcode13 int,gcode14 int,gcode15 int,gcode16 int,gcode17 int,gcode18 int,gcode19 int
                 , ostn money null -- ������ �� ������
				 , dobo money null -- ��������� ������� �� ������
				 , kobo money null -- ���������� ������� �� ������
				 , ostk money null -- ������ �� �����
     				)  
insert into #obo(schet, korSchet, rdate, code, anal, koranal
				, acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9
				, acode10,acode11,acode12,acode13,acode14,acode15,acode16,acode17,acode18,acode19
				, gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9
				, gcode10,gcode11,gcode12,gcode13,gcode14,gcode15,gcode16,gcode17,gcode18,gcode19 
				, ostn, dobo, kobo, ostk)
select schet, korSchet, rdate, code, anal, koranal
, acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9
, acode10,acode11,acode12,acode13,acode14,acode15,acode16,acode17,acode18,acode19
, gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9
, gcode10,gcode11,gcode12,gcode13,gcode14,gcode15,gcode16,gcode17,gcode18,gcode19
, ostn = sum(case when kind in ('beginSaldo_debet','beginSaldo_kredit','beginSaldo_ost') then summa else 0 end)
, dobo = sum(case when kind = 'debet'													 then summa else 0 end)
, kobo = sum(case when kind = 'kredit'												 	 then -summa else 0 end)
, ostk = sum(case when kind in ('endSaldo_debet','endSaldo_kredit','endSaldo_ost')		 then summa else 0 end)
from #ag_turnovers
group by schet, korSchet, rdate, code, anal, koranal 
, acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9
, acode10,acode11,acode12,acode13,acode14,acode15,acode16,acode17,acode18,acode19
, gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9
, gcode10,gcode11,gcode12,gcode13,gcode14,gcode15,gcode16,gcode17,gcode18,gcode19

--select * from #obo where anal = 6441119
--select sum(dobo), sum(kobo) from #obo
--} �������� ������ � ������� � ������� #obo

--{ �������� ���������, ������� �� ����� ��������
if(@schetkorShow is null) update #obo set korSchet = '0'

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode0) 
 update #obo set gcode0 = 0, acode0 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode1) 
 update #obo set gcode1 = 0, acode1 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode2) 
 update #obo set gcode2 = 0, acode2 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode3) 
 update #obo set gcode3 = 0, acode3 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode4) 
 update #obo set gcode4 = 0, acode4 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode5) 
 update #obo set gcode5 = 0, acode5 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode6) 
 update #obo set gcode6 = 0, acode6 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode7) 
 update #obo set gcode7 = 0, acode7 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode8) 
 update #obo set gcode8 = 0, acode8 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode9) 
 update #obo set gcode9 = 0, acode9 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode10) 
 update #obo set gcode10 = 0, acode10 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode11) 
 update #obo set gcode11 = 0, acode11 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode12) 
 update #obo set gcode12 = 0, acode12 = 0

if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode13) 
 update #obo set gcode13 = 0, acode13 = 0										
																			
if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode14) 
 update #obo set gcode14 = 0, acode14 = 0										
																			
if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode15) 
 update #obo set gcode15 = 0, acode15 = 0										
																			
if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode16) 
 update #obo set gcode16 = 0, acode16 = 0										
																			
if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode17) 
 update #obo set gcode17 = 0, acode17 = 0										
																			
if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode18) 
 update #obo set gcode18 = 0, acode18 = 0										
																			
if not exists (select 1 from #obo as o join #gcode as g on g.gcode = o.gcode19) 
 update #obo set gcode19 = 0, acode19 = 0
--} �������� ���������, ������� �� ����� ��������

-- �������� ������������ �������� �� #obo � ������� #analName
exec proddt '#analName'
create table #analName (  anal        int          not null -- ��� ���������
						, name        varchar(255) not null -- ������������ ���������
						, podr        varchar(255) null     -- �������������
						, atype       varchar(255) not null -- ��� ���������
						, org_rosneft varchar(255) null     -- ���� ��������
						, org_inn     varchar(255) null     -- ��� �����������
						)
insert into #analName(anal, name, podr, atype, org_rosneft, org_inn)
select anal = a.anal
     , name =  case when @analitCode = 1
					then (case when a.anal = 0 then '...' else convert(varchar(255),a.anal) + ' ' + u.name end)
					else (case when a.anal = 0 then '...' else u.name end)
					end
	 , podr = convert(varchar(1000),null)
     , atype = u.atype
	 , org_rosneft = (select top 1 spr.id_rn from spr_org spr where spr.vcode = a.anal ) 
     , org_inn = (select top 1 inn from spr_org spr1 where spr1.vcode = a.anal)
from (
	   select distinct anal = anal	from #obo
	   union
	   select distinct anal = koranal from #obo
	   union
	   select distinct anal = acode0 from #obo
	   union   
	   select distinct anal = acode1 from #obo
	   union   
	   select distinct anal = acode2 from #obo
	   union   
	   select distinct anal = acode3 from #obo
	   union   
	   select distinct anal = acode4 from #obo
	   union   
	   select distinct anal = acode5 from #obo
	   union   
	   select distinct anal = acode6 from #obo
	   union   
	   select distinct anal = acode7 from #obo
	   union   
	   select distinct anal = acode8 from #obo
	   union   
	   select distinct anal = acode9 from #obo
	   union
	   select distinct anal = acode10 from #obo
	   union   
	   select distinct anal = acode11 from #obo
	   union   
	   select distinct anal = acode12 from #obo
	   union   
	   select distinct anal = acode13 from #obo
	   union   
	   select distinct anal = acode14 from #obo
	   union   
	   select distinct anal = acode15 from #obo
	   union   
	   select distinct anal = acode16 from #obo
	   union   
	   select distinct anal = acode17 from #obo
	   union   
	   select distinct anal = acode18 from #obo
	   union   
	   select distinct anal = acode19 from #obo
	  ) as a
left join [dbo].[unianalit] as u on a.anal=u.vcode 
--select * from #analName


-- ���������� � ���������
insert into #printObo(schet,korSchet,code, anal--, koranal
					, acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9
					, acode10,acode11,acode12,acode13,acode14,acode15,acode16,acode17,acode18,acode19
					,ostnd,ostnk,dobo,kobo,ostkd,ostkk )
select 
  schet = o.schet
, korSchet = case when o.korSchet = '0' then '...' else o.korSchet end
, code = (select a.name from [dbo].[filials] as a where a.vcode = o.code)
, anal     = (select a.name from #analname as a where a.anal = o.anal)
, acode0   = (select a.name from #analname as a where a.anal = o.acode0)
, acode1   = (select a.name from #analname as a where a.anal = o.acode1)
, acode2   = (select a.name from #analname as a where a.anal = o.acode2)
, acode3   = (select a.name from #analname as a where a.anal = o.acode3)
, acode4   = (select a.name from #analname as a where a.anal = o.acode4)
, acode5   = (select a.name from #analname as a where a.anal = o.acode5)
, acode6   = (select a.name from #analname as a where a.anal = o.acode6)
, acode7   = (select a.name from #analname as a where a.anal = o.acode7)
, acode8   = (select a.name from #analname as a where a.anal = o.acode8)
, acode9   = (select a.name from #analname as a where a.anal = o.acode9)
, acode10  = (select a.name from #analname as a where a.anal = o.acode10)
, acode11  = (select a.name from #analname as a where a.anal = o.acode11)
, acode12  = (select a.name from #analname as a where a.anal = o.acode12)
, acode13  = (select a.name from #analname as a where a.anal = o.acode13)
, acode14  = (select a.name from #analname as a where a.anal = o.acode14)
, acode15  = (select a.name from #analname as a where a.anal = o.acode15)
, acode16  = (select a.name from #analname as a where a.anal = o.acode16)
, acode17  = (select a.name from #analname as a where a.anal = o.acode17)
, acode18  = (select a.name from #analname as a where a.anal = o.acode18)
, acode19  = (select a.name from #analname as a where a.anal = o.acode19)
, ostnd   = sum(case when ostn>0 then ostn  else 0 end)
, ostnk   = sum(case when ostn<0 then -ostn else 0 end)
, dobo    = sum(dobo)
, kobo    = sum(case when kobo<0  then -kobo else 0 end)
--, kobo    = sum(kobo)
, ostkd   = sum(case when ostk>0  then ostk  else 0 end)
--, ostkd   = sum(ostk)
, ostkk   = sum(case when ostk<0  then -ostk else 0 end)                               
--, ostkk   = 0
from #obo as o
group by o.code,o.schet,o.korSchet, o.anal, o.koranal,
	o.acode0,o.acode1,o.acode2,o.acode3,o.acode4,o.acode5,o.acode6,o.acode7,o.acode8,o.acode9
	,o.acode10,o.acode11,o.acode12,o.acode13,o.acode14,o.acode15,o.acode16,o.acode17,o.acode18,o.acode19

--{ ��������������� �������
-- ���������� ������������� ������ 2
insert into #ColumnSetupprodOSV_2020 (Width, SetCode) values (2,10)

-- ������� ��������� �������:
if(@hideSchet = 0)  --���� �� ����� ���� "�������� ����"
 insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
 values ('schet', '����', 100, '�� ���������')

if(@schetkorShow = 1) --���� ������ �������
 insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
 values ('korSchet', '�������' , 100, '�� ���������')

insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
values	('code', '�����������', 150, '�� ���������')

declare @n int = 0
	, @i int = 0 
	, @_gcode int
	, @Name varchar(255)

select @n = max(id) from #gcodeList

while @i <= @n
begin

 select @_gcode = l.gcode from #gcodeList as l
 join #gcode as g on g.gcode = l.gcode
 where l.id = @i

 if(@_gcode is not null)
 begin
  select @Name = Name from dbo.Unianalit where vcode = @_gcode
  insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
  values
	 ('acode' + convert(varchar(50),@i), @Name, 150, '�� ���������')
 end

 set @_gcode = null
 set @i = @i + 1
end
-- ���� ����� �� ��������
declare  @ostnd varchar(50)
		,@ostnk varchar(50) 
		,@dobo	varchar(50)
		,@kobo	varchar(50)
		,@ostkd varchar(50)
		,@ostkk varchar(50)
select 
		 @ostnd = replace(convert(varchar(50),sum(ostnd)),'.',',')
		,@ostnk = replace(convert(varchar(50),sum(ostnk)),'.',',')
		,@dobo	= replace(convert(varchar(50),sum(dobo)),'.',',')
		,@kobo	= replace(convert(varchar(50),sum(kobo)),'.',',')
		,@ostkd = replace(convert(varchar(50),sum(ostkd)),'.',',')
		,@ostkk = replace(convert(varchar(50),sum(ostkk)),'.',',')
from #printObo

insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
values
	 ('ostnd', '������ �� ������|�����|'	+ @ostnd,	150, '�� ���������')
	,('ostnk', '������ �� ������|������|'	+ @ostnk,	150, '�� ���������')
	,('dobo',  '�������|�����|'				+ @dobo,	150, '�� ���������')
	,('kobo',  '�������|������|'			+ @kobo,	150, '�� ���������')
	,('ostkd', '������ �� �����|�����|'		+ @ostkd,	150, '�� ���������')
	,('ostkk', '������ �� �����|������|'	+ @ostkk,	150, '�� ���������')
--} ��������������� �������

select * from #printObo
--select * from #ColumnSetupprodOSV_2020

/*
--������ ������� ��� ����� ������ � ���������� @bdate and @edate �� ������ prodbuhALL, prodVADdataALL, prodVAKdataALL
exec proddt '#turnovers'
create table #turnovers (  kind     varchar(20) not null  -- ��� �����: debet, kredit
				         , schet    varchar(10) not null
						 , korSchet varchar(10) not null
				         , gcode    int         not null
				         , acode    int         not null
				         , summa    money       not null
				         , rdate    datetime    not null
						 , code int         not null
						 , anal     int         not null
						 , koranal  int         not null 
						 , pcode	int         not null
				         )

--�������� ��������� �������
select @sql = '
insert into #turnovers (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,koranal,pcode)  
select kind     = ''debet''
	 , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.danal
	 , koranal  = b.kanal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b 
join #schet as s on s.schet = b.DEBET '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end + '
join #code as u on u.code = b.code
join [dbo].[prodVADdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterNotMain = 0 and (@gcode is not null)) then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcode as g on g.gcode = v.gcode' else '' end
+ case when  @gcodeFilterNotMain = 1 then '  
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcodeFilterNotMain as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate between @bdate and @edate

union

select kind     = ''debet''
	 , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = b.danal
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.danal
	 , koranal  = b.kanal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b 
join #schet as s on s.schet = b.DEBET '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end + '
join #code as u on u.code = b.code 
join #schet_gcode as v on v.main = 1 and v.code = b.code and v.schet = s.schet ' --������� ������� ���������
+ case when (@gcodeFilterMain = 0 and (@gcode is not null)) then '  
  join #gcode as g on g.gcode = v.gcode' else '' end
+ case when  @gcodeFilterMain = 1 then '
  join #gcodeFilterMain as g on g.gcode = v.gcode and g.filtr = b.danal ' else '' end + '
where b.rdate between @bdate and @edate
'
--�������� ���������� �������
select @sql = @sql + '
insert into #turnovers (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,koranal,pcode)  
select kind     = ''kredit''
	 , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.kanal
	 , koranal  = b.danal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.KREDIT '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.DEBET ' else '' end +'
join #code as u on u.code = b.code
join [dbo].[prodVAKdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterNotMain = 0 and (@gcode is not null)) then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcode as g on g.gcode = v.gcode' else '' end
+ case when  @gcodeFilterNotMain = 1 then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcodeFilterNotMain as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate between @bdate and @edate 

union

select kind     = ''kredit''
	 , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = b.kanal
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.kanal
	 , koranal  = b.danal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b 
join #schet as s on s.schet = b.KREDIT '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end + '
join #code as u on u.code = b.code
join #schet_gcode as v on v.main = 1 and v.code = b.code and v.schet = s.schet '  --������� ������� ���������
+ case when (@gcodeFilterMain = 0 and (@gcode is not null)) then '
  join #gcode as g on g.gcode = v.gcode' else '' end
+ case when  @gcodeFilterMain = 1 then '
  join #gcodeFilterMain as g on g.gcode = v.gcode and g.filtr = b.kanal ' else '' end + '
where b.rdate between @bdate and @edate
'
select @sql
-- ������ �� ����������
exec dbo.SP_ExecuteSQL @sql, N'@bdate datetime, @edate datetime', @bdate = @bdate, @edate = @edate
--select * from #turnovers
*/



/*
--���� ���� �������� �������� �� codeplan, ��� ���� �� ������� � ��������� prodOstatki_H
exec proddt '#odate'
create table #odate (code int not null, odate datetime not null)
insert into #odate(code, odate)
select code = s.code
     , odate = case 
	           when s.bdate > @bdate
			   then @bdate
			   when datepart(day,s.bdate) <> 1					   -- ���� s.bdate �� ������ ���� ������
			   then dateadd(day,1-(datepart(day,s.bdate)),s.bdate) -- �� �������� ������ ���� ������
			   else s.bdate
			   end
from [dbo].[prodsetup_h] as s 
join #codeplan as c on c.codeplan = s.vcode

--������ ������� ��� ����� ������ �� ������ �� ������ prodbuhALL, prodVADdataALL, prodVAKdataALL, prodostatkiALL
exec proddt '#beginSaldo'
create table #beginSaldo ( kind     varchar(20)  not null  -- ��� �����: debet, kredit, ost
				         , schet    varchar(10) not null
						 , korSchet varchar(10) not null
				         , gcode    int         not null
				         , acode    int         not null
				         , summa    money       not null
				         , rdate    datetime    not null
						 , code int         not null
						 , anal     int         not null
						 , pcode	int         not null
				         )
--�������� ��������� ������� ��� ������ �� ������ � ���������� ����� odate � @bdate
select @sql = '
insert into #beginSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,pcode)  
select kind     = ''beginSaldo_debet''
	 , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = case when s.obdoc = 0 then 0 else b.danal end -- ������������ ���������(obdoc)
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.DEBET '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end +'
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVADdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterNotMain = 0 and (@gcode is not null)) then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterNotMain = 1 then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcodeFilterNotMain as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate >= o.odate and b.rdate < @bdate

union

select kind     = ''beginSaldo_debet''
	 , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = b.danal
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.danal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b 
join #schet as s on s.schet = b.DEBET '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end + '
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join #schet_gcode as v on v.main = 1 and v.code = b.code '  --������� ������� ���������
+ case when (@gcodeFilterMain = 0 and (@gcode is not null)) then '
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterMain = 1 then '
  join #gcodeFilterMain as g on g.gcode = v.gcode and g.filtr = b.danal ' else '' end + '
where b.rdate >= o.odate and b.rdate < @bdate
'
  
--�������� ���������� ������� ��� ������ �� ������ � ���������� ����� odate � @bdate
select @sql = @sql + '
insert into #beginSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,pcode)  
select kind     = ''beginSaldo_kredit''
	 , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = -b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = case when s.obdoc = 0 then 0 else b.kanal end -- ������������ ���������(obdoc)
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.KREDIT '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.DEBET ' else '' end +'
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVAKdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterNotMain = 0 and (@gcode is not null)) then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterNotMain = 1 then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcodeFilterNotMain as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate >= o.odate and b.rdate < @bdate

union

select kind     = ''beginSaldo_kredit''
	 , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = b.kanal
	 , summa    = -b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.kanal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b 
join #schet as s on s.schet = b.KREDIT '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end + '
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join #schet_gcode as v on v.main = 1 and v.code = b.code '  --������� ������� ���������
+ case when (@gcodeFilterMain = 0 and (@gcode is not null)) then '
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterMain = 1 then '
  join #gcodeFilterMain as g on g.gcode = v.gcode and g.filtr = b.kanal ' else '' end + '
where b.rdate >= o.odate and b.rdate < @bdate
'

select @sql = @sql + '
--�������� ������� ��� ������ �� ������ �� ���� odate
insert into #beginSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,pcode)  
select kind     = ''beginSaldo_ost''
     , schet    = b.schet
	 , korSchet = 0
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = case when s.obdoc = 0 then 0 else b.anal end  -- ������������ ���������(obdoc)
	 , pcode	= b.vcode
from [dbo].[prodostatkiALL] as b
join #schet as s on s.schet = b.SCHET
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVaOstatkiALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterAll = 0 and (@gcode is not null)) then '
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterAll = 1 then '
  join #gcodeFilterAll as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate = o.odate
'
-- ������ �� ����������
exec dbo.SP_ExecuteSQL @sql, N'@bdate datetime, @edate datetime', @bdate = @bdate, @edate = @edate

--select * from #turnovers where gcode = 12271
--select * from #odate where code = 249
--select * from #beginSaldo where acode = 16915396
--,844975936

--������ ������� ��� ����� ������ �� ����� �� ������ prodbuhALL, prodVADdataALL, prodVAKdataALL, prodostatkiALL
exec proddt '#endSaldo'
create table #endSaldo ( kind		varchar(20) not null  -- ��� �����: debet, kredit, ost
				       , schet		varchar(10) not null
					   , korSchet	varchar(10) not null
				       , gcode		int         not null
				       , acode		int         not null
				       , summa		money       not null
				       , rdate		datetime    not null
					   , code	int			not null
					   , anal		int         not null
					   , pcode		int         not null
				       )

--�������� ��������� ������� ��� ������ �� ������ � ���������� ����� odate � @edate
select @sql = '
insert into #endSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,pcode)  
select kind     = ''endSaldo_debet''
     , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = case when s.obdoc = 0 then 0 else b.danal end  -- ������������ ���������(obdoc)
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.DEBET '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end +'
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVADdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterNotMain = 0 and (@gcode is not null)) then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterNotMain = 1 then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcodeFilterNotMain as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate >= o.odate and b.rdate <= @edate

union

select kind     = ''endSaldo_debet''
	 , schet    = isnull(b.debet,0)
	 , korSchet = isnull(b.kredit,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = b.danal
	 , summa    = b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.danal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b 
join #schet as s on s.schet = b.DEBET '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end + '
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join #schet_gcode as v on v.main = 1 and v.code = b.code'  --������� ������� ���������
+ case when (@gcodeFilterMain = 0 and (@gcode is not null)) then '
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterMain = 1 then '
  join #gcodeFilterMain as g on g.gcode = v.gcode and g.filtr = b.danal ' else '' end + '
where b.rdate >= o.odate and b.rdate <= @edate
'
  
--�������� ���������� ������� ��� ������ �� ������ � ���������� ����� odate � @edate
select @sql = @sql + '
insert into #endSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,pcode)  
select kind     = ''endSaldo_kredit''
     , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = isnull(v.acode,0)
	 , summa    = -b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = case when s.obdoc = 0 then 0 else b.kanal end  -- ������������ ���������(obdoc)
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b
join #schet as s on s.schet = b.KREDIT '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.DEBET ' else '' end +'
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVAKdataALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterNotMain = 0 and (@gcode is not null)) then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterNotMain = 1 then '
  join #schet_gcode as vv on vv.main <> 1 and vv.code = b.code and vv.schet = s.schet and vv.gcode = v.gcode
  join #gcodeFilterNotMain as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate >= o.odate and b.rdate <= @edate

union

select kind     = ''endSaldo_kredit''
	 , schet    = isnull(b.kredit,0)
	 , korSchet = isnull(b.debet,0)
     , gcode    = isnull(v.gcode,0)
	 , acode    = b.kanal
	 , summa    = -b.summa
	 , rdate    = b.rdate
	 , code = b.code
	 , anal     = b.kanal
	 , pcode	= b.pcode
from [dbo].[prodbuhALL] as b 
join #schet as s on s.schet = b.KREDIT '
+ case when (@schetkor is not null) then 'join #korSchet as k on k.schet = b.KREDIT ' else '' end + '
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join #schet_gcode as v on v.main = 1 and v.code = b.code'  --������� ������� ���������
+ case when (@gcodeFilterMain = 0 and (@gcode is not null)) then '
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterMain = 1 then '
  join #gcodeFilterMain as g on g.gcode = v.gcode and g.filtr = b.kanal ' else '' end + '
where b.rdate >= o.odate and b.rdate <= @edate
'

select @sql = @sql + '
--�������� ������� ��� ������ �� ������ �� ���� odate
insert into #endSaldo (kind,schet,korSchet,gcode,acode,summa,rdate,code,anal,pcode)  
select kind = ''endSaldo_ost''
     , schet = b.schet
	 , korSchet = 0
     , gcode = isnull(v.gcode,0)
	 , acode = isnull(v.acode,0)
	 , summa = b.summa
	 , rdate = b.rdate
	 , code = b.code
	 , anal = case when s.obdoc = 0 then 0 else b.anal end --  ������������ ���������(obdoc)
	 , pcode	= b.vcode
from [dbo].[prodostatkiALL] as b
join #schet as s on s.schet = b.SCHET
join #code as u on u.code = b.code
join #odate as o on o.code = b.code
join [dbo].[prodVaOstatkiALL] as v on v.pcode = b.vcode and v.vrdate = b.rdate '
+ case when (@gcodeFilterAll = 0 and (@gcode is not null)) then '
  join #gcode as g on g.gcode = v.gcode ' else '' end
+ case when  @gcodeFilterAll = 1 then '
  join #gcodeFilterAll as g on g.gcode = v.gcode and g.filtr = v.acode ' else '' end + '
where b.rdate = o.odate 
'
-- ������ �� ����������
exec dbo.SP_ExecuteSQL @sql, N'@bdate datetime, @edate datetime', @bdate = @bdate, @edate = @edate

--select * from #turnovers
--select * from #beginSaldo  
--select * from #endSaldo
--select * from #schet_gcode


--declare @IX nvarchar (64), @SQL nvarchar(max)
--select @IX = convert (nvarchar (16), @@SPID) + N'_' + replace (convert (nvarchar (8), getdate (), 108), N':', N'_')
--SELECT @SQL = convert (nvarchar (max), N'
--CREATE NONCLUSTERED INDEX [#TmpIX_GRecOBO_') + @IX + N'_1] ON [#GRecOBO] ([BDate])              
--INCLUDE([NGDU],[code],[OSCode],[PCode],[EDate],[UZena],[Iznos_B],[Izn_Schet_B],[Kredit],[TDoc],[Bal_Schet],[PodrArend])'   
--+ N'CREATE NONCLUSTERED INDEX [#TmpIX_GIznOBO_' + @IX + N'_1] ON [#GIznOBO] ([BDate],[Iznos_Buh])              
--INCLUDE([code],[OSCode])'              
--EXEC (@SQL)

--������������ ������� #turnovers, ������������ �� �������� acode � gcode
exec proddt '#ag_turnovers'
create table #ag_turnovers ( 
 	 kind     varchar(20) not null  -- ��� �����: debet, kredit, ost
   , schet    varchar(10) not null
   , korSchet varchar(10) not null
   , summa    money       not null
   , rdate    datetime    not null
   , code int         not null		
   , anal     int         not null	
   , koranal  int         null
   , pcode	  int         not null	  
   , acode0 int, acode1 int, acode2 int, acode3 int, acode4 int, acode5 int, acode6 int, acode7 int, acode8 int, acode9 int
   , gcode0 int, gcode1 int, gcode2 int, gcode3 int, gcode4 int, gcode5 int, gcode6 int, gcode7 int, gcode8 int, gcode9 int
   )
insert into #ag_turnovers (
     kind, schet, korSchet, summa, rdate, code, anal, koranal, pcode 
   , acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9 				  
   , gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9 
   )
select kind     = t.kind
     , schet    = t.schet
	 , korSchet = t.korSchet
	 , summa    = t.summa
	 , rdate    = t.rdate
	 , code = t.code
	 , anal     = t.anal
	 , koranal  = t.koranal
	 , pcode	= t.pcode
	 , acode0 = max(case when s.vcode=0 then t.acode else 0 end)
	 , acode1 = max(case when s.vcode=1 then t.acode else 0 end)
	 , acode2 = max(case when s.vcode=2 then t.acode else 0 end)
	 , acode3 = max(case when s.vcode=3 then t.acode else 0 end)
	 , acode4 = max(case when s.vcode=4 then t.acode else 0 end)
	 , acode5 = max(case when s.vcode=5 then t.acode else 0 end)
	 , acode6 = max(case when s.vcode=6 then t.acode else 0 end)
	 , acode7 = max(case when s.vcode=7 then t.acode else 0 end)
	 , acode8 = max(case when s.vcode=8 then t.acode else 0 end)
	 , acode9 = max(case when s.vcode=9 then t.acode else 0 end)
	-- , gcode0 = (select gcode from #schet_gcode where vcode = 0)
	 --, gcode0 = max(case when s.vcode=0 then s.gcode else 0 end)
	 , gcode0 = max(case when s.vcode=0 then t.gcode else 0 end)
	 , gcode1 = max(case when s.vcode=1 then t.gcode else 0 end)
	 , gcode2 = max(case when s.vcode=2 then t.gcode else 0 end)
	 , gcode3 = max(case when s.vcode=3 then t.gcode else 0 end)
	 , gcode4 = max(case when s.vcode=4 then t.gcode else 0 end)
	 , gcode5 = max(case when s.vcode=5 then t.gcode else 0 end)
	 , gcode6 = max(case when s.vcode=6 then t.gcode else 0 end)
	 , gcode7 = max(case when s.vcode=7 then t.gcode else 0 end)
	 , gcode8 = max(case when s.vcode=8 then t.gcode else 0 end)
	 , gcode9 = max(case when s.vcode=9 then t.gcode else 0 end)

from #turnovers as t
join #schet_gcode as s on s.schet = t.schet and s.gcode = t.gcode and s.code = t.code
group by t.kind, t.schet, t.korSchet, t.summa, t.rdate, t.code, t.anal, t.koranal, t.pcode 

--������������ ������� #beginSaldo, ������������ �� �������� acode � gcode
insert into #ag_turnovers (
     kind, schet, korSchet, summa, rdate, code, anal, koranal, pcode
   , acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9 				  
   , gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9 
   )
select kind     = t.kind
     , schet    = t.schet
	 , korSchet = t.korSchet
	 , summa    = t.summa
	 , rdate    = t.rdate
	 , code = t.code
	 , anal     = t.anal
	 , koranal  = null
	 , pcode	= t.pcode
	 /*
	 , acode0 = max(case when s.vcode=0 then t.acode else 0 end)
	 , acode1 = max(case when s.vcode=1 then t.acode else 0 end)
	 , acode2 = max(case when s.vcode=2 then t.acode else 0 end)
	 , acode3 = max(case when s.vcode=3 then t.acode else 0 end)
	 , acode4 = max(case when s.vcode=4 then t.acode else 0 end)
	 , acode5 = max(case when s.vcode=5 then t.acode else 0 end)
	 , acode6 = max(case when s.vcode=6 then t.acode else 0 end)
	 , acode7 = max(case when s.vcode=7 then t.acode else 0 end)
	 , acode8 = max(case when s.vcode=8 then t.acode else 0 end)
	 , acode9 = max(case when s.vcode=9 then t.acode else 0 end)
	 , gcode0 = max(case when s.vcode=0 then t.gcode else 0 end)
	 , gcode1 = max(case when s.vcode=1 then t.gcode else 0 end)
	 , gcode2 = max(case when s.vcode=2 then t.gcode else 0 end)
	 , gcode3 = max(case when s.vcode=3 then t.gcode else 0 end)
	 , gcode4 = max(case when s.vcode=4 then t.gcode else 0 end)
	 , gcode5 = max(case when s.vcode=5 then t.gcode else 0 end)
	 , gcode6 = max(case when s.vcode=6 then t.gcode else 0 end)
	 , gcode7 = max(case when s.vcode=7 then t.gcode else 0 end)
	 , gcode8 = max(case when s.vcode=8 then t.gcode else 0 end)
	 , gcode9 = max(case when s.vcode=9 then t.gcode else 0 end)
	 */
	 , acode0 = max(case when s.vcode=0 and s.saldo = 1 then t.acode else 0 end)
	 , acode1 = max(case when s.vcode=1 and s.saldo = 1 then t.acode else 0 end)
	 , acode2 = max(case when s.vcode=2 and s.saldo = 1 then t.acode else 0 end)
	 , acode3 = max(case when s.vcode=3 and s.saldo = 1 then t.acode else 0 end)
	 , acode4 = max(case when s.vcode=4 and s.saldo = 1 then t.acode else 0 end)
	 , acode5 = max(case when s.vcode=5 and s.saldo = 1 then t.acode else 0 end)
	 , acode6 = max(case when s.vcode=6 and s.saldo = 1 then t.acode else 0 end)
	 , acode7 = max(case when s.vcode=7 and s.saldo = 1 then t.acode else 0 end)
	 , acode8 = max(case when s.vcode=8 and s.saldo = 1 then t.acode else 0 end)
	 , acode9 = max(case when s.vcode=9 and s.saldo = 1 then t.acode else 0 end)
	 --, gcode0 = max(case when s.vcode=0 and s.saldo = 1 then s.gcode else 0 end)
	 , gcode0 = max(case when s.vcode=0 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode1 = max(case when s.vcode=1 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode2 = max(case when s.vcode=2 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode3 = max(case when s.vcode=3 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode4 = max(case when s.vcode=4 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode5 = max(case when s.vcode=5 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode6 = max(case when s.vcode=6 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode7 = max(case when s.vcode=7 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode8 = max(case when s.vcode=8 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode9 = max(case when s.vcode=9 and s.saldo = 1 then t.gcode else 0 end)
	 

from #beginSaldo as t
join #schet_gcode as s on s.schet = t.schet and s.gcode = t.gcode and s.code = t.code
group by t.kind, t.schet,  t.korSchet, t.summa, t.rdate, t.code, t.anal, t.pcode

--������������ ������� #endSaldo, ������������ �� �������� acode � gcode
insert into #ag_turnovers (
     kind, schet, korSchet, summa, rdate, code, anal, koranal, pcode
   , acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9 				  
   , gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9 
   )
select kind     = t.kind
     , schet    = t.schet
	 , korSchet = t.korSchet
	 , summa    = t.summa	 
	 , rdate    = t.rdate
	 , code = t.code
	 , anal     = t.anal
	 , koranal  = null
	 , pcode	= t.pcode
	 /*
	 , acode0 = max(case when s.vcode=0 then t.acode else 0 end)
	 , acode1 = max(case when s.vcode=1 then t.acode else 0 end)
	 , acode2 = max(case when s.vcode=2 then t.acode else 0 end)
	 , acode3 = max(case when s.vcode=3 then t.acode else 0 end)
	 , acode4 = max(case when s.vcode=4 then t.acode else 0 end)
	 , acode5 = max(case when s.vcode=5 then t.acode else 0 end)
	 , acode6 = max(case when s.vcode=6 then t.acode else 0 end)
	 , acode7 = max(case when s.vcode=7 then t.acode else 0 end)
	 , acode8 = max(case when s.vcode=8 then t.acode else 0 end)
	 , acode9 = max(case when s.vcode=9 then t.acode else 0 end)
	 , gcode0 = max(case when s.vcode=0 then t.gcode else 0 end)
	 , gcode1 = max(case when s.vcode=1 then t.gcode else 0 end)
	 , gcode2 = max(case when s.vcode=2 then t.gcode else 0 end)
	 , gcode3 = max(case when s.vcode=3 then t.gcode else 0 end)
	 , gcode4 = max(case when s.vcode=4 then t.gcode else 0 end)
	 , gcode5 = max(case when s.vcode=5 then t.gcode else 0 end)
	 , gcode6 = max(case when s.vcode=6 then t.gcode else 0 end)
	 , gcode7 = max(case when s.vcode=7 then t.gcode else 0 end)
	 , gcode8 = max(case when s.vcode=8 then t.gcode else 0 end)
	 , gcode9 = max(case when s.vcode=9 then t.gcode else 0 end)
	 */
	 , acode0 = max(case when s.vcode=0 and s.saldo = 1 then t.acode else 0 end)
	 , acode1 = max(case when s.vcode=1 and s.saldo = 1 then t.acode else 0 end)
	 , acode2 = max(case when s.vcode=2 and s.saldo = 1 then t.acode else 0 end)
	 , acode3 = max(case when s.vcode=3 and s.saldo = 1 then t.acode else 0 end)
	 , acode4 = max(case when s.vcode=4 and s.saldo = 1 then t.acode else 0 end)
	 , acode5 = max(case when s.vcode=5 and s.saldo = 1 then t.acode else 0 end)
	 , acode6 = max(case when s.vcode=6 and s.saldo = 1 then t.acode else 0 end)
	 , acode7 = max(case when s.vcode=7 and s.saldo = 1 then t.acode else 0 end)
	 , acode8 = max(case when s.vcode=8 and s.saldo = 1 then t.acode else 0 end)
	 , acode9 = max(case when s.vcode=9 and s.saldo = 1 then t.acode else 0 end)
	 --, gcode0 = max(case when s.vcode=0 and s.saldo = 1 then s.gcode else 0 end)
	 , gcode0 = max(case when s.vcode=0 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode1 = max(case when s.vcode=1 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode2 = max(case when s.vcode=2 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode3 = max(case when s.vcode=3 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode4 = max(case when s.vcode=4 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode5 = max(case when s.vcode=5 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode6 = max(case when s.vcode=6 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode7 = max(case when s.vcode=7 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode8 = max(case when s.vcode=8 and s.saldo = 1 then t.gcode else 0 end)
	 , gcode9 = max(case when s.vcode=9 and s.saldo = 1 then t.gcode else 0 end)
	 

from #endSaldo as t
join #schet_gcode as s on s.schet = t.schet and s.gcode = t.gcode and s.code = t.code
group by t.kind, t.schet,  t.korSchet, t.summa, t.rdate, t.code, t.anal, t.pcode


--select * from #schet_gcode
--select * from #ag_turnovers where summa =644420  acode1 = 16915396 


--select * from [dbo].[prodbuhALL] where vcode = 1709585101
--select * from [dbo].[prodVADdataALL] where gcode = 12270
--select * from [dbo].[prodVAKdataALL] where pcode = 1709585101

--�������� ������ � ������� � ������� #obo
exec proddt '#obo'
create table #obo (schet    varchar(10) not null
				 , korSchet varchar(10) not null
                 , rdate    datetime    not null
                 , code int         not null		
                 , anal     int         not null	
				 , koranal  int	        null
				 , gcode_anal int       null	-- gcode ������� ��������� �����
                 , acode0 int, acode1 int, acode2 int, acode3 int, acode4 int, acode5 int, acode6 int, acode7 int, acode8 int, acode9 int				  
                 , gcode0 int, gcode1 int, gcode2 int, gcode3 int, gcode4 int, gcode5 int, gcode6 int, gcode7 int, gcode8 int, gcode9 int
                 , ostn money null -- ������ �� ������
				 , dobo money null -- ��������� ������� �� ������
				 , kobo money null -- ���������� ������� �� ������
				 , ostk money null -- ������ �� �����
     				)  
insert into #obo(schet, korSchet, rdate, code, anal, koranal
				, acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9 				  
				, gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9 
				, ostn, dobo, kobo, ostk)
select schet, korSchet, rdate, code, anal, koranal
, acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9 				  
, gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9 
, ostn = sum(case when kind in ('beginSaldo_debet','beginSaldo_kredit','beginSaldo_ost') then summa else 0 end)
, dobo = sum(case when kind = 'debet'													 then summa else 0 end)
, kobo = sum(case when kind = 'kredit'												 	 then -summa else 0 end)
, ostk = sum(case when kind in ('endSaldo_debet','endSaldo_kredit','endSaldo_ost')		 then summa else 0 end)
from #ag_turnovers
group by schet, korSchet, rdate, code, anal, koranal
   , acode0, acode1, acode2, acode3, acode4, acode5, acode6, acode7, acode8, acode9 				  
   , gcode0, gcode1, gcode2, gcode3, gcode4, gcode5, gcode6, gcode7, gcode8, gcode9

-- ��������� ���� gcode_anal
update o
set o.gcode_anal = p.code_anal
from #obo as o
join [Schema].[prodPlans_h] as p on p.schet = o.schet

--select * from #obo where acode1 = 16915396

-- �������� ������������ �������� �� #obo � ������� #analName
exec proddt '#analName'
create table #analName (  anal        int          not null -- ��� ���������
						, name        varchar(255) not null -- ������������ ���������
						, podr        varchar(255) null     -- �������������
						, atype       varchar(255) not null -- ��� ���������
						, org_rosneft varchar(255) null     -- ���� ��������
						, org_inn     varchar(255) null     -- ��� �����������
						)
insert into #analName(anal, name, podr, atype, org_rosneft, org_inn)
select anal = a.anal
     , name =  case when @analitCode = 1
					then (case when a.anal = 0 then '...' else convert(varchar(255),a.anal) + ' ' + u.name end)
					else (case when a.anal = 0 then '...' else u.name end)
					end
	 , podr = convert(varchar(1000),null)
     , atype = u.atype
	 , org_rosneft = (select top 1 spr.id_rn from spr_org spr where spr.vcode = a.anal ) 
     , org_inn = (select top 1 inn from spr_org spr1 where spr1.vcode = a.anal)
from (
	   select distinct anal = anal from #obo
	   union
	   select distinct anal = isnull(koranal,0) from #obo
	   union
	   select distinct anal = acode0 from #obo
	   union   
	   select distinct anal = acode1 from #obo
	   union   
	   select distinct anal = acode2 from #obo
	   union   
	   select distinct anal = acode3 from #obo
	   union   
	   select distinct anal = acode4 from #obo
	   union   
	   select distinct anal = acode5 from #obo
	   union   
	   select distinct anal = acode6 from #obo
	   union   
	   select distinct anal = acode7 from #obo
	   union   
	   select distinct anal = acode8 from #obo
	   union   
	   select distinct anal = acode9 from #obo
	  ) as a
left join [dbo].[unianalit] as u on a.anal=u.vcode 

--select * from #analName

declare @period varchar(1000)                                                  
select @period=DBO.prodPERIODNAME(@bdate,@edate)                                                  

--{ �������� ������� ��� ���������
declare  @updColumns varchar(500) = ''

select @updColumns = 'o.koranal=0'

--���� ����� ���� "�������� ����"
if(@hideSchet = 1) select @updColumns = @updColumns + ', o.schet=0'

if ((@schetkor is null) and (@schetkorShow = 0)) select @updColumns = @updColumns + ',o.korSchet=0'

-- ���� � ������� gcode � ������� #obo ��� ������� ��� ��� ����������� ���� - ������� ����� ��������
if not exists (select 1 from #gcode as g join (select gcode=max(gcode_anal) from #obo) as o on o.gcode = g.gcode)	
 select @updColumns = @updColumns + ',o.gcode_anal=0, o.anal=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode0) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode0=0, o.acode0=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode1) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode1=0, o.acode1=0'
	
if not exists (select 1 from #gcode as g join (select gcode=max(gcode2) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode2=0, o.acode2=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode3) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode3=0, o.acode3=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode4) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode4=0, o.acode4=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode5) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode5=0, o.acode5=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode6) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode6=0, o.acode6=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode7) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode7=0, o.acode7=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode8) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode8=0, o.acode8=0'

if not exists (select 1 from #gcode as g join (select gcode=max(gcode9) from #obo) as o on o.gcode = g.gcode)
 select @updColumns = @updColumns + ',o.gcode9=0, o.acode9=0'

-- �������� �� ������ ��� ������������ ����
select @sql = '
update o
set ' + @updColumns + '
from #obo as o'
--select @sql
exec (@sql)
--select * from #obo

--} �������� ������� ��� ��������� � ��������

-- ���������� � ���������
insert into #printObo(schet,korSchet,code
					,acode0,acode1,acode2,acode3,acode4,acode5,acode6,acode7,acode8,acode9
					,ostnd,ostnk,dobo,kobo,ostkd,ostkk )
select 
  schet = o.schet
, korSchet = case when o.korSchet = '0' then '...' else o.korSchet end
, code = (select a.name from [dbo].[filials] as a where a.vcode = o.code)
, acode0  = (select a.name from #analname as a where a.anal = o.acode0)
, acode1  = (select a.name from #analname as a where a.anal = o.acode1)
, acode2  = (select a.name from #analname as a where a.anal = o.acode2)
, acode3  = (select a.name from #analname as a where a.anal = o.acode3)
, acode4  = (select a.name from #analname as a where a.anal = o.acode4)
, acode5  = (select a.name from #analname as a where a.anal = o.acode5)
, acode6  = (select a.name from #analname as a where a.anal = o.acode6)
, acode7  = (select a.name from #analname as a where a.anal = o.acode7)
, acode8  = (select a.name from #analname as a where a.anal = o.acode8)
, acode9  = (select a.name from #analname as a where a.anal = o.acode9)
, ostnd   = sum(case when ostn>0 then ostn  else 0 end)
, ostnk   = sum(case when ostn<0 then -ostn else 0 end)
, dobo    = sum(dobo)
, kobo    = sum(case when kobo<0  then -kobo else 0 end)
--, kobo    = sum(kobo)
, ostkd   = sum(case when ostk>0  then ostk  else 0 end)
--, ostkd   = sum(ostk)
, ostkk   = sum(case when ostk<0  then -ostk else 0 end)                               
--, ostkk   = 0
from #obo as o
group by o.code,o.schet,o.korSchet,o.koranal,o.anal, o.acode0,o.acode1,o.acode2,o.acode3,o.acode4,o.acode5,o.acode6,o.acode7,o.acode8,o.acode9
/*
insert into #printObo(schet,korSchet,code,koranal,anal
					,acode0,acode1,acode2,acode3,acode4,acode5,acode6,acode7,acode8,acode9
					,ostnd,ostnk,dobo,kobo,ostkd,ostkk )
select 
  schet = o.schet
, korSchet = case when o.korSchet = '0' then '...' else o.korSchet end
, code = (select a.name from [dbo].[filials] as a where a.vcode = o.code)
, koranal = (select a.name from #analname as a where a.anal = o.koranal)
, anal    = (select a.name from #analname as a where a.anal = o.anal)
, acode0  = (select a.name from #analname as a where a.anal = o.acode0)
, acode1  = (select a.name from #analname as a where a.anal = o.acode1)
, acode2  = (select a.name from #analname as a where a.anal = o.acode2)
, acode3  = (select a.name from #analname as a where a.anal = o.acode3)
, acode4  = (select a.name from #analname as a where a.anal = o.acode4)
, acode5  = (select a.name from #analname as a where a.anal = o.acode5)
, acode6  = (select a.name from #analname as a where a.anal = o.acode6)
, acode7  = (select a.name from #analname as a where a.anal = o.acode7)
, acode8  = (select a.name from #analname as a where a.anal = o.acode8)
, acode9  = (select a.name from #analname as a where a.anal = o.acode9)
, ostnd   = sum(case when ostn>0 then ostn  else 0 end)
, ostnk   = sum(case when ostn<0 then -ostn else 0 end)
, dobo    = sum(dobo)
, kobo    = sum(case when kobo<0  then -kobo else 0 end)
--, kobo    = sum(kobo)
, ostkd   = sum(case when ostk>0  then ostk  else 0 end)
--, ostkd   = sum(ostk)
, ostkk   = sum(case when ostk<0  then -ostk else 0 end)                               
--, ostkk   = 0
from #obo as o
group by o.code,o.schet,o.korSchet,o.koranal,o.anal, o.acode0,o.acode1,o.acode2,o.acode3,o.acode4,o.acode5,o.acode6,o.acode7,o.acode8,o.acode9
*/
--select * from #printObo

--{ ������� ������� #printObo ��� ������ 

-- ���������� ������������� ������ 2
insert into #ColumnSetupprodOSV_2020 (Width, SetCode) values (2,10)

-- ������� ��������� �������:
if(@hideSchet = 0)  --���� �� ����� ���� "�������� ����"
 insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
 values ('schet', '����', 100, '�� ���������')

if((@schetkor is not null) or (@schetkorShow = 1)) --���� ������ �������
 insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
 values ('korSchet', '�������' , 100, '�� ���������')

insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
values ('code', '�����������', 200, '�� ���������')

--������ ���������� ��������
declare @columns table (id int identity, acode varchar(20), gcode varchar(20))
insert into @columns(acode,gcode) 
values	-- ('anal','gcode_anal'),
		 ('acode0','gcode0')
		,('acode1','gcode1')
		,('acode2','gcode2')
		,('acode3','gcode3')
		,('acode4','gcode4')
		,('acode5','gcode5')
		,('acode6','gcode6')
		,('acode7','gcode7')
		,('acode8','gcode8')
		,('acode9','gcode9')

declare   @i int = 1
		, @n int = 0
		, @_acode varchar(20)
		, @_gcode varchar(20)			

select @n = max(id) from @columns

-- ���������� ������� acode
while @i <= @n
BEGIN
 select   @_acode = acode
		, @_gcode = gcode 
 from @columns where id = @i

 select @sql = '
 declare @gcode int
       , @clmnName varchar(255)
	   , @sql varchar(max)

 select @gcode = max('+@_gcode+') from #obo
 /* ���� ������� ��� ����� ���������� */
 if(@gcode > 0)
 begin
  /* ���� �������� ������� */
  select @clmnName = REPLACE([Name],'' '', ''_'') from dbo.unianalit where vcode = @gcode
  
  /*���������� �������� ������� � ������� #ColumnSetupprodOSV_2020 ��� ����������� ������*/
  insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
  values ('''+@_acode+''', @clmnName, 150, ''�� ���������'')
 end
 /* ���� ������� ������ ������� ���*/
 else
  select @sql = ''ALTER TABLE #printObo DROP COLUMN ' + @_acode + '''

 exec (@sql)'

 --/* ��������������� �������   select @sql = ''EXEC tempdb.sys.sp_rename ''''#printObo.'+@_acode+''''', ''+@clmnName+'', ''''COLUMN'''''' */
 --values (@clmnName, @clmnName, 150, ''�� ���������'')
 
 --select @sql
 exec (@sql)

 set @i = @i + 1
END

-- ������ �������� � ���������� ��������
ALTER TABLE #printObo DROP COLUMN koranal
--EXEC tempdb.sys.sp_rename '#printObo.schet',	'����',						'COLUMN'
--EXEC tempdb.sys.sp_rename '#printObo.code',	'�����������',				'COLUMN'
--EXEC tempdb.sys.sp_rename '#printObo.ostnd',	'������ �� ������|�����',	'COLUMN'
--EXEC tempdb.sys.sp_rename '#printObo.ostnk',	'������ �� ������|������',	'COLUMN'
--EXEC tempdb.sys.sp_rename '#printObo.dobo',		'�������|�����',			'COLUMN'
--EXEC tempdb.sys.sp_rename '#printObo.kobo',		'�������|������',			'COLUMN'
--EXEC tempdb.sys.sp_rename '#printObo.ostkd',	'������ �� �����|�����',	'COLUMN'
--EXEC tempdb.sys.sp_rename '#printObo.ostkk',	'������ �� �����|������',	'COLUMN'

--} ������� ������� #printObo ��� ������ 


-- ���� ����� �� ��������
declare  @ostnd varchar(50)
		,@ostnk varchar(50) 
		,@dobo	varchar(50)
		,@kobo	varchar(50)
		,@ostkd varchar(50)
		,@ostkk varchar(50)
select 
		 @ostnd = replace(convert(varchar(50),sum(ostnd)),'.',',')
		,@ostnk = replace(convert(varchar(50),sum(ostnk)),'.',',')
		,@dobo	= replace(convert(varchar(50),sum(dobo)),'.',',')
		,@kobo	= replace(convert(varchar(50),sum(kobo)),'.',',')
		,@ostkd = replace(convert(varchar(50),sum(ostkd)),'.',',')
		,@ostkk = replace(convert(varchar(50),sum(ostkk)),'.',',')
from #printObo

 --��������������� ������� � �������
 insert into #ColumnSetupprodOSV_2020 (FieldName, Label, Width, viewname)
 values
	 ('ostnd', '������ �� ������|�����|'	+ @ostnd,	150, '�� ���������')
	,('ostnk', '������ �� ������|������|'	+ @ostnk,	150, '�� ���������')
	,('dobo',  '�������|�����|'				+ @dobo,	150, '�� ���������')
	,('kobo',  '�������|������|'			+ @kobo,	150, '�� ���������')
	,('ostkd', '������ �� �����|�����|'		+ @ostkd,	150, '�� ���������')
	,('ostkk', '������ �� �����|������|'	+ @ostkk,	150, '�� ���������')


select * from #printObo 

--select * from #ColumnSetupprodOSV_2020
--exec proddt '#OSV_param,#printObo'

*/