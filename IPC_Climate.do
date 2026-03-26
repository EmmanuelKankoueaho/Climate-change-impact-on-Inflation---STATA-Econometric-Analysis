import excel "C:\Magistère2\SEMESTRE1\Rapport Eco\Data\nvell_base.xlsx", firstrow clear


 
	* Supposons que vous avez déjà une base de données avec les variables 

	* Encoder la variable "" en une variable numérique
	encode iso3, generate(Iso3)

	//Convertir periode  en chaînes de caractères

	tostring periode, replace
	encode periode, generate(Periode)


	* Définir le panel
	duplicates report Iso3 Periode
	duplicates list Iso3 Periode
	duplicates drop Iso3 Periode, force
	
	xtset Iso3 Periode
	


	* Créer les variables décalées
	gen Inflation_lag = L.Inflation
	gen SPEI_lag = L.SPEI
	gen SPEI_lag2= L2.SPEI
	gen SPEI_lag3= L3.SPEI
	gen money_lag=L.money_growth
	gen SPEI_sq = SPEI^2
	gen SPEI_Agriimport = SPEI * Agriimport
    gen SPEI_lag_Agriexport = SPEI_lag * Agriexport
	

    
gen log_Debt_PPG=log(Debt_PPG)
gen log_Debt_P_pc_pib = log(Debt_P_pc_pib)
gen log_money_lag = log(money_lag)

gen Agri_Prop = 1000*Agriculture_mean/GDP40

*Tests à effectuer pour utilioser les GMM

/*1. Stationnarité des variables (facultatif mais recommandé)
   - Objectif : Vérifier la présence de racine unitaire.
   - Tests STATA :*/
    
 xtunitroot fisher Inflation, lags(1) dfuller

 xtunitroot ips Inflation
 xtunitroot fisher Inflation, lags(1) pperron
 
  *2. Présence d'effet dynamique (est-ce que la variable dépend de sa valeur passée ?)
   *- Objectif : Justifier un modèle dynamique avec variable retardée.
   *- Commande STATA :
   
	

/* 3. Test Hausman : Effets fixes ou aléatoires ?
   - Objectif : Vérifier si les effets fixes sont préférables aux effets aléatoires.
   - Commandes STATA : on doit introduire les effet fixes */
   
xtreg Inflation Inflation_lag SPEI Real_IR REER money_growth Dependance Debt_PPG GDP_growth, fe
estimates store fe_model
xtreg Inflation Inflation_lag SPEI Real_IR REER money_growth Dependance Debt_PPG GDP_growth, re
estimates store re_model
hausman fe_model re_model, sigmamore

/* test à effet temporels : Statistique F (8, 177) = 8.14 : Cette valeur mesure la variance expliquée par les effets temporels par rapport à la variance non expliquée.p-value = 0.0000 : Comme la p-value est inférieure à 0.05, on rejette l'hypothèse nulle. Cela signifie que les effets temporels sont statistiquement significatifs.*/

xtreg Inflation Inflation_lag SPEI Real_IR REER money_growth Dependance Debt_PPG GDP_growth i.Periode, fe
testparm i.Periode

* Gmm en systeme se fait en deux etapes:  L'équation en différence (différencier les variables pour éliminer les effets fixe et L'équation en niveau (pour la validite des insytruments ). la commande xtabond2 permet de faire les deux a fois donc pas besoin d'introduire effet fixe car la commande tient compte de ca via la premiere difference et l'elimine directement mais on doit introduire effet temporel i.Periode Apres plusieurs regression  , j'ai vu que reer nest pas un varible mais c'est un intrument 

*Estimation gmm en systeme avec i.periode : intrument plus valides 
xtabond2 Inflation Inflation_lag SPEI GDP_growth REER Real_IR Dependance Debt_P_pc_pib money_lag i.Periode,  gmm(Inflation_lag , lag(2 4) collapse ) iv(i.Periode Dependance   GDP_growth money_lag Real_IR REER Debt_P_pc_pib )  twostep robust small
est store gmm_model01



* Estimation du modèle GMM système sans i.period: intrument moins valides 

xtabond2 Inflation Inflation_lag SPEI  GDP_growth Real_IR money_lag Dependance REER Debt_P_pc_pib,  gmm(Inflation_lag , lag(2 3) collapse ) iv( GDP_growth Real_IR money_lag Dependance REER Debt_P_pc_pib)  twostep robust small
est store gmm_model11

