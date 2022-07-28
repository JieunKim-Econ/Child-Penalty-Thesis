clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}output/final_sample.dta", clear
 
*------------------------------------------------------------------------------
* Summary statistics at one year before first childbirth -- Update: 28.July.2022
*------------------------------------------------------------------------------
* Sample: Individuals trackable for 15 years (with 23rd wave KLIPS from 1998 to 2020)
*-------------------------------------------------------------------------------

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

preserve
keep if p_sex == 1
save "${hp}output/men_sample.dta", replace
restore

preserve
keep if p_sex == 2
save "${hp}output/women_sample.dta", replace
restore 

* Leave samples before the first childbirth 
keep if eventtime == -1

* Check the number of remaining observations 
sum num_pid // result: 2,035

by p_sex, sort: sum p_age birthyear_1c lfp emp earning wage_rate p_hours unigrad
// male: 1046, female: 989

* Average by five income groups
collapse h_inc_total lfp emp earning wage_rate p_hours unigrad, by (p_sex)

