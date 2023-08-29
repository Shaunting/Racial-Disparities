
* import data from June2020; 
proc import out=work.import_allegations
datafile='C:\Users\shaun\OneDrive\Documents\Important\A - DCYF\SAS Data\Investigations2021.xlsx'
DBMS=xlsx REPLACE;
GETNAMES=YES;
run;

/***** Unduplicate investigations by month *****/
* Create Month Year column;
data ALGTNS;
set import_allegations;
format MMYEAR1 MMDDYY10.;
MMYEAR1 = CpsTsCr;
MMYEAR = put(MMYEAR1, monyy7.);
drop MMYEAR1;
run;

data ALGTNS2;
set ALGTNS;
uniqueid = IdPrsnVctm || IdCase || MMYEAR; 
uniqueid2 = IdPrsnVctm || IdCase;
run;

proc sort data = ALGTNS2; by uniqueid; run;

data ALGTNS_OUTCOME;
set AlGTNS2; 
by uniqueid;
if first.uniqueid;
run;

/***** Data Wrangling *****/
data ALGTNS_OUTCOME_race;
set ALGTNS_OUTCOME;

* Create Agegroup variable;
format agegroup $8.;
if agevctm ge 10 then agegroup = "10-17";
if agevctm le 9 then agegroup = "0-9";

* Create Racenew variable;
format racenew $40.;
if missing(CDHSPNVCTM) then CDHSPNVCTM = "U";
if (CDHSPNVCTM=" " or CDHSPNVCTM="." or CDHSPNVCTM= "U" or CDHSPNVCTM= "D" or CDHSPNVCTM= "Unknown") then CDHSPNVCTM="U";
if CDHSPNVCTM= "Y" then racenew="Hispanic"; 
if (Racevctm = "Asian" or Racevctm = "Pacific Isl") and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM="D" or CDHSPNVCTM= "Unknown") then racenew="Other/multiracial";
if Racevctm = "Amer Indian" and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM="D" or CDHSPNVCTM= "Unknown") then racenew="Other/multiracial";
if Racevctm = "Black" and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM="D" or CDHSPNVCTM= "Unknown") then racenew="Black Non-H";
if (Racevctm = "Multiracial" or Racevctm = "Multi") and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM="D" or CDHSPNVCTM= "Unknown") then racenew="Other/multiracial";
if Racevctm= "White" and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM="D" or CDHSPNVCTM= "Unknown") then racenew="White Non-H";
if (Racevctm = "Unable to D" or Racevctm=" " or Racevctm="Decline to Disclose" or Racevctm= " ") and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM="D" or CDHSPNVCTM= "Unknown") then racenew="Unknown";
if (Racevctm = "Unknown" or Racevctm = "Unkno" or Racevctm= "Decline to Disclose") and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM= "D" or CDHSPNVCTM= "Unknown") then racenew="Unknown";
if (Racevctm = "Decline" or Racevctm = "Decli" or Racevctm=" " or racevctm="Decline to Disclose" or Racevctm= " ") and (CDHSPNVCTM="N" or CDHSPNVCTM="U" or CDHSPNVCTM="D" or CDHSPNVCTM= "Unknown") then racenew="Unknown";
run;

* Charts: Race/Ethnicity, Age group, Allegations;
proc freq data=ALGTNS_OUTCOME_race;
table racenew agegroup CanCode;run;

* Charts: Investigation Outcome;
proc freq data = ALGTNS_OUTCOME_race; 
table TxInvsVldtn TxAlgtnSbst;run;


/***** Exploratory Data Analysis *****/

* Charts: Relationship between investigation, race, gender, and age;
proc freq data=ALGTNS_OUTCOME_race;
tables TxInvsVldtn*racenew TxInvsVldtn*gndrvctm TxInvsVldtn*agegroup/ norow nofreq  nopercent; 
title "Relationship between investigation, race, gender, and age"; run;

