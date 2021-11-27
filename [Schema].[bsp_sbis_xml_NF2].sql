ALTER procedure [Schema].[bsp_sbis_xml_NF2]
  @docvcode int = null	-- vcode ���������
, @show int = 0			-- ������� xml �� ����� ������ ��������   
as
set nocount on;

/*comment 
������: ���� �������������� � �������
��������: ������ ��������������
����������: �������� XML-�������� ��� ����
�����: ���������� �.�.
���� ��������: 20.10.2020
��������: 
commentEnd*/

--{ ������������
--allsee 194
--declare @docvcode int = 1244260436
--	  , @show int = 1
--} ������������

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

--{ �������� ������ ����������
declare @������������� varchar(100)
      , @������������� varchar(100)

select @������������� = ltrim(rtrim(receiver.inn))
     , @������������� = COALESCE(([dbo].[EFN_OrgKPP](mainTable.org, @getdate)),(ltrim(rtrim(receiver.kpp))))
from [Schema].[veco_prod] as mainTable 
join [dbo].[Spr_Org] as receiver on receiver.vcode = mainTable.org
where mainTable.VCode = @docvcode
--select @�������������, @�������������
if(@������������� is null) raiserror('� ����������� ����������� ��� ������ � "���������� ���(�����������(�����))"',16,1)
if(@������������� is null) raiserror('� ����������� ����������� ��� ������ � "���������� ���(�����������(�����))"',16,1)
--} �������� ������ ����������

--{ �������� ������ �����������
declare @�������������� varchar(100) 
      , @�������������� varchar(100)

declare @kppTable table(Podr int, KPP varchar(10))
insert into @kppTable (Podr, KPP)
values (16350886,'027801001') -- �� - ��������
	 , (16350916,'665845004') -- �� - ������������
	 , (16350946,'561045007') -- �� - ��������
	 , (16350976,'183145001') -- �� - ��������
 	 , (33449386,'132745004') -- �� - ���������
 	 , (34318996,'745245002') -- �� - ���������

select @�������������� = ltrim(rtrim(sender.inn))
     , @�������������� = COALESCE(kpp.KPP, ([dbo].[EFN_OrgKPP](mainTable.we, @getdate)), (ltrim(rtrim(sender.kpp))))
from [Schema].[veco_prod] as mainTable 
join [dbo].[Spr_Org]				as sender	on sender.vcode = mainTable.we
left join @kppTable					as kpp		on kpp.Podr = mainTable.code_podr
where mainTable.VCode = @docvcode
--select @��������������, @��������������
if(@�������������� is null) raiserror('� ����������� ����������� ��� ������ � "����������� ���(���� �����������)"',16,1)
if(@�������������� is null) raiserror('� ����������� ����������� ��� ������ � "����������� ���(���� �����������)"',16,1)
--} �������� ������ �����������

--{ �������� ��������
declare @fileName table (Name varchar(1000), VCode bigint)
insert into @fileName(Name, VCode)
values ('ON_NSCHFDOPPR_' + @������������� + @������������� + '_' + @�������������� + @�������������� + '_' +  convert(varchar(10),@getdate,112), @docvcode)
     , ('DP_TOVTORGPR_' + @������������� + @������������� + '_' + @�������������� + @�������������� + '_' +  convert(varchar(10),@getdate,112), @docvcode)
--} �������� ��������

--{ �������� ������ �������� ��������
declare @�������� varchar(1000)
select @�������� = ltrim(rtrim(mainTable.norder)) 
from [Schema].[veco_prod] as mainTable 
where mainTable.VCode = @docvcode
--select @��������
if(@�������� is null) raiserror('� ��������� ��� ������ � "����-������� �"',16,1)
--} �������� ������ �������� ��������

--{ �������
declare @����������       varchar(3)
      , @�����������      datetime
	  , @�������������    varchar(1)
	  , @��������������   varchar(1)
	  , @���������������� varchar(3)

select @���������������� = isnull(Text12,'') from [Schema].[veco_prod] where VCode = @docvcode
if (@���������������� <> '')
begin
 select @����������     = @����������������
      , @�����������    = convert(varchar(10),mainTable.[date],104)
	  , @�������������  = '-'
	  , @�������������� = '-'
from [Schema].[veco_prod] as mainTable 
where mainTable.VCode = @docvcode
end
--} �������

--{ �������� ������ ������ (���� �����������)
declare @�������������         nvarchar(500) 
      , @�����������������     nvarchar(500)
	  , @��������������������  nvarchar(500)
	  , @����������������      nvarchar(500)
	  , @����������������      nvarchar(500)
	  , @��������������������� nvarchar(500)
	  , @����������������      nvarchar(500)
	  , @��������������        nvarchar(500)
	  , @�����������������     nvarchar(500)
	  , @����������������      nvarchar(500)
	  , @�����������������     nvarchar(500)
	  , @�������������������   nvarchar(500)

select @�������������         = dbo.EFN_Org_Fullname(mainTable.we, @getdate)
     , @�����������������     = isnull(adr.SapPost,'')
	 , @��������������������  = isnull(adr.SapRegion,'')
	 , @����������������      = ''
	 , @����������������      = isnull(adr.SapCity,'')
	 , @��������������������� = isnull(adr.SapCity,'')
	 , @����������������      = isnull(adr.SapStreet,'')
	 , @��������������        = isnull(adr.SapDom,'')
	 , @�����������������     = isnull(adr.SapKorp,'')
	 , @����������������      = isnull(adr.SapKvart,'')
	 , @�����������������     = isnull(ourOrg.country,'643')
	 , @�������������������   = ourOrg.adr1
from [Schema].[veco_prod] as mainTable
left join [dbo].[VLexOrg]           as ourOrg    on ourOrg.VCode = mainTable.we
outer apply (
             select top 1 SapPost, SapRegion, SapCity, SapStreet, SapDom, SapKorp, SapKvart
             from [dbo].[LexPdadr]
			 where pcode = mainTable.we
			 and cuser = '������ �� ���'
             ) adr 
where mainTable.VCode = @docvcode

if(@������������� is null) raiserror('� ��������� ��� ������ � ������� ����������� � ���� "���� �����������"',16,1)
if(@�������������������� is null) raiserror('� ����������� ����������� ��� ������ � ��������� ����������� � ���� "���� �����������"',16,1)
if(@������������� is null) raiserror('� ��������� ��� ������ � ������� ����������� � ���� "���� �����������"',16,1)
if(@������������������� is null) raiserror('� ��������� ��� ������ � �������� ����������� � ���� "���� �����������"',16,1)
--} �������� ������ ������ (���� �����������)

--{ �������� ������ ����������������
declare @�������������  nvarchar(500)
      , @�����������    nvarchar(500)
	  , @���������      nvarchar(500)
	  , @�������������� nvarchar(500)
	  , @�������_���������� int
	  , @����������������   int

select @�������_���������� = isnull(int4,0) from [Schema].[veco_prod] where VCode = @docvcode
select @����������������   = gruzotp        from [Schema].[veco_prod] where VCode = @docvcode

-- ���� ������� ���������� = 3113908(���������� �������������� ������ �����)
if(@�������_���������� = 3113908)
begin
 select  @�������������  = case
                           when gruzotp.fullname is not null
						   then gruzotp.fullname
						   else '��� "��������-�������" ' + replace(ltrim(rtrim(podr.NamePodr)), '- ', '"') + '" ' + gruzotpUa.[Name]
						   end
       , @�����������    = case
                           when gruzotp.inn is not null
						   then gruzotp.inn
						   else ltrim(rtrim(sender.inn))
						   end
 	   , @���������      = case 
	                       when gruzotp.kpp is not null
						   then	gruzotp.kpp
						   else COALESCE(([dbo].[EFN_OrgKPP](mainTable.we, @getdate)),(ltrim(rtrim(sender.kpp))))
						   end
 	   , @�������������� = case 
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
 raiserror('"������� ����������" ������ �� "���������� �������������� ������ �����"',16,1)
 return
end
if(@�������������  is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "����������������"',16,1)
if(@�����������    is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "����������������"',16,1)
if(@���������      is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "����������������"',16,1)
if(@�������������� is null) raiserror('� ����������� ����������� ��� ������ � ������ ����������� � ���� "����������������"',16,1)
--} �������� ������ ����������������

--{ �������� ������ ���������������
declare @����������������  nvarchar(500)
      , @��������������    nvarchar(500)
	  , @������������      nvarchar(500)
	  , @��������������    nvarchar(500)
	  , @����������������  nvarchar(500)
	  , @������������      nvarchar(500)
	  , @����������������� nvarchar(500)
	  , @����������������� nvarchar(500)
	  , @���������������   nvarchar(500)
      , @���������������   int
	  , @����������������� bit = 0

select @��������������� = org from [Schema].[veco_prod] where VCode = @docvcode

if(isnull((select s.fl from vLexOrg s where s.vcode = @���������������), 0) <> 1) -- ��������������� �����������
begin
 select @���������������� = case when mainTable.org = 3948992 
							then '������ ��� "�������-���" � �. ��������� ����������� �������' 
							else dbo.EFN_Org_Fullname(case 
												when gruzpoluch.vcode in (1830322500,1830322290)
												then gruzpoluch.vcode
												 when dbo.LexGetPlatOrg(gruzpoluch.vcode) in (1512824,1812453180,5255458,1779365,1830322500) 
												 then gruzpoluch.vcode
												 when gruzpoluch.vcode in (1814880690) -- ����������������� ��
												 then isnull(mainTable.int12,mainTable.org)  -- �����������������                
                                                 else dbo.LexGetPlatOrg(gruzpoluch.vcode) 
												 end
												 , mainTable.date) 
												 end

	, @��������������     = gruzpoluch.inn
	, @������������       = case when mainTable.org=3948992 then '740443001' else dbo.EFN_OrgKPP(gruzpoluch.vcode, mainTable.date) end	
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as gruzpoluch on gruzpoluch.VCode= isnull(mainTable.int12, mainTable.org)
 where mainTable.VCode = @docvcode

 if(@����������������  is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "���������������"',16,1)
 if(@��������������    is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "���������������"',16,1)
 if(@������������      is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "���������������"',16,1)
end
if(isnull((select fl from vLexOrg s where s.vcode = @���������������), 0) = 1) -- ��������������� ��
begin
 select @��������������   = org.inn
      , @���������������� = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then '�� ' + flc.Fam 
							else left(org.name, CHARINDEX(' ', org.name))
							end	
	  , @������������     = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.im 
							else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
							end
	 , @����������������� = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Otch
							else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
							end
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as org on org.VCode  = mainTable.org
 left join [dbo].[VBn_kadry_FLuni]   as flc on flc.treevc = org.code_fl
 where mainTable.VCode = @docvcode
 
 if(@��������������    is null) raiserror('� ����������� ����������� ��� ������ � ��� ������ � ���� "���������������"',16,1)
 if(@����������������  is null) raiserror('� ����������� ����������� ��� ������ � �������� ������ � ���� "���������������"',16,1)
 if(@������������      is null) raiserror('� ����������� ����������� ��� ������ � ����� ������ � ���� "���������������"',16,1)
 if(@����������������� is null) raiserror('� ����������� ����������� ��� ������ �� �������� ������ � ���� "���������������"',16,1)

 select @����������������� = 1 -- ��� �������� � return
end

select @����������������� = isnull(nullif([dbo].[efn_GetAdr] (org.vcode, @rdate, 11858, 0),''), [dbo].[efn_GetAdr] (org.vcode, @rdate, 11857, 0))
     , @���������������   = case when isnull(org.country,0)=0 then '643' else org.country end
from [Schema].[veco_prod] as mainTable
left join [dbo].[VLexOrg]           as org on org.VCode = mainTable.org
where mainTable.VCode = @docvcode

if(@����������������� is null) raiserror('� ����������� ����������� ��� ������ � ������ ����������� � ���� "���������������"',16,1) 
--} �������� ������ ���������������

--{ �������� ������ �����
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

if not exists (select 1 from @tableSender) raiserror('� ��������� ��� ������ � �����/�������� ��� �����/�������',16,1)
--} �������� ������ �����

--{ �������� ������ �������� � ����������
declare @��������������    nvarchar(500)
      , @������������      nvarchar(500)
	  , @����������        nvarchar(500)
	  , @������������      nvarchar(500)
	  , @��������������    nvarchar(500)
	  , @����������        nvarchar(500)
	  , @���������������   nvarchar(500)
	  , @���������������   nvarchar(500)
	  , @�������������     nvarchar(500)
      , @����������        int
	  , @������������      bit = 0

select @���������� = org from [Schema].[veco_prod] where VCode = @docvcode

if(isnull((select s.fl from vLexOrg s where s.vcode = @����������), 0) <> 1) -- ���������� �����������
begin
 select @�������������� = dbo.EFN_Org_Fullname(case 
											   when dbo.LexGetPlatOrg(buyer.vcode) in (1512824,1812453180) 
											   then buyer.vcode 
											   else dbo.LexGetPlatOrg(buyer.vcode) 
											   end
											   , mainTable.date)
		, @������������ = buyer.inn
		, @����������   = [dbo].[EFN_OrgKPP](buyer.vcode, mainTable.date)
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as buyer    on buyer.VCode    = (case when dbo.lexgetplatorg(mainTable.int12) = mainTable.org then isnull(mainTable.int12, mainTable.org) else isnull(mainTable.org, mainTable.int12) end)
 left join [dbo].[VLexOrg]           as buyerAdr on buyerAdr.vcode = isnull((select plat from spr_org where vcode = mainTable.org ),mainTable.org)--isnull([dbo].[EFN_Org_plat](mainTable.org), mainTable.org)
 where mainTable.VCode = @docvcode
 if(@�������������� is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "�����������(�����)"',16,1) 
 if(@������������   is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "�����������(�����)"',16,1) 
 if(@����������     is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "�����������(�����)"',16,1) 
end

if(isnull((select s.fl from vLexOrg s where s.vcode = @����������),0) = 1) -- ���������� ��
begin
 select @������������   = org.inn
      , @�������������� = case 
						  when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
						  then '�� ' + flc.Fam 
						  else left(org.name,CHARINDEX(' ',org.name))
						  end
	, @���������� = case 
					when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
					then flc.im 
					else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
					end
	, @��������������� = case 
						 when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
						 then flc.Otch
						 else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
						end
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as org on org.VCode  = mainTable.org
 left join [dbo].[VBn_kadry_FLuni]   as flc on flc.treevc = org.code_fl
 where mainTable.VCode = @docvcode
 if(@������������    is null) raiserror('� ����������� ����������� ��� ������ � ��� ������ � ���� "�����������(�����)"',16,1)
 if(@��������������  is null) raiserror('� ����������� ����������� ��� ������ � ������� ������ � ���� "�����������(�����)"',16,1)
 if(@����������      is null) raiserror('� ����������� ����������� ��� ������ � ����� ������ � ���� "�����������(�����)"',16,1)
 if(@��������������� is null) raiserror('� ����������� ����������� ��� ������ �� �������� ������ � ���� "�����������(�����)"',16,1)
 select @������������ = 1
end

select @��������������� = isnull(buyerAdr.adr1, buyerAdr.adr2)
     , @�������������   = case when isnull(buyerAdr.country,0)=0 then '643' else buyerAdr.country end --isnull(buyerAdr.country, '643')
from [Schema].[veco_prod] as mainTable
left join [dbo].[VLexOrg]           as buyerAdr on buyerAdr.vcode = isnull((select plat from spr_org where vcode = mainTable.org ), mainTable.org)--isnull([dbo].[EFN_Org_plat](mainTable.org), mainTable.org)
where mainTable.VCode = @docvcode

if(@��������������� is null) raiserror('� ����������� ����������� ��� ������ � ������ ����������� � ���� "�����������(�����)"',16,1) 
--} �������� ������ �������� � ����������

--{ �������� ������������� ��������
/*declare @tableDoc table (����������� nvarchar(500), ���������� nvarchar(500), ����������� nvarchar(500))

insert into @tableDoc (�����������, ����������, �����������)
select   ����������� = '� �/� ' + convert(nvarchar(500),ROW_NUMBER () OVER(ORDER BY m.vcode))
	   , ���������� = isnull(mainTable.Nomer,'')
	   , ����������� = convert(varchar(10), mainTable.Rdate,104)
from [Schema].[veco_prod] as mainTable
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode 
where mainTable.VCode = @docvcode*/
declare @docmatVcodeCount nvarchar(500) --����� �������
select @docmatVcodeCount = count(*)
from [Schema].[veco_prodMat] as m           
where m.pcode = @docvcode

declare   @����������� nvarchar(500)
		, @���������� nvarchar(500)
		, @����������� nvarchar(500)

select   @����������� = '� �/� 1-' + @docmatVcodeCount
	   , @���������� = isnull(mainTable.Nomer,'')
	   , @����������� = convert(varchar(10), mainTable.Rdate,104)
from [Schema].[veco_prod] as mainTable
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode 
where mainTable.VCode = @docvcode
--} �������� ������������� ��������

--{ ���� ������ ����� ������� ����� 20.01.2020 �� ������ � ���������� ��������� � �/�
declare @�������������� nvarchar(500)
      , @�������������  nvarchar(500)
	  , @�������������� nvarchar(500)
	  , @��������		nvarchar(500)
	  , @������������	nvarchar(500)
	  , @���������		nvarchar(500)
	  , @�������������	nvarchar(500)
	  , @�������������� nvarchar(500)
	  , @�������������	nvarchar(500)

declare @textInf table(id varchar(100), vl varchar (500))

select @�������������� = case 
                         when @�������_���������� = 3113908 -- ������� ���������� (���������� �������������� ������ �����)
                         then '��������-�������_��' 
		                 else '��������-�������' 
		                 end
	 , @�������������  = convert(varchar(10),mainTable.[date],104)
	 , @�������������� = mainTable.norder
	 , @��������       = (
	                      select top 1 bar.barcode
						  from [sea_schema].[eco_barCodes_mat_h] bar                 
                          where bar.DocVcode = mainTable.vcode and bar.DocTdoc = 'NF2' and bar.SEATdoc = 'SA'                                
                          order by DocWdate desc 
	                     )
	 , @������������   = '�������(��������):'+isnull(d.text4,'') + case when d.text4 is null then '' else '/' end + u.Name
	 , @���������      = isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  isnull([dbo].[EFN_Org_plat](mainTable.org),mainTable.org)),'')
	 , @�������������  =  case when mainTable.org=3948992 then '������ ��� "�������-���" � �. ��������� ����������� �������' else isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  isnull([dbo].[EFN_Org_plat](mainTable.int12),mainTable.int12)),'') end
	 , @�������������� = mainTable.nomer
	 , @������������� = convert(varchar(10), mainTable.Rdate,104)
from [Schema].[veco_prod] as mainTable
left join [dbo].[lexdogovor]        as d on d.treevc = mainTable.dogovor
left join [dbo].[unianalit]         as u on u.VCode  = d.treevc
where mainTable.VCode = @docvcode

insert into @textInf (id, vl) 
values ('��������������', @��������������)
     , ('�������������',  @������������� )
	 , ('��������������', @��������������)
	 , ('��������',       @��������      )
	 , ('������������',   @������������  )
	 , ('���������',      @���������     )
	 , ('�������������',  @������������� ) 
	 , ('��������������', @��������������) 
	 , ('�������������',  @������������� )
if(@�������������� is null) raiserror('� ��������� ��� ������ � ���� "������� ����������"',16,1) 
if(@�������������  is null) raiserror('� ��������� �� ��������� ����',16,1) 
if(@�������������� is null) raiserror('� ��������� ��� ������ � ���� "����-������� �"',16,1) 
if(@��������       is null) raiserror('� ����������� ��� ������ � ���������',16,1) 
if(@������������   is null) raiserror('� ����������� ��������� ��� ������ � ��������',16,1) 
if(@���������      is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "�����������(�����)"',16,1) 
if(@�������������  is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "���������������"',16,1) 
--} ���� ������ �����



--{ ���� ������ �������� � ������
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
								   , ���������      nvarchar(500)
                                  )
insert into @productInformation (id, name, OKEI, number, price, rateWithoutNDS, rate, rateSum, excise, sumexcise, sumWithoutNDS, sumCash, ���������)
select 
   id             = ROW_NUMBER() over(order by m.MatCode, m.text1, m.Text5,  m.pnds, m.OZena2)
 , name           = case      --����������� ���� � ���������    
                    when m.text1 like '%'+( select top 1 gost_vid  from bn_product where vcode = m.matcode)+'%' and ( select top 1 gost_vid  from bn_product where vcode = m.matcode) is not null    
                    then substring(m.text1,0,CHARINDEX(( select top 1 gost_vid  from bn_product where vcode = m.matcode),m.text1))    
                    else m.text1    
                    end  
                    + isnull((select top 1 full_gost=' '+isnull(gost_vid,'')+' '+isnull(gost,'')  from bn_product where vcode = m.matcode),'') 
 , OKEI           = case when @�������_���������� = 3113908 then '168' else '112' end 
 , number         = case 
                    when @�������_���������� = 3113908 
 				    then rtrim(ltrim(convert(varchar(50),convert(float,round(m.kolvo1,3)))))               
                    else rtrim(ltrim(convert(varchar(50),convert(money,round(m.kolvo,2))))) 
 				    end 
 , price          = rtrim(ltrim(convert(varchar(50),convert(money,round(convert(money,m.ozena2*100/120),2))))) 
 , rateWithoutNDS = rtrim(ltrim(convert(varchar(50),round(m.SumBNDSRsh,2)))) 
 , rate           = convert(varchar(8), m.PNDS) + '%' 
 , rateSum        = rtrim(ltrim(convert(varchar(50),round(m.SumSNDSRsh,2))))
 , excise         = case when round(isnull(m.summa,0),2) = 0 then '��� ������' else null end
 , sumexcise      = case when round(isnull(m.summa,0),2) <> 0 then rtrim(ltrim(convert(varchar(50), round(isnull(m.summa,0),2)))) else null end 
 , sumWithoutNDS  = case when round(isnull(m.SumNDSRsh,0),2) = 0 then '��� ���' else null end
 , sumCash        = case when round(isnull(m.SumNDSRsh,0),2) <> 0 then rtrim(ltrim(convert(varchar(50),round(isnull(m.SumNDSRsh,0),2)))) else null end
 , ���������      = case when @�������_���������� = 3113908 then '�' else '�' end 

from [Schema].[veco_prod]    as mainTable                                
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode
where mainTable.vcode = @docvcode
if not exists(select 1 from @productInformation) raiserror('� ��������� ����� ��������� ��� ������ � ������',16,1)

declare @���������������  nvarchar(500)
      , @�����������      nvarchar(500)
      , @�����������      nvarchar(500)
	  , @���������������� nvarchar(500)
select @��������������� = rtrim(ltrim(convert(varchar(50),round(sum(m.SumSNDSRsh),2))))
     , @����������� = case when round(sum(isnull(m.SumNDSRsh,0)),2) = 0 then '��� ���' else null end 
     , @����������� = case when round(sum(isnull(m.SumNDSRsh,0)),2) <> 0 then rtrim(ltrim(convert(varchar(50),round(sum(isnull(m.SumNDSRsh,0)),2)))) else null end
	 , @���������������� = rtrim(ltrim(convert(varchar(50),round(sum(m.SumBNDSRsh),2))))
from [Schema].[veco_prod]    as mainTable                               
join [Schema].[veco_prodMat] as m on mainTable.vcode = m.pcode                                
where mainTable.vcode = @docvcode
if(@��������������� is null) raiserror('� ��������� ����� ��������� ��� ������ � �����',16,1) 
if(@����������� is null and @����������� is null) raiserror('� ��������� ����� ��������� ��� ������ � �����',16,1)
--} ���� ������ �������� � ������

--{ ���� ������ �������� ��������� ��������
declare @���������������������        nvarchar(500)
      , @���������������������������� nvarchar(500)
	  , @��������������������������   nvarchar(500)
	  , @������������������������     nvarchar(500)
	  , @�������������������������    nvarchar(500)
	  , @�����������������������      nvarchar(500)
	  , @��������������������         nvarchar(500)
	  , @���������������������������  nvarchar(500)
	  , @�������������������������    nvarchar(500)
	  , @��������������������         nvarchar(500)
	  , @������������������������     nvarchar(500)
declare @OwrNeftebaza table(vcode int)
insert into @OwrNeftebaza(vcode)
select t.UA5
from Schema.Eco_prod_SprNoFilter t
where t.UA5 is not null and t.ChCode = 'SubFilials2' and t.CodePlan = 6

select @��������������������� = case 
                       when @�������_���������� = 3113908 -- ������� ���������� (���������� �������������� ������ �����)
					        and @���������������� not in (select vcode from @OwrNeftebaza)--(104579626,101026606,104579176,16354456,16368886,16370056,16370866,16370986,16371286,104556886,104557126,104557336,104567326,104567476,104569876,104579386,104579746,104582476,104582656,16368436) -- 104579626 - ��������������� ��������� (okpo ����� �����������)  � ��. ���������
					   then (select s.okpo 
					         from Spr_Org s 
							 join Schema.EFn_TankFarmsFull (@rdate, 194, mainTable.gruzotp) as p1 on s.vcode = p1.[owner])
                       else (select okpo from vLexOrg where vcode = @we) 
					   end
from [Schema].[veco_prod] as mainTable 
where mainTable.vcode = @docvcode 
if(@��������������������� is null) raiserror('� ����������� ����������� ��� ������ � ���� ����������� � ���� "����������������"',16,1)

--select @�������_���������� = isnull(int4,0) from [Schema].[veco_prod] where VCode = @docvcode
--select @����������������   = gruzotp from [Schema].[veco_prod] where VCode = @docvcode 
if(@�������_���������� = 3113908 and exists ( select 1 from dbo.UniAnalit where VCode = @���������������� and AType = '�����' ))
begin
 select @���������������������������� = o.fullname
	  , @��������������������������   = ltrim(rtrim(o.inn))
	  , @������������������������     = ltrim(rtrim(o.kpp))
	  , @�������������������������    = farm.factAddress
	  , @�����������������������      = '643'
	  , @���������������������������  = ltrim(rtrim(acc.account))
	  , @�������������������������    = ltrim(rtrim(acc.bankname))
	  , @��������������������         = ltrim(rtrim(sb.MFO))
	  , @������������������������     = ltrim(rtrim(sb.ksch))
 from [Schema].[veco_prod] as mainTable 
 left join Schema.vecotankfarm  as p    on p.vcode = mainTable.gruzotp
 left join spr_org                   as o    on p.[owner] = o.vcode 
 left join Schema.vecotankfarm  as farm on farm.vcode = mainTable.gruzotp
 left join vLexorg_accounts          as acc  on o.vcode = acc.pcode and acc.active = 1
 left loop join spr_bank             as sb   on acc.bank = sb.code
 where mainTable.vcode = @docvcode
 if(@���������������������������� is null) raiserror('� ����������� ����������� ��� ������ � ����������� ����������� � ���� "����������������"',16,1)
 if(@��������������������������   is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "����������������"',16,1)
 if(@������������������������     is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "����������������"',16,1) 
 if(@�������������������������    is null) raiserror('� ����������� ����������� ��� ������ � ������ ����������� � ���� "����������������"',16,1) 
 if(@���������������������������  is null) raiserror('� ����������� ����������� ��� ������ � ������ ����� ����������� � ���� "����������������"',16,1)
 if(@�������������������������    is null) raiserror('� ����������� ��� ������ � ������������ ����� ����������� � ���� "����������������"',16,1)
 if(@��������������������         is null) raiserror('� ����������� ��� ������ � ��� ����� ����������� � ���� "����������������"',16,1)
 if(@������������������������     is null) raiserror('� ����������� ��� ������ � ��� ����� ����� ����������� � ���� "����������������"',16,1)
end

else
begin
 select @���������������������������� = '��� "��������-�������" '+replace(ltrim(rtrim(p.NamePodr)), '- ', '"') + '" ' + gruzotpUa.Name    
      , @�������������������������� = (select s.inn from vLexOrg s where s.vcode = @we) 
      , @������������������������ = 
	   (
	     select top 1 kpp = coalesce (p.KPP, ss.KPP, '')                
         from Schema.EFn_prod_AccessDocCodePodr (@getdate, 194, 0, null) as p                
         join dbo.Spr_Org as ss with (nolock) on ss.VCode = p.OrgCode                
         where p.VCode = mainTable.Code_Podr
        )
	   , @������������������������� = p.AddressTXT
	   , @����������������������� = (select case when isnull(s.country,'643')=0 then '643' else s.country end from  vLexOrg s where s.vcode = @we) 
	   , @��������������������������� = (   
                                         select top 1 acc.account    
                                         from vLexorg_accounts acc     
                                         where acc.vcode  = (case 
										                     when @�������_���������� = 3113908     
                                                             then 808278226     
                                                             else (select p.account    
                                                                   from Schema.EFn_prod_AccessDocSubCodePodr(@getdate,194,null,null,null) as p              
                                                                   where p.VCode = (case 
																                    when @�������_���������� = 3113908 
																					then @���������������� 
																					else mainTable.Code_Podr 
																					end)      
                                                                         and p.CodePodr = mainTable.Code_Podr --!!!!!!!!!!!!       
                                                                  )    
															end)
	                                     )
	  , @������������������������� = oa.bankName
	  , @��������������������      = oa.bik
	  , @������������������������  = oa.korSchet
 from [Schema].[veco_prod] as mainTable
 join [Schema].[EFn_prod_AccessDocSubCodePodr](@getdate,194,null,null,null) as p on p.VCode = (case when @�������_���������� = 3113908 then mainTable.gruzotp else mainTable.Code_Podr end)  
 left join [dbo].[unianalit] as gruzotpUa on gruzotpUa.VCode = mainTable.gruzotp
 outer apply ( 
              select top 1 bankName = acc.bankname + ' �. ' + sb.gorod
                         , bik      = acc.bik
						 , korSchet = sb.ksch              
               from vLexorg_accounts acc     
               left loop JOIN spr_bank sb on acc.bank=sb.code       
               where acc.vcode  = (case 
			                       when @�������_���������� = 3113908     
                                   then 808278226     
                                   else (select p.account    
                                        from Schema.EFn_prod_AccessDocSubCodePodr(@getdate,194,null,null,null) as p                where p.VCode = (case 
										                 when @�������_���������� = 3113908 
														 then mainTable.gruzotp 
														 else mainTable.Code_Podr 
														 end)      
                                         and p.CodePodr = mainTable.Code_Podr --!!!!!!!!!!!!!!!!!       
                                         )  
									end) 
                 ) as oa
 where mainTable.vcode = @docvcode                                     
 if(@���������������������������� is null) raiserror('� ����������� ����������� ��� ������ � ����������� ����������� � ���� "����������������"',16,1)
 if(@��������������������������   is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "����������������"',16,1)
 if(@������������������������     is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "����������������"',16,1)
 if(@�������������������������    is null) raiserror('� ����������� ����������� ��� ������ � ������ ����������� � ���� "����������������"',16,1)
 if(@���������������������������  is null) raiserror('� ����������� ����������� ��� ������ � ������ ����� ����������� � ���� "����������������"',16,1)
 if(@�������������������������    is null) raiserror('� ����������� ��� ������ � ������������ ����� ����������� � ���� "����������������"',16,1)
 if(@��������������������         is null) raiserror('� ����������� ��� ������ � ��� ����� ����������� � ���� "����������������"',16,1)
 if(@������������������������     is null) raiserror('� ����������� ��� ������ � ��� ����� ����� ����������� � ���� "����������������"',16,1)
end
select @�������������������� = case when mainTable.deban in (3920308,3920728,3920788) then ' '  else '-' end
from [Schema].[veco_prod] as mainTable 
where mainTable.vcode = @docvcode 
--} ���� ������ �������� ��������� ��������

--{ ���� ������ �������� ��������� ���������
declare @����������������������        nvarchar(500)
      , @����������������������������� nvarchar(500)
	  , @���������������������������   nvarchar(500)
	  , @�������������������������     nvarchar(500)
	  , @�����������������������       nvarchar(500)
	  , @�������������������������     nvarchar(500)
	  , @���������������������         nvarchar(500)
	  , @��������������������������    nvarchar(500)
	  , @��������������������������    nvarchar(500)
	  , @������������������������      nvarchar(500)
	  , @���������������������         nvarchar(500)
	  , @����������������������������  nvarchar(500)
	  , @��������������������������    nvarchar(500)
	  , @���������������������         nvarchar(500)
	  , @�������������������������     nvarchar(500)
	  , @���������                     int

select @���������������������� = nullif((select okpo from vLexOrg where vcode = isnull(mainTable.int12,mainTable.org)),'')
from [Schema].[veco_prod] as mainTable 
where mainTable.vcode = @docvcode 
--if(@���������������������� is null) raiserror('� ����������� ����������� ��� ������ � ���� ����������� � ���� "���������������"',16,1)

select @��������� = isnull(int12, org) from [Schema].[veco_prod] where VCode = @docvcode
if( isnull((select fl from vLexOrg where vcode = @���������),0) <> 1 ) -- ���������� �����������
begin
  select @����������������������������� = dbo.EFN_Org_Fullname(s.vcode, @rdate)
       , @��������������������������� = s.inn
	   , @������������������������� = dbo.EFN_OrgKPP(s.vcode, mainTable.date)
 from [Schema].[veco_prod] as mainTable 
 left join vLexOrg                   as s on s.vcode = isnull(mainTable.int12, mainTable.org)
 where mainTable.vcode = @docvcode
 
 if(@����������������������������� is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "���������������"',16,1)
 if(@���������������������������   is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "���������������"',16,1)
 if(@�������������������������     is null) raiserror('� ����������� ����������� ��� ������ � ��� ����������� � ���� "���������������"',16,1)
end

if(isnull((select fl from vLexOrg where vcode = @���������),0) = 1) -- ���������� ��
begin
 select @����������������������� = org.inn
      , @������������������������� = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Fam 
							else left(org.name, CHARINDEX(' ', org.name))
							end	
	  , @��������������������� = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.im 
							else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
							end
	 , @�������������������������� = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Otch
							else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
							end
 from [Schema].[veco_prod] as mainTable
 left join [dbo].[VLexOrg]           as org on org.VCode  = isnull(mainTable.int12,mainTable.org)
 left join [dbo].[VBn_kadry_FLuni]   as flc on flc.treevc = org.code_fl
 where mainTable.VCode = @docvcode
 
 if(@�����������������������    is null) raiserror('� ����������� ����������� ��� ������ � ��� ������� � ���� "���������������"',16,1)
 if(@�������������������������  is null) raiserror('� ����������� ����������� ��� ������ � �������� ������� � ���� "���������������"',16,1)
 if(@���������������������      is null) raiserror('� ����������� ����������� ��� ������ � ����� ������� � ���� "���������������"',16,1)
 if(@�������������������������� is null) raiserror('� ����������� ����������� ��� ������ �� �������� ������� � ���� "���������������"',16,1)
end

select @�������������������������� = isnull(nullif([dbo].[efn_GetAdr](s.vcode, @rdate, 11858, 0),''), [dbo].[efn_GetAdr] (s.vcode, @rdate, 11857, 0))
     , @������������������������ = case when s.country=0 then '643' else isnull(s.country,'643') end
from [Schema].[veco_prod] as mainTable
left join [dbo].[vLexOrg]           as s on s.vcode = isnull(mainTable.int12,mainTable.org) 
where mainTable.VCode = @docvcode

if(@�������������������������� is null) raiserror('� ����������� ����������� ��� ������ � ������ ����������� � ���� "���������������"',16,1)

select @��������������������� = case 
                                when len(o.Phone) = 0 
								then case 
								     when len(o.fax) = 0 
									 then '-' 
									 else left(o.fax,20) 
									 end                  
                                else left(o.Phone,20) 
								end                                
from vLexOrg as o where o.vcode = @���������

select top 1 @���������������������������� = ac.account
           , @�������������������������� = ac.bankname + ' �. ' + sb.gorod
		   , @��������������������� = ac.bik   
		   , @������������������������� = ltrim(rtrim(sb.ksch))
from [dbo].[VLexorg_accounts]   as ac               
left loop join [dbo].[spr_bank] as sb on ac.bank = sb.code  
where ac.pcode = @���������  
  and ac.active = 1
--} ���� ������ �������� ��������� ���������

--{���� ������ ��������
declare @������������       nvarchar(500)
      , @���������������    nvarchar(500)
	  , @�������������      nvarchar(500)
	  , @�����������        nvarchar(500)
	  , @����������������   nvarchar(500)
	  , @��������������     nvarchar(500)
	  , @�����������        nvarchar(500)
	  , @������������������ nvarchar(500)
	  , @����������������   nvarchar(500)
	  , @����������� 	    nvarchar(500)
	  , @���������������    nvarchar(500)

select @������������     = o.okpo 
     , @���������������  = dbo.EFN_Org_Fullname(o.vcode, @rdate)
	 , @�������������    = o.inn
	 , @�����������      = (select kpp from [dbo].[VLex_own_org] where vcode = @we)
	 , @���������������� = isnull(o.adr2, o.adr1)
	 , @��������������   = case when o.country=0 then '643' else isnull(o.country, '643') end
from [dbo].[vLexOrg] as o 
where vcode = @we

if(@���������������  is null) raiserror('� ����������� ����������� ��� ������ � ������������ ��������',16,1)
if(@�������������    is null) raiserror('� ����������� ����������� ��� ������ � ��� ��������',16,1)
if(@�����������      is null) raiserror('� ����������� ����������� ��� ������ � ��� ��������',16,1)
if(@���������������� is null) raiserror('� ����������� ����������� ��� ������ � ������ ��������',16,1)
 
select @����������� = case when mainTable.deban in (3920308,3920728,3920788) then ' '  else '-' end
from [Schema].[veco_prod] as mainTable
where mainTable.VCode = @docvcode

select top 1 
  @������������������ = acc.account
, @����������������   = (select top 1 acc.bankname + ' �. ' + sb.gorod)
, @�����������        = acc.bik
, @���������������    = sb.ksch
from [Schema].[veco_prod] as mainTable
left join [dbo].[vLexorg_accounts]  as acc on acc.vcode  = (case 
                    when @�������_���������� = 3113908     
                    then 808278226     
                    else (select p.account    
                          from Schema.EFn_prod_AccessDocSubCodePodr(@getdate,194,null,null,null) as p    
                          where p.VCode = (case when @�������_���������� = 3113908 then mainTable.gruzotp else mainTable.Code_Podr end)      
                          and p.CodePodr = mainTable.Code_Podr --!!!!!!!!!!!!!!
                         ) 
				    end)     
left loop join [dbo].[spr_bank] as sb on acc.bank = sb.code       
where mainTable.VCode = @docvcode  
--}���� ������ ��������

--{ ���� ������ ����������
declare @��������������       nvarchar(500)
      , @�����������������    nvarchar(500)
	  , @���������������      nvarchar(500)
	  , @�������������        nvarchar(500)
	  , @���������������      nvarchar(500)
	  , @�����������������    nvarchar(500)
	  , @�������������        nvarchar(500)
	  , @������������������   nvarchar(500)
	  , @������������������   nvarchar(500)
	  , @����������������     nvarchar(500)
	  , @�������������        nvarchar(500)
	  , @�������������������� nvarchar(500)
	  , @������������������   nvarchar(500)
	  , @������������� 	      nvarchar(500)
	  , @�����������������    nvarchar(500)
      , @Org_plat             int

select @Org_plat = isnull([dbo].[EFN_Org_plat](@���������������), @���������������)

if(isnull((select fl from vLexOrg s where s.vcode = @Org_plat),0) <> 1) -- ���������� �����������
begin
 select @�������������� = nullif((org.okpo),'')
      , @����������������� = dbo.EFN_Org_Fullname(org.vcode,@rdate)
	  , @��������������� = org.inn
	  , @������������� = dbo.EFN_OrgKPP(org.vcode, @rdate)
 from  [dbo].[VLexOrg] as org  
 where org.VCode  = @Org_plat
end

if(isnull((select fl from vLexOrg s where s.vcode = @Org_plat),0) = 1 ) -- ���������� �������
begin
  select @�������������� = nullif((org.okpo),'')
      , @��������������� = org.inn
      , @����������������� = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Fam 
							else left(org.name, CHARINDEX(' ', org.name))
							end	
	  , @������������� = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.im 
							else isnull(nullif(left(REPLACE(org.name, left(org.name,CHARINDEX(' ',org.name)),''), CHARINDEX(' ', REPLACE(org.name, left(org.name, CHARINDEX(' ',org.name)),''))),''),'_') 
							end
	 , @������������������ = case 
							when org.code_fl is not null and exists(select 1 from unianalit where vcode = org.code_fl)                 
							then flc.Otch
							else replace(REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''),left(REPLACE(org.name,left(org.name, CHARINDEX(' ',org.name)),'') ,CHARINDEX(' ',REPLACE(org.name,left(org.name,CHARINDEX(' ',org.name)),''))),'')
							end
 from [dbo].[VLexOrg] as org 
 left join [dbo].[VBn_kadry_FLuni] as flc on flc.treevc = org.code_fl
 where org.VCode  = @Org_plat
end

select @������������������ = case 
                             when @��������������� in (1812971700, 1812566220) 
							 then s.adr2
                             when @��������������� in (33439906) and @rdate between '20160909' and '20161231' 
							 then s.adr2
                             else s.adr1 
							 end           
       , @���������������� = case when s.country=0 then '643' else isnull(s.country,'643') end
	   , @������������� = case 
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


select top 1 @�������������������� = account
           , @������������������ = ac.bankname
		   , @������������� = ac.bik
		   , @����������������� = ltrim(rtrim(sb.ksch)) 
from  [dbo].[VLexorg_accounts]  as ac       
left loop JOIN [dbo].[spr_bank] as sb on ac.bank = sb.code      
where ac.pcode =  @Org_plat and active = 1  
--} ���� ������ ����������

--{ ���� ������ ���������
declare @������� nvarchar(500)
      , @������  nvarchar(500)
	  , @������� nvarchar(500)
select @������� = isnull(d.text4,'') + case when d.text4 is null then '' else '/' end + u.Name
     , @������ = d.nomer
	 , @������� = convert(varchar(10),d.[rdate],104)
from [Schema].[veco_prod] as mainTable
left join [dbo].[lexdogovor]        as d on d.treevc = mainTable.dogovor
left join [dbo].[unianalit]         as u on u.VCode  = d.treevc
where mainTable.VCode = @docvcode
--} ���� ������ ���������

--{ ���� ������ ���������1
declare @��������������1 nvarchar(500)
      , @�����������1    nvarchar(500)
	  , @������������1   nvarchar(500)
	  , @��������1		 nvarchar(500)
	  , @���������1		 nvarchar(500)
	  , @�������������1	 nvarchar(500)
	  
declare @textInf1 table(id varchar(100), vl varchar (500))

select @��������������1 = case 
                         when @�������_���������� = 3113908 -- ������� ���������� (���������� �������������� ������ �����)
                         then '��������-�������_��' 
		                 else '��������-�������' 
		                 end
	 , @�����������1  = convert(varchar(10),d.[rdate],104)
	 , @������������1 = d.nomer
	 , @��������1       = (
	                      select top 1 bar.barcode
						  from [sea_schema].[eco_barCodes_mat_h] bar                 
                          where bar.DocVcode = mainTable.vcode and bar.DocTdoc = 'NF2' and bar.SEATdoc = 'TN'
                          order by DocWdate desc 
	                     )
	 , @���������1 = isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  @Org_plat),'')
	 , @�������������1 = isnull((select top 1 dbo.EFN_Org_Fullname(s.vcode, @rdate) from vLexOrg s where s.vcode =  @Org_plat),'')
	 
from [Schema].[veco_prod] as mainTable
left join [dbo].[lexdogovor]        as d on d.treevc = mainTable.dogovor
left join [dbo].[unianalit]         as u on u.VCode  = d.treevc
where mainTable.VCode = @docvcode

insert into @textInf1 (id, vl) 
values ('��������������', @��������������1)
     , ('�����������',    @�����������1   )
	 , ('������������',   @������������1  )
	 , ('��������',       @��������1      )
	 , ('���������',      @���������1     )
	 , ('�������������',  @�������������1 ) 
 
--if(@�������������� is null) raiserror('� ��������� ��� ������ � ���� "������� ����������"',16,1) 
--if(@�������������  is null) raiserror('� ��������� �� ��������� ����',16,1) 
--if(@�������������� is null) raiserror('� ��������� ��� ������ � ���� "����-������� �"',16,1) 
--if(@��������       is null) raiserror('� ����������� ��� ������ � ���������',16,1) 
--if(@������������   is null) raiserror('� ����������� ��������� ��� ������ � ��������',16,1) 
--if(@���������      is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "�����������(�����)"',16,1) 
--if(@�������������  is null) raiserror('� ����������� ����������� ��� ������ � ������������ ����������� � ���� "���������������"',16,1) 
--} ���� ������ ���������1

--{ ���� ������ ������2
declare @�������    varchar (500)
      , @���������� varchar (500)
	  , @��������	varchar (500)
	  , @���������	varchar (500)
declare @productInfo table(������        int
                         , �������       varchar (500)
						 , ������        varchar (500)
						 , ���������     varchar (500)
						 , ����_���      varchar (500)
						 , ������������� varchar (500)
						 , ����          varchar (500)
						 , ��������      varchar (500)
						 , �����         varchar (500)
						 , ������        varchar (500)
						 , �������       varchar (500))
insert into @productInfo (������, �������, ������, ���������, ����_���, �������������, ����, ��������, �����, ������, �������)
select               
 ������ = ROW_NUMBER() over(order by m3.MatCode, m3.text1, m3.Text5,  m3.pnds, m3.PNDS)
--����������� ���� � ��������� 
,������� = case 
	          when m3.text1 like '%'+( select top 1 gost_vid  from bn_product where vcode = m3.matcode)+'%' 
				   and ( select top 1 gost_vid  from bn_product where vcode = m3.matcode) is not null      
              then substring(m3.text1,0,CHARINDEX(( select top 1 gost_vid  from bn_product where vcode=m3.matcode),m3.text1))  
              else m3.text1    
              end     
              + isnull((select top 1 full_gost=' '+isnull(gost_vid,'')+' '+isnull(gost,'')  
			             from bn_product where vcode = m3.matcode),'')
,������ = m3.MatCode 
,��������� = case when @�������_���������� = 3113908 then '�' else '�' end 
,����_��� = case when @�������_���������� = 3113908 then '168' else '112' end 
,������������� = case 
                    when @�������_���������� = 3113908 
					then rtrim(ltrim(convert(varchar(50),convert(float,round(m3.kolvo1,3)))))
					else rtrim(ltrim(convert(varchar(50),convert(money,round(m3.kolvo ,2))))) 
					end 
,���� = rtrim(ltrim(convert(varchar(50),convert(money,round(m3.OZena2*100/120,2))))) 
,�������� = rtrim(ltrim(convert(varchar(50),round(m3.SumBNDSRsh,2)))) 
,����� = rtrim(ltrim(convert(varchar(50),m3.PNDS)))+'%'
,������ = rtrim(ltrim(convert(varchar(50),round(isnull(m3.SumNDSRsh,0),2)))) 
,������� = rtrim(ltrim(convert(varchar(50),round(m3.SumSNDSRsh,2))))                        
from [Schema].[veco_prod]    as mainTable
join [Schema].[veco_prodMat] as m3 on mainTable.vcode = m3.pcode
where mainTable.VCode = @docvcode

select @������� = case 
                  when isnull(mainTable.int4,0) = 3113908 
				  then rtrim(ltrim(convert(varchar(50),convert(float,round(sum(m3.kolvo1),3)))))
				  else rtrim(ltrim(convert(varchar(50),convert(money,round(sum(m3.kolvo),2))))) 
				  end 
	, @���������� = rtrim(ltrim(convert(varchar(50),round(sum(m3.SumBNDSRsh),2)))) 
	, @�������� = rtrim(ltrim(convert(varchar(50),round(sum(isnull(m3.SumNDSRsh,0)),2))))
	, @��������� = rtrim(ltrim(convert(varchar(50),round(sum(m3.SumSNDSRsh),2))))            
from [Schema].[veco_prod]   as mainTable 
join [Schema].[veco_prodMat] as m3 on mainTable.vcode = m3.pcode                                
where mainTable.VCode = @docvcode             
group by mainTable.int4
--} ���� ������ ������2

--{ ���� ������ ������3
declare @�����������     varchar (500)
      , @������������    varchar (500)
	  , @������������    varchar (500)
	  , @������          varchar (500) 
	  , @������������    varchar (500)
	  , @��������        varchar (500)
	  , @�������         varchar (500)
	  , @��������        varchar (500)
	  , @��������������� varchar (500)
	  , @���������       varchar (500)
	  , @�������������   varchar (500)
	  , @����������������� int

declare @orgInfo table (id varchar(100), vl varchar (500))
select
  @����������� = case 
                 when @�������_���������� = 3113908 
				 then coalesce(t.inputnomer,mainTable.nomer) 
				 else null 
				 end
, @������������ = case 
                  when @�������_���������� = 3113908 
				  then convert(varchar(10),(coalesce (t.rdate, @rdate)),104)
				  else null 
				  end
from [Schema].[veco_prod] as mainTable               
left join [Schema].[Eco_TTN]   as t on t.prcode2 = mainTable.vcode                              
where mainTable.VCode = @docvcode

select @����������������� = isnull(ua9,0) from [Schema].[veco_prod] where VCode = @docvcode

--if(@����������������� <> 0)
--begin
 if(@�������_���������� = 3113908)
 begin
  select
  @������������ =  isnull([Schema].[efn_prod_Podpisi_dolg]('������������ ��������� ��� ���������� �� ���', mainTable.gruzotp, @rdate, mainTable.we, mainTable.ua9), ' ')              
  , @������ = isnull(u.Name + (select top 1 '(' + pd.text3 + ')'              
                                  from eco_mtr_komissia_all p 
								  join eco_mtr_komissia_mat_all pd on p.vcode = pd.pcode              
                                  where p.tdoc = 'NRP' 
								   and pd.rcode = mainTable.ua9 
								   and pd.code = 19153530 
								   and isnull(pd.text3,'') <> ''
								   and @rdate between isnull(pd.date1,'19000101') 
								   and isnull(pd.date2,'30000101')
								), ' ') 
  , @������������ = isnull(u1.Name + (select [Schema].[efn_prod_Podpisi]('��������� ��������� ��� ���������� �� ���', mainTable.gruzotp, @rdate, mainTable.we, mainTable.ua10))    , ' ') 
  , @�������� = isnull(mainTable.text1,' ') 
  , @������� =  isnull(convert(varchar(10),mainTable.DPD,104), ' ')
  , @�������� = isnull(o.fullname, ' ') 
  , @��������������� = isnull(mainTable.text13,' ') 
  , @��������� =isnull(mainTable.text2,' ') 
  , @������������� = isnull(dbo.LexNumeralKolvo_rezTnKg((select sum(m.kolvo1) from Schema.eco_prodmat as m where m.pcode = mainTable.vcode)), ' ') 
  from [Schema].[veco_prod] as mainTable
  left join [dbo].[unianalit]         as u  on u.VCode  = mainTable.ua9
  left join [dbo].[unianalit]         as u1 on u1.VCode = mainTable.ua10
  left join [dbo].[Spr_Org]           as o  on o.vcode  = mainTable.org
  where mainTable.VCode = @docvcode

  insert into @orgInfo (id, vl) 
  values ('������������',    @������������   )
       , ('������',          @������         )
  	   , ('������������',    @������������   )
	   , ('��������',        @��������       )
	   , ('�������',         @�������        )
	   , ('��������',        @��������       ) 
	   , ('���������������', @���������������)
	   , ('���������',       @���������      )
	   , ('�������������',   @�������������  )

 end
--} ���� ������ ������3

--{ ��������� ��������, ���� ������� �� ����� ����
declare @���������� nvarchar(500) 
select @���������� = case 
						when @�������������='0277067012' and  @�������������='027701001'  then '1' 
						when @�������������='0277090269' and  @�������������='027701001'  then '1'
						when @�������������='1644040406' and  @�������������='164901001'  then '10' 
						else null 
						end 
--} ��������� ��������, ���� ������� �� ����� ����   

-- ���� �����-�� �� ������������ ����� ������ - ���������� ���������� ���������
if( @�������������      is null
 or @�������������      is null
 or @��������������     is null
 or @��������������     is null
 or @��������           is null
 or @�������������      is null
 or @�������������      is null
 or @�����������        is null
 or @���������          is null
 or @��������������     is null
 or (@����������������  is null and @����������������� = 0)
 or (@��������������    is null and @����������������� = 0)
 or (@������������      is null and @����������������� = 0)
 or (@��������������    is null and @����������������� = 1)
 or (@����������������  is null and @����������������� = 1)
 or (@������������      is null and @����������������� = 1)
 or (@����������������� is null and @����������������� = 1)
 or @�����������������  is null
 or not exists (select 1 from @tableSender)
 or (@��������������    is null and @������������ = 0)
 or (@������������      is null and @������������ = 0)
 or (@����������        is null	and @������������ = 0)
 or (@������������      is null	and @������������ = 1)
 or (@��������������    is null	and @������������ = 1)
 or (@����������        is null	and @������������ = 1)
 or (@���������������   is null	and @������������ = 1)
 or @���������������    is null
 or @���������������    is null
 or (@�����������       is null 
     and @�����������   is null)
  ) return

  --����������/���������

-- �������� ����� XML
SELECT @tmpf_im_sprxml = (
select 
  '@�����' = @tdoc + convert(varchar(255),@docvcode)
, '����������/@���'  = @�������������
, '����������/@���'  = @�������������
, '����������/@����������' = @����������
, '�����������/@���' = @��������������
, '�����������/@���' = @��������������
, cast((select 
   '@��������' = fileName.Name + '.xml'
 , '����/@������' = fileName.Name
 , '����/@��������' = '5.01'
 , '����/@��������' = '����3'
 , '����/�����������/@�����' = ''
 , '����/�����������/@������' = ''
 , '����/�����������/���������/@�������' = '��� "�������� "������"'
 , '����/�����������/���������/@�����' = '7605016030'
 , '����/�����������/���������/@�����' = '2BE'
 , '����/��������/@���' = '1115131'
 , '����/��������/@�������' = '���'
 , '����/��������/@���������' = convert(varchar(10),mainTable.[date],104)
 , '����/��������/@���������' = replace(convert(varchar(8), mainTable.[date], 108),':','.')
 , '����/��������/@���������������' = '��������-�������'
 , '����/��������/��������/@��������' = @��������
 , '����/��������/��������/@�������' = convert(varchar(10),mainTable.[date],104)--dbo.DateToStr(mainTable.[date])
 , '����/��������/��������/@������' = '643'
 , '����/��������/��������/�������/@����������' = @����������
 , '����/��������/��������/�������/@�������������' = case when @���������� is null then @������������� end
 , '����/��������/��������/�������/@�����������'= @����������� 
 , '����/��������/��������/�������/@��������������' = case when @����������� is null then @�������������� end
 , '����/��������/��������/������/����/������/@�������' = @�������������
 , '����/��������/��������/������/����/������/@�����' = @��������������
 , '����/��������/��������/������/����/������/@��������' = case when @�������������� is null then '-' end
 , '����/��������/��������/������/����/������/@���' = @��������������
 --, '��������/��������/������/�����/�����/@������' = @�����������������   
 --, '��������/��������/������/�����/�����/@���������' = @��������������������
 --, '��������/��������/������/�����/�����/@�����' = @����������������     
 --, '��������/��������/������/�����/�����/@�����' = @����������������     
 --, '��������/��������/������/�����/�����/@����������' = @���������������������
 --, '��������/��������/������/�����/�����/@�����' = @����������������     
 --, '��������/��������/������/�����/�����/@���' = @��������������       
 --, '��������/��������/������/�����/�����/@������' = @�����������������    
 --, '��������/��������/������/�����/�����/@�����' = @����������������     
 , '����/��������/��������/������/�����/������/@������' = @�����������������    
 , '����/��������/��������/������/�����/������/@��������' = @������������������� 
 , '����/��������/��������/������/��������/����/������/@�������' = @������������� 
 , '����/��������/��������/������/��������/����/������/@�����' = @����������� 
 , '����/��������/��������/������/��������/����/������/@��������' = case when @����������� is null then '-' end
 , '����/��������/��������/������/��������/����/������/@���' = @���������
 , '����/��������/��������/������/��������/�����/������/@��������' = @��������������
 , '����/��������/��������/������/��������/�����/������/@������' = '643'
 , '����/��������/��������/���������/����/������/@�������' = @����������������
 , '����/��������/��������/���������/����/������/@�����' = @��������������
 , '����/��������/��������/���������/����/������/@���' = @������������
 , '����/��������/��������/���������/����/����/@�����' = @��������������
 , '����/��������/��������/���������/����/����/���/@�������' = @����������������
 , '����/��������/��������/���������/����/����/���/@���' = @������������
 , '����/��������/��������/���������/����/����/���/@��������' = @�����������������
 , '����/��������/��������/���������/�����/������/@��������' = @�����������������
 , '����/��������/��������/���������/�����/������/@������' = @���������������
 , '����/��������/��������' = (
                                select '@��������' = s.norder
    							     , '@�������'  = s.date
								from @tableSender as s
								FOR XML PATH('�����'), type
                               )
 , '����/��������/��������/�������/����/������/@�������' = @��������������
 , '����/��������/��������/�������/����/������/@�����' = @������������
 , '����/��������/��������/�������/����/������/@���' = @����������
 , '����/��������/��������/�������/����/����/@�����' = @������������
 , '����/��������/��������/�������/����/����/���/@�������' = @��������������
 , '����/��������/��������/�������/����/����/���/@���' = @����������
 , '����/��������/��������/�������/����/����/���/@��������' = @���������������
 , '����/��������/��������/�������/�����/������/@��������' = @���������������
 , '����/��������/��������/�������/�����/������/@������' = @�������������
 , '����/��������/��������/������������/@�����������' = @�����������
 , '����/��������/��������/������������/@����������' = @����������
 , '����/��������/��������/������������/@�����������' = @�����������
 /*, '����/��������/��������' = (
                                select '@�����������' = �����������
    							     , '@����������'  = ����������
									 , '@�����������' = �����������
								from @tableDoc as t
								FOR XML PATH('������������'), type
                               )*/
 , '����/��������/��������/���������1' = (                               --������� ����� 20.01.2020 �� ������ � ���������� ��������� � �/�
                                          select '@�������' = i.id
                                               , '@������'  = i.vl
                                          from @textInf as i
                                          FOR XML PATH('��������'), type
										  )
 , '����/��������/����������' = (
                            select '@������'      = pinf.id
							     , '@�������'     = pinf.name
							     , '@����_���'    = pinf.OKEI
							     , '@�������_���' = case when pinf.OKEI is null then '-' end
							     , '@������'      = pinf.number
							     , '@�������'     = pinf.price
							     , '@�����������' = pinf.rateWithoutNDS
							     , '@�����'       = pinf.rate
							     , '@����������'  = pinf.rateSum
								 , '�����/��������' =  pinf.excise        
								 , '�����/��������' =  pinf.sumexcise     
								 , '������/������'  =  pinf.sumWithoutNDS 
								 , '������/������'  =  pinf.sumCash
								 , '����������/@���������' = case when pinf.OKEI is not null then pinf.��������� else '-' end
							from @productInformation as pinf
							FOR XML PATH('�������'), type
                            )				
 , '����/��������/����������/��������/@���������������' = @���������������
 , '����/��������/����������/��������/@������������������' = case when @��������������� is null then '-' end
 , '����/��������/����������/��������/@����������������' = @����������������
 , '����/��������/����������/��������/�����������/������' = @�����������
 , '����/��������/����������/��������/�����������/������' = @�����������
 , '����/��������/���������/�����/@�������' = '������ ��������'
 , '����/��������/���������/�����/������/@�������' = '��� ���������-���������'
 , '����/��������/���������/�����/������/@�������' = convert(varchar(10),mainTable.[date],104)
 , '����/��������/���������/@�������' = 0
 , '����/��������/���������/@������' = 1 
 , '����/��������/���������/@�������' = '����������� �����������'
 , '����/��������/���������/��/@�����' = ''
 , '����/��������/���������/��/@�����' = ''
 , '����/��������/���������/��/���/@�������' = ''
 , '����/��������/���������/��/���/@���' = ''
 , '����/��������/���������/��/���/@��������' = ''
 from [Schema].[veco_prod] as mainTable
 join @fileName                      as fileName on fileName.VCode = mainTable.VCode
 where mainTable.VCode = @docvcode and fileName.Name like '%ON_NSCHFDOPPR_%'
 FOR XML PATH('��������')) AS XML)

 , cast((select 
   '@��������' = fileName.Name + '.xml'
 , '����/@������' = fileName.Name
 , '����/@��������' = '5.01'
 , '����/�����������/@�����' = ''
 , '����/�����������/@������' = ''
 , '����/�����������/���������/@�������' = '��� "�������� "������"'
 , '����/�����������/���������/@�����' = '7605016030'
 , '����/�����������/���������/@�����' = '2BE'
 , '����/��������/@���' = '1175010'
 , '����/��������/@���������' = convert(varchar(10),mainTable.[date],104)
 , '����/��������/@���������' = replace(convert(varchar(8), mainTable.[date], 108),':','.')
 , '����/��������/@���������������' = '��������-�������'
 , '����/��������/��������������/���������/�������/@��������' = '�������� � �������� ������ ��� �������� ���������'
 , '����/��������/��������������/���������/�������/@����������' = '�������� ���������'
 , '����/��������/��������������/���������/��������/@��������' = mainTable.Nomer
 , '����/��������/��������������/���������/��������/@���������' =convert(varchar(10),mainTable.[date],104)
 , '����/��������/��������������/���������/������/@������' = '643'
 , '����/��������/��������������/���������/������1/��������/@����' = @���������������������
 , '����/��������/��������������/���������/������1/��������/����/�����/����/@�������' = @����������������������������
 , '����/��������/��������������/���������/������1/��������/����/�����/����/@�����' = @��������������������������
 , '����/��������/��������������/���������/������1/��������/����/�����/����/@���' = @������������������������
 , '����/��������/��������������/���������/������1/��������/�����/������/@��������' = @�������������������������
 , '����/��������/��������������/���������/������1/��������/�����/������/@������' = @�����������������������
 , '����/��������/��������������/���������/������1/��������/�������/@���' = @��������������������
 , '����/��������/��������������/���������/������1/��������/��������/@����������' = @���������������������������
 , '����/��������/��������������/���������/������1/��������/��������/������/@��������' = @�������������������������
 , '����/��������/��������������/���������/������1/��������/��������/������/@���' = @��������������������     
 , '����/��������/��������������/���������/������1/��������/��������/������/@�������' =	@������������������������ 
 , '����/��������/��������������/���������/������1/���������/@����' = @����������������������
 , '����/��������/��������������/���������/������1/���������/����/�����/����/@�������' = @�����������������������������
 , '����/��������/��������������/���������/������1/���������/����/�����/����/@�����' = @���������������������������
 , '����/��������/��������������/���������/������1/���������/����/�����/����/@���' = @�������������������������
 , '����/��������/��������������/���������/������1/���������/����/����/@�����' = @�����������������������
 , '����/��������/��������������/���������/������1/���������/����/����/���/@�������' = @�������������������������
 , '����/��������/��������������/���������/������1/���������/����/����/���/@���' = @���������������������
 , '����/��������/��������������/���������/������1/���������/����/����/���/@��������' = @��������������������������
 , '����/��������/��������������/���������/������1/���������/�����/������/@��������' = @��������������������������
 , '����/��������/��������������/���������/������1/���������/�����/������/@������' = @������������������������
 , '����/��������/��������������/���������/������1/���������/�������/@���' = @���������������������
 , '����/��������/��������������/���������/������1/���������/��������/@����������' = @����������������������������
 , '����/��������/��������������/���������/������1/���������/��������/������/@��������' = @��������������������������
 , '����/��������/��������������/���������/������1/���������/��������/������/@���' = @���������������������
 , '����/��������/��������������/���������/������1/���������/��������/������/@�������' = @�������������������������
 , '����/��������/��������������/���������/������1/��������/@����' = @������������
 , '����/��������/��������������/���������/������1/��������/����/�����/����/@�������' =  @���������������
 , '����/��������/��������������/���������/������1/��������/����/�����/����/@�����' = @�������������  
 , '����/��������/��������������/���������/������1/��������/����/�����/����/@���' = @�����������    
 , '����/��������/��������������/���������/������1/��������/�����/������/@��������' = @����������������
 , '����/��������/��������������/���������/������1/��������/�����/������/@������'  = @��������������  
 , '����/��������/��������������/���������/������1/��������/�������/@���' = @�����������
 , '����/��������/��������������/���������/������1/��������/��������/@����������' = @������������������
 , '����/��������/��������������/���������/������1/��������/��������/������/@��������' = @����������������  
 , '����/��������/��������������/���������/������1/��������/��������/������/@���' = @����������� 	   
 , '����/��������/��������������/���������/������1/��������/��������/������/@�������' = @���������������   
 , '����/��������/��������������/���������/������1/����������/@����' = @��������������
 , '����/��������/��������������/���������/������1/����������/����/�����/����/@�������' = @�����������������
 , '����/��������/��������������/���������/������1/����������/����/�����/����/@�����' = @���������������
 , '����/��������/��������������/���������/������1/����������/����/�����/����/@���' = @�������������
 , '����/��������/��������������/���������/������1/����������/����/����/@�����' = @���������������
 , '����/��������/��������������/���������/������1/����������/����/����/���/@�������' = @����������������� 
 , '����/��������/��������������/���������/������1/����������/����/����/���/@���' = @�������������     
 , '����/��������/��������������/���������/������1/����������/����/����/���/@��������' = @������������������
 , '����/��������/��������������/���������/������1/����������/�����/������/@��������' = @������������������
 , '����/��������/��������������/���������/������1/����������/�����/������/@������'  = @����������������
 , '����/��������/��������������/���������/������1/����������/�������/@���' = @�������������
 , '����/��������/��������������/���������/������1/����������/��������/@����������' = @��������������������
 , '����/��������/��������������/���������/������1/����������/��������/������/@��������' = @������������������    
 , '����/��������/��������������/���������/������1/����������/��������/������/@���' = @������������� 	     
 , '����/��������/��������������/���������/������1/����������/��������/������/@�������' = @�����������������     
 , '����/��������/��������������/���������/������1/���������/@�������' = @�������
 , '����/��������/��������������/���������/������1/���������/@������' = @������ 
 , '����/��������/��������������/���������/������1/���������/@�������' = @�������
 , '����/��������/��������������/���������/������1/���������1' = (
                                                                 select '@�������' = i.id
                                                                      , '@������'  = i.vl
                                                                 from @textInf1 as i
                                                                 FOR XML PATH('��������'), type
										                         )
 , '����/��������/��������������/������2' = (
                                               select   '@������'        = i.������       
                                                      , '@�������'       = i.�������      
							                 		  , '@������'        = i.������       
							                 		  , '@���������'     = i.���������    
							                 		  , '@����_���'      = i.����_���     
							                 		  , '@�������������' = i.�������������
							                 		  , '@����'          = i.����         
							                 		  , '@��������'      = i.��������     
							                 		  , '@�����'         = i.�����        
							                 		  , '@������'        = i.������       
							                 		  , '@�������'       = i.�������      
                                               from @productInfo as i
                                               FOR XML PATH('�����'), type
							                 )
 , '����/��������/��������������/������2/�����/@�������' =  @�������    
 , '����/��������/��������������/������2/�����/@����������' = @���������� 
 , '����/��������/��������������/������2/�����/@��������' =  @��������	
 , '����/��������/��������������/������2/�����/@���������' = @���������	
 , '����/��������/������3/@�������' = '������������� � ��������� �������� ��������'
 , '����/��������/������3/��������/@�����������' = @�����������
 , '����/��������/������3/��������/@������������' = @������������
 , '����/��������/������3' = (
                             select '@�������' = i.id
                                  , '@������'  = i.vl
                             from @orgInfo as i
                             FOR XML PATH('���������3'), type
							 )
 , '����/��������/���������/@�������' = 1
 , '����/��������/���������/@������' = 1
 , '����/��������/���������/@�������' = ''
 , '����/��������/���������/@����������' = ''
 , '����/��������/���������/��/@�����' = ''
 , '����/��������/���������/��/@�����' = ''
 , '����/��������/���������/��/���/@�������' = ''
 , '����/��������/���������/��/���/@���' = ''
 , '����/��������/���������/��/���/@��������' = ''
   from [Schema].[veco_prod] as mainTable
   join @fileName                      as fileName on fileName.VCode = mainTable.VCode
   where mainTable.VCode = @docvcode and fileName.Name like '%DP_TOVTORGPR_%'
   FOR XML PATH('��������')) AS XML)

 FOR XML PATH('�����'), ROOT('������')
 )

-- select @tmpf_im_sprxml

 -- ������� xml �� ����� ������ ��������                
if @show = 1                
begin
 select convert(xml,@tmpf_im_sprxml)
 return                
end 

declare @tmpf_im_spr varchar(max)
      , @inn         varchar(255) = @��������������
      , @kpp         varchar(255) = @��������������
	  , @inn_pokup   varchar(255) = @�������������
	  , @kpp_pokup   varchar(255) = @�������������

-- ��������� � ������ ��������� ����������
SELECT @tmp0 = (SELECT CAST(@tmpf_im_sprxml AS NVARCHAR(MAX)))                                
SELECT @tmpf_im_spr = '<?xml version='+'"'+'1.0'+'"'+' encoding='+'"'+'windows-1251'+'"'+'?>'+@tmp0 

--���������� id
declare @myid varchar(255) 
SELECT @myid = CONVERT(CHAR(255), NEWID()) 

--���������� � �����
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

--���������� ������������ ����� ������������
select @userVcode = vcode from [Schema].[VBN_uzdo_sbis_user] where userName = user_name()

select @patchFull = '\\sbis_.ru\UZDO_SBIS_Connect\' 
					+ convert(varchar(255),@userVcode) 
					+ '\Exchange\������������\' 

select @SQL='BCP.exe "SELECT top (1) text FROM serv.tempdb..##t" queryout ' + @patchFull+@file + ' -c -C 1251 -S -T'

--select @SQL

exec dbo.bsp_cmdshell @SQL

/*
delete from nalog_schema.bn_sbis_int                                 
INSERT INTO nalog_schema.bn_sbis_int (stroka, name)                                
SELECT @tmpf_im_spr, @name                                

declare @puth varchar(2000)      
select @puth = '\\sbis_.ru\UZDO_SBIS_Connect\1\Exchange\������������\' 
--SBIS_Connect\1 - ������� �������� ��������
                    
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

declare @patchFull varchar(max) = '\\sbis_.ru\UZDO_SBIS_Connect\1\Exchange\������������\' 
, @file varchar(max) = '1.txt'
, @SQL varchar(max)

select @SQL='BCP.exe "SELECT top (1) vcode FROM serv.tempdb..##t" queryout ' + @patchFull+@file + ' -c -C 1251 -S -T'

select @SQL

exec dbo.bsp_cmdshell @SQL

*/