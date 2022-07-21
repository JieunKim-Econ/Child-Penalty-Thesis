clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}HP/save_0407.dta", clear
 
*------------------------------------------------------------------------------
* KLIPS sample selection with household data	        -- Update: 21.July.2022
*------------------------------------------------------------------------------
gen newborn = .

* New family member from childbirth
// Condition 1. Addition year >= birth year (Addition due to birth before/at the survey year)
// Condition 2. Reason for addition = birth
replace newborn = 1 if h0441 - h0301 >= 0 & h0481 == 1
replace newborn = 1 if h0442 - h0302 >= 0 & h0482 == 1
replace newborn = 1 if h0443 - h0303 >= 0 & h0483 == 1
replace newborn = 1 if h0444 - h0304 >= 0 & h0484 == 1
replace newborn = 1 if h0445 - h0305 >= 0 & h0485 == 1
replace newborn = 1 if h0446 - h0306 >= 0 & h0486 == 1
replace newborn = 1 if h0447 - h0307 >= 0 & h0487 == 1
replace newborn = 1 if h0448 -  h0308 >= 0 & h0488 == 1
replace newborn = 1 if h0449 -  h0309 >= 0 & h0489 == 1
replace newborn = 1 if h0450 -  h0310 >= 0 & h0490 == 1
replace newborn = 1 if h0451 -  h0311 >= 0 & h0491 == 1
replace newborn = 1 if h0452 -  h0312 >= 0 & h0492 == 1
replace newborn = 1 if h0453 -  h0313 >= 0 & h0493 == 1
replace newborn = 1 if h0454 -  h0314 >= 0 & h0494 == 1
replace newborn = 1 if h0455 -  h0315 >= 0 & h0495 == 1

* Leave individuals only with new childbirth
keep if newborn == 1 

* Ensure that the newborn is the first child in household 
// Total number of kids = Number of kids under 6 yrs old
keep if h_kid == 1 & h_kidage06 == 1 

xtset pid year, yearly

* Generate the year of the first child birth
bysort pid: egen birthyr_1c = min(year)

save "${hp}output/parents_pid.dta", replace

* The first child birth year by individual 
collapse birthyr_1c, by(pid)

save "${hp}output/pid_final.dta", replace

sort pid
*** Step 1: Merge with original data ***
merge 1:m pid using "${hp}HP/save_0407.dta"
keep if _merge == 3
drop _merge

xtset pid year, yearly

* Leave individuals only with the first childbirth year btw 1999 and 2016
keep if birthyr_1c != .
keep if inrange(birthyr_1c, 1999, 2016)

* Make sure that the newborn is the first child in household 
// the later condition is for calculating the length of years before the first child birth
keep if (h_kid == 1 & h_kidage06 == 1) | (h_kid == 0 & h_kidage06 == 0)

** Step 2: Keep individuals only if observable for 6 years (1 year before birth and 4 yrs after birth)

* Difference between the survey year and the first childbirth year
gen diff = year - birthyr_1c

* After birth
bysort pid: egen afterbirth = max(diff)

* Before birth
bysort pid: egen beforebirth = min(diff)

* Leave individuals trackable over 6 years 
keep if afterbirth >= 4 & beforebirth <= -1  

* Drop the sample with the discrepency regarding the year of first childbirth
bysort pid: egen wsample = max(p9072)
drop if wsample != . 

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 839 individual 

save "${hp}output/final_sample.dta", replace

* Collect pid as the key variable for the merge with Covid dataset 
use "${hp}output/final_sample.dta", clear
collapse p_sex, by (pid)
save "${hp}output/sample_id.dta", replace

* Keep the ncessary variables for the merge with work history dataset
use "${hp}output/final_sample.dta", clear
keep pid p_sex p_married birthyr_1c wave year 
save "${hp}output/sample_to_merge.dta", replace

*------------------------------------------------------------------------------
* Merge the baseline dataset and the Covid survey   	 -- Update: 4.July.2022
*------------------------------------------------------------------------------
use "${hp}output/sample_id.dta", clear

merge 1:m pid using "${hp}ADTsurvey/klips23a.dta"
keep if _merge == 3
drop _merge

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 738 individuals 
save "${hp}output/sample_covid.dta", replace

*------------------------------------------------------------------------------
* Merge the baseline dataset and individual's work history  -- Update: 4.July.2022
*------------------------------------------------------------------------------
use "${hp}HH_PSN/klips23w_i.dta", clear
rename jobwave wave

merge m:1 pid wave using "${hp}output/sample_to_merge.dta"
drop if _merge == 1
drop _merge

sort pid wave

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 839 individuals
save "${hp}output/sample_emphistory.dta", replace
