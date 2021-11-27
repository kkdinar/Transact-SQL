ALTER procedure [Schema].[BSP_DistributionIncomingDocLog_Ins]
as
set nocount on;

/*commentBegin
������: �������� �����
��������: ������������� �������� ����������
����������: ��� ������������� ����� ���������� �� ����������� �� ���������
�����: ���������� �.�.
���� ��������: 14.02.2020
��������: ��� JOB. ������ BN_DistributionIncomingDoc_Log ���������� INDEX(code,docVCode,docTdoc)
commentEnd*/  

--{������������
--allsee 194
--select * from  [Schema].[BN_DistributionIncomingDoc_Document_h]
--select * from  [Schema].[BN_DistributionIncomingDoc_Worker_h]
--select * from  [Schema].[BN_DistributionIncomingDoc_Log_h] truncate table  [Schema].[BN_DistributionIncomingDoc_Log_h]
--}������������

exec lexdt '#MonitoringTable,#docInfo,#Row_Count,#sendMail,#usersVCode,#sendMailDocInfo,#workerInfo'

declare @sql              varchar(max)
      , @i                int = 1
	  , @n                int = 0  
	  , @reestrDoc        varchar(max) -- ������ ���������
	  , @tdoc             varchar(3)   -- TDoc ���������
	  , @DocumentVCode    varchar(255) -- ��� ��������� �� ������� [Schema].[BN_DistributionIncomingDoc_Document]
	  , @pdocmat          varchar(255) -- ������� pdocmat ������������ �� ��������� ���������
	  , @VCode            varchar(255)
	  , @Row_Count        int
	  , @WorkerVCode      bigint       -- ���������
	  , @body             nvarchar(max)
	  , @userName         varchar(255)
	  , @userMail         varchar(255)
	  , @docRDate         datetime     -- ���� ���������
	  , @lexbuhWuser      varchar(255) -- wuser �� lexbuh
	  , @surname          varchar(255) -- ������� ����������
      , @workDays         int          -- ������� ���� � ���� ������ �������� ���������
	  , @workDaysKalendar int          -- ������� ���� � ���� ������ ������ �������� ���������
	  , @normaRowsCount   float        -- �������� ���������� ����� �� ���������
	  , @rowsCountTODO    int          -- ���������� ����� � ������ �� ������ ����� �� ��������� ��� ����������
	  , @code		  int

select @code = dbo.code()

-- �� ������ ��������� ������
create table #MonitoringTable ( id            int identity primary key
                              , tdoc          varchar(3)
							  , reestrDoc     varchar(255) -- ������ ���������
							  , DocumentVCode bigint       -- ��� ��������� �� ������� [Schema].[BN_DistributionIncomingDoc_Document]
							  , pdoc          varchar(255) -- ������� pdoc ��������� tdoc
					          , pdocmat       varchar(255) -- ������� pdocmat ��������� tdoc
                               )

-- ���������� ����� � ������� 
create table #Row_Count (  Row_Count   int
                         , WorkerVCode bigint
						 , DocumentVCode bigint
                        )

-- ���������� � ����� ����������
create table #docInfo(  id    int identity primary key
                      , vcode bigint         -- vcode ������������ �� ��������� ���������
                      , rdate datetime       -- rdate ������������ �� ��������� ���������
					  , nomer varchar(255)   -- ����� ������������ �� ��������� ���������
					  , Tdoc  varchar(3)     -- Tdoc ������������ �� ��������� ���������
					  , DocumentVCode bigint -- ��� ��������� �� ������� [Schema].[BN_DistributionIncomingDoc_Document] 		  					  
                      )

-- ���������� � �����������
create table #workerInfo ( id      int identity primary key
                         , surname varchar(255) -- ������� ����������
						 , vcode   bigint       -- ��� ����������
                         )

-- ���������� � ����� ����������� �� ���������� ����������
create table #sendMailDocInfo(  id    int identity primary key
                              , docvcode bigint         -- vcode ������������ �� ��������� ���������
                              , docRDate datetime       -- rdate ������������ �� ��������� ���������
					          , docNomer varchar(255)   -- ����� ������������ �� ��������� ���������
					          , docTdoc  varchar(3)     -- Tdoc ������������ �� ��������� ���������	  					  
                              )
						 
-- ������ �����������, ������� ����� ��������� �������� ���������
create table #usersVCode (  id int identity primary key
                          , WorkerVCode bigint
						 )

-- ������ � ����� ���������� ��� ��������
create table #sendMail(WorkerVCode  bigint
                     , Rdate        varchar(10)
					 , Nomer        varchar(255)
					 , DocumentName varchar(255)
					 , Info         varchar(1000)
					 , Info2        varchar(1000)
					 )

--{ �������� ���������� �� ���������� ��������� ����� �� ����������� � ������ ������� ������
select @i = min(VCode) from [Schema].[BN_DistributionIncomingDoc_Worker]
select @n = max(VCode) from [Schema].[BN_DistributionIncomingDoc_Worker]
while @i <= @n
begin
 -- ���� ��������� �������� - �� ���� �� ���� �������.
 if (1 = (select DisableWorker from  [Schema].[BN_DistributionIncomingDoc_Worker_h] where vcode = @i))
	set @i = @i + 1
 else
 begin 	

 select @WorkerVCode = @i
 select @workDays = sum(  -- ������� ���� � ���� ������ �������� ���������
   case when t.[d1] = 1 then 1 else 0 end
 + case when t.[d2] = 1 then 1 else 0 end          
 + case when t.[d3] = 1 then 1 else 0 end        
 + case when t.[d4] = 1 then 1 else 0 end        
 + case when t.[d5] = 1 then 1 else 0 end        
 + case when t.[d6] = 1 then 1 else 0 end        
 + case when t.[d7] = 1 then 1 else 0 end        
 + case when t.[d8] = 1 then 1 else 0 end        
 + case when t.[d9] = 1 then 1 else 0 end        
 + case when t.[d10]= 1 then 1 else 0 end        
 + case when t.[d11]= 1 then 1 else 0 end        
 + case when t.[d12]= 1 then 1 else 0 end        
 + case when t.[d13]= 1 then 1 else 0 end        
 + case when t.[d14]= 1 then 1 else 0 end        
 + case when t.[d15]= 1 then 1 else 0 end        
 + case when t.[d16]= 1 then 1 else 0 end        
 + case when t.[d17]= 1 then 1 else 0 end        
 + case when t.[d18]= 1 then 1 else 0 end        
 + case when t.[d19]= 1 then 1 else 0 end        
 + case when t.[d20]= 1 then 1 else 0 end        
 + case when t.[d21]= 1 then 1 else 0 end        
 + case when t.[d22]= 1 then 1 else 0 end        
 + case when t.[d23]= 1 then 1 else 0 end        
 + case when t.[d24]= 1 then 1 else 0 end        
 + case when t.[d25]= 1 then 1 else 0 end        
 + case when t.[d26]= 1 then 1 else 0 end        
 + case when t.[d27]= 1 then 1 else 0 end        
 + case when t.[d28]= 1 then 1 else 0 end        
 + case when t.[d29]= 1 then 1 else 0 end        
 + case when t.[d30]= 1 then 1 else 0 end        
 + case when t.[d31]= 1 then 1 else 0 end  ) 
 from [Schema].[BN_DistributionIncomingDoc_Kalendar] as t
 where t.[WorkerVCode] = @WorkerVCode
 and month(t.[RDate]) = month(getdate()) 
 --select @workDays
 
 -- ���������� ������� ��� � ������ �� ���������
 select  @workDaysKalendar = count(k.rdate)
 from [ZPL_SCHEME].[BN_kalendar_all] as k
 where year(k.rdate) = year(getdate())   --��������� ���
   and month(k.rdate) = month(getdate()) --��������� �����
   and k.grup_org = 1                    -- ��������
   and k.vid in (3,5)                    -- 3-��������������� ����/ 5-������� ����.
 
 -- ������� �������� ����� �� ���������
 select @normaRowsCount = d.Row_Count 
 from [Schema].[BN_DistributionIncomingDoc_Document] as d 
 join [Schema].[BN_DistributionIncomingDoc_Worker] as w on w.DocumentVCode = d.VCode
 where w.VCode = @WorkerVCode
 
 if(@workDaysKalendar <= @workDays) --���� ���������� ������� ���� ���������� ������������� �����
  select @rowsCountTODO = @normaRowsCount  
 else -- ���� ��������� � ���� ������ �������� ������ �����     
  select @rowsCountTODO = ROUND(@workDays*@normaRowsCount/@workDaysKalendar, 0)
   
 -- ��������� �������� ��� ����������
 update w
 set w.Row_Count = @rowsCountTODO
 from [Schema].[BN_DistributionIncomingDoc_Worker] as w 
 where w.VCode = @WorkerVCode

 set @i = @i + 1
 end
end 
--} �������� ���������� �� ���������� ��������� ����� �� ����������� � ������ ������� ������

--{�������� ���������� � ����������, �� �������� ����� �������
insert into #MonitoringTable(tdoc,reestrDoc,DocumentVCode,pdoc,pdocmat)
select tdoc          = d.tdoc
     , reestrDoc     = isnull(u.pdocnq, u.pdocq) 
	 , DocumentVCode = d.vcode
	 , pdoc          = ISNULL(u.pdoct,u.pdocq)
	 , pdocmat       = ISNULL(u.pdocmatt,u.pdocmatq)
from [Schema].[BN_DistributionIncomingDoc_Document] as d
left join [dbo].[Umcdocs] as u on u.tdoc = d.tdoc
where d.DisableDocument = 0  -- �������� ��������

--select * from #MonitoringTable
--}�������� ���������� � ����������, �� �������� ����� �������

--{�������� ������ � ����������, ������� ��� ��� � ������� [Schema].[BN_DistributionIncomingDoc_Document] 
select @i = 1
select @n = max(id) from #MonitoringTable

while @i <= @n
begin
 select @reestrDoc     = reestrDoc     from #MonitoringTable where id = @i
 select @tdoc          = tdoc          from #MonitoringTable where id = @i
 select @DocumentVCode = DocumentVCode from #MonitoringTable where id = @i
 select @pdocmat       = pdocmat       from #MonitoringTable where tdoc = @tdoc

 --�������� ������ ��� ����� ����������, ������� ��� ��� � ������� [Schema].[BN_DistributionIncomingDoc_Document] 
 select @sql = '
  insert into #docInfo(vcode,rdate,nomer,Tdoc,DocumentVCode)
  select VCode           = p.VCode 
       , Rdate           = p.Rdate
	   , Nomer           = p.Nomer
	   , Tdoc            = p.Tdoc
	   , DocumentVCode   = ' + @DocumentVCode + ' 
  from ' + @reestrDoc +' p
  where p.CDate >= ''20200201''--dateadd(month, -1, getdate())--
    and p.CDate <= dateadd(month,  1, getdate())
	and p.Nomer is not null ' 
	+ case 
	  when @tdoc = 'NF2'
	  then ' and (isnull(p.prtdoc,'''') = '''') ' --��������� �������
	      +' and p.kol_doc_arhiv > 1 '            -- � ������� � ������� ������ ���-�� ���-� � ���� ���-� ������ 0 
	  else ''
	  end
   +' and p.Tdoc = ' + '''' + @tdoc + '''' + '
	  and not exists ( ' -- ��������� ��� ��� � ������� [Schema].[BN_DistributionIncomingDoc_Document]
	             +' select 1 
	                from [Schema].[BN_DistributionIncomingDoc_Log] as d 
					where d.docVCode = p.VCode
  					  and d.docNomer = p.Nomer
  					  and d.docRDate = p.Rdate
					  and d.docTdoc  = p.Tdoc
	                )
	  and ((select Row_Count = COUNT(vcode) from ' + @pdocmat + ' where pcode = p.VCode) > 0)' --���� ������ �  pdocmat 

  exec (@sql)

  set @i = @i + 1
end

--select * from #docInfo
--}�������� ������ � ����������, ������� ��� ��� � ������� [Schema].[BN_DistributionIncomingDoc_Document] 

