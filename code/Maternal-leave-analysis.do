clear
set more off
set trace off
global hp = "C:/Users"

use "${hp}output/women_sample_0509.dta", clear
 
*------------------------------------------------------------------------------
* Beyond access, Actual usage of maternal leave 	     
*------------------------------------------------------------------------------
rename p4109 ml_work // 1: work provides maternal leave 2: no provision 
rename p4110 ml_employee // 1: survey respondent can use maternal leave 2: can't use 
rename p4163 ml_day // the number of days used for maternal leave

* Identify working women 1 year before childbirth 
bysort pid: gen workbfchild = (emp == 1 & eventtime == -1) // Identify workbfchild moms
bysort pid: egen empbfchild = max(workbfchild) // Mark workbfchild moms over all eventtime 
drop workbfchild 

* Total days of maternal leave for 3 years around the childbirth
bysort pid: gen ml_sumday = sum(ml_day) if inrange(eventtime,-1,1) & empbfchild==1
bysort pid: egen ml_totalday = max(ml_sumday)
drop ml_sumday

/* Create group indicator
G1. No use: No maternal leave
G2. Insufficinet use: Take less days than the mandatory number of days
G3. Sufficient use: Take the mandatory days 
*/
gen ml_use = . 
replace ml_use = 1 if ml_totalday == 0
replace ml_use = 2 if ml_totalday > 0 & ml_totalday < 90
replace ml_use = 3 if ml_totalday >= 90 & ml_totalday <.

* Count the number of distinct individuals by group 
egen tag = tag(pid ml_totalday)
egen distinct = total(tag), by(ml_totalday)
tabdisp ml_totalday, c(distinct) // nouse: 313, insufficientuse: 21, sufficientuse: 116
drop tag distinct

* Save data by maternal leave group
forvalues i = 1/3 {
	preserve
	keep if ml_use == `i'
	save "${hp}output/women_ml_`i'.dta", replace
	restore 
}


/* Create an indicator
1. No access & No use: NANU
2. Yes access & Yes use: YAYU
3. Yes access & No use: YANU
*/

gen mld_group = .  
replace mld_group = 1 if inrange(eventtime,-1,0) & ml_work == 2 & empbfchild==1 // NANU
replace mld_group = 2 if inrange(eventtime,-1,0) & ml_work == 1 & ml_employee == 1 & empbfchild==1 // YAYU
replace mld_group = 3 if inrange(eventtime,-1,0)  & ml_work == 1 & ml_employee == 1 & ml_day == 0 & empbfchild==1 // YANU 
replace mld_group = 3 if  inrange(eventtime,-1,0) & ml_work == 1 & ml_employee == 2 & empbfchild==1 // YANU 
bysort pid: egen mld_use = max(mld_group) // Mark mom's groups over all eventtime 
drop mld_group

* Count the number of distinct individuals by group 
egen tag = tag(pid mld_use)
egen distinct = total(tag), by(mld_use)
tabdisp mld_use, c(distinct) // 1-No use: 106, 2-Yes use: 135, 3-Yes but I couldn't: 140
drop tag distinct

* Save data by maternal leave group
forvalues i = 1/3 {
	preserve
	keep if mld_use == `i'
	save "${hp}output/women_mld_`i'.dta", replace
	restore 
}


