********************************************************************************
*
* Complete File for Analysis
*
********************************************************************************
local  datestamp 070119
use "Q:\DOC\FI\FAS\FAST\Data\FAS_base", clear
replace		countrycode = 487 if economy == "West Bank and Gaza"				// double-check
replace iso3 = "PSE" if iso3 == "WBG" // WB uses different iso3 code
tempfile A
save 	`A'
import 	excel "Q:\DOC\FI\FAS\FAST\Data\Income Classification.xlsx", sheet("Country - Metadata") firstrow clear
rename	Code iso3
replace iso3 = "UVK" if iso3 == "KSV" // WB uses different iso3 code
replace iso3 = "ROU" if iso3 == "ROM" // WB uses different iso3 code
replace iso3 = "COD" if iso3 == "ZAR" // WB uses different iso3 code
replace iso3 = "PSE" if iso3 == "WBG" // WB uses different iso3 code
replace iso3 = "TLS" if iso3 == "TMP" // WB uses different iso3 code
rename 	Region group_region
rename	IncomeGroup group_income2
gen		group_income = group_income2
replace	group_income = "High income" if group_income == "High income: OECD"
replace	group_income = "High income" if group_income == "High income: nonOECD"
keep	iso3 group_*
tempfile B
save	`B'

import excel "Q:\DOC\FI\FAS\FAST\Data\Denominators\Denominators-FAS 2018 Update July\FAS WDI Denominators 072018.xlsx", sheet("Land-WDI 072018") firstrow clear
rename (N-AA) YR#, addnumber(1)
keep E YR*
rename E iso3
reshape long YR, i(iso3) j(year)
replace year = year + 2003
rename YR denom_landarea
tempfile A1
save	`A1'

import excel "Q:\DOC\FI\FAS\FAST\Data\Denominators\Denominators-FAS 2018 Update July\FAS WDI Denominators 072018.xlsx", sheet("Adult Pop-WDI 072018") firstrow clear
rename (F-S) YR#, addnumber(1)
keep CountryCode YR*
rename CountryCode iso3
reshape long YR, i(iso3) j(year)
replace year = year + 2003
rename YR denom_adultpop
tempfile A2
save	`A2'

import excel "Q:\DOC\FI\FAS\FAST\Data\Denominators\Denominators-FAS 2018 Update July\FAS WDI Denominators 072018.xlsx", sheet("GDP-WDI 072018") firstrow clear
rename (N-AA) YR#, addnumber(1)
keep E YR*
rename E iso3
drop in 214/1048575
reshape long YR, i(iso3) j(year)
replace year = year + 2003
rename YR denom_gdp
tempfile A3
save	`A3'

use	`A1', clear
merge 1:1 iso3 year using `A2'
drop if _merge != 3																// please verify no FAS countries are dropped
drop _merge
merge 1:1 iso3 year using `A3'
drop if _merge != 3																// please verify no FAS countries are dropped
drop _merge

replace iso3 = "UVK" if iso3 == "KSV" // WB uses different iso3 code
replace iso3 = "ROU" if iso3 == "ROM" // WB uses different iso3 code
replace iso3 = "COD" if iso3 == "ZAR" // WB uses different iso3 code
replace iso3 = "PSE" if iso3 == "WBG" // WB uses different iso3 code
replace iso3 = "TLS" if iso3 == "TMP" // WB uses different iso3 code

tempfile C
save	`C'

clear *
import excel "Q:\DOC\FI\FAS\FAST\Data\GSMAMarchSTATA.xlsx", sheet("Tracker_stata") firstrow clear

rename	Country economy
rename	CountryISOCode iso3
rename	LaunchYear year

sort economy year
collapse (first) year_first=year iso3 Region (last) year_last=year (count) services=year, by(economy)

forvalues j=2004/2017 {
gen		gsma`j' = 0
replace gsma`j' = 1 if year_first <= `j'
}
tempfile D
save	`D'

use		"Q:\DOC\FI\FAS\FAST\Data\Clean\FAS_`datestamp'.dta", clear				// facilitates further merging
merge	m:1 iso3 using `A'
drop if _merge == 2
drop _merge
merge	m:1 iso3 using `B'
drop if _merge == 2
drop _merge
merge m:1 iso3 year using `C'
drop if _merge == 2
drop _merge
merge m:1 iso3 using `D'
drop if _merge == 2
drop _merge

saveold 			"Q:\DOC\FI\FAS\FAST\Data\Clean\Latest Complete File for Analysis\CompleteLatestFAS_`datestamp'.dta", replace version(11)
export excel using	"Q:\DOC\FI\FAS\FAST\Data\Clean\Latest Complete File for Analysis\CompleteLatestFAS_`datestamp'.xlsx", firstrow(varlabels) nolabel replace
