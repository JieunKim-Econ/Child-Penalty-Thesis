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
* GBTM analysis: Career trajectories of women and men 	 -- Update: 8.Sep.2022
*------------------------------------------------------------------------------

* Check the number of observations 
egen num_pid = group(pid) 
sum num_pid // 1,149 women 
drop num_pid

* Update job codes of 2000 to the latest codes in 2017
replace p_jobfam2000 = 1 if inlist(p_jobfam2000, 11, 12, 13, 21, 22, 23, 24, 291, 30)
replace p_jobfam2000 = 2 if inlist(p_jobfam2000, 111, 112, 113, 172, 213, 211, 212, 120, 132, 232, 220, 235, 131, 134, 135, 231, 237, 238, 133, 233, 236, 234, 141, 142, 143, 241, 145, 144, 242, 243, 741, 292, 442, 444, 263, 271, 293, 173, 272, 151, 152, 153, 155, 154, 156, 252, 253, 157, 251, 171, 161, 291, 162, 163, 165, 164, 261, 262, 511, 182, 181, 184, 281, 316, 530, 713, 183, 282, 415, 283)
replace p_jobfam2000 = 3 if inlist(p_jobfam2000, 313, 318, 263, 311, 312, 314, 316, 315, 291, 317, 411, 292, 321, 322, 323, 415)
replace p_jobfam2000 = 4 if inlist(p_jobfam2000, 441, 442, 443, 444, 411, 412, 414, 416, 413, 431, 415, 432, 421, 422)
replace p_jobfam2000 = 5 if inlist(p_jobfam2000, 261, 262, 263, 511, 513, 321, 322, 512, 314, 415, 521, 522, 530)
replace p_jobfam2000 = 6 if inlist(p_jobfam2000, 611, 612, 613, 614, 616, 617, 615, 618, 620, 630)
replace p_jobfam2000 = 7 if inlist(p_jobfam2000, 751, 743, 744, 753, 754, 713, 741, 742, 752, 721, 722, 821, 731, 733, 732, 712, 711, 714, 941)
replace p_jobfam2000 = 8 if inlist(p_jobfam2000, 827, 828, 815, 744, 826, 754, 833, 822, 823, 721, 722, 812, 821, 742, 752, 811, 741, 813, 816, 817, 831, 829, 832, 841, 842, 843, 844, 814, 824, 825)
replace p_jobfam2000 = 9 if inlist(p_jobfam2000, 941, 942, 913, 930, 911, 914, 912, 411, 421, 512, 915, 620, 920)

* Extrat the first digit of 2017 codes 
gen total_jobfam = floor(p_jobfam2017/100)
replace total_jobfam = p_jobfam2000 if total_jobfam == .

* Categorize 9 groups to 7 groups 
replace total_jobfam = 6 if inlist(total_jobfam, 7, 8)
replace total_jobfam = 7 if total_jobfam == 9  
 
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
replace jobstat = 2 if p_job_status == 5 | p_job_status == 4 // 2: non-wage worker (self-employed + non-paid family worker)
replace jobstat = 3 if p_job_status == 3 | p_job_status == 2 // 4: temporary worker (non-regular + daily worker)
replace jobstat = 4 if p_job_status == 1 // 5: regular worker 

* Check duplicated data
duplicates tag pid eventtime, gen(flagss)
browse if flagss

save "${hp}output/GBTM.dta", replace
use "${hp}output/GBTM.dta", clear

keep jobstat total_jobfam pid eventtime
keep if inrange(eventtime, -2, 10)

gen time = eventtime + 3
drop eventtime

* Long to wide for GBTM analysis
reshape wide jobstat total_jobfam, i(pid) j(time)
save "${hp}output/GBTM_wide2.dta", replace

use "${hp}output/GBTM_wide2.dta", replace

* Generate a set of time variables to pass to traj
forval i = 1/13{ 
  generate t_`i' = `i'
}

traj, var(jobstat*) indep(t_*) model(cnorm) order(2 2 2 2 2) min(1) max(4) 
trajplot, xlabel(1(1)13) xtitle("Time") ytitle("Work status") 
* JE to-do: Add a vertical line at t=3, indicating the birth year

save "${hp}output/GBTM_trajplot.dta", replace

use "${hp}output/GBTM_trajplot.dta", clear

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

rename _traj_Group traj_group
