clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}output/final_sample.dta", clear
 
*------------------------------------------------------------------------------
* Subsample: 10 income groups 						    -- Update: 25.July.2022
* Idea: B10 Child penalty vs. T10 Child penalty -> Inequality in inequality 
*------------------------------------------------------------------------------

* Create income groups
global pctls = "10 50 90"
		
forvalues myear = 1998(1)2020 {

		* compute percentiles
		qui _pctile h_inc_total if year == `myear', p($pctls)

		local P10 = `r(r1)'
		local P50 = `r(r2)'
		local P90 = `r(r3)'
		
		qui gen incgroup_`myear' = .
		
		replace incgroup_`myear' = 1 if h_inc_total <= `P10' & year == `myear' 
		replace incgroup_`myear' = 2 if h_inc_total > `P10' & h_inc_total <= `P50' & year == `myear'   
		replace incgroup_`myear' = 3 if h_inc_total > `P50' & h_inc_total <= `P90' & year == `myear' 
		replace incgroup_`myear' = 4 if h_inc_total > `P90' & year == `myear'  
	} 


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
keep if diff == 1

* Check the number of remaining observations 
sum num_pid // obs 2,270

* by p_sex, sort: sum p_age birthyr_1c lfp emp earning wage_rate p_hours unigrad

* Average by five income groups
collapse lfp emp earning wage_rate p_hours unigrad, by (p_sex incgroup_2005)
	
	
	
	

	
/*
forvalues i = 2000(5)2015 {
	
	xtile income_quint`i' = h_income_to`cyear' if income`cyear' < ., nq(5)

	}	
	
	
	forvalues yi = 1(1)`nyears'  { 

	local cyear = word("`yearlist'",`yi')
	//display "`cyear'"
	xtile income_quint`cyear' = income`cyear' if income`cyear' < . , nq(5)
	
	if( inlist(`cyear',1983,1988,1993,1998,2000,2002,2004,2006,2008,2010,2012)) {
		xtile wealth_quint`cyear' = wealth`cyear' if wealth`cyear' < . , nq(5) 
		} // cyear

	} // yi