esttab gmm_model01 gmm_model11 ///
    b(3) se(3) /// 
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(ar2 Hansen, labels("AR(2) p-value" "Hansen p-value")) ///
    mtitles("Model avec periode" "Model sans periode") ///
    title("Résumé des résultats") ///
    note("Les erreurs standard robustes sont indiquées entre parenthèses.")

	

xtabond2 Inflation Inflation_lag  , gmm(Inflation_lag , lag(2 3)) collapse 

/*xtabond2 Inflation Inflation_lag SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG ,  gmm(Inflation, lag(2 .)) iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) twostep robust
est store gmm_model0


xtabond2 Inflation Inflation_lag SPEI_lag GDP_growth Real_IR money_lag Dependance REER Debt_PPG SPEI_sq, gmm(Inflation, lag(2 .)) iv(SPEI_lag GDP_growth Real_IR money_lag Dependance REER Debt_PPG) twostep robust
est store gmm_model1


xtabond2 Inflation Inflation_lag SPEI_lag2 GDP_growth Real_IR money_lag Dependance REER Debt_PPG SPEI_sq, gmm(Inflation, lag(2 .)) iv(SPEI_lag2 GDP_growth Real_IR money_lag Dependance REER Debt_PPG) twostep robust
est store gmm_model2



xtabond2 Inflation Inflation_lag SPEI_lag3 GDP_growth Real_IR money_lag Dependance REER Debt_PPG SPEI_sq, gmm(Inflation, lag(2 .)) iv(SPEI_lag3 GDP_growth Real_IR money_lag Dependance REER Debt_PPG) twostep robust
est store gmm_model3

xtabond2 Inflation Inflation_lag SPEI_lag2 , gmm(Inflation, lag(2 .)) iv(SPEI_lag2) twostep robust
est store gmm_model2


xtabond2 Inflation Inflation_lag SPEI_lag3 GDP_growth money_growth Dependance, gmm(Inflation, lag(2 .)) iv(SPEI SPEI_lag SPEI_lag2 SPEI_lag3 GDP_growth money_growth Dependance) twostep robust
est store gmm_model3


xtabond2 Inflation Inflation_lag SPEI_lag3 GDP_growth Real_IR money_lag Dependance, gmm(Inflation, lag(2 .)) iv(SPEI_lag3 GDP_growth Real_IR money_lag Dependance) twostep robust
est store gmm_model4


xtabond2 Inflation Inflation_lag SPEI SPEI_lag SPEI_lag2 SPEI_lag3 GDP_growth Real_IR money_lag Dependance REER Debt_PPG, gmm(Inflation, lag(2 .)) iv(SPEI SPEI_lag SPEI_lag2 SPEI_lag3 GDP_growth  Real_IR money_lag Dependance REER Debt_PPG) twostep robust
est store gmm_model5

* Résumer les résultats dans un tableau
esttab gmm_model0 gmm_model1 gmm_model2 gmm_model3 gmm_model4 gmm_model5 , ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(ar2 Hansen, labels("AR(2) p-value" "Hansen p-value")) ///
    mtitles("" "" "" "" "" "" ) ///
    title("Résumé des résultats") ///
    note("Les erreurs standard robustes sont indiquées entre parenthèses.")
	
*/


gen shock_sup1 = (SPEI > 1)

gen shock_inf1 = (SPEI_lag < -1)


gen shock_inf1_spei = shock_inf1*SPEI

gen shock_sup1_spei = shock_sup1*SPEI

gen shock_inf1_inflation= shock_inf1* Inflation

gen shock_sup1_L1 = L.shock_sup1
gen shock_sup1_L2 = L2.shock_sup1
gen shock_sup1_L3 = L3.shock_sup1

gen shock_inf1_L1 = L.shock_inf1
gen shock_inf1_L2 = L2.shock_inf1
gen shock_inf1_L3 = L3.shock_inf1

gen shock_inf1_L1_spei = L.shock_inf1_spei
gen shock_inf1_L2_spei = L2.shock_inf1_spei
gen shock_inf1_L3_spei = L3.shock_inf1_spei

gen shock_sup1_L1_spei = L.shock_sup1_spei
gen shock_sup1_L2_spei = L2.shock_sup1_spei
gen shock_sup1_L3_spei = L3.shock_sup1_spei


