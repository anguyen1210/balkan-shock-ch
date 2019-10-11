* ===================================
* Balkan refugee supply shocks and Swiss unemployment, 2/2
* ===================================

* Author: Anthony Nguyen
* Email: anthony.nguyen@unine.ch

/*
Data: extract taken from IPUMS International
Url: https://international.ipums.org/international/ */

/* Description: this script generates descriptive and summary statistics
related to the impact of the Balkan immigration shock on Swiss unemployment/employment
rates during the period between 1990 to 2000.*/

* UNINE, Applied Econometrics, Assignment 2

clear

set more off

log using anguyen1210_balkan_shock_summary.log, replace

* ===================================
* Summaries by canton
* ===================================

use balkan_shock_ch

collapse (sum) native balkan total native_e native_ue native_nonlf , by(year canton)

sort canton year

xtset canton year

* Create dummy for labor force natives
gen native_lf = native_e + native_ue

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

* Balkan shock
gen shock_abs = balkan-L.balkan
gen shock_rel = shock_abs/(total-shock_abs) // this is the main regressor of interest

label var shock_abs "Number of balkan refugees entering cell"
label var shock_rel "Balkan immigration shock, relative size"

* Balkan shock as a percentage
gen pct_shock = shock_rel*100

* Convert delta unemployment/employment to percentage
gen pct_delta_ue = delta_ue*100

gen pct_delta_e = delta_e*100

* Drop all irrelevant variables, save to final table.

drop if year == 0

keep canton native balkan pct_shock pct_delta_ue pct_delta_e

gsort -native

save "shock_canton.dta"


* ===================================
* Summaries by educational attainment level
* ===================================

clear all

use balkan_shock_ch

collapse (sum) native balkan total native_e native_ue native_nonlf , by(year edattain)

sort edattain year

xtset edattain year

* Create dummy for labor force natives
gen native_lf = native_e + native_ue

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

* Balkan shock
gen shock_abs = balkan-L.balkan
gen shock_rel = shock_abs/(total-shock_abs) // this is the main regressor of interest

label var shock_abs "Number of balkan refugees entering cell"
label var shock_rel "Balkan immigration shock, relative size"

* Balkan shock as a percentage
gen pct_shock = shock_rel*100

* Convert delta unemployment/employment to percentage
gen pct_delta_ue = delta_ue*100

gen pct_delta_e = delta_e*100

* Drop all irrelevant variables, save to final table.

drop if year == 0

keep edattain native balkan pct_shock pct_delta_ue pct_delta_e

save "shock_edattain.dta"


* ===================================
* Educational attainment distribution by native/balkan
* ===================================

clear all

use balkan_shock_ch

collapse (sum) native balkan total native_e native_ue native_nonlf , by(year edattain)

sort edattain year

xtset edattain year

* Create dummy for labor force natives
gen native_lf = native_e + native_ue

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

* Balkan shock
gen shock_abs = balkan-L.balkan
gen shock_rel = shock_abs/(total-shock_abs) // this is the main regressor of interest

label var shock_abs "Number of balkan refugees entering cell"
label var shock_rel "Balkan immigration shock, relative size"

* Keep relevant variables for analysis

drop if year==0

keep edattain native balkan total native_supp1 shock_abs

save "edattain_distribution.dta"

* Plot educational attainment distributions for natives and balkan refugees

graph bar native_supp1, over(edattain)

graph bar shock_abs, over(edattain)
