clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}HP/save_0509.dta", clear
 
*------------------------------------------------------------------------------
* KLIPS sample selection with household data	        -- Update: 5.Sep.2022
*------------------------------------------------------------------------------
gen newborn = .

* New family member from childbirth
// Condition 1. Addition year >= birth year (Addition due to birth before/at the survey year)
// Condition 2. Reason for addition = birth
foreach i of numlist 1/9 {
	replace newborn = 1 if h044`i' - h030`i' >= 0 & h048`i' == 1
	}

foreach j of numlist 0/5 {
	replace newborn = 1 if h045`j' - h031`j' >= 0 & h049`j' == 1
	}

* Leave individuals only with new childbirth
keep if newborn == 1 

* Ensure that the newborn is the first child in household 
// Total number of kids = Number of kids under 6 yrs old
keep if h_kid <= 1 & h_kidage06 <= 1 

xtset pid year, yearly

* Generate the year of the first child birth
bysort pid: egen birthyear_1c = min(year)

* The first child birth year by individual 
collapse birthyear_1c, by(pid)

* Label birthyear_1c as the year of the first childbirth
label variable birthyear_1c "the year of the first childbirth" 

save "${hp}output/pid_birthyear_1c_0509.dta", replace

********************************************************************************
* Step 1: Merge with original data 
********************************************************************************
sort pid
merge 1:m pid using "${hp}HP/save_0509.dta"
keep if _merge == 3
drop _merge

xtset pid year, yearly

* Correct the discrepency of years of the first childbirth
replace birthyear_1c = p9072 if p9072 != . & p9072 != birthyear_1c // 354 changed
/* Double check 
bysort pid: gen birthyear_gap = (p9072 == birthyear_1c) if p9072 != . */

* Leave individuals with the year of first childbirth between 1999 and 2019
keep if inrange(birthyear_1c, 1999, 2019)

********************************************************************************
* Step 2: Keep individuals if observable for 15 years around the first childbirth
********************************************************************************

* Difference between the survey year and the first childbirth year
gen eventtime = year - birthyear_1c

drop if eventtime < -5
drop if eventtime > 10

* After birth
bysort pid: egen afterbirth = max(eventtime)

* Before birth
bysort pid: egen beforebirth = min(eventtime) 

* Leave individuals observable at least 1 year after the first childbirth 
keep if beforebirth <= -1 & afterbirth >= 1 

* Age restriction: Age 19-50 when having the first child
gen age2050_1c = .
replace age2050_1c = 1 if eventtime == 0 & inrange(p_age, 19, 50)
bysort pid: egen birthage_1c = max(age2050_1c) 
drop if birthage_1c != 1 // 1,522 deleted
drop age2050_1c 

* Keep individuals with at least 7 observations 
bysort pid : gen nobs = _N 
keep if nobs >= 7 //  1,395 deleted
drop nobs

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 2,370 obs
drop num_pid

save "${hp}output/final_sample_0509.dta", replace

* Collect pid as the key variable for merging with Covid dataset 
use "${hp}output/final_sample_0509.dta", clear
collapse p_sex, by (pid)
save "${hp}output/sample_id_0509.dta", replace

* Keep the ncessary variables for merging with work history dataset
use "${hp}output/final_sample_0509.dta", clear
keep pid p_sex p_married birthyear_1c wave year 
save "${hp}output/sample_to_merge_0509.dta", replace

*------------------------------------------------------------------------------
* Merge the baseline dataset and the Covid survey   	 
*------------------------------------------------------------------------------
use "${hp}output/sample_id_0509.dta", clear

merge 1:m pid using "${hp}ADTsurvey/klips23a.dta"
keep if _merge == 3
drop _merge

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 2,046 individuals 
save "${hp}output/sample_covid_0509.dta", replace

use "${hp}output/sample_covid_0509.dta", clear 

/*
*------------------------------------------------------------------------------
* Merge the baseline dataset and individual's work history  
*------------------------------------------------------------------------------
use "${hp}HH_PSN/klips23w_i.dta", clear
rename jobwave wave

merge m:1 pid wave using "${hp}output/sample_to_merge.dta"
drop if _merge == 1
drop _merge

sort pid wave

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 2,052 individuals
save "${hp}output/sample_emphistory.dta", replace
*/