* Relationship between investigation and race by age;
proc sort data=ALGTNS_OUTCOME_race; by agegroup; run;
proc freq data=ALGTNS_OUTCOME_race;
by agegroup;
table TxInvsVldtn*racenew/ norow nopercent nofreq;
title "Relationship between investigation and race by age"; run;

* Relationship between investigation and race by gender;
proc sort data=ALGTNS_OUTCOME_race; by gndrvctm; run;
proc freq data=ALGTNS_OUTCOME_race;
by gndrvctm;
table TxInvsVldtn*racenew/ norow nopercent nofreq;
title "Relationship between investigation and race by gender"; run;

* Compare race distribution based on "Domestic Violence";
proc freq data=algtns_outcome_race; 
where CanCodeDesc= "Domestic Violence";
table racenew; 
title "Domestic Violence"; run;

* Compare race distribution based on "Neglect";
proc sort data=ALGTNS_OUTCOME_race; by cancode; run;
proc freq data=algtns_outcome_race; 
by cancode;
table racenew; 
title "Neglect"; run;

* Rename;
data allegations;
set algtns_outcome_race;
run;

proc freq data=allegations;
tables TxInvsVldtn*racenew
		TxInvsVldtn*gndrvctm TxInvsVldtn*agegroup/ norow nofreq  nopercent; 
title "June 2021 - May 2023"; run;


/***** Import Removals *****/

proc import out=work.import_removals
datafile='C:\Users\shaun\OneDrive\Documents\Important\A - DCYF\SAS Data\Removals2021.xlsx'
DBMS=xlsx REPLACE;
GETNAMES=YES;
run;

proc format;
value servicetype
	1 = "Congregate care"
	2 = "Foster Care"
	3 = "Kinship Foster Care"
	4 = "Ind Living Contracted"
	5 = "SLA";
run;

* Categorize Service Type; 
data removals;
set import_removals;
removal = "yes";
uniqueid2 = idprsn || idcase;
format type servicetype.;

if SrvcTyp = "Acute Residential Trtmt then Type" then do; Type= 1; end;
if SrvcTyp = "Asmt Stbln Ctr" then do; Type = 1; end;
if SrvcTyp = "Group Homes" then do; Type= 1; end;             
if SrvcTyp = "High End Res Trtmnt"  then do; Type = 1;  end;  
if SrvcTyp = "RCC - Non Contracted"  then do; Type = 1;   end;
if SrvcTyp = "Rsdntl Trtmnt Center"  then do; Type = 1;   end;
if SrvcTyp = "Semi- Independent Living" then do; Type = 1;end;
if SrvcTyp = "FC Court Ordered Non-Rel" then do; Type = 2;end;
if SrvcTyp = "Foster Care - NonRelative" then do; Type = 2;end;
if SrvcTyp = "Foster Care Priv Agency" then do; Type = 2;end;
if SrvcTyp = "POS Foster Care" then do; Type = 2;    end;
if SrvcTyp = "Foster Care - Relative" then do; Type = 3; end;
if SrvcTyp = "Foster Care Court Ord Rel" then do; Type = 3; end;
if SrvcTyp = "Ind Living Contracted" then do; Type = 4;    end;
if SrvcTyp = "SLA-Apt/Home: Roommates" then do; Type=  5;end;
if SrvcTyp = "SLA-Apt/Home: SingParw/Ch" then do; Type= 5;end;
if SrvcTyp = "SLA-Apt/Home: Solo" then do; Type=5;     end;
if SrvcTyp = "SLA-Apt/Home: Spouse/Part"    then do; Type=5;end;
if SrvcTyp = "SLA-Former Foster Home"    then do; Type=5;end;
if SrvcTyp = "SLA-Relative/Kin" then do; Type = 5; end;
keep CpsTsCr uniqueid2 idprsn idcase dtbgn dtend EndRsnRmvl kinship SrvcTyp FL_CPS_RMVL type removal;
run;

* Merge allegations and removals;
proc sort data = allegations; by uniqueID2; run;
proc sort data = removals; by uniqueID2; run;

PROC SQL;
	CREATE TABLE merge AS
	SELECT *
	FROM work.allegations Alleg
	LEFT JOIN work.Removals Removals
	ON Alleg.uniqueID2 = Removals.uniqueID2
	ORDER BY Alleg.uniqueID2;
quit;


/***** Data Wrangling *****/

* Unduplicate data for each month;
proc sort data = merge; by uniqueid; run;
data merge2;
set merge; 
by uniqueid;
if first.uniqueid;
run;

* Categorize removals and non-removals;
data merge3;
set merge2;
drop idprsn;
if dtbgn = . then Removal = 'N';
else Removal = 'Y';
run;
proc sort  data = merge; by uniqueid; run;
* Reporter rank - Professional, Related, Anonymous, Other;
* Reporter rank 2 - Professional/Non-Professional;
proc format;
value reporter_rank
1="Professional"
2="Family/Friend/Victim"
3="Anonymous"
4="Other";
value reporter_rank_provsnon
0="Non-professional"
1="Professional"
3="Anonymous"
4="Other";
run;

* Categorize reporter types;
data merge4;
set merge3;
format type servicetype. reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
if cpssource = "Anonymous" then do; 
reporter_type2 = "Anonymous"; 
reporter_rank = 3; 
reporter_rank2=0; end;

else if cpssource = "Victim" then do; 
reporter_type2="Victim"; 
reporter_rank =2; 
reporter_rank2=0; end;

else if cpssource in ("Not Noted by Report Taker", " ") then do; 
reporter_type2="Missing"; 
reporter_rank =4; 
reporter_rank2=0; end;

else if cpssource in ("Principal","Assistant Principal", "Attendance Officer", "Other School Personn", "Other School Personnel", "Pre-School/Nursery School", 
"Principal", "Teacher") then do; 
reporter_type2="Education"; 
reporter_rank =1;
reporter_rank2=1; end;

else if cpssource in ("Child Care", "Child Day Care Cente", "Child Day Care Center", "Child Day Care Home", "Other Child Care Pro","Other Child Care Provider","Other Child Care Provide") then do; 
reporter_type2="Child Care Provider"; 
reporter_rank =1;
reporter_rank2=1; end;

else if cpssource in ("Baby-sitter", "Father/Father Substi","Father/Father Substitute", "Father/Father Substitut", "Father/Father Substitu", "Friend/Neighbor", "Mother/Mother Substi",  "Mother/Mother Substitute","Mother/Mother Substitu", "Mother/Mother Substitut", "Relative of Family", 
"Sibling") then do; 
reporter_type2="Family/Friends"; 
reporter_rank =2; 
reporter_rank2=0; end;

else if cpssource in ("CPI", "DCYF Attorney", "DCYF Probation/Parole Officer","DCYF Probation/Parole", "DCYF Social Worker", "Other DCYF Staff", "DCYF Probation/Parole Office") then do; 
reporter_type2="DCYF"; 
reporter_rank =1; 
reporter_rank2=1; end;

else if cpssource in ("Child Advocate Office", "DHS Personnel","Dept. of Corrections","Dept. of Corrections Per",  "Dept. of Corrections Pe","Dept. of Corrections Personn","Dept. of Corrections Personne","Dept. of Corrections Personnel") then do; 
reporter_type2="Other State Agencies"; 
reporter_rank =1; 
reporter_rank2=1; end;

else if cpssource in ("Courts(Judge/Master/","Courts(Judge/Master/Ca", "Courts(Judge/Master/Cas", "Courts(Judge/Master/Case","Courts(Judge/Master/Casewrke","Courts(Judge/Master/Casewrker","Courts(Judge/Master/Casewrker/","Courts(Judge/Master/Casewrker/A","Courts(Judge/Master/Casewrker/Attorney)","Other Law Enforcement P", "Police", "Other Law Enforcement Personnel","Other Law Enforcement", "Other Law Enforcement Pe", "Courts(Judge/Master/Casewrke", "Other Law Enforcemen", "Other Law Enforcement Pe","Other Law Enforcement Person","Other Law Enforcement Personn", "Other Law Enforcement Personne", "Other Law Enforcement Personnel") then do; 
reporter_type2="Law Enforcement"; 
reporter_rank =1; 
reporter_rank2=1; end;

