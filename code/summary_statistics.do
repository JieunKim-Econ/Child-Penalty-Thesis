clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}output/final_sample.dta", clear
 
*------------------------------------------------------------------------------
* Summary statistics at one year before first childbirth -- Update: 22.July.2022
*------------------------------------------------------------------------------
* Sample: Individuals trackable from 1 year before and 4 years after their first childbirth
* i.e. first childbirth between 1999 and 2016 (since 23rd wave KLIPS from 1998 to 2020)
*-------------------------------------------------------------------------------

*---- Prepare variables for summary statistics ----*

* Earnings: self-reported avg. monthly wage
gen earning = p_wage if p_wage <. 
replace earning = 0 if p_econstat != 1  // 0 if a person without a job

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

* Leave samples before the first childbirth 
keep if diff == -1

* Check the number of remaining observations 
sum num_pid // result: 1964

by p_sex, sort: sum p_age birthyr_1c lfp emp earning wage_rate p_hours unigrad

* Average by five income groups
collapse h_inc_total lfp emp earning wage_rate p_hours unigrad, by (p_sex incgroup)
