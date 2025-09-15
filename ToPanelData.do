/*******************************************************************************
* Title:      ToPanelData
* Author:     Wu Zi-Jie
* Date:       2024-08-19
* Purpose:    This script imports and appends all .xlsx files from the '/data' 
* subdirectory and saves them as a single Stata dataset.
*******************************************************************************
*-------------------------------------------------------------------------------
* 准备工作：设置
*-------------------------------------------------------------------------------
* 假设您的原始数据名为 merged_data.dta
* use "path/to/your/merged_data.dta", clear

* 最佳实践：检查关键分组变量的缺失情况
misstable summarize ProvCode CityCode CountyCode year
* 如果存在缺失，后续collapse会忽略这些行，请务必注意

/*
       year |      Freq.     Percent        Cum.
------------+-----------------------------------
       1995 |          1        0.00        0.00
       1997 |          5        0.00        0.00
       1998 |          2        0.00        0.00
       1999 |          1        0.00        0.00
       2000 |          4        0.00        0.00
       2001 |        121        0.01        0.01
       2002 |        220        0.02        0.04
       2003 |        296        0.03        0.06
       2004 |        373        0.04        0.10
       2005 |        468        0.05        0.15
       2006 |        317        0.03        0.18
       2007 |      1,035        0.10        0.28
       2008 |      1,496        0.15        0.43
       2009 |      1,463        0.14        0.57
       2010 |      2,934        0.29        0.86
       2011 |      4,779        0.47        1.34
       2012 |     12,415        1.23        2.57
       2013 |     41,761        4.13        6.70
       2014 |    171,904       17.01       23.71
       2015 |    176,874       17.50       41.21
       2016 |    178,797       17.69       58.90
       2017 |    182,342       18.04       76.94
       2018 |    128,635       12.73       89.66
       2019 |    104,465       10.34      100.00
       2104 |          2        0.00      100.00
       2106 |          1        0.00      100.00
       2107 |          1        0.00      100.00
------------+-----------------------------------
      Total |  1,010,712      100.00
*/

// 首先，仅保留2013-2019年的数据（裁判文书在2013年才正式强制性公开，此前的数据很可能不准确）
*/

keep if year > 2012 & <= 2019

encode(region_dt_code), gen(CountyCode)
encode(region_ct_code), gen(CityCode)
encode(region_pr_code), gen(ProvCode)





*-------------------------------------------------------------------------------
* 一：构建【区县-年份】面板 (District-Year Panel)
*-------------------------------------------------------------------------------
di "正在构建区县级面板数据..."

* 使用 collapse 命令进行汇总
* (sum) 用于计算各类案件的总数（计数变量求和）
* (mean) 用于计算审理周期的平均天数（连续变量求均值）
* by() 指定了面板的单位：每个区县(CountyCode)每一年(year)

collapse ///
    (sum) total_cases = caseNum ///
    (sum) total_defendants = defandant_num ///
    (sum) total_victims = victim_num ///
    (sum) total_unemployed = Unemploy ///
    (sum) PropertyCrime ViolenceCrime felony TroubleProvokingCrime ///
    (sum) IntentionalInjuryCrime LiangQiangYiDao ///
    (sum) total_co_offending_cases = is_co_offending ///
    (mean) avg_interval_days = interval_days ///
    (mean) avg_interval_days_w99 = interval_days_w ///
    (mean) avg_victims_per_case = victim_num ///
    (mean) avg_defendants_per_case = defandant_num ///
    (mean) avg_unemployed_per_case = Unemploy, ///
    by(ProvCode CityCode CountyCode year region_pr_name region_ct_name region_dt_name)

* --- 后续处理 ---
* 重命名变量以便理解
rename caseNum total_cases
rename defandant_num total_defendants
rename victim_num total_victims
rename Unemploy total_unemployed
rename interval_days avg_interval_days
rename interval_days_w avg_interval_days_w99

* 为面板数据设置ID和时间
* CountyCode 本身就可以作为面板ID，因为它在全国是唯一的
xtset CountyCode year

* 保存区县级面板数据
compress
label data "District-Year Crime Panel"
save "panel_district_year.dta", replace
di "成功！区县级面板数据已保存为 panel_district_year.dta"


*-------------------------------------------------------------------------------
* 二：构建【城市-年份】面板 (City-Year Panel)
*-------------------------------------------------------------------------------
di "正在构建城市级面板数据..."

* 重新加载原始数据
use "merged_data.dta", clear

* 这次，我们按城市(CityCode)和年份(year)进行汇总
* --- 这是修正后的版本 ---

collapse ///
    (sum) total_cases = caseNum ///
    (sum) total_defendants = defandant_num ///
    (sum) total_victims = victim_num ///
    (sum) total_unemployed = Unemploy ///
    (sum) PropertyCrime ViolenceCrime felony TroubleProvokingCrime ///
    (sum) IntentionalInjuryCrime LiangQiangYiDao ///
    (sum) total_co_offending_cases = is_co_offending ///
    (mean) avg_interval_days = interval_days ///
    (mean) avg_interval_days_w99 = interval_days_w ///
    (mean) avg_victims_per_case = victim_num ///
    (mean) avg_defendants_per_case = defandant_num ///
    (mean) avg_unemployed_per_case = Unemploy, ///
    by(ProvCode CityCode year region_pr_name region_ct_name)

* 设置面板
xtset CityCode year

* 保存城市级面板数据
compress
label data "City-Year Crime Panel"
save "panel_city_year.dta", replace
di "成功！城市级面板数据已保存为 panel_city_year.dta"


*-------------------------------------------------------------------------------
* 三：构建【省份-年份】面板 (Province-Year Panel)
*-------------------------------------------------------------------------------
di "正在构建省级面板数据..."

* 再次重新加载原始数据
use "merged_data.dta", clear

* 按省份(ProvCode)和年份(year)进行汇总
* --- 这是修正后的版本 ---

collapse ///
    (sum) total_cases = caseNum ///
    (sum) total_defendants = defandant_num ///
    (sum) total_victims = victim_num ///
    (sum) total_unemployed = Unemploy ///
    (sum) PropertyCrime ViolenceCrime felony TroubleProvokingCrime ///
    (sum) IntentionalInjuryCrime LiangQiangYiDao ///
    (sum) total_co_offending_cases = is_co_offending ///
    (mean) avg_interval_days = interval_days ///
    (mean) avg_interval_days_w99 = interval_days_w ///
    (mean) avg_victims_per_case = victim_num ///
    (mean) avg_defendants_per_case = defandant_num ///
    (mean) avg_unemployed_per_case = Unemploy, ///
    by(ProvCode year region_pr_name)

* 设置面板
xtset ProvCode year

* 保存省级面板数据
compress
label data "Province-Year Crime Panel"
save "panel_province_year.dta", replace
di "成功！省级面板数据已保存为 panel_province_year.dta"