else if cpssource in ("Clinic or Hospital P","Clinic or Hospital Physician", "Clinic or Hospital Phy","Clinic or Hospital Phys", "Clinic or Hospital Physi", "Counselor", "Dental Professional", "Emergency Services Perso","Emergency Services Personnel", "Emergency Services Pers", "Emergency Services Per", "Emergency Services Perso", "Medical Examiner", 
"Mental Health Person","Mental Health Personnel","Mental Health Personne", "Nurse (LPN)", "Nurse (RPN)", "Other Medical Person", "Other Medical Personnel","Other Medical Personne", "Private Physician", "Psychologist", "School Nurse") then do; 
reporter_type2="Medical Professional"; 
reporter_rank =1; 
reporter_rank2=1; end;

else if cpssource in ("Hospital Social Work","Hospital Social Worker","Other Social Service", "Other Social Services P","Other Social Services Pe", "Other Social Services Person","Other Social Services Personn","Other Social Services Personne","Other Social Services Personnel","Private Agency Socia", "Private Agency Social Wo","Private Agency Social Worker","Private Agency Social W", "Other Social Services","Other Social Services Pe", "Private Agency Social Worker", "Private Agency Social", "Private Agency Social Wo", "School Social Worker", "Other Social Services Person") then do; 
reporter_type2="Social Worker"; 
reporter_rank =1; 
reporter_rank2=1; end;

else if cpssource in ("Institutional Staff","Institutional Staff Personnel","Institutional Staff Per", "Institutional Staff Pe", "Institutional Staff Pers", "Landlord","Other Reporting Sour", "Other Reporting Source", "Institutional Staff Personne") then do; 
reporter_type2="Other"; 
reporter_rank =4; 
reporter_rank2=0; end;

if txalgtnsbst = "Pending" or txalgtnsbst = "Unable to" then delete;
if GndrVctm = "U" then delete;
*exclude or categorize reporter_type2?;

reporter_type3=reporter_type2;
if (reporter_type2 = "Other" or reporter_type2 = "Victim" or reporter_type2 ="Missing" or reporter_type2 = "Anonymous") then reporter_type3 ="Other/Missing";
if (reporter_type2 = "Education" or reporter_type2 = "Child Care Provider") then reporter_type3 = "Education/Child Care";
if (reporter_type2 = "DCYF" or reporter_type2 = "Social Worker" or reporter_type2= "Other State Agencies") then reporter_type3= "Social Worker/DCYF"; 

if missing(type) then type = "Unknown";
run;

* Create Kinship variable (boolean);
data merge5;
   set merge4;
   format type servicetype.;
   if type = 3 then kinship = "Y";
   else kinship = "N";
run;

* Reporter type, Reporter rank, and kinship;
proc freq data = merge5;
table reporter_type2 reporter_type3 reporter_rank reporter_rank2 kinship;run;

* Investigations, by race/ethnicity and reporter type;
PROC freq data=merge5;
table reporter_type3*mmyear
		reporter_type3*racenew
		reporter_rank2*racenew
		reporter_rank2*txalgtnsbst
		reporter_type3*txalgtnsbst
		txalgtnsbst*racenew; 
title '2) Investigations, by race/ethnicity and reporter type';
run;

* Trend of reporter types;
proc freq data=merge5;
  tables reporter_type3*mmyear/ noprint out=freq_output(rename=(count=frequency));
  ods output table=freq_output;
  title 'Trend of reporter type';
run;

data freq_data;
  set freq_output;
run;
proc sort data = freq_data; by mmyear; run;
proc sort data = merge5; by mmyear; run;

data merged_data;
  merge freq_data merge5;
  by mmyear;
