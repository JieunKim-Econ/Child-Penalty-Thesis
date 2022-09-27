clear
set more off
set trace off
global hp = "C:/Users/"

use "${hp}output/GBTM_trajplot.dta", clear

* Plot style
grstyle init 
grstyle set plain
grstyle set symbol
grstyle set lpattern
grstyle set color plottig

*-------------------------------------------------------------------------------
* Occupation transition before/after childbirth   		
* Re-entry after exit mothers vs. Stable participation mothers
*-------------------------------------------------------------------------------
rename _traj_Group traj_group

* Group 1: Re-entry after exit
keep if traj_group == 2 // 106 women

* Occupation rank BEFORE childbirth
gen job_bfchild = total_jobfam2
replace job_bfchild = total_jobfam1 if job_bfchild == . & total_jobfam1 != .

* Occupation rank AFTER childbirth 
/*gen job_postchild_all = total_jobfam4 
forvalues i = 5/13 {
	replace job_postchild_all = total_jobfam`i' if job_postchild_all == . & total_jobfam`i' != . 
	} */
gen job_postchild_all = total_jobfam13
foreach i in 12 11 10 9 8 7 6 5 4 {
	replace job_postchild_all = total_jobfam`i' if job_postchild_all == . & total_jobfam`i' != . 
	}	
	

keep if job_bfchild != . & job_postchild_all !=. // 89 women remain 

* Create occupation transition matrix prior/post-childbirth 
foreach cyear in all { 

		matrix jobtrans_postchild_`cyear' = J(6,6,.)
		
		matrix rownames jobtrans_postchild_`cyear' = "original_Elementary" "Skilled" "Sales" "Service" "Clerk" "Professional" 
		matrix colnames jobtrans_postchild_`cyear' = "destin_Elementary" "Skilled" "Sales" "Service" "Clerk" "Professional"
	
		matrix list jobtrans_postchild_`cyear'

} // cyear

save "${hp}output/GBTM_transition_prep2.dta", replace 

use "${hp}output/GBTM_transition_prep2.dta", clear

gen totalobs = 0
gen elementary = 0
gen skilled = 0
gen sales = 0
gen service = 0
gen clerk = 0
gen professional = 0 
gen manager = 0

local ci = 0
foreach cyear in all { 
		local ci = `ci' + 1
	
		replace totalobs = totalobs + (job_bfchild < .)
	    
		* (1) Elementary labor
		count if job_bfchild == 7 &  job_postchild_`cyear' != .  // Total number of elementary workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 7 // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 6 // Elementary -> Skilled
		local alt1 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 5   // Elementary -> Sales
		local alt2 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 4  // Elementary -> Service
		local alt3 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 3  // Elementary -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 2   // Elementary -> Professional
		local alt5 = `r(N)'
		//count if job_bfchild == 7 &  job_postchild_`cyear' == 1  // Elementary -> Manager
		//local alt6 = `r(N)'
		
		replace elementary = elementary + `denom'
		
		matrix jobtrans_postchild_`cyear'[1 , `ci'] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+1] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+2] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+3] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+5] = (`alt5'/`denom')*100
		//matrix jobtrans_postchild_`cyear'[1 , `ci'+6] = (`alt6'/`denom')*100
		
		
		* (2) Skilled
		count if job_bfchild == 6 & job_postchild_`cyear' != . // Total number of skilled workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 7 // Skilled -> Elementary: Downgrade
		local alt1 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 6 // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 5   // Skilled -> Sales
		local alt2 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 4  // Skilled -> Service
		local alt3 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 3  // Skilled -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 2   // Skilled -> Professional
		local alt5 = `r(N)'
		//count if job_bfchild == 6 &  job_postchild_`cyear' == 1  // Skilled -> Manager
		//local alt6 = `r(N)'

		replace skilled = skilled + `denom'	
		
		matrix jobtrans_postchild_`cyear'[2 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+1] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+2] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+3] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+5] = (`alt5'/`denom')*100
		//matrix jobtrans_postchild_`cyear'[2 , `ci'+6] = (`alt6'/`denom')*100

		* (3) Sales
		count if job_bfchild == 5 & job_postchild_`cyear' != . // Total number of sales workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 7 // Sales -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 6 // Sales -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 5   // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 4  // Sales -> Service
		local alt3 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 3  // Sales -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 2   // Sales -> Professional
		local alt5 = `r(N)'
		//count if job_bfchild == 5 &  job_postchild_`cyear' == 1  // Sales -> Manager
		//local alt6 = `r(N)'

		replace sales = sales + `denom'	
		
		matrix jobtrans_postchild_`cyear'[3 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+2] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+3] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+5] = (`alt5'/`denom')*100
		//matrix jobtrans_postchild_`cyear'[3 , `ci'+6] = (`alt6'/`denom')*100	
		
		* (4) Service
		count if job_bfchild == 4 & job_postchild_`cyear' != . // Total number of service workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 7 // Service -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 6 // Service -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 5   // Service -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 4  // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 3  // Service -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 2   // Service -> Professional
		local alt5 = `r(N)'
		//count if job_bfchild == 4 &  job_postchild_`cyear' == 1  // Service -> Manager
		//local alt6 = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[4 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+3] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+5] = (`alt5'/`denom')*100
		//matrix jobtrans_postchild_`cyear'[4 , `ci'+6] = (`alt6'/`denom')*100	
		
		* (5) Clerk
		count if job_bfchild == 3 & job_postchild_`cyear' != . // Total number of clerk workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 7 // Clerk -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 6 // Clerk -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 5   // Clerk -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 4  // Clerk -> Service (Downgrade) Remain in the same group after childbirth
		local alt4 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 3  // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 2   // Clerk -> Professional
		local alt5 = `r(N)'
		//count if job_bfchild == 3 &  job_postchild_`cyear' == 1  // Clerk -> Manager
		//local alt6 = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[5 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+3] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+4] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+5] = (`alt5'/`denom')*100
		//matrix jobtrans_postchild_`cyear'[5 , `ci'+6] = (`alt6'/`denom')*100	
		
		* (6) Professional
		count if job_bfchild == 2 & job_postchild_`cyear' != . // Total number of professional workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 7 // Professional  -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 6 // Professional  -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 5   // Professional  -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 4  // Professional  -> Service (Downgrade) 
		local alt4 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 3  // Professional -> Clerk (Downgrade) 
		local alt5 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 2   // Remain in the same group after childbirth
		local numb = `r(N)'
		//count if job_bfchild == 2 &  job_postchild_`cyear' == 1  // Professional -> Manager
		//local alt6 = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[6 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+3] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+4] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+5] = (`numb'/`denom')*100
		//matrix jobtrans_postchild_`cyear'[6 , `ci'+6] = (`alt6'/`denom')*100	
		
		/* (7) Manager
		count if job_bfchild == 1 & job_postchild_`cyear' != . // Total number of managers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 7 // Manager  -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 6 // Manager  -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 5   // Manager  -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 4  // Manager  -> Service (Downgrade) 
		local alt4 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 3  // Manager -> Clerk (Downgrade) 
		local alt5 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 2   // Manager -> Professional (Downgrade) 
		local alt6 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 1  // Remain in the same group after childbirth
		local numb = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[7 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+3] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+4] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+5] = (`alt6'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+6] = (`numb'/`denom')*100	*/
		
		}	
	