--���� �� ��������� ����� ��������� - ������� �� ���������
--if not exists (select 1 from #docInfo) return

--��������� ����� ��������� � ������� [Schema].[BN_DistributionIncomingDoc_Log]
insert into [Schema].[BN_DistributionIncomingDoc_Log](docVCode,docNomer,docRDate,docTdoc,DocumentVCode,Row_Count,DisableLog)
select
  docVCode      = i.VCode
, docNomer      = i.Nomer
, docRDate      = i.RDate
, docTdoc       = i.Tdoc
, DocumentVCode = i.DocumentVCode
, Row_Count     = 0
, DisableLog    = 0
from #docInfo as i

--{�������� ������ � ���������� ����� � ����� ����������
set @i = 1
select @n = max(id) from #docInfo 
while @i <= @n
begin
 select @tdoc    = tdoc    from #docInfo         where id   = @i
 select @VCode   = vcode   from #docInfo         where id   = @i
 select @pdocmat = pdocmat from #MonitoringTable where tdoc = @tdoc 
 
 --���������� � ������� #Row_Count ���������� ����� � ������� @pdocmat
 select @sql = ' truncate table #Row_Count'
             + ' insert into #Row_Count(Row_Count)'
             + ' select Row_Count = COUNT(vcode)'
             + ' from ' + @pdocmat 
			 + ' where pcode = ' + @VCode
 --select @sql 
 exec (@sql)	
 
 --���������� ������ � ������� � ������� [Schema].[BN_DistributionIncomingDoc_Log]
 update l
 set l.Row_Count = (select top 1 Row_Count from #Row_Count)
 from [Schema].[BN_DistributionIncomingDoc_Log] as l
 where l.docVCode = @VCode
   and l.docTdoc  = @tdoc 
   and l.code = @code 
 				   
 set @i = @i + 1
end
--}�������� ������ � ���������� ����� � ����� ����������

--{ ��������� � lexbuh, ��� ��������� ��������� �� �����
--�������� ��������� �� �����
truncate table #docInfo
insert into #docInfo (vcode,rdate,nomer,Tdoc,DocumentVCode)
select l.docVCode
     , l.docRDate
	 , l.docNomer
	 , l.docTdoc
	 , l.DocumentVCode
from [Schema].[BN_DistributionIncomingDoc_Log] as l
where l.docRDate >= '20200101'--dateadd(month, -1, getdate())--
  and l.docRDate <= dateadd(month,  1, getdate())

set @i = 1
select @n = max(id) from #docInfo 
while @i <= @n
begin
 select @DocumentVCode = DocumentVCode from #docInfo where id = @i
 select @tdoc          = tdoc          from #docInfo where id = @i
 select @VCode         = vcode         from #docInfo where id = @i

 --���� �������� � ������� lexbuh � ���������� wuser � @lexbuhWuser
 select top 1 @lexbuhWuser = isnull(b.wuser,'')
 from [dbo].[lexbuh] as b
 where b.typ = @tdoc
   and b.rdate >='20200101'-- dateadd(month, -1, getdate())--
   and b.rdate <= dateadd(month,  1, getdate())
   and b.pcode = @VCode

 if (@lexbuhWuser <> '') --���� �������� ��� ��������� � ���� ������� ������������ ������� ���������
 begin
 --�������� ������� �����������, ������� ����� ������������ �������� @DocumentVCode
  truncate table #workerInfo
  insert into #workerInfo (surname, vcode) 
  select surname = substring(w.WorkerName, 0, charindex(' ', w.WorkerName)) -- �������� ������� �� ���� WorkerName
       , vcode = w.vcode
  from [Schema].[BN_DistributionIncomingDoc_Worker] as w
  where w.DocumentVCode = @DocumentVCode  
  
  declare @j int = 1
  declare @m int = 0
  select @m = max(id) from #workerInfo
  --������� ������� ���������� ������� � @lexbuhWuser
  while @j <= @m
  begin
   select @surname     = surname from #workerInfo where id = @j
   select @WorkerVCode = vcode   from #workerInfo where id = @j
   
   --���� ������� ���������� ������ �� ��� �� lexbuh
   if(@lexbuhWuser like '%'+@surname+'%')
   begin
    update l
    set l.WorkerVCode = @WorkerVCode
	  , l.DocFinished = 1
    from [Schema].[BN_DistributionIncomingDoc_Log] as l
    where l.docVCode = @VCode
      and l.docTdoc  = @tdoc  
	  and l.code = @code    
   end
   --���� �� ����� ���������� ������� ����������, ���������� @lexbuhWuser � ���� DocFinishedUser
   else
   begin    
    update l 
	set l.DocFinishedUser = @lexbuhWuser
    from [Schema].[BN_DistributionIncomingDoc_Log] as l
    where l.docVCode = @VCode
      and l.docTdoc  = @tdoc 
	  and l.code = @code 
   end

   set @j = @j + 1
  end
 end

set @i = @i + 1
end 
--{ ��������� � lexbuh, ��� ��������� ��������� �� �����


--{��������� ����������� ��� ��������� ���������� ��� ������� ��� �� �������� ����������
--���� ��������� ��� ������� ��� �� �������� ����������
truncate table #docInfo
insert into #docInfo (vcode,rdate,nomer,Tdoc,DocumentVCode)
select l.docVCode
     , l.docRDate
	 , l.docNomer
	 , l.docTdoc
	 , l.DocumentVCode
from [Schema].[BN_DistributionIncomingDoc_Log] as l
where l.WorkerVCode is null

set @i = 1
select @n = max(id) from #docInfo 
while @i <= @n
begin
 select @DocumentVCode = DocumentVCode from #docInfo where id = @i
 select @tdoc          = tdoc          from #docInfo where id = @i
 select @VCode         = vcode         from #docInfo where id = @i
 select @docRDate      = rdate         from #docInfo where id = @i

 --select @workerCount = count(VCode) from [Schema].[BN_DistributionIncomingDoc_Worker] where DocumentVCode = @DocumentVCode
 
 --�������� ����� ���������� ����������� ����� �� ��������� @DocumentVCode �� ������������� �� ������� �����
 truncate table #Row_Count
 insert into #Row_Count(Row_Count,WorkerVCode,DocumentVCode)
 select distinct
        Row_Count     = sum(Row_Count) 			
      , WorkerVCode   = WorkerVCode	   
	  , DocumentVCode = @DocumentVCode
 from [Schema].[BN_DistributionIncomingDoc_Log]
 where docRDate > EOMONTH (dateadd(month, -1, @docRDate))-- ��������� ���� ����������� ������ �� ���� ���������
   and docRDate < dateadd(day, 1, EOMONTH(@docRDate))    -- ������ ���� ���������� ������ �� ���� ���������
   and DocumentVCode = @DocumentVCode
   and WorkerVCode is not null
 group by WorkerVCode

 --select * from #Row_Count

 --�������� �������� ������������ ����������(����� ����� ���������� ������������ ����� �� ����� �� ����� �� �����������)
 select top 1 @WorkerVCode = a.VCode
 from (
         select VCode = case
						when c.Row_Count is null  --�� ��������� ���� ������ �� ���������     		                                
						then w.VCode
						when (isnull(c.Row_Count,0) < w.Row_Count)  --����� ��������� ������������ ����� �� ����� ������ ����� ����������
						then c.WorkerVCode
						else null
						end
		      , rate = case
			           when c.Row_Count is not null --�� ��������� ��� ���-�� ����������
					   then convert(decimal(10,5),(convert(float, c.Row_Count)/convert(float,w.Row_Count)))
					   else 0.00001
					   end
		 from [Schema].[BN_DistributionIncomingDoc_Worker] as w
         left join #Row_Count as c on c.WorkerVCode = w.VCode
		 where (@DocumentVCode = w.DocumentVCode) --�������� ����� ������������ ����� ��������
		   and w.Row_Count > 0        --� ��������� ��������� �����
		   and w.DisableWorker = 0    -- �������� �������
       ) a
 order by a.rate asc

-- c.Row_Count/w.Row_Count - 5 ���� ����� �������
-- select top 1 ... order by a.rate asc - ������� ������ �������� �� ��������������� �� �����������

-- select workername from [Schema].[BN_DistributionIncomingDoc_Worker] where vcode=@WorkerVCode

 --���� �����, ��������� ���������� @WorkerVCode �� ��������� ��������� @DocumentVCode 
 if isnull(@WorkerVCode,0) <> 0
 begin
  update l
  set l.WorkerVCode = @WorkerVCode
  from [Schema].[BN_DistributionIncomingDoc_Log] as l
  where l.docVCode = @VCode
    and l.docTdoc  = @tdoc
	and l.code = @code 
 end
 
 set @i = @i + 1
end
--}��������� ����������� ��� ��������� ���������� ��� ������� ��� �� �������� ����������

 --�������� ������ � ��� �� ������������ ���������� ��� �������� ���������
 insert into #sendMailDocInfo(docvcode, docRDate, docNomer, docTdoc)
 select docvcode = l.docvcode        
	  , docRDate = l.docRDate
	  , docNomer = l.docNomer
	  , docTdoc  = l.docTdoc
 from [Schema].[BN_DistributionIncomingDoc_Log] as l
 where l.DocFinished = 0
   and l.docRDate >= '20200201' --dateadd(month, -1, getdate())
   and l.docRDate <= dateadd(month,  1, getdate())

--{�������� ��������� �� ����� � ����� ����������� ���������� ������������
--�������� ������ � ����� ���������� ��� ��������
insert into #sendMail(WorkerVCode, Rdate, Nomer, DocumentName, Info, Info2)
select WorkerVCode  = l.WorkerVCode
     , Rdate        = convert(varchar(10),l.docRDate,104)
	 , Nomer        = l.docNomer
	 , DocumentName = d.DocumentName
	 , Info = case
	          when l.docTdoc = 'NF2'
			  then dbo.unianalitname(code.gruzotp)
			  else ''
			  end
	, Info2 = case
	          when l.docTdoc = 'NF2'
			  then code.org_name
			  else ''
			  end
from [Schema].[BN_DistributionIncomingDoc_Log] as l
join [Schema].[BN_DistributionIncomingDoc_Document] as d on d.vcode = l.DocumentVCode
join #sendMailDocInfo as i on l.docVCode = i.docVCode
				          and l.docNomer = i.docNomer
				          and l.docRDate = i.docRDate
				          and l.docTdoc  = i.docTdoc
outer apply (select top 1 gruzotp, org_name from [Neft_Schema].[veco_NefteProd] where vcode = l.docVCode) code

-- �������� �����������, ������� ����� ��������� �������� ���������
insert into #usersVCode (WorkerVCode)
select distinct WorkerVCode from #sendMail

set @i = 1
select @n = max(id) from #usersVCode
while @i <= @n
begin
 select @WorkerVCode = WorkerVCode from #usersVCode where id = @i
 select @userName = WorkerName 
      , @userMail = isnull(email,'')
 from [Schema].[BN_DistributionIncomingDoc_Worker] 
 where vcode = @WorkerVCode

 -- �������� ������ ��� ��������
 SET @body = N'
 <html> <head> <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/> </head> <body>
 <p><img style="float:right;" src="https://sturm.ru/pics/portfolio/graphic/pr_008/pr_008_01.png"/></p>
 <p>������ ����. ���������(��) ' + @userName + N' ��� � ������ ��������� ��������� ���������:</p>
 <table border=1> <!--������� ����� �������-->
 <tr align=center><th>��������</th>
                  <th>�����</th>
				  <th>����</th>
				  <th>����������</th>
				  <th>����������2</th>
				  </tr>' --������ ����������

 select @body = @body + ' <tr><td>' + m.DocumentName + '</td>  
                              <td>' + m.Nomer+ '</td>
							  <td>' + m.Rdate + '</td>
							  <td>' + m.Info + '</td>
							  <td>' + m.Info2 + '</td>
					      </tr> '                      --������ ���� �������
 from #sendMail as m
 where m.WorkerVCode = @WorkerVCode
 order by m.Rdate

 set @body = @body + '</table> <p>�������� ���!</p> </body> </html>'

 -- �������� ������
 if(@userMail <> '')
 begin
  BEGIN TRY  
   EXEC dbo.bsp_send_dbmail        
       @profile_name = 'databasemail_profile'
      , @recipients = @userMail 
	  , @subject = 'Lexema. ��������� �� ���������.'
      , @body = @body
      , @body_format = 'HTML'
  END TRY 
  BEGIN CATCH
   print ERROR_MESSAGE()
  END CATCH 
 end
 
 set @i = @i + 1
end
--}�������� ��������� �� ����� � ����� ����������� ���������� ������������

