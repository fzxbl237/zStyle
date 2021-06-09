**Remove work lib;
proc datasets lib=work kill  nolist; quit;

option nomprint nomlogic nosymbolgen;
***clean log and output;
dm 'log' clear;
dm 'output' clear;

%let pgmname=T14_1_1;

***Create log file****;
proc printto  new
    log="&root.\Production\tables\log\&pgmname..log";
run;

/*=============================================================================
                            Project Information
-------------------------------------------------------------------------------
Customer Name          : Ji Xing Pharmaceuticals (Shanghai) Co., Ltd.
Protocol Number        : JX01001
Project Code           : ZZA13331
Study Drug             : CK-3773274
Project Root Path      : \\ieedc-vnasc01\BIOSdata\KUNTUO\CK-3773274\ZZA13331\Biostatistics
-------------------------------------------------------------------------------
                          Program Information
-------------------------------------------------------------------------------
Program                : \Production\Derived\SDTM\d_0dm
Brief Description      : Demographics
Copied From            :
Raw Data Sets Used     : \Data\CDM_Data\SUB
                         \Data\CDM_Data\DM
                         \Data\CDM_Data\DS_IC
                         \Data\CDM_Data\DS_RAND
                         \Data\CDM_Data\IE
Derived Data Sets Used : \Data\SDTM\DM
                         \Data\SDTM\IS
Data Set Created       : \Data\SDTM\DM
                         \Data\SDTM\SUPPDM
Output Files           : \Ouput\Production_out\T14_1_1.rtf
Notes / Assumptions    : ...
-------------------------------------------------------------------------------
                    Programmer Information
-------------------------------------------------------------------------------
Author                 : zhi.xu
Creation Date          : 2021-06-04
-------------------------------------------------------------------------------
                    Environment Information
-------------------------------------------------------------------------------
SAS Version            : 7.1
Operating System       : Windows
-------------------------------------------------------------------------------
                    Change Control Information
-------------------------------------------------------------------------------
Modifications:
Programmer/Date:     		Reason:
----------------     		--------------------------------------------------
... /ddMMMyyyy

==============================================================================*/

/*Include or List all Macros Used in this Program Here*/
/* %INC ... OR list...*/

options validvarname=upcase;

**合并adam.adsl和adam.adae数据集;
proc sql;
    create table conbDs as
        select
            a.subjid,
            a.trtpn,
            a.sexn,
            b.*,
            case
                when ^missing(b.subjid) then "Y"
            end as anlfl
        from adam.adsl(where=(saffl='是')) a
            left join adam.adae(where=(saffl='是' and trtemfl='Y') rename=(subjid=subjid_  trtpn=trtpn_  sexn=sexn_)) b
                on a.subjid=b.subjid_;
quit;

**为”trtpn“变量进行pool衍生;
data adae1;
    set conbDs;
    output;
    if ^missing(trtpn) then do;
          if trtpn in (3 6) then do;
                trtpn =98;
                output;
          end;
          if trtpn in (1 2 3 4 5 6) then do;
                trtpn =99;
                output;
          end;
    end;
run;

**为”sexn“变量进行pool衍生;
data adae2;
    set adae1;
    output;
    if ^missing(sexn) then do;
          if sexn in (1 2) then do;
                sexn =99;
                output;
          end;
    end;
run;

**用于得到分母信息的数据集;
proc sql;
    create table denom as
        select
            distinct subjid,
            trtpn,
            sexn
        from adae2;
quit;

**用于分析的数据集;
data adae3;
    set adae2;
    where anlfl="Y";
run;

**无数据标记;
%let nodataMsg=&sysnobs.;

**创建用于预加载的format;
proc format;
   value arm
       1 ='组1'
       2 ='组2'
       4 ='组4'
       5 ='组5'
       98 ='安慰剂组合计'
       99 ='合计';
   value sex
       1 ='男'
       2 ='女'
       99 ='性别合计';
run;

**设置观测ID和任何事件信息
data adae4;
    set adae3;
    eventID=_n_;
    anyEvent="任何TEAE";
run;

proc sort data=adae4;
    by _all_;
run;

proc transpose data=adae4 out=outRes1 name=cat;
    by _all_;
    var anyEvent aesoc aedecod;
run;

**处理变量"aetoxgrn"的信息;
data outRes2;
    set outRes1(in=ina) outRes1(in=inb) outRes1(in=inc);
    if ina then do;
        across=0;call missing(aetoxgrn);
    end;
    else if inb then across=1;
    else if inc then across=2;
run;

**赋空无用的观测值;
data outRes3(drop= i j);
    set outRes2;
    prior=2;
    array varlist anyEvent aesoc aedecod;
    do i=1 to dim(varlist);
        if upcase(cat)=upcase(vname(varlist{i})) then do;
        prior=i;
        if missing(varlist{i}) then do;
           if upcase(cat)="AESOC" then do;
                varlist{i}="SocUncode";
                prior=3;
            end;
           else if upcase(cat)="AEDECOD" then do;
                varlist{i}="PtUncode";
                prior=3;
            end;
        end;
        if i<dim(varlist) then do;
            do j=i+1 to dim(varlist);
                call missing(varlist{j});
            end;
        end;
    end;
run;

/**
    across=0->不考虑变量"aetoxgrn"的数据
    across=1->考虑变量"aetoxgrn"，同时考虑该变量取MAX或者MIN处理后的数据
    across=2->考虑变量"aetoxgrn"，但不考虑该变量取MAX或者MIN处理后的数据
*/
proc sql;
    create table outRes4 as
        select
            *
        from outRes3
        group by
            aesoc,aedecod,trtpn,sexn,
            case
                when across=2 then subjid
            end
        having
            case
                when across=2 then aetoxgrn=max(aetoxgrn)
                else 1=1
            end;
quit;

**获得各分组，各水平下的例数和事件数;
proc sql;
    create table outRes5 as
        select
            distinct
            trtpn,
            sexn,
            anyEvent,
            aesoc,
            aedecod,
            across,
            aetoxgrn,
            prior,
            cat,
            case upcase(cat)
                when "ANYEVENT" then 0
                    when "AESOC" then 1
                    when "AEDECOD" then 2
            end as catn,
            case upcase(cat)
                when "ANYEVENT" then 0
                when "AESOC" then 1
                when "AEDECOD" then 2
            end as indent,
            col1,
            count(distinct subjid) as popNum,
            count(distinct enentId) as eventNum
        from outRes4
        group by
            aesoc,aedecod,trtpn,sexn,aetoxgrn,across;
quit;

**转置后筛选需要的受试者例数和事件数;
proc sort data=outRes5;
    by _all_:
run;

proc transpose data=outRes5 out=outRes6 name=numCat;
    by _all_;
    var popNum eventNum;
run;

data outRes7;
    set outRes6;
    where across=0
        or (across=2 and numcat="POPNUM")
        or (across=1 and numcat="EVENTNUM");
    if across^=0 then across=1;
run;

**获取排序的映射表，为后续的排序控制做准备;
data _colMap;
    set outRes7;
    where across=0 and numcat="POPNUM";
    if trtpn in (99) and sexn in (99);
run;

proc sql;
    create table sortMap1 as
        select
            distinct
            l.anyEvent,
            l0.n as anyEventNum,
            l.aesoc,
            l1.n as aesocNum,
            l.aedecod,
            l2.n as aedecodNum
        from
            _colMap l
            left join (select * from _colMap where catn=2) l2
                on l.aesoc=l2.aesoc and l.aedecod=l2.aedecod
            left join (select * from _colMap where catn=1) l1
                on l.aesoc=l1.aesoc
            left join (select * from _colMap where catn=0) l0
                on l.anyEvent=l0.anyEvent;
quit;

**添加各水平下用于控制排序的seq变量;
data sortMap;
    set sortMap1;
    array varlist levelSeq_1 levelSeq_2;
    do over varlist;
        temp=input(scan(vname(varlist),-1,"_"),??best.);
        if catn=temp then varlist=1;
        else if catn>temp>. then varlist=2;
    end;
run;

**创建分组信息表;
proc tabulate data=denom
    out=grpMapper1(keep=trtpn sexn _table_ n);
    format trtpn arm. sexn sex.;
    class trtpn sexn/preloadfmt;
    tables trtpn*sexn*(n)/printmiss;
    tables trtpn*(n)/printmiss;
run;

**填补缺失的例数信息并筛选各水平下需要展示的分组;
data grpMapper2;
    set grpMapper1;
    where trtpn in (1 2 4 5 98 99)
            and sexn in (2 1 99);
    n=coalesce(n,0);
    array trtpnArray{6} _temporary_ (1 2 4 5 98 99);
    do i=1 to dim(trtpnArray);
        if trtpn=trtpnArray{i} then _grpSeq1=i;
    end;
    array sexnArray{3} _temporary_ (2 1 99);
    do i=1 to dim(sexnArray);
        if sexn=sexnArray{i} then _grpSeq2=i;
    end;
run;

proc sort data=grpMapper2;
    by _table_ _grpSeq: trtpn sexn;
run;

**为各水平下各分组设置宏变量储存例数;
data grpMapper;
    set grpMapper2;
    by _table_ _grpSeq: trtpn sexn;
    if first._table_ then seq=0;
         seq+1;
    if _table_=1 then call symput(cats("trt",seq),cats(n));
    else call symput(cats("level",2-_table_+1,"_",seq),cats(n));
run;

**为"aetoxgrn"变量设置Mapper信息表;
proc tabulate data=adae4
    out=acrossMapper(keep=aetoxgrn);
    format aetoxgrn toxgr.;
    class aetoxgrn/preloadfmt;
    tables aetoxgrn/printmiss;
run;

**合并分组和"aetoxgrn"变量Mapper表，得到总体Mapper表;
proc sql;
    create table colMapPart1 as
        select
        distinct
        *,
        1 as across
    from grpMapper(where=(_table_=1)),acrossMapper
quit;

data colMap;
    set colMapPart1(in=ina) grpMapper(in=inb);
    if inb then across=0;
run;