gen chocsup = SPEI > 1
gen chocinf = SPEI <-1
gen gdp2 = GDP_growth^2
gen chocsup_multi = SPEI*chocsup
gen chocinf_multi = SPEI*chocinf
gen mon2 = log_money_lag^2

* Modèle avec chocs sup2
xtabond2  Inflation Inflation_lag shock_inf1  GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1 GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small
est store gmm_shock_INF1




* darnelle robustesse avec choc precipîtation 
gen choc_lag = L.choc_precip
gen choc_lag2 = L2.choc_precip
gen choc_lag3 = L3.choc_precip

gen preci_sup1 = (choc_precip > 1)
tabulate preci_sup1
gen preci_inf1 = (choc_precip < -1)
tabulate preci_inf1
 
 gen preci_inf1_choic = preci_inf1*choc_precip
 gen preci_sup1_choic = preci_sup1*choc_precip
 
 gen preci_inf1_lag = L.preci_inf1
 gen preci_sup1_lag= L.preci_sup1
/*gen 
gen shock_inf1_spei= shock_inf1*SPEI

gen shock_inf1_inflation= shock_inf1* Inflation */

* Regression avec choc uniquement avce reer
ssc install xtabond2
xtabond2  Inflation Inflation_lag choc_precip GDP_growth Real_IR money_lag Dependance REER Debt_P_pc_pib,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( GDP_growth Real_IR money_lag Dependance REER Debt_P_pc_pib)  twostep robust small //OK 
est store mode1

*regression avec choc retarde 1

xtabond2  Inflation Inflation_lag choc_lag GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag choc_lag, lag(2 3) collapse ) iv( GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small
est store gmm_mode2

* regression avec choc retardee 2 

xtabond2  Inflation Inflation_lag choc_precip choc_lag2 GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag choc_lag2, lag(2 3) collapse ) iv( choc_precip GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small

* regression avec choc retardee 3 
xtabond2  Inflation Inflation_lag choc_precip choc_lag3 GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag choc_lag3 , lag(2 3) collapse ) iv(choc_precip GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small

* regression avce le choc retardee1 uniquement 
xtabond2  Inflation Inflation_lag choc_lag GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag choc_lag , lag(2 3) collapse)  iv(GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small
est store mode3

xtabond2  Inflation Inflation_lag choc_lag2 GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag choc_lag2 , lag(2 3) collapse)  iv(GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small

xtabond2  Inflation Inflation_lag choc_lag3 GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag choc_lag3 ,lag(2 3) collapse)  iv(choc_lag GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small /// chooc lag pour que les instrument soit valides 

* Résumer les résultats dans un tableau
ssc install estout
esttab mode1 gmm_mode2 mode3 , ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(ar2 Hansen, labels("AR(2) p-value" "Hansen p-value")) ///
    mtitles("" "" "" "" "" "" ) ///
    title("Résumé des résultats") ///
    note("Les erreurs standard robustes sont indiquées entre parenthèses.")
	

* regression avec les choc importants seulement 
xtabond2  Inflation Inflation_lag preci_sup1 GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  ,lag(2 3) collapse)  iv( preci_sup1 GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small


xtabond2  Inflation Inflation_lag preci_inf1 GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  ,lag(2 3) collapse)  iv(preci_inf1 GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small
 
 * Regression avec retard des choc important 
 xtabond2  Inflation Inflation_lag preci_inf1 preci_inf1_lag GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag preci_inf1_lag, lag(2 3) collapse ) iv preci_inf1 GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small


xtabond2  Inflation Inflation_lag preci_sup1 preci_sup1_lag GDP_growth Real_IR money_lag Dependance REER Debt_P_pc_pib,  gmm(Inflation_lag preci_sup1_lag, lag(2 3) collapse ) iv (preci_sup1 GDP_growth Real_IR money_lag Dependance REER Debt_P_pc_pib ) twostep robust small


* choc uniquement sans reer 
ssc install xtabond2
xtabond2  Inflation Inflation_lag choc_precip GDP_growth Real_IR Dependance  Debt_P_pc_pib REER, gmm(Inflation_lag  , lag(2 3) collapse ) iv( GDP_growth Real_IR Dependance REER Debt_P_pc_pib)  twostep robust small //OK 
est store mode1

gen spei_carre = SPEI^2
gen Inflationlag_caree = Inflation_lag^2
xtabond2  Inflation Inflation_lag Inflationlag_caree SPEI  GDP_growth Real_IR money_lag Dependance REER Debt_P_pc_pib,  gmm(Inflation_lag  , lag(2 3) collapse ) iv (GDP_growth Real_IR money_lag Dependance money_growth REER Debt_P_pc_pib)  twostep robust small //OK 
est store mode1


************************************HETEROGENEITE

ssc install xtabond2


*****************POIDS DE L'AGRICULTURE DANS L'ECONOMIE 

gen Agri_poi = 0

replace Agri_poi = 1 if Agri_Prop > 0.3


***Pays agricoles
*Choc dynamique
preserve
keep if Agri_Prop > 0.8
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store Agri_Countriesg
restore

*Choc t
xtreg inflation SPEI gdp money_lag REER Real_IR Debt_P_pc_pib if Agri_poi == 1, re robust
est sto Agri_Countries

*Choc important positif t
xtreg inflation SPEI chocsup chocsup_multi gdp money_lag REER Real_IR Debt_P_pc_pib if Agri_poi == 1, re robust
est sto Agri_Countries_sup

*Choc important négatif t
xtreg inflation SPEI chocinf chocinf_multi gdp money_lag REER Real_IR Debt_P_pc_pib if Agri_poi == 1, re robust
est sto Agri_Countries_inf



***Pays Non-agricoles
*Choc dynamique
preserve
keep if Agri_Prop <= 0.8
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store NoAgri_Countriesg
restore

*Choc t
xtreg inflation SPEI gdp money_lag REER Real_IR Debt_P_pc_pib if Agri_poi == 0, re robust
est sto NoAgri_Countries

*Choc important positif t
xtreg Inflation SPEI chocsup chocsup_multi GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Agri_poi == 0, re robust
est sto NoAgri_Countries_sup

*Choc important négatif t
xtreg inflation SPEI chocinf chocinf_multi gdp money_lag REER Real_IR Debt_P_pc_pib if Agri_poi == 0, re robust
est sto NoAgri_Countries_inf


outreg2 [Agri_Countries_inf  NoAgri_Countries_inf] using tab_resultheteo.doc, title("Poids agricole")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)

outreg2 [Agri_Countries_inf  NoAgri_Countries_inf] using tab_resultheteo.tex, title("Poids agricole")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)



*****************IMPORTATIONS DE FUELS/ENERGY
*Energy import net, fuels import

gen Ener_import = 0

replace Ener_import = 1 if Energyimportsnet_ofenergy > 0


***Pays importateurs
*Choc dynamique
preserve
keep if Energyimportsnet_ofenergy > 0
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store Import_Countriesg
restore

*Choc t
xtreg Inflation SPEI GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Ener_import == 1, re robust
est sto Import_Countries

*Choc important positif t
xtreg Inflation SPEI chocsup chocsup_multi GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Ener_import == 1, re robust
est sto Import_Countries_sup

*Choc important négatif t
xtreg Inflation SPEI chocinf chocinf_multi GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Ener_import == 1, re robust
est sto Import_Countries_inf



***Pays exportateurs
*Choc dynamique
preserve
keep if Energyimportsnet_ofenergy < 0
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store Export_Countriesg
restore

*Choc t
xtreg Inflation SPEI GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Ener_import == 0, re robust
est sto Export_Countries

*Choc important positif t
xtreg Inflation SPEI chocsup chocsup_multi GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Ener_import == 0, re robust
est sto Export_Countries_sup

*Choc important négatif t
xtreg Inflation SPEI chocinf chocinf_multi GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Ener_import == 0, re robust
est sto Export_Countries_inf


outreg2 [Import_Countries Import_Countries_sup Import_Countries_inf Export_Countries Export_Countries_sup Export_Countries_inf] using tab_resultheteo.doc, title("Importations agricoles")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)


esttab Import_Countries Import_Countries_L1 Import_Countries_L2 Import_Countries_L3 ///
       Export_Countries Export_Countries_L1 Export_Countries_L2 Export_Countries_L3 ///
       using regression_results.csv, ///
       se star(* 0.10 ** 0.05 *** 0.01) stats(N r2) label replace
	   
esttab Import_Countries Import_Countries_L1 Import_Countries_L2 Export_Countries Export_Countries_L1 Export_Countries_L2 , ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(ar2 Hansen, labels("AR(2) p-value" "Hansen p-value")) ///
    mtitles("" "" "" "" "" "" ) ///
    title("Résumé des résultats") ///
    note("Les erreurs standard robustes sont indiquées entre parenthèses.")


****OUVERTURE COMMERCIALE
/*On utilise le trade openness ratio qui est égal à la somme des importations et des exportations rapportée au PIB.
✔️ < 30% → Économie relativement fermée
✔️ 50% → Seuil indicatif d'une économie ouverte
✔️ 100% et plus → Économie très ouverte et intégrée dans le commerce mondial*/

gen Ouvert = 0

replace Ouvert = 1 if Trade_openness >= 100

***Pays ouverts
*Choc dynamique
preserve
keep if Trade_openness >= 50
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store Opened_Countriesg
restore

*Choc t
xtreg Inflation SPEI GDP_growth lmoney_lag REER Real_IR log_Debt_P_pc_pib if Ouvert == 1, re robust
est sto Open

*Choc important positif t
xtreg Inflation SPEI chocsup chocsup_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Ouvert == 1, re robust
est sto Opensup

*Choc important négatif t
xtreg Inflation SPEI chocinf chocinf_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Ouvert == 1, re robust
est sto Openinf


***Pays non-ouverts
*Choc dynamique
preserve
keep if Trade_openness < 50
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store Nonopened_Countriesg
restore

*Choc t
xtreg Inflation SPEI GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Ouvert == 0, re robust
est sto Nonopened_Countries

*Choc important positif t
xtreg Inflation SPEI chocsup chocsup_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Ouvert == 0, re robust
est sto Noopensup

*Choc important négatif t
xtreg Inflation SPEI chocinf chocinf_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Ouvert == 0, re robust
est sto Noopeninf


outreg2 [Openinf Opensup Noopeninf Noopensup] using tab_resultheteo.doc, title("Ouverture commerciale")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)

outreg2 [Openinf Opensup Noopeninf Noopensup] using tab_resultheteo.tex, title("Ouverture commerciale")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)


esttab Opened_Countries Opened_Countries_L1 Opened_Countries_L2 Opened_Countries_L3 ///
Nonopened_Countries Nonopened_Countries_L1 Nonopened_Countries_L2 Nonopened_Countries_L3 ///
       using regression_results.csv, ///
       se star(* 0.10 ** 0.05 *** 0.01) stats(N r2) label replace
	   
esttab Opened_Countries Opened_Countries_L1 Opened_Countries_L2 Nonopened_Countries Nonopened_Countries_L1 Nonopened_Countries_L2 , ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(ar2 Hansen, labels("AR(2) p-value" "Hansen p-value")) ///
    mtitles("" "" "" "" "" "" ) ///
    title("Résumé des résultats") ///
    note("Les erreurs standard robustes sont indiquées entre parenthèses.")



****NIVEAU DE REVENU 
* Faible revenu : GDPpc< 1146$ 
* Revenu intermédiaire inférieur : entre 1146 et 4516$
* Revenu intermédiaire supérieur : entre 4516$ and 14005$

gen Rev_Inf = 0

replace Rev_Inf =1 if GDP_pc < 4516


***Pays à revenu inférieur
*Choc dynamique
preserve
keep if GDP_pc < 4516
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store LowIncome_Countriesg
restore

*Choc t
xtreg Inflation SPEI GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Rev_Inf == 1, re robust
est sto LowInc

*Choc important positif t
xtreg Inflation SPEI chocsup chocsup_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Rev_Inf == 1, re robust
est sto LowIncsup

*Choc important négatif t
xtreg Inflation SPEI chocinf chocinf_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Rev_Inf == 1, re robust
est sto LowIncinf


***Pays à revenu supérieur
*Choc dynamique
preserve
keep if GDP_pc >= 4516
xtabond2 inflation inflation_lag SPEI SPEI_lag GDP_growth ///
    Real_IR money_lag Dependance REER Debt_PPG, ///
    gmm(inflation_lag, lag(2 3) collapse) ///
    iv(SPEI GDP_growth Real_IR money_lag Dependance REER Debt_PPG) ///
    twostep robust small
est store HighIncome_Countriesg
restore

*Choc t
xtreg Inflation SPEI GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib if Rev_Inf == 0, re robust
est sto HighIncome_Countries

*Choc important positif t
xtreg Inflation SPEI chocsup chocsup_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Rev_Inf == 0, re robust
est sto HighIncsup

*Choc important négatif t
xtreg Inflation SPEI chocinf chocinf_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib if Rev_Inf == 0, re robust
est sto HighIncinf


outreg2 [LowIncsup LowIncinf HighIncsup HighIncinf] using tab_resultheteo.tex, title("Niveau de revenu")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)

outreg2 [LowIncsup LowIncinf HighIncsup HighIncinf] using tab_resultheteo.tex, title("Niveau de revenu")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)


esttab Opened_Countries Opened_Countries_L1 Opened_Countries_L2 Opened_Countries_L3 ///
Nonopened_Countries Nonopened_Countries_L1 Nonopened_Countries_L2 Nonopened_Countries_L3 ///
       using regression_results.csv, ///
       se star(* 0.10 ** 0.05 *** 0.01) stats(N r2) label replace
	   
esttab LowIncome_Countries LowIncome_Countries_L1 LowIncome_Countries_L2 HighIncome_Countries HighIncome_Countries_L1 HighIncome_Countries_L2 , ///
    b(3) se(3) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(ar2 Hansen, labels("AR(2) p-value" "Hansen p-value")) ///
    mtitles("" "" "" "" "" "" ) ///
    title("Résumé des résultats") ///
    note("Les erreurs standard robustes sont indiquées entre parenthèses.")






/***Pays importateurs
*Choc année t
xtabond2  Inflation Inflation_lag shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Energyimportsnet_ofenergy > 0
est store Import_Countries

* Choc année t-1
xtabond2  Inflation Inflation_lag shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ener_import == 1
est store Import_Countries_L1

* Choc année t-2
xtabond2  Inflation Inflation_lag shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ener_import == 1
est store Import_Countries_L2

* Choc année t-3
xtabond2  Inflation Inflation_lag shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ener_import == 1
est store Import_Countries_L3


***Pays exportateurs
*Choc année t
xtabond2  Inflation Inflation_lag shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ener_import == 0
est store Export_Countries_L1

* Choc année t-1
xtabond2  Inflation Inflation_lag shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ener_import == 0
est store Export_Countries_L1

* Choc année t-2
xtabond2  Inflation Inflation_lag shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ener_import == 0
est store Export_Countries_L2

* Choc année t-3
xtabond2  Inflation Inflation_lag shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ener_import == 0
est store Export_Countries_L3


****OUVERTURE COMMERCIALE
/*On utilise le trade openness ratio qui est égal à la somme des importations et des exportations rapportée au PIB.
✔️ < 30% → Économie relativement fermée
✔️ 50% → Seuil indicatif d'une économie ouverte
✔️ 100% et plus → Économie très ouverte et intégrée dans le commerce mondial*/

gen Ouvert = 0

replace Ouvert = 1 if Trade_openness >= 100

***Pays très ouverts
*Choc année t
xtabond2  Inflation Inflation_lag shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 1
est store Opened_Countries

* Choc année t-1
xtabond2  Inflation Inflation_lag shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 1
est store Opened_Countries_L1

* Choc année t-2
xtabond2  Inflation Inflation_lag shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 1
est store Opened_Countries_L2

* Choc année t-3
xtabond2  Inflation Inflation_lag shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 1
est store Opened_Countries_L3


***Pays pas très ouverts
*Choc année t
xtabond2  Inflation Inflation_lag shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 0
est store Nonopened_Countries_L1

* Choc année t-1
xtabond2  Inflation Inflation_lag shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 0
est store Nonopened_Countries_L1

* Choc année t-2
xtabond2  Inflation Inflation_lag shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 0
est store Nonopened_Countries_L2

* Choc année t-3
xtabond2  Inflation Inflation_lag shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Ouvert == 0
est store Nonopened_Countries_L3




****NIVEAU DE REVENU 
* Faible revenu : GDPpc< 1146$ 
* Revenu intermédiaire inférieur : entre 1146 et 4516$
* Revenu intermédiaire supérieur : entre 4516$ and 14005$

gen Rev_Inf = 0

replace Rev_Inf =1 if GDP_pc < 4516

***Pays à revenu inférieur
*Choc année t
xtabond2  Inflation Inflation_lag shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 1
est store LowerIncome_Countries

* Choc année t-1
xtabond2  Inflation Inflation_lag shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 1
est store LowerIncome_Countries_L1

* Choc année t-2
xtabond2  Inflation Inflation_lag shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 1
est store LowerIncome_Countries_L2

* Choc année t-3
xtabond2  Inflation Inflation_lag shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 1
est store LowerIncome_Countries_L3


***Pays à revenu supérieur
*Choc année t
xtabond2  Inflation Inflation_lag shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 0
est store LowerIncome_Countries_L1

* Choc année t-1
xtabond2  Inflation Inflation_lag shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 0
est store LowerIncome_Countries_L1

* Choc année t-2
xtabond2  Inflation Inflation_lag shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 0
est store LowerIncome_Countries_L2

* Choc année t-3
xtabond2  Inflation Inflation_lag shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag  , lag(2 3) collapse ) iv( shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small if Rev_Inf == 0
est store LowerIncome_Countries_L3*/





*******************************CANAUX DE TRANSMISSION
*********************PRODUCTION ALIMENTAIRE / AGRICOLE (proxi importations )

gen AgriProd = Agriculture_mean/1000000
gen logAgrPr = log(AgriProd)

*****Effet des chocs sur la production agricole

xtreg AgriProd SPEI GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Agri_Choc 

xtreg AgriProd SPEI chocinf chocinf_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto AgriChocinf 

xtreg AgriProd SPEI chocsup chocsup_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto AgriChocsup 


*****Effet de la variabilité de la production sur l'inflation

xtreg Inflation SPEI AgriProd GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Infl_Agri_Choc

xtreg Inflation SPEI chocinf chocinf_multi AgriProd GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto InflAgriChocinf

xtreg Inflation SPEI chocsup chocsup_multi AgriProd GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto InflAgriChocsup


*********************PRODUCTION D'ENERGIE
******Effet des chocs sur la production énergétique

xtreg Ener_Prod SPEI GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Ener_Choc 

xtreg Ener_Prod SPEI chocsup chocsup_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Ener_Choc_sup

xtreg Ener_Prod SPEI chocinf chocinf_multi GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Ener_Choc_inf

******Effet sur la variabilité de la production énergétique 

xtreg Inflation SPEI Ener_Prod GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Infl_Ener_Choc

xtreg Inflation SPEI chocsup chocsup_multi Ener_Prod GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Infl_Ener_Choc_sup

xtreg Inflation SPEI chocinf chocinf_multi Ener_Prod GDP_growth money_lag REER Real_IR Debt_P_pc_pib, re robust
est sto Infl_Ener_Choc_inf


outreg2 [AgriChocinf InflAgriChocinf Ener_Choc Infl_Ener_Choc] using tab_resultheteo.tex, title("Canaux de transmission")  addtext(Year FE, Yes) bdec(3) sdec(3) replace drop (i.period)




******Effet conjoint de la consommation agricole et du choc 
xtabond2 Inflation Inflation_lag Imp_Agri_pct shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag, lag(2 3) collapse ) iv(Imp_Agri_pct shock_inf1 shock_inf1_spei shock_sup1 shock_sup1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small

xtabond2 Inflation Inflation_lag Imp_Agri_pct shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag, lag(2 3) collapse ) iv(Imp_Agri_pct shock_inf1_L1 shock_inf1_L1_spei shock_sup1_L1 shock_sup1_L1_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small

xtabond2 Inflation Inflation_lag Imp_Agri_pct shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag, lag(2 3) collapse ) iv(Imp_Agri_pct shock_inf1_L2 shock_inf1_L2_spei shock_sup1_L2 shock_sup1_L2_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small

xtabond2 Inflation Inflation_lag Imp_Agri_pct shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG,  gmm(Inflation_lag, lag(2 3) collapse ) iv(Imp_Agri_pct shock_inf1_L3 shock_inf1_L3_spei shock_sup1_L3 shock_sup1_L3_spei GDP_growth Real_IR money_lag Dependance REER Debt_PPG)  twostep robust small


****PRODUCTION/CONSOMMATION ENERGIE






*✅ Étapes pour générer les résidus après une régression panel (RE)
*1. Estimer ton modèle (si ce n'est pas encore fait) :
xtreg Inflation SPEI GDP_growth log_money_lag REER Real_IR log_Debt_P_pc_pib, re robust
   
 xtreg inflation SPEI gdp money_lag REER Real_IR Debt_P_pc_pib, re 
  
   
   
*2. Générer les résidus à partir du modèle estimé :
predict resid, e



*5.3.2 Test de normalité des résidus

sktest resid
histogram resid, normal
scatter inflation SPEI 
twoway (scatter inflation SPEI) (lfit inflation SPEI)