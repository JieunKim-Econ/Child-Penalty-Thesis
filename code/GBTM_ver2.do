clear
set more off
set trace off
global hp = "C:/Users/jieun/Desktop/Thesis/Data_KLIPS/"

use "${hp}output/women_sample_0509.dta", clear

* Plot style
grstyle init 
grstyle set plain
grstyle set symbol
grstyle set lpattern
grstyle set color plottig
*------------------------------------------------------------------------------
* GBTM analysis: Career trajectories of women and men 	 -- Update: 7.Sep.2022
*------------------------------------------------------------------------------

* Check the number of observations 
egen num_pid = group(pid) 
sum num_pid // 1,179 women 
drop num_pid

/*
Task order
1. Select women who were employed in the past 2 years till childbirth 
-- i.e. employed in t = -2 | t = -1 | t = 0 (0: year of childbirth) 
2. Create the rank by work status: From 1 (unemployed) to 5 (regular employee) 
3. Categorize women with unique patterns in changes in work status by GBTM analysis 
*/

* Identify working women in the past two years before childbirth 
bysort pid: gen workbfchild = (emp == 1 & inrange(eventtime,-2,0)) 
bysort pid: egen empbfchild = max(workbfchild)
drop workbfchild 

* Count the number of distinct individuals by group 
// https://www.statalist.org/forums/forum/general-stata-discussion/general/1523113-tabulating-distinct-counts-of-an-id-by-group
egen tag = tag(pid empbfchild)
egen distinct = total(tag), by(empbfchild)
tabdisp empbfchild, c(distinct) // 0(not worked): 434, 1(worked): 715

* Only leave mothers who have work experience before the first childbirth
keep if empbfchild == 1

* Rank the job status 
gen jobstat = .
replace jobstat = 1 if p_econstat != 1  // 1: unemployed or out of labor participation
replace jobstat = 2 if p_job_status == 5 | p_job_status == 4 // 2: non-wage worker
replace jobstat = 3 if p_job_status == 3 | p_job_status == 2 // 4: temporary worker
replace jobstat = 4 if p_job_status == 1 // 5: regular worker 

* Check duplicated data
duplicates tag pid eventtime, gen(flagss)
browse if flagss

save "${hp}output/GBTM.dta", replace
use "${hp}output/GBTM.dta", clear

keep jobstat p_jobfam* pid eventtime
keep if inrange(eventtime, -2, 10)

gen time = eventtime + 3
drop eventtime

* Long to wide for GBTM analysis
reshape wide jobstat p_jobfam*, i(pid) j(time)
save "${hp}output/GBTM_wide2.dta", replace

use "${hp}output/GBTM_wide2.dta", replace

* Generate a set of time variables to pass to traj
forval i = 1/13 { 
  generate t_`i' = `i'
}

traj, var(jobstat*) indep(t_*) model(cnorm) order(2 2 2 2) min(1) max(4) 
trajplot, xlabel(1(1)13) xtitle("Time") ytitle("Work status") 
* JE to-do: Add a vertical line at t=3, indicating the birth year

* Function to print out summary stats
program summary_table_procTraj
    preserve
    * Drop missing assigned observations
    drop if missing(_traj_Group)
	
    * Look at the average posterior probability
	gen Mp = 0
	foreach i of varlist _traj_ProbG* {
	    replace Mp = `i' if `i' > Mp 
	}
    sort _traj_Group
    
	* The odds of correct classification
    by _traj_Group: gen countG = _N
    by _traj_Group: egen groupAPP = mean(Mp)
    by _traj_Group: gen counter = _n
    
	gen n = groupAPP/(1 - groupAPP)
    gen p = countG/ _N
    gen d = p/(1-p)
    gen occ = n/d
    
	* Estimated proportion for each group
    scalar c = 0
    gen TotProb = 0
    foreach i of varlist _traj_ProbG* {
       scalar c = c + 1
       quietly summarize `i'
       replace TotProb = r(sum)/ _N if _traj_Group == c 
    }
	gen d_pp = TotProb/(1 - TotProb)
	gen occ_pp = n/d_pp
	
    *This displays the group number [_traj_~p], 
    *the count per group (based on the max post prob), [countG]
    *the average posterior probability for each group, [groupAPP]
    *the odds of correct classification (based on the max post prob group assignment), [occ] 
    *the odds of correct classification (based on the weighted post. prob), [occ_pp]
    *and the observed probability of groups versus the probability [p]
    *based on the posterior probabilities [TotProb]
	
    list _traj_Group countG groupAPP occ occ_pp p TotProb if counter == 1
    restore
end

* Print out summary stats
summary_table_procTraj