* Display the matrix
foreach cyear in all {
	matrix list jobtrans_postchild_`cyear'
}

* Export the matrix to MS word
foreach cyear in all {	
	asdoc wmat, mat(jobtrans_postchild_`cyear') 
}

* Visualization wiht heatmap
heatplot jobtrans_postchild_all,  values(format(%4.2f)) legend(off) color(Reds , intensity(.6)) /*
*/ xlabel(,labsize(small) angle(45)) ylabel(,labsize(small))

*-------------------------------------------------------------------------------
* Group 2: Stable participation mothers 
*-------------------------------------------------------------------------------
use "${hp}output/GBTM_trajplot.dta", clear
rename _traj_Group traj_group

keep if traj_group == 5 // 203 women

* Occupation rank BEFORE childbirth
gen job_bfchild = total_jobfam2
replace job_bfchild = total_jobfam1 if job_bfchild == . & total_jobfam1 != .

* Occupation rank AFTER childbirth 
gen job_postchild_all = total_jobfam13
foreach i in 12 11 10 9 8 7 6 5 4 {
	replace job_postchild_all = total_jobfam`i' if job_postchild_all == . & total_jobfam`i' != . 
	}

keep if job_bfchild != . & job_postchild_all !=. // 189 women remain 

* Create occupation transition matrix prior/post-childbirth 
foreach cyear in all { 

		matrix jobtrans_postchild_`cyear' = J(7,7,.)
		
		matrix rownames jobtrans_postchild_`cyear' = "original_Elementary" "Skilled" "Sales" "Service" "Clerk" "Professional" "Manager"
		matrix colnames jobtrans_postchild_`cyear' = "destin_Elementary" "Skilled" "Sales" "Service" "Clerk" "Professional" "Manager" 
	
		matrix list jobtrans_postchild_`cyear'

} // cyear

save "${hp}output/GBTM_transition_prep3.dta", replace 

use "${hp}output/GBTM_transition_prep3.dta", clear

gen totalobs = 0
gen elementary = 0
gen skilled = 0
gen sales = 0
gen service = 0
gen clerk = 0
gen professional = 0 
gen manager = 0

local ci = 0
foreach cyear in all { 
		local ci = `ci' + 1
	
		replace totalobs = totalobs + (job_bfchild < .)
	    
		* (1) Elementary labor
		count if job_bfchild == 7 &  job_postchild_`cyear' != .  // Total number of elementary workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 7 // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 6 // Elementary -> Skilled
		local alt1 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 5   // Elementary -> Sales
		local alt2 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 4  // Elementary -> Service
		local alt3 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 3  // Elementary -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 2   // Elementary -> Professional
		local alt5 = `r(N)'
		count if job_bfchild == 7 &  job_postchild_`cyear' == 1  // Elementary -> Manager
		local alt6 = `r(N)'
		
		replace elementary = elementary + `denom'
		
		matrix jobtrans_postchild_`cyear'[1 , `ci'] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+1] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+2] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+3] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+5] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[1 , `ci'+6] = (`alt6'/`denom')*100
		
		
		* (2) Skilled
		count if job_bfchild == 6 & job_postchild_`cyear' != . // Total number of skilled workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 7 // Skilled -> Elementary: Downgrade
		local alt1 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 6 // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 5   // Skilled -> Sales
		local alt2 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 4  // Skilled -> Service
		local alt3 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 3  // Skilled -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 2   // Skilled -> Professional
		local alt5 = `r(N)'
		count if job_bfchild == 6 &  job_postchild_`cyear' == 1  // Skilled -> Manager
		local alt6 = `r(N)'

		replace skilled = skilled + `denom'	
		
		matrix jobtrans_postchild_`cyear'[2 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+1] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+2] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+3] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+5] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[2 , `ci'+6] = (`alt6'/`denom')*100

		* (3) Sales
		count if job_bfchild == 5 & job_postchild_`cyear' != . // Total number of sales workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 7 // Sales -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 6 // Sales -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 5   // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 4  // Sales -> Service
		local alt3 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 3  // Sales -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 2   // Sales -> Professional
		local alt5 = `r(N)'
		count if job_bfchild == 5 &  job_postchild_`cyear' == 1  // Sales -> Manager
		local alt6 = `r(N)'

		replace sales = sales + `denom'	
		
		matrix jobtrans_postchild_`cyear'[3 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+2] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+3] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+5] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[3 , `ci'+6] = (`alt6'/`denom')*100	
		
		* (4) Service
		count if job_bfchild == 4 & job_postchild_`cyear' != . // Total number of service workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 7 // Service -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 6 // Service -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 5   // Service -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 4  // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 3  // Service -> Clerk
		local alt4 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 2   // Service -> Professional
		local alt5 = `r(N)'
		count if job_bfchild == 4 &  job_postchild_`cyear' == 1  // Service -> Manager
		local alt6 = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[4 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+3] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+4] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+5] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[4 , `ci'+6] = (`alt6'/`denom')*100	
		
		* (5) Clerk
		count if job_bfchild == 3 & job_postchild_`cyear' != . // Total number of clerk workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 7 // Clerk -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 6 // Clerk -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 5   // Clerk -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 4  // Clerk -> Service (Downgrade) Remain in the same group after childbirth
		local alt4 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 3  // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 2   // Clerk -> Professional
		local alt5 = `r(N)'
		count if job_bfchild == 3 &  job_postchild_`cyear' == 1  // Clerk -> Manager
		local alt6 = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[5 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+3] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+4] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+5] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[5 , `ci'+6] = (`alt6'/`denom')*100	
		
		* (6) Professional
		count if job_bfchild == 2 & job_postchild_`cyear' != . // Total number of professional workers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 7 // Professional  -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 6 // Professional  -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 5   // Professional  -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 4  // Professional  -> Service (Downgrade) 
		local alt4 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 3  // Professional -> Clerk (Downgrade) 
		local alt5 = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 2   // Remain in the same group after childbirth
		local numb = `r(N)'
		count if job_bfchild == 2 &  job_postchild_`cyear' == 1  // Professional -> Manager
		local alt6 = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[6 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+3] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+4] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+5] = (`numb'/`denom')*100
		matrix jobtrans_postchild_`cyear'[6 , `ci'+6] = (`alt6'/`denom')*100	
		
		* (7) Manager
		count if job_bfchild == 1 & job_postchild_`cyear' != . // Total number of managers before childbirth 
		local denom = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 7 // Manager  -> Elementary(Downgrade)
		local alt1 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 6 // Manager  -> Skilled (Downgrade)
		local alt2 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 5   // Manager  -> Sales (Downgrade)
		local alt3 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 4  // Manager  -> Service (Downgrade) 
		local alt4 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 3  // Manager -> Clerk (Downgrade) 
		local alt5 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 2   // Manager -> Professional (Downgrade) 
		local alt6 = `r(N)'
		count if job_bfchild == 1 &  job_postchild_`cyear' == 1  // Remain in the same group after childbirth
		local numb = `r(N)'

		replace service = service + `denom'	
		
		matrix jobtrans_postchild_`cyear'[7 , `ci'] = (`alt1'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+1] = (`alt2'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+2] = (`alt3'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+3] = (`alt4'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+4] = (`alt5'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+5] = (`alt6'/`denom')*100
		matrix jobtrans_postchild_`cyear'[7 , `ci'+6] = (`numb'/`denom')*100	
		
		}	

	
* Display the matrix
foreach cyear in all {
	matrix list jobtrans_postchild_`cyear'
}


* Export the matrix to MS word
foreach cyear in all {	
	asdoc wmat, mat(jobtrans_postchild_`cyear') 
}

* Visualization wiht heatmap
heatplot jobtrans_postchild_all,  values(format(%4.2f)) legend(off) color(Oranges, intensity(.5)) /*
*/ xlabel(,labsize(small) angle(45)) ylabel(,labsize(small))
