**Remove work lib;
proc datasets lib=work kill  nolist; quit;

option nomprint nomlogic nosymbolgen;
***clean log and output;
dm 'log' clear;
dm 'output' clear;

%let pgmname=${fileName};

***Create log file****;
proc printto  new
    log="&root.\Production\tables\log\&pgmname..log";
run;

<#--引入Header模板-->
<#include "progHeader.ftl">

options validvarname=upcase;

<#if denomDs??>
**合并${denomDs.indsName}和${inds.indsName}数据集;
proc sql;
    create table conbDs as
        select
            a.${uniqueId},
            <#list colVars as colvar>
            <#if colvar.inDenomDs!=false>
            a.${colvar.var},
            </#if>
            </#list>
            b.*,
            case
                when ^missing(b.${uniqueId}) then "Y"
            end as anlfl
        from ${denomDs.indsName}(where=(${denomDs.indsCond})) a
            left join ${inds.indsName}(where=(${inds.indsCond}) rename=(${uniqueId}=${uniqueId}_<#rt>
            <#list colVars as colvar>
                <#if colvar.inDenomDs!=false>
                  <#lt>  ${colvar.var}=${colvar.var}_<#rt>
                </#if>
            </#list>
    <#lt>)) b
                on a.${uniqueId}=b.${uniqueId}_;
quit;
<#else>
data conbDs;
    set ${inds.indsName};
    where ${inds.indsCond};
 run;
</#if>
<#--定义temp变量作为临时数据集的前缀-->
<#list inds.indsName?split(".") as str>
    <#if !str_has_next>
        <#assign temp=str>
    </#if>
</#list>

<#assign sn=0>
<#if colVars??>
    <#list colVars as colVar >
        <#if colVar.pool??>
            <#assign sn=sn+1>
            <#lt>**为”${colVar.var}“变量进行pool衍生;
            <#lt>data ${temp}${sn};
            <#lt>    set <#if sn=1>conbDs<#else>${temp}${sn-1}</#if>;
            <#lt>    output;
            <#lt>    if ^missing(${colVar.var}) then do;
            <#list colVar.pool?keys as key><#lt>
                <#lt>          if ${colVar.var} in (${key}) then do;
                <#lt>                ${colVar.var} =${colVar.pool[key]};
                <#lt>                output;
                <#lt>          end;
            </#list><#lt>
            <#lt>    end;
            <#lt>run;

            <#t></#if>
    </#list><#lt>
</#if>
**用于得到分母信息的数据集;
proc sql;
    create table denom as
        select
            distinct ${uniqueId},
    <#list colVars as colvar>
        <#if colvar_has_next>
            ${colvar.var},
        <#else>
            ${colvar.var}
        </#if>
    </#list>
        from ${temp}${sn};
quit;

**用于分析的数据集;
<#assign sn=sn+1>
data ${temp}${sn};
    set ${temp}${sn-1};
    where anlfl="Y";
run;

**无数据标记;
%let nodataMsg=${"&"}sysnobs.;

**创建用于预加载的format;
<#if fmtMaps??>
    <#lt>proc format;
    <#list fmtMaps as fmt>
        <#if fmt.fmtType?upper_case="FORMAT">
            <#lt>   value ${fmt.fmtName}
            <#list fmt.fmtMap?keys as key><#lt>
                <#lt>       <#if fmt.fmtName?starts_with("$")>'${key}'<#else>${key}</#if> ='${fmt.fmtMap[key]}'<#if key_has_next=false>;</#if>
            <#lt></#list><#rt>
        <#elseif fmt.fmtType?upper_case="INFORMAT">
            <#lt>   invalue ${fmt.fmtName}
            <#list fmt.fmtMap?keys as key><#lt>
                <#lt>       '${key}'=<#if fmt.fmtName?starts_with("$")>'${fmt.fmtMap[key]}'<#else>${fmt.fmtMap[key]}</#if><#if key_has_next=false>;</#if>
            <#lt></#list><#rt>
        </#if>
    </#list>
    <#lt>run;
</#if>
<#assign sn=sn+1>

**设置观测ID<#if anyEvent.anyEvent!=false>和任何事件信息</#if>
data ${temp}${sn};
    set ${temp}${sn-1};
    eventID=_n_;
<#if anyEvent.anyEvent!=false>
    <#if anyEvent.anyEventLabel??>
        <#lt>    anyEvent="${anyEvent.anyEventLabel}";
    <#else><#lt>    anyEvent="任何TEAE";
    </#if><#lt>
</#if>
run;

proc sort data=${temp}${sn};
    by _all_;
run;

<#assign outsn=1>
proc transpose data=${temp}${sn} out=outRes${outsn} name=cat;
    by _all_;
    var<#rt>
    <#lt><#if anyEvent.anyEvent!=false> anyEvent</#if><#rt>
    <#lt><#list linVars as linvar><#lt>
        <#t> ${linvar.var}
    </#list>;<#lt>
run;

<#--如果acrossVar 存在则添加该信息-->
<#if acrossVar??>
<#assign outsn=outsn+1>
**处理变量"${acrossVar.var}"的信息;
data outRes${outsn};
    set outRes${outsn-1}(in=ina) <#if !acrossVar.limitOption?? || acrossVar.eventLimit=false>outRes${outsn-1}(in=inb)</#if> <#if acrossVar.limitOption??>outRes${outsn-1}(in=inc)</#if>;
    if ina then do;
        across=0;call missing(${acrossVar.var});
    end;
    <#if !acrossVar.limitOption?? || acrossVar.eventLimit=false>
    else if inb then across=1;
    </#if>
    <#if acrossVar.limitOption??>
    else if inc then across=2;
    </#if>
run;
</#if>

**赋空无用的观测值;
<#assign outsn=outsn+1>
data outRes${outsn}(drop= i j);
    set outRes${outsn-1};
    prior=2;
    array varlist<#rt>
    <#lt><#if anyEvent!=false> anyEvent</#if><#rt>
    <#lt><#list linVars as linvar><#lt>
        <#t> ${linvar.var}
    </#list>;<#lt>
    do i=1 to dim(varlist);
        if upcase(cat)=upcase(vname(varlist{i})) then do;
        prior=i;
        if missing(varlist{i}) then do;
        <#list linVars as linvar><#lt>
        <#if linvar_index=0>   if<#else>   else if</#if><#rt>
            <#lt> upcase(cat)="${linvar.var?upper_case}" then do;
                varlist{i}="<#if linvar.uncodeLabel??>${linvar.uncodeLabel}<#else>Uncode</#if>";
                prior=<#if linvar.uncodePrior??>${linvar.uncodePrior}<#else>3</#if>;
            end;
        </#list>
        end;
        if i${"<"}dim(varlist) then do;
            do j=i+1 to dim(varlist);
                call missing(varlist{j});
            end;
        end;
    end;
run;

<#if  acrossVar.limitOption??>
    <#assign outsn=outsn+1>
/**
    across=0->不考虑变量"${acrossVar.var}"的数据
    across=1->考虑变量"${acrossVar.var}"，同时考虑该变量取MAX或者MIN处理后的数据
    across=2->考虑变量"${acrossVar.var}"，但不考虑该变量取MAX或者MIN处理后的数据
*/
proc sql;
    create table outRes${outsn} as
        select
            *
        from outRes${outsn-1}
        group by
    <#list linVars as linvar>
        <#if linvar_index=0>
            ${linvar.var},<#rt>
        <#else>
            <#lt>${linvar.var},<#rt>
        </#if>
    </#list>
    <#list colVars as colvar>
        <#lt>${colvar.var},<#rt>
    </#list>

            case
                when across=2 then ${uniqueId}
            end
        having
            case
                when across=2 then ${acrossVar.var}=<#if acrossVar.limitOption?upper_case="MAX">max<#elseif acrossVar.limitOption?upper_case="MIN">min</#if>(${acrossVar.var})
                else 1=1
            end;
quit;
</#if>

**获得各分组，各水平下的例数和事件数;
<#assign outsn=outsn+1>
proc sql;
    create table outRes${outsn} as
        select
            distinct
            <#list colVars as colvar><#lt>
                <#lt>            ${colvar.var},
            </#list><#lt>
            <#lt><#if anyEvent.anyEvent!=false>            anyEvent,</#if>
            <#list linVars as linvar><#lt>
                <#lt>            ${linvar.var},
            </#list><#lt>
            <#if acrossVar??>
            across,
            ${acrossVar.var},
            </#if>
            prior,
            cat,
            case upcase(cat)
                when "ANYEVENT" then 0
                <#list linVars as linvar>
                    when "${linvar.var?upper_case}" then ${linvar_index+1}
                </#list>
            end as catn,
            case upcase(cat)
                when "ANYEVENT" then 0
                <#list linVars as linvar>
                when "${linvar.var?upper_case}" then <#if linvar.indent??>${linvar.indent}<#else>${linvar_index}</#if>
                </#list>
            end as indent,
            col1,
            count(distinct ${uniqueId}) as popNum,
            count(distinct enentId) as eventNum
        from outRes${outsn-1}
        group by
            <#list linVars as linvar>
                <#if linvar_index=0>
            ${linvar.var}<#rt>
                <#else>
                     <#lt>,${linvar.var}<#rt>
                </#if>
            </#list>
            <#list colVars as colvar>
                <#lt>,${colvar.var}<#rt>
            </#list>
            <#if acrossVar??>
                <#lt>,${acrossVar.var}<#rt>
                 <#lt>,across<#rt>
            </#if>
;
quit;

**转置后筛选需要的受试者例数和事件数;
proc sort data=outRes${outsn};
    by _all_:
run;

<#assign outsn=outsn+1>
proc transpose data=outRes${outsn-1} out=outRes${outsn} name=numCat;
    by _all_;
    var popNum eventNum;
run;

<#assign  outsn=outsn+1>
data outRes${outsn};
    set outRes${outsn-1};
    where across=0
    <#if acrossVar.var??>
        or (<#rt>
        <#if acrossVar.limitOption??>
            <#lt>across=2 <#rt>
        <#else>
            <#lt>across=3 <#rt>
        </#if>
        <#lt>and numcat="POPNUM")
        or (<#rt>
        <#if acrossVar.eventLimit= false>
            <#lt>across=1 <#rt>
        <#elseif acrossVar.limitOption??>
            <#lt>across=2 <#rt>
        <#else>
            <#lt>across=1 <#rt>
        </#if>
        <#lt>and numcat="EVENTNUM");
    </#if>
    if across^=0 then across=1;
run;

**获取排序的映射表，为后续的排序控制做准备;
data _colMap;
    set outRes${outsn};
    where across=0 and numcat="POPNUM";
    if<#rt>
    <#lt><#list 0..colVars?size-1 as i>
        <#lt><#if !i_has_next> and</#if> ${colVars[i].var} in (${sortList[i]})<#rt>
    <#lt></#list>;
run;

<#assign level=linVars?size>
proc sql;
    create table sortMap1 as
        select
            distinct
            <#if anyEvent!=false>
            l.anyEvent,
            l0.n as anyEventNum,
            </#if>
            <#list linVars as linvar>
            l.${linvar.var},
            l${linvar_index+1}.n as ${linvar.var}Num<#if linvar_has_next>,</#if>
            </#list>
        from
            _colMap l
            <#list linVars?reverse as linvar>
            left join (select * from _colMap where catn=${level-linvar_index}) l${level-linvar_index}
                on<#rt>
                <#list 0..level-linvar_index-1 as i>
                <#lt><#if i_index!=0> and</#if> l.${linVars[i].var}=l${level-linvar_index}.${linVars[i].var}<#rt>
                </#list>

        </#list>
        <#if anyEvent!=false>
            left join (select * from _colMap where catn=0) l0
                on l.anyEvent=l0.anyEvent<#rt>
        </#if>
;
quit;

**添加各水平下用于控制排序的seq变量;
data sortMap;
    set sortMap1;
    array varlist<#rt>
    <#if anyEvent="Y">
        <#lt> levelSeq_0<#rt>
    </#if>
    <#list linVars as linvar>
        <#lt> levelSeq_${linvar_index+1}<#rt>
    </#list>
    <#lt>;
    do over varlist;
        temp=input(scan(vname(varlist),-1,"_"),??best.);
        if catn=temp then varlist=1;
        else if catn>temp>. then varlist=2;
    end;
run;

**创建分组信息表;
<#assign grpsn=1>
proc tabulate data=denom
    out=grpMapper${grpsn}(keep=<#rt>
    <#list colVars as colvar>
        <#lt>${colvar.var} <#rt>
    </#list>
    <#if colVars?size gt 1>
        <#lt>_table_ <#rt>
    </#if>
        <#lt>n);
    format<#rt>
    <#list colVars as colvar>
        <#lt> ${colvar.var} ${colvar.fmt}.<#rt>
    </#list>
    <#lt>;
    class<#rt>
    <#list colVars as colvar>
        <#lt> ${colvar.var}<#rt>
    </#list>
    <#lt>/preloadfmt;
    <#list 0..(colVars?size-1) as i>
    tables <#rt>
        <#list 0..(colVars?size-i-1) as j>
            <#lt>${colVars[j].var}*<#rt>
        </#list>
        <#lt>(n)/printmiss;
    </#list>
run;

**填补缺失的例数信息并筛选<#if colVars?size gt 1>各水平下</#if>需要展示的分组;
<#assign grpsn=grpsn+1>
data grpMapper${grpsn};
    set grpMapper${grpsn-1};
    where <#rt>
    <#list colVars as colvar>
        <#if colvar_index=0>
            <#lt>${colvar.var} in (${colvar.show})
        <#elseif colvar_has_next>
            and ${colvar.var} in (${colvar.show})
        <#else>
            and ${colvar.var} in (${colvar.show});
        </#if>
    </#list><#lt>
    n=coalesce(n,0);
    <#list 0..(colVars?size-1) as i>
        <#if colVars[i].show??>
            <#lt>    array ${colVars[i].var}Array{${colVars[i].show?split(" ")?size}} _temporary_ (${colVars[i].show});
            <#lt>    do i=1 to dim(${colVars[i].var}Array);
            <#lt>        if ${colVars[i].var}=${colVars[i].var}Array{i} then _grpSeq${i+1}=i;
            <#lt>    end;
        <#else>
            <#lt>    _grpSeq${grpSeq}=${colVars[i+1].var};
        </#if>
    </#list>
run;

proc sort data=grpMapper${grpsn};
    by <#if colVars?size gt 1>_table_ </#if>_grpSeq:<#rt>
    <#list colVars as colvar>
        <#lt> ${colvar.var}<#rt>
    </#list>
<#lt>;
run;

**为<#if colVars?size gt 1>各水平下</#if>各分组设置宏变量储存例数;
data grpMapper;
    set grpMapper${grpsn};
    by <#if colVars?size gt 1>_table_ </#if>_grpSeq:<#rt>
    <#list colVars as colvar>
        <#lt> ${colvar.var}<#rt>
    </#list>
    <#lt>;
    <#if colVars?size gt 1>
    if first._table_ then seq=0;
         seq+1;
    if _table_=1 then call symput(cats("trt",seq),cats(n));
    else call symput(cats("level",${colVars?size}-_table_+1,"_",seq),cats(n));
    <#else>
    call symput(cats("trt",seq),cats(n));
    </#if>
run;

<#if acrossVar??>
**为"${acrossVar.var}"变量设置Mapper信息表;
proc tabulate data=${temp}${sn}
    out=acrossMapper(keep=${acrossVar.var});
    format ${acrossVar.var} ${acrossVar.fmt};
    class ${acrossVar.var}/preloadfmt;
    tables ${acrossVar.var}/printmiss;
run;

**合并分组和"${acrossVar.var}"变量Mapper表，得到总体Mapper表;
proc sql;
    create table colMapPart1 as
        select
        distinct
        *,
        1 as across
    from grpMapper<#if colVars?size gt 1>(where=(_table_=1))</#if>,acrossMapper
quit;

data colMap;
    set colMapPart1(in=ina) grpMapper(in=inb);
    if inb then across=0;
run;
<#else>
data colMap;
    set grpMapper;
run;
</#if>