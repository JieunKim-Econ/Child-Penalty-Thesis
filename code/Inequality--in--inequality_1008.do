clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}output/final_sample.dta", clear
*------------------------------------------------------------------------------
* Sample for inequality in inequality					 -- Update: 10.AUG.2022
* Q1: Do the poor have higher child penalties than the rich? 
* Q2: Do the poor's penalties last longer than the rich? 
*------------------------------------------------------------------------------

/*
-- Task order
-- 1. Create five income groups
	-- a. Separate by gender before/after generating income groups?
-- 2. Calculate child penalties
*/

*---- Prepare variables for summary statistics ----*

* Earnings: self-reported avg. monthly wage
gen earning = p_wage if p_wage <. 
replace earning = 0 if p_econstat != 1  // 0 if a person is unemployed

* Labor force participation: indicator variable for job status 
* 1 if individuals have positive earnings
gen lfp = (earning > 0 & p_econstat == 1)
replace lfp = 0 if earning == 0

* Hourly wage rate = monthly earnings / monthly hours worked 
gen wage_rate = earning / (p_hours * 4.345) if lfp == 1 

* Education level
gen unigrad = (p_edu == 6)
gen college = (p_edu == 5) 
gen highschool = (p_edu == 3)
gen under_highschool =  (p_edu < 3)

* Employed
gen emp = (p_econstat == 1)

* Gender in string format
gen gender = "`gender'"
replace gender = "men" if p_sex == 1
replace gender = "women" if p_sex == 2

* Create five groups by level of household total income 
*-- Reason why we don't use the exisiting variable "h_incomeq": 
*-- since 1) we only look into "selected" parents 2) we need only 5 groups 
gen tinc = h_inc_total

global pctls = "20 40 60 80"

qui levelsof year, clean local(myears)

foreach dvar in tinc { 

		foreach myear of local myears {
		
		qui gen `dvar'group_`myear' = .
		
		* compute percentiles
		qui _pctile `dvar' if year == `myear' , p($pctls)

		local P20 = `r(r1)'
		local P40 = `r(r2)'
		local P60 = `r(r3)'
		local P80 = `r(r4)'
		
		qui replace `dvar'group_`myear' = 1 if `dvar' <= `P20' & `dvar' < . & year == `myear' 
		qui replace `dvar'group_`myear' = 2 if `dvar' > `P20' & `dvar' <= `P40' & `dvar' < . & year== `myear'   
		qui replace `dvar'group_`myear' = 3 if `dvar' > `P40' & `dvar' <= `P60' & `dvar' < . & year == `myear' 
		qui replace `dvar'group_`myear' = 4 if `dvar' > `P60' & `dvar' <= `P80' & `dvar' < . & year == `myear' 
		qui replace `dvar'group_`myear' = 5 if `dvar' > `P80' & `dvar' < . & year == `myear'  
	} 
}


preserve
keep if p_sex == 1
save "${hp}output/men_incgroup_sample.dta", replace
restore

preserve
keep if p_sex == 2
save "${hp}output/women_incgroup_sample.dta", replace
restore 

// collapse h_inc_total lfp emp earning wage_rate p_hours unigrad, by (p_sex tincgroup_2000)

save "${hp}output/total_incgroup_sample.dta", replace

use"${hp}output/total_incgroup_sample.dta", replace

* Divide the total sample by gender, income group, and year
global incgroup_years "1998 1999 2000(5)2020"

foreach g in 1 2 { 
	foreach i of numlist 1 5 { 
		foreach myear of numlist $incgroup_years { 
			
			preserve
		
			keep if p_sex == `g' & tincgroup_`myear' == `i'
			
			* Check the final number of unique pid
			egen num_id = group(pid) 
			sum num_id 
			
			keep pid
			
			if `g' == 1 {
			local gender = "men"
			}
			else if `g' == 2 {
			local gender = "women"
			}

			save "${hp}output/pid`myear'`gender'_incgroup`i'.dta", replace
			
			restore			
			
			} //gender g 
		} // incgroup i 
	} // myear 

* Merge with the original sample
foreach gender in men women {
	foreach i of numlist 1 5 {
		foreach myear of numlist $incgroup_years {
			
			
			use  "${hp}output/pid`myear'`gender'_incgroup`i'.dta", clear 
				
			merge 1:m pid using "${hp}output/`gender'_incgroup_sample.dta"
			keep if _merge == 3
			drop _merge
				
			* Check the final number of unique pid
			egen num_fpid = group(pid) 
			sum num_fpid 

			save "${hp}output/`myear'`gender'_incgroup`i'.dta", replace
			
			}
		}
	}


* Leave samples before the first childbirth 
keep if eventtime == -1

* Check the number of remaining observations 
sum num_pid // result: 2,035

* Average by five income groups
collapse h_inc_total lfp emp earning wage_rate p_hours unigrad, by (p_sex tincgroup_1999)

