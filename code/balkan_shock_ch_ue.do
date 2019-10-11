* ===================================
* Balkan refugee supply shocks and Swiss unemployment, 1/2
* ===================================

* Author: Anthony Nguyen
* Email: anthony.nguyen@unine.ch

/*
Data: extract taken from IPUMS International
Url: https://international.ipums.org/international/ */

/* Description: this script calculates the change in UNEMPLOYMENT and EMPLOYMENT
for labor market skill cells defined by REGION (canton) and SKILL (education level
attained) in Switzerland from 1990 to 2000.*/

* UNINE, Applied Econometrics, Assignment 2

clear

set more off

use "C:\Users\anguy\OneDrive\documents\coursework\unine\applied-econometrics\assignments\assignment02_balkan_shock\data\ipumsi_ch_1990_2000.dta"

log using anguyen1210_balkan_shock.log, replace

* ===================================
* Drop irrelevant variables
* ===================================

* Drop source (non-harmonized) variables--redundant
drop ch1990a_bpl ch1990a_citiz ch1990a_nation ch1990a_res5yr ch2000a_bpl ch2000a_nation ch2000a_res5yr ch2000a_respermt ch2000a_citiz

* Drop irrelevant sample identifiers
drop sample serial hhwt

* Drop extra, un-used variables
drop age2 nativity citizen school educch eedattain occisco isco88a indgen classwk classwkd eclasswk hrswork1 hrswork2 hrsfull migrate5


* ===================================
* Narrow sample to prime age males in the labor force
* ===================================

/* To keep this analysis as simple as possible, the sample is restricted to
prime working age males (25-54). Furthermore, those in school or who are retired,
will also be removed as they are not considered part of the labor force.*/

* Keep only prime working age
keep if age >= 25 & age <=54

* Keep only males
keep if sex==1

* Drop students and retirees
drop if empstatd==330 | empstatd==344


* ===================================
* Calculate region-skill cell counts
* ===================================

/* For the analysis, we will be looking at the supply shocks of balkan
immigration to native labor markets defined by different region-skill cells and
how that affects the number of employed, not employed and not active.

For the Swiss case, regions will be based on cantons.

For labor market skills, in keeping with the literature, we will use educational
attainment (levels) as our main indicator.*/

* Create dummy for people from the Balkans
gen balkan = 0
replace balkan = 1 if nation==43140

* Create dummy for Native workers
gen native = 0
replace native = (balkan==0)

* Create dummy for employed natives
gen native_e = (empstat==1 & native==1)

* Create dummy for unemployed natives
gen native_ue = (empstat==2 & native==1)

* Create dummy for labor force natives
gen native_lf = native_e + native_ue

* Create dummy for non-labor force natives
gen native_nonlf = (empstat==3 & native==1)

* Rename `geo1_ch` to `canton`
rename geo1_ch canton

* Remove unknown value from educational attainment levels
drop if edattain==9

* Add sample weights
replace balkan = balkan*perwt
replace native = native*perwt

* Collapse into region-skill cells
preserve

collapse (rawsum) native balkan total=perwt native_e native_ue native_lf native_nonlf (count) n=native, by(year canton edattain)


* ===================================
* Define dependent/indpendent variables of interest
* ===================================

* Declare the data as panel data; use the lag and difference operators

* Define `cell` variable
egen cell= group(canton edattain)

sort cell year

* Recode `year` variable
recode year (1990=0) (2000=1)

* Define panel data
xtset cell year

* Create native unemployment rate variable
gen ue_rate = (native_ue/native_lf)

label var ue_rate "Unemployment rate, native workers"

* Create change in unemployment rate variable
gen delta_ue = (native_ue/native_lf) - (L.native_ue/L.native_lf)

label var delta_ue "Change in unemployment rate, native workers"

* Create change in employment rate variable
gen delta_e = (native_e/native) - (L.native_e/L.native)

label var delta_e "Change in employment rate, native workers"

* Native worker labor supply change variables
gen native_supp0 = L.total
gen native_supp1 = total-D.balkan
gen log_nativesupp = log(native_supp1/native_supp0)

label var native_supp0 "Supply of native workers, 1990"
label var native_supp1 "Supply of native workers, 2000"
label var log_nativesupp "%Change supply of native workers"

/* Balkan immigration shock--change in supply due to refugees.

As stated in Borjas and Monras (2007), "the measure of the supply shock should
give the percent by which immigrants increased the size of the workforce, with
the base being the number of native workers in the post-shock period." */
gen shock_abs = balkan-L.balkan
gen shock_rel = shock_abs/(total-shock_abs) // this is the main regressor of interest

label var shock_abs "Number of balkan refugees entering cell"
label var shock_rel "Balkan immigration shock, relative size"

