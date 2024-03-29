clear
set more off
set trace off
global hp = "C:/Users/"

*------------------------------------------------------------------------------
* [Yes/No version] Maternal leave estimation		     
*------------------------------------------------------------------------------

* Resetting
gen gender = "`gender'"

foreach i of numlist 1(1)3 { // maternal leave group
	save "${hp}output/Eventstudy_mldleave`i'.dta", replace 
	}


* Getting the data by gender and maternal leave group
foreach gender in men women  {
	foreach j of numlist 1(1)3 { // maternal leave group
	
	use "${hp}output/`gender'_mld_`j'.dta", clear
	
	* Creating Event Time Dummies
	sort pid eventtime 
	char eventtime[omit] -1
	xi i.eventtime
	
	save "${hp}output/Mldleave_eventstudy`j'.dta", replace


********************************************************************************
* RUNNING LOOPS
********************************************************************************
	foreach var in earnings extensive intensive wagerate {
		display "    " 
		display "`gender' `var'"
		display "   " 
		
		use "${hp}output/Mldleave_eventstudy`j'.dta", clear
		
		if "`var'"=="earnings" {
			gen var = earning
		}
		
		if "`var'"=="extensive"{ // Labor participation rate 
			gen var = lfp
		}
		
		if "`var'"=="intensive"{ // Hours Worked
			gen var = p_hours 		
		}
		
		if "`var'"=="wagerate"{
			gen var = wage_rate 
		}

		* Running Regression
		reg var _Ieventtime* i.p_age i.year, r

		predict var_p, xb

		gen b  = .
		gen bL = .
		gen bH = .
		replace b  = 0                                         if eventtime == -1
		replace bL = 0                                         if eventtime == -1
		replace bH = 0                                         if eventtime == -1

		foreach i of numlist 1(1)16 {
			display "Eventtime " `i'-6
			if `i' ~= 5 {
				replace b  = _b[_Ieventtime_`i']                             if eventtime == `i'-6
				replace bL = _b[_Ieventtime_`i'] - 1.96*_se[_Ieventtime_`i'] if eventtime == `i'-6
				replace bH = _b[_Ieventtime_`i'] + 1.96*_se[_Ieventtime_`i'] if eventtime == `i'-6
			
			} // i ~= 5
		
		} // i
		
********************************************************************************
* Creating Counterfactual
********************************************************************************
		gen var_c  = var_p - b
		gen var_cL = var_p - bL
		gen var_cH = var_p - bH

********************************************************************************
* Collapsing Data and Calculating Relative Impact 
********************************************************************************
		keep eventtime var_* b bL bH
		sort eventtime
		collapse var* b bL bH, by(eventtime)

		gen variable = "`var'"
		gen gender   = "`gender'"

		append using "${hp}output/Eventstudy_mldleave`j'.dta"

		save "${hp}output/Eventstudy_mldleave`j'.dta", replace

		} // var
	} // gender
 } // j: maternal use group

********************************************************************************
* Figure: LOADING AND RESHAPING DATA
********************************************************************************
set more off 

foreach j in 1 2 3 { // maternal leave group
	foreach var in earnings extensive intensive wagerate {

	display "    " 
	display "`var'"
	display "   " 

	use "${hp}output/Eventstudy_mldleave`j'", clear

	keep if variable == "`var'"

		gen gap    = (var_p - var_c) /var_c
		gen boundL = (var_p - var_cL)/var_c // JE: Low
		gen boundH = (var_p - var_cH)/var_c // JE: High 

	keep b var_c gap boundL boundH variable eventtime gender

	reshape wide b var_c gap boundL boundH, i(variable eventtime) j(gender, string)

	if "`var'"=="earnings"{
		global label Earnings
		global ylabel Earnings
		global axis1 xlabel(-5(1)10, nogrid) ylabel(-1.00(0.20)1) xline(-.5) ttext(0.20 1.15 "First Child Birth") ttext(-0.47 7 "Long-Run Child Penalty
	}
	if "`var'"=="extensive"{
		global label Participation Rate
		global ylabel Participation Rate
		global axis1 xlabel(-5(1)10, nogrid) ylabel(-1.00(0.20)1) xline(-.5) ttext(0.20 1.15 "First Child Birth") ttext(-0.47 7 "Long-Run Child Penalty
	}
	if "`var'"=="intensive"{
		global label Hours Worked
		global ylabel Hours Worked
		global axis1 xlabel(-5(1)10, nogrid) ylabel(-1.00(0.20)1) xline(-.5) ttext(0.20 1.15 "First Child Birth") ttext(-0.47 7 "Long-Run Child Penalty
	}
	if "`var'"=="wagerate"{
		global label Wage Rate
		global ylabel Wage Rate
		global axis1 xlabel(-5(1)10, nogrid) ylabel(-1.00(0.20)1) xline(-.5) ttext(0.20 1.15 "First Child Birth") ttext(-0.47 7 "Long-Run Child Penalty
	}

********************************************************************************
* Calculating Penalty
********************************************************************************

	gen penal  = (bmen  - bwomen)/var_cwomen
	
	quietly sum penal if eventtime == 10
	local m1 = r(mean)
	gen penalty = `m1'
	
	if "`var'"=="earnings" | "`var'"=="extensive"  | "`var'"=="intensive"  | "`var'"=="wagerate" { 
	format penalty %9.3fc
	}
	
	tostring penalty, replace force usedisplayformat
	global penalty = penalty

	twoway (rarea boundLmen   boundHmen   eventtime, color(gs14) lcolor(gs12) lwidth(vvthin))        ///
		   (rarea boundLwomen boundHwomen eventtime, color(gs14) lcolor(gs12) lwidth(vvthin))        ///
		   (connected gapmen   eventtime, lcolor(gs8) mcolor(gs8))      			    			 ///
		   (connected gapwomen eventtime, lcolor(black) mcolor(black)), 			    			 ///
	graphregion(color(white)) xtitle("Event Time (Years)") ytitle("$ylabel Relative to Event Time -1")   ///
	legend(order(3 "Male $label" 4 "Female $label") col(1) ring(0) position(5)) ///
	$axis1 = $penalty", justification(left))

	graph export "${hp}Graphs/v2_mleavegrp`j'_`var'.pdf", as(pdf) replace
	graph export "${hp}Graphs/v2_mleavegrp`j'_`var'.eps", as(eps) preview(off) replace	
	
			} // var
	} // j: maternal use group 
