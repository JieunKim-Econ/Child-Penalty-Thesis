clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}output/women_sample_0509.dta", clear

*------------------------------------------------------------------------------
* GBTM analysis: Career trajectories of women and men 	 -- Update: 5.Sep.2022
*------------------------------------------------------------------------------

* Check the number of remaining observations 
egen num_pid = group(pid) 
sum num_pid // 1,179 women 
drop num_pid

/*
Task order
1. Select women who were employed in the past 2 years till childbirth 
-- i.e. employed in t=-2 or t=-1 or t=0
2. Estimation equation
3. Install the GBTM package and proceed  
*/

* Employed women before childbirth 
* We exclude non-wage family worker 
bysort pid: gen workbfchild = (emp == 1 & inrange(eventtime,-2,0)) 
bysort pid: egen empbfchild = max(workbfchild)
drop workbfchild 

* Count the number of distinct individuals by group 
// https://www.statalist.org/forums/forum/general-stata-discussion/general/1523113-tabulating-distinct-counts-of-an-id-by-group
egen tag = tag(pid empbfchild)
egen distinct = total(tag), by(empbfchild)
tabdisp empbfchild, c(distinct) // 0: 447, 1: 732

* Create a group by work status 
gen jobstat = .
replace jobstat = 1 if p_econstat != 1  // 1: unemployed or out of labor participation
replace jobstat = 2 if p_job_status == 5 // 2: non-wage family worker
replace jobstat = 3 if p_job_status == 4 // 3: self-employed
replace jobstat = 4 if p_job_status == 3 | p_job_status == 2 // 4: temporary worker
replace jobstat = 5 if p_job_status == 1 // 3: regular worker 


