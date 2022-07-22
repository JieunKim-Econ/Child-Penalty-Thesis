clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}HP/save_0407.dta", clear
 
*------------------------------------------------------------------------------
* KLIPS sample selection with household data	        -- Update: 22.July.2022
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
bysort pid: egen birthyr_1c = min(year)

* The first child birth year by individual 
collapse birthyr_1c, by(pid)

* Specify the label of birthyr_1c as the year of the first childbirth
label variable birthyr_1c "the year of the first childbirth" 

save "${hp}output/pid_birthyr_1c.dta", replace

*** Step 1: Merge with original data ***
sort pid
merge 1:m pid using "${hp}HP/save_0407.dta"
keep if _merge == 3
drop _merge

xtset pid year, yearly

* Correct the discrepency of years of the first childbirth
replace birthyr_1c = p9072 if p9072 != . & p9072 != birthyr_1c // 354 changed
/* Double check 
bysort pid: gen birthyr_gap = (p9072 == birthyr_1c) if p9072 != . */
keep if inrange(birthyr_1c, 1999, 2016)

** Step 2: Keep individuals only if observable for 6 years (1 year before birth and 4 yrs after birth)

* Difference between the survey year and the first childbirth year
gen diff = year - birthyr_1c

* After birth
bysort pid: egen afterbirth = max(diff)

* Before birth
bysort pid: egen beforebirth = min(diff)

* Leave individuals trackable over 6 years 
keep if afterbirth >= 4 & beforebirth <= -1
	
* Keep individuals with at least six observations 
bysort pid : gen nobs = _N 
keep if nobs >= 6 // 50 deleted
* drop nobs

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 2363 obs

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
* Merge the baseline dataset and the Covid survey   	 
*------------------------------------------------------------------------------
use "${hp}output/sample_id.dta", clear

merge 1:m pid using "${hp}ADTsurvey/klips23a.dta"
keep if _merge == 3
drop _merge

* Check the final number of unique pid
egen num_pid = group(pid) 
sum num_pid // 2054 individuals 
save "${hp}output/sample_covid.dta", replace

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
sum num_pid // 2363 individuals
save "${hp}output/sample_emphistory.dta", replace