* Define weights for each cell
gen weight = (n*L.n)/(n+L.n)

label var weight "cell weight"

* Save data table

save "balkan_shock_ch.dta"


* ===================================
* Run regressions, UNEMPLOYMENT
* ===================================

/*The main relationship is the change in unemployment in a particular cell with
the refugee supply shock in that same cell.

The `log native supply change` will be added as a control, along with fixed
effects for canton and education.*/

* OLS regression, no control, no fixed effects
quietly reg delta_ue shock_rel, r
quietly estimates store ols_ue1

* OLS regression, with native supply change, no fixed effects
quietly reg delta_ue shock_rel log_nativesupp, r
quietly estimates store ols_ue2

* OLS-LSDV, no control, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_ue shock_rel i.edattain i.canton, r
quietly estimates store lsdv_ue1

* OLS-LSDV, with native supply change, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_ue shock_rel log_nativesupp i.edattain i.canton, r
quietly estimates store lsdv_ue2

* AREG, no control, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_ue shock_rel i.canton, r a(edattain)
quietly estimates store areg_ue1

* AREG, with native supply change, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_ue shock_rel log_nativesupp i.canton, r a(edattain)
quietly estimates store areg_ue2

* Print estimates table
estimates table ols_ue1 ols_ue2 lsdv_ue1 lsdv_ue2 areg_ue1 areg_ue2, drop(_Ican* _Ied* _cons)star stats(N r2 r2_a)


* ===================================
* Run regressions, UNEMPLOYMENT, *cell weight applied
* ===================================

* regressions repeated from above; cell weights applied

* OLS regression, no control, no fixed effects
quietly reg delta_ue shock_rel [aweight=weight], r
quietly estimates store ols_ue3

* OLS regression, with native supply change, no fixed effects
quietly reg delta_ue shock_rel log_nativesupp [aweight=weight], r
quietly estimates store ols_ue4

* OLS-LSDV, no control, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_ue shock_rel i.edattain i.canton [aweight=weight], r
quietly estimates store lsdv_ue3

* OLS-LSDV, with native supply change, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_ue shock_rel log_nativesupp i.edattain i.canton [aweight=weight], r
quietly estimates store lsdv_ue4

* AREG, no control, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_ue shock_rel i.canton [aweight=weight], r a(edattain)
quietly estimates store areg_ue3

* AREG, with native supply change, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_ue shock_rel log_nativesupp i.canton [aweight=weight], r a(edattain)
quietly estimates store areg_ue4

* Print estimates table
estimates table ols_ue3 ols_ue4 lsdv_ue3 lsdv_ue4 areg_ue3 areg_ue, drop(_Ican* _Ied* _cons)star stats(N r2 r2_a)


* ===================================
* Run regressions, EMPLOYMENT
* ===================================

/*The main relationship is the change in EMPLOYMENT in a particular cell with
the refugee supply shock in that same cell.

The `log native supply change` will be added as a control, along with fixed
effects for canton and education.*/

* OLS regression, no control, no fixed effects
quietly reg delta_e shock_rel, r
quietly estimates store ols_e1

* OLS regression, with native supply change, no fixed effects
quietly reg delta_e shock_rel log_nativesupp, r
quietly estimates store ols_e2

* OLS-LSDV, no control, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_e shock_rel i.edattain i.canton, r
quietly estimates store lsdv_e1

* OLS-LSDV, with native supply change, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_e shock_rel log_nativesupp i.edattain i.canton, r
quietly estimates store lsdv_e2

* AREG, no control, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_e shock_rel i.canton, r a(edattain)
quietly estimates store areg_e1

* AREG, with native supply change, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_e shock_rel log_nativesupp i.canton, r a(edattain)
quietly estimates store areg_e2

* Print estimates table
estimates table ols_e1 ols_e2 lsdv_e1 lsdv_e2 areg_e1 areg_e2, drop(_Ican* _Ied* _cons)star stats(N r2 r2_a)


* ===================================
* Run regressions, EMPLOYMENT, *cell weight applied
* ===================================

* regressions repeated from above; cell weights applied

* OLS regression, no control, no fixed effects
quietly reg delta_e shock_rel [aweight=weight], r
quietly estimates store ols_e3

* OLS regression, with native supply change, no fixed effects
quietly reg delta_e shock_rel log_nativesupp [aweight=weight], r
quietly estimates store ols_e4

* OLS-LSDV, no control, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_e shock_rel i.edattain i.canton [aweight=weight], r
quietly estimates store lsdv_e3

* OLS-LSDV, with native supply change, with EDUCATION and CANTON fixed effects
quietly xi: reg delta_e shock_rel log_nativesupp i.edattain i.canton [aweight=weight], r
quietly estimates store lsdv_e4

* AREG, no control, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_e shock_rel i.canton [aweight=weight], r a(edattain)
quietly estimates store areg_e3

* AREG, with native supply change, canton dummies + absorb(EDUCATION)
quietly xi: reg delta_e shock_rel log_nativesupp i.canton [aweight=weight], r a(edattain)
quietly estimates store areg_e4

* Print estimates table
estimates table ols_e3 ols_e4 lsdv_e3 lsdv_e4 areg_e3 areg_e4, drop(_Ican* _Ied* _cons)star stats(N r2 r2_a)


* ===================================
* Generate tables for print
* ===================================

* All UNEMPLOYMENT regressions in one table
outreg2 [ols_ue1] using "tables/balkanshock_ch_ue.xls", nocons title(TABLE, Effect of Balkan immigration shock on Swiss unemployment rate) ctitle(OLS) tex(frag) label addtext(Control, No, Fixed effects, No, Cell weights, No) replace
outreg2 [ols_ue2] using "tables/balkanshock_ch_ue.xls", nocons append ctitle(OLS) tex(frag) label addtext(Control, Yes, Fixed effects, No, Cell weights, No)
outreg2 [ols_ue4] using "tables/balkanshock_ch_ue.xls", nocons append ctitle(OLS) tex(frag) label addtext(Control, Yes, Fixed effects, No, Cell weights, Yes)
outreg2 [lsdv_ue1] using "tables/balkanshock_ch_ue.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-LSDV) tex(frag) label addtext(Control, No, Fixed effects, Yes, Cell weights, No)
outreg2 [lsdv_ue2] using "tables/balkanshock_ch_ue.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-LSDV) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, No)
outreg2 [lsdv_ue4] using "tables/balkanshock_ch_ue.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-LSDV) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, Yes)
outreg2 [areg_ue1] using "tables/balkanshock_ch_ue.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-AREG) tex(frag) label addtext(Control, No, Fixed effects, Yes, Cell weights, No)
outreg2 [areg_ue2] using "tables/balkanshock_ch_ue.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-AREG) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, No)
outreg2 [areg_ue4] using "tables/balkanshock_ch_ue.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-AREG) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, Yes) see

* All EMPLOYMENT regressions in one table
outreg2 [ols_e1] using "tables/balkanshock_ch_e.xls", nocons title(TABLE, Effect of Balkan immigration shock on Swiss employment rate)ctitle(OLS) tex(frag) label addtext(Control, No, Fixed effects, No, Cell weights, No) replace
outreg2 [ols_e2] using "tables/balkanshock_ch_e.xls", nocons append ctitle(OLS) tex(frag) label addtext(Control, Yes, Fixed effects, No, Cell weights, No)
outreg2 [ols_e4] using "tables/balkanshock_ch_e.xls", nocons append ctitle(OLS) tex(frag) label addtext(Control, Yes, Fixed effects, No, Cell weights, Yes)
outreg2 [lsdv_e1] using "tables/balkanshock_ch_e.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-LSDV) tex(frag) label addtext(Control, No, Fixed effects, Yes, Cell weights, No)
outreg2 [lsdv_e2] using "tables/balkanshock_ch_e.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-LSDV) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, No)
outreg2 [lsdv_e4] using "tables/balkanshock_ch_e.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-LSDV) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, Yes)
outreg2 [areg_e1] using "tables/balkanshock_ch_e.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-AREG) tex(frag) label addtext(Control, No, Fixed effects, Yes, Cell weights, No)
outreg2 [areg_e2] using "tables/balkanshock_ch_e.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-AREG) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, No)
outreg2 [areg_e4] using "tables/balkanshock_ch_e.xls", nocons keep(shock_rel log_nativesupp) append ctitle(FE-AREG) tex(frag) label addtext(Control, Yes, Fixed effects, Yes, Cell weights, Yes) see


* ===================================
* Plots
* ===================================

* plot UNEMPLOYMENT rate by balkan shock
twoway (scatter delta_ue shock_rel if edattain ==1, mcolor(blue) msymbol(smsquare_hollow)) ///
      (scatter delta_ue shock_rel if edattain ==3, mcolor(red) msymbol(smcircle_hollow)) ///
      (scatter delta_ue shock_rel if edattain ==4, mcolor(green) msymbol(smtriangle_hollow)) ///
      || lfit delta_ue shock_rel

* plot EMPLOYMENT rate by balkan shock
twoway (scatter delta_e shock_rel if edattain ==1, mcolor(blue) msymbol(smsquare_hollow)) ///
      (scatter delta_e shock_rel if edattain ==3, mcolor(red) msymbol(smcircle_hollow)) ///
      (scatter delta_e shock_rel if edattain ==4, mcolor(green) msymbol(smtriangle_hollow)) ///
      || lfit delta_e shock_rel