run;
proc sort data = merged_data; by CpsTsCr; run;
proc sgplot data=merged_data;
  series x=mmyear y=frequency / group=reporter_type3 lineattrs=(thickness=2);
  where reporter_type3 = 'Medical Professional';
  xaxis display=(nolabel);
  yaxis grid;
run;

* Indicated investigations, by race/ethnicity and reporter type;
PROC freq data=merge5;
where txalgtnsbst = "Indicated";
table reporter_type3*mmyear
		reporter_type3*racenew
		reporter_rank2*racenew
		racenew;
title '3) Indicated investigations, by race/ethnicity and reporter type';
run;

*white vs BIPOC categories for logicistic regression model;
data merge6; 
set merge5;
if racenew="White Non-H" then racemodel = "White Non-H";
else racemodel = "BIPOC"; 
run;

proc freq data = merge6; table TxInvsVldtn*reporter_rank2;run;



* Filter: Only Professionals, Indicated/Unfounded investigations;
* Create Domestic Violence and Drug/Alcohol Abuse boolean variable;
data merge7;
set merge6;
if reporter_rank2 = 0 then delete;
if TxInvsVldtn = "Pending" then delete;
if CanCodeDesc = "Domestic Violence" then DV = "Y";
else DV = 'N';
if CanCodeDesc = "Drug/Alcohol Abuse" the Drug = "Y";
else Drug = "N";
if missing(fl_cps_rmvl ) then fl_cps_rmvl  = "N";
run;


proc freq data = merge7; table cancodeDesc*TxInvsVldtn; run;
proc freq data = cps_removals; where removal = "Y"; table cancodedesc*TxInvsVldtn; run;

* Filter for only cps removals; 
data cps_removals;
set merge7; 
if fl_cps_rmvl = "N" then delete;
run;

* Presentation Charts: Removals, Kinship, Type;
proc freq data = cps_removals; table removal; title 'Removals';run;
proc freq data = cps_removals; where removal = "Y"; table cancode kinship type; run;
proc freq data = cps_removals; where removal = "Y"; table drug*cancode DV*cancode/ norow nocol nofreq; run;

* Removal based on race; 
proc freq data=merge7;
table fl_cps_rmvl *racenew / norow nofreq nopercent; run;

proc sort data = merge7; by reporter_type3; run;
proc freq data=merge7; by reporter_type3;
table fl_cps_rmvl *racenew / norow nofreq nopercent; run;

* Presentation Charts: All Frequencies;
proc freq data=merge7;
table racenew TxInvsVldtn GndrVctm agegroup cancode; 
title 'Investigation Frequencies';run;

* Indicated based on race by reporter types; 
proc freq data=merge7;
table TxInvsVldtn*racenew / norow nofreq nopercent; run;

proc sort data = merge7; by reporter_type3; run;
proc freq data=merge7; by reporter_type3;
table TxInvsVldtn*racenew / norow nofreq nopercent; run;

/*****Analysis*****/

* Reporter rank - BIPOC, agegroup, allegations; 
proc logistic data=merge6 descending; 
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racemodel(ref="White Non-H") agegroup (ref="10-17")  cancode (ref="Neglect")/param=ref;
model reporter_rank2= racemodel agegroup cancode; 
run;

* Investigation Outcome - Reporter rank, BIPOC, agegroup, gender, allegations;
proc logistic data=merge6;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class reporter_rank2 (ref="Non-professional") racemodel(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") cancode (ref="Neglect")/param=ref;
model TxAlgtnSbst= reporter_rank2 racemodel agegroup GndrVctm cancode;
title "Odds Ratio - Investigation outcome by reporter profession type";
run;

* Investigation Outcome - Reporter Type, BIPOC, agegroup, gender, allegations;
proc logistic data=merge7;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class reporter_type3 (ref="Education/Child Care ") racemodel(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") cancode (ref="Neglect")/param=ref;
model TxAlgtnSbst= reporter_type3 racemodel agegroup GndrVctm cancode;
title "Odds Ratio - Investigation outcome by reporter profession type";
run;

* Presentation: Investigation Outcome - Race, Agegroup, Gender;
proc logistic data=merge7;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model TxInvsVldtn= racenew agegroup GndrVctm;
title "Odds Ratio - Investigation Outcome";
run;

proc sort data=merge7; by reporter_type3; run;
proc logistic data=merge7 descending;
by reporter_type3;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model removal= racenew agegroup GndrVctm ;
title "Odds Ratio - Investigation Outcome by Reporter Type";
run;

* Presentation: Removals - Race, Agegroup, Gender;
proc logistic data=merge7 descending;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model removal= racenew agegroup GndrVctm ;
title "Odds Ratio - Removals";
run;

proc sort data=merge7; by reporter_type3; run;
proc logistic data=cps_removals descending;
by reporter_type3;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model removal= racenew agegroup GndrVctm ;
title "Odds Ratio - Removals by Reporter Type";
run;

* Presentation: Kinship - Race, Agegroup, Gender;
proc logistic data=merge7 descending;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref= "F" ) /param=ref;
model kinship= racenew agegroup GndrVctm;
title "Odds Ratio - Kinship";
run;

proc sort data=merge7; by reporter_type3; run;
proc logistic data=merge7 descending;
by reporter_type3;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref= "F" ) /param=ref;
model kinship= racenew agegroup GndrVctm;
title "Odds Ratio - Kinship by Reporter Type";
run;

* Domestic Violence - Race, Agegroup, Gender;
proc logistic data=merge7 descending;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref= "F" ) /param=ref;
model DV= racenew agegroup GndrVctm;
title "Odds Ratio - Domestic Violence";
run;

proc sort data=merge7; by reporter_type3; run;
proc logistic data=merge7 descending;
by reporter_type3; 
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model DV= racenew agegroup GndrVctm;
title "Odds Ratio - Domestic Violence by Reporter Type";
run;

* Drug - Race, Agegroup, Gender;
proc logistic data=merge7 descending;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref= "F" ) /param=ref;
model Drug= racenew agegroup GndrVctm;
title "Odds Ratio - Drug";
run;

proc sort data=merge7; by reporter_type3; run;
proc logistic data=merge7 descending;
by reporter_type3; 
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model Drug= racenew agegroup GndrVctm;
title "Odds Ratio - Drug by Reporter Type";
run;

proc freq data = merge7;
*by reporter_type3;
table TxInvsVldtn*racenew removal*racenew/missing nopercent nofreq norow;
run;

proc freq data=merge7;
table reporter_type3 reporter_type2 reporter_rank reporter_rank2; run;

proc freq data = merge7;
*by reporter_type3;
table TxInvsVldtn*racenew removal*racenew kinship*racenew type*racenew dv*racenew drug*racenew/missing nopercent nofreq nocol;
run;

proc freq data = merge7;
*by reporter_type3;
table racenew*TxInvsVldtn racenew*removal agegroup*TxInvsVldtn GndrVctm*TxInvsVldtn/missing nopercent nofreq nocol;
run;

proc freq data = merge7;
by reporter_type3; 
where type ne " ";
table kinship*racenew; run;

proc freq data=merge7;
table fl_cps_rmvl*racenew / norow nofreq nopercent; run;

proc sort data = merge7; by reporter_type3; run;
proc freq data=merge7; by reporter_type3;
table fl_cps_rmvl*racenew / norow nofreq nopercent; run;

proc logistic data=merge7 descending;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model fl_cps_rmvl= racenew agegroup GndrVctm ;
title "Odds Ratio - Removals";
run;

proc sort data=merge7; by reporter_type3; run;
proc logistic data=merge7 descending;
by reporter_type3;
format reporter_type2 $40. reporter_rank reporter_rank. reporter_rank2 reporter_rank_provsnon.;
class racenew(ref="White Non-H") agegroup (ref="10-17") GndrVctm (ref="F") /param=ref;
model fl_cps_rmvl= racenew agegroup GndrVctm ;
title "Odds Ratio - Removals by Reporter Type";
run;
