#La bonne execution du Script necessite l'installation et l'importation des packages situés dans la partie 'LIBRARY'
#
#
#
##################      LIBRARY     #############################################
library(data.table)
library(caret)
#library(ggbiplot)
#library(dplyr)
library(randomForest)
library(factoextra)
library(FactoMineR)
############   Importation des données et nettoyage de la Table #################################
dragon_table = read.csv('./Edragon_results_NH.csv', header = TRUE, sep ="\t") #Importe la table entière d'E-dragon (sans l'en-tête)
new_table = dragon_table[complete.cases(dragon_table[,]),] #Table sans lignes avec des cases vides ( sans composés où il manque de l'info)
variance = sapply(new_table,sd) #Calcul d'un vecteur variance pour chacun des descripteurs
numb_col_del=which(variance %in% 0) #Calcul d'un vecteur numero de colonne qui ont une variance nulle 
new_tablesd0=new_table[,-numb_col_del] #Table sans les descripteurs qui ont variance = 0 

#### Separation des 2 premieres colonnes du reste des descripteurs (Mol ID et Formule brute)####
table_valuesSD0=new_tablesd0[,3:length(new_tablesd0)]
col2=new_tablesd0[,1:2]

#### Calculs et representations Lipinski ####
##### Poids moléculaire #####
h=hist(table_valuesSD0[,"MW"], nclass = 8, ylab = "Nombre de molécules", xlab = "Poids Moléculaire (g/mol)", main = "Histogramme représentant la distribution du Poids Moléculaire")
xfit<-seq(min(table_valuesSD0[,"MW"]),max(table_valuesSD0[,"MW"]),length=40) 
yfit<-dnorm(xfit,mean=mean(table_valuesSD0[,"MW"]),sd=sd(table_valuesSD0[,"MW"])) 
yfit <- yfit*diff(h$mids[1:2])*length(table_valuesSD0[,"MW"]) 
lines(xfit, yfit, col="blue", lwd=2)


##### Log P #####
ALOGP=(table_valuesSD0[,"ALOGP"])
h=hist(ALOGP, ylab = "Nombre de molécules", xlab = "Log P", main = "Histogramme représentant la distribution du Log P", breaks = c(0:15))


##### H Donor #####
barplot(table(table_valuesSD0$nHDon), width= 0.2,xlim = c(0,1), yaxp = c(0,25,25), ylab = "Nombre de molécules", xlab = "Nombre d'atomes donneurs d'hydrogène", main = "Distribution du nombre d'atomes donneurs d'hydrogène")



##### H ACC #####
#hist(table_valuesSD0$nHAcc, nclass = 16, xaxp = c(0, 20, 20), ylab = "Nombre de molécules", xlab = "Nombre d'atomes accepteurs d'hydrogène", main = "Histogramme représentant la distribution du nombre d'atomes \n accepteurs d'hydrogène")
#barplot(table(table_valuesSD0$nHAcc), yaxp = c(0,16,16), xlab = "Nombre d'atomes accepteurs d'hydrogène", ylab="Nombre de molécules", main = "Nombre de molécules en fonction du \n nombre d'atomes accepteurs d'hydrogène")
qplot(table_valuesSD0$nHAcc,binwidth=0.2,xlab = "Nombre d'atomes accepteurs d'hydrogène", ylab="Nombre de molécules", main = "Distribution du nombre d'atomes accepteurs d'hydrogène") + scale_x_continuous(breaks = c(0:20)) + theme(plot.title = element_text(hjust = 0.5)) + scale_y_continuous(breaks = c(0:20))




#### Normalise les donnees numeriques ####
scaled_1=as.data.frame(scale(table_valuesSD0)) #Normalise les donnees numeriques
#normtable=cbind(col2, scaled_1)
#install.packages("caret")
#library(caret)


#### Calcul de la matrice de correlation et filtre les descripteurs corrélés ####
matricecorrelation=cor(scaled_1)
DescrCorreles = findCorrelation(matricecorrelation, cutoff = 0.95)
tableP = scaled_1[,-DescrCorreles] #Tables des valeurs, apres nettoyage des donn?es,  sans les 2 premi?res colonnes (col2)


#### Calcul de l'ACP ####
pca_result = (prcomp(tableP)) #Calcul d'ACP


###############   Cercle de corrélation    ###############
fviz_pca_var(pca_result, col.var = "black")

##########################################################
#install.packages("devtools")
#library(devtools)
#install_github("vqv/ggbiplot")
#library(ggbiplot) INSTALLATION DE PACKAGE ETC


##### Renomme les lignes par les noms de molecules pour pouvoir les avoir dans le graphe ####
#On peut comme moi creer un vecteur comportant le nom des categories correspondantes dans le eme ordre d'apparition des molecules
names_mol = c("Aldrin","Chlordane","Dichlorodiphenyltrichloroethane ","Dieldrin","Endrin","Heptachlor","Hexachlorobenzene","Mirex","Toxaphene","2,2'-Dichlorobiphenyl","2,2',3,4',5,5',6-Heptachloro-1,1'-biphenyl","2,2',4,4',5,5'-Hexachlorobiphenyl","2,3,7,8-Tetrachlorodibenzodioxin","alpha-1,2,3,4,5,6-Hexachlorocyclohexane ","beta-Hexachlorocyclohexane ","Chlordecone (Kepone)","1,1'-Oxybis[2,3,4,5,6-pentabromobenzene] ","1,2,5,6,9,10-Hexabromocyclododecane ","2,2',4,4',5,5'-Hexabromodiphenyl ether","Hexachloro-1,3-butadiene","Lindane","Pentachlorobenzene","Pentachlorophenol","Perfluorooctanesulfonic acid","Chlorinated paraffins:C12, 60% chlorine","Endosulfan I","2,2',4,4'-Tetrabromodiphenyl ether","2,2',4,4',5-Pentabromodiphenyl ether","1-Chloronaphthalene")
row.names(tableP)=names_mol
#On aurait également pu importer le fichier qui contient la colonne avec les noms et l'écrire dans une variable en temps que vecteur etc...



#### Création du vecteur Class (categorie) ####
#De la meme maniere que precedemment soit un vecteur soit a partir d'une table
V_class = c("Pesticide","Pesticide","Pesticide","Pesticide","Pesticide","Pesticide","PIU","Pesticide","Pesticide","IU","IU","IU","Unintentional","Pesticide","Pesticide","Pesticide","Industrial","Industrial","Industrial","IU","Pesticide","PIU","Pesticide","PIU","Industrial","Pesticide","Industrial","Industrial","Unintentional")
tableP2_class = cbind(V_class,tableP)  


#### Représentation Graphique de l'ACP 1 ####
fviz_pca_ind(pca_result,
             geom.ind = c("point"), # Montre les points seulement (mais pas le "text")
             col.ind = V_class, # colorer by groups
             palette = c("#D3D600", "#00AFBB",  "#49FF00", "#FC4E07", "#FF00CD", "#26A97D"), #couleur des groupes
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups",
             repel = T 
)

############################
#####################
# GENETIC ALGORITHM #
#####################
################  Creation de la variable ctrl avec methode cross validation et focntion  #####
ctrl = gafsControl(functions = rfGA, method = "cv", number = 3, verbose = TRUE)

#### Execution Genetic algorihm. *Attention cette étape peut être assez longue suivant les paramètres indiqués* ####
set.seed(2019) # Regle le phénomène aléatoire pour la  reproductibilité des résultats
rf_search2 = caret::gafs(tableP2_class[,-1], tableP2_class[,1], iters = 600, gafsControl = ctrl) #Execute l'algorithme
##### Affichage et Selection des meilleurs descripteurs #####
rf_search$optVariables
Descr_GA=rf_search$optVariables #Variable contenant un vecteur avec le nom de tous ldes descripteurs selectionnés
table_after_GA=tableP[,Descr_GA] #création d'une nouvelle table avec les descripteurs sélectionnés uniquement

##################################
######  ACP 2 Genetic Algo  ######
##################################
#Calcul
pca_result_GA = (prcomp(table_after_GA)) #Calcul d'ACP 2 sur Best Descr GA
#Plot
fviz_pca_ind(pca_result_GA,
             geom.ind = c("point"), # Montre les points seulement (mais pas le "text")
             col.ind = V_class, # colorer by groups
             palette = c("#D3D600", "#00AFBB",  "#49FF00", "#FC4E07", "#FF00CD", "#26A97D"),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups",
             repel = T 
)
#################################################
#################################################
#################################################
########     RANDOM FOREST IMPORTANCE   #########
#################################################
#################################################
ntree.val = 600 #Nombre d'arbres
mtry.val = sqrt(length(tableP))  # Pour ajuster ntree on prend au debut racine carree du nombre de var et on ajuste en fonction de l'erreur OOB la valeur de ntree. 
set.seed(2019) #Regle un phénomène d'aléatoire pour pouvoir avoir des résultats reproductibles
fit.RF = randomForest(tableP2_class[,1] ~ . , data = tableP, ntree = ntree.val, mtry = mtry.val) #Execution Random Forest

#Plot de l'erreur OOB pour être sûr de ntree.val
plot(fit.RF$err.rate[, 1], type = "l", xlab = "Nombre d'arbres", ylab = "Erreur OOB", main="Erreur Out Of Bag (OOB) en fonction du \n nombre d'arbres")

#Creation variable meilleur descripteur classé par ordre décroissant selon MeanDecreaseGini
fit.des = as.matrix(sort(fit.RF$importance[,"MeanDecreaseGini"],decreasing = T))

#Représentation croissante/decroissante des meilleurs descripteurs 
barplot(fit.des[1 :150,], las = 2)
varImpPlot(fit.RF)

plot(fit.des, xlab="Rang du descripteur", ylab="MeanDecreaseGini", xaxp=c(0,600,12), ylim= c(0,0.3), type="l", main = "Importance des Descripteurs")
plot(fit.des, xlab="Rang du descripteur", ylab="MeanDecreaseGini", xaxp=c(0,100,10), xlim =c(0,100), ylim= c(0,0.3), type="l", main = "Importance des Descripteurs")

top10desRF = rownames(fit.des)[1:10]
table_top10RF = tableP[,top10desRF]

pca_result_top10RF = (prcomp(table_top10RF))#Calcul d'ACP 2 sur Best Descr RF

#### Calcul plot variances cumulees  ####
Var_table=data.frame(a=1:80,b=1:80)
for(i in 1:80) {
  topdesRFloop = rownames(fit.des)[1:i]
  table_topRFloop = tableP[,topdesRFloop]
  pca_result_topRFloop = (prcomp(table_topRFloop))
  varcumulloop = as.numeric(get_eigenvalue(pca_result_topRFloop)[2,3])
  Var_table[i,] = c(i, as.numeric(varcumulloop))
  
}
Var_table=transform(Var_table[5:80,], a=as.numeric(a), b= (as.numeric(b)))
plot(Var_table$a,Var_table$b, ylab="Variance cumulée PC1 + PC2 (%)", xlab = "TOP n° ", main = "Variance cumulée en fonction des descripteurs choisis après Random Forest", type="l", lab= c(30,10,0) )
abline(v = 11, col='blue')
#### PLOT ACP GA####
fviz_pca_ind(pca_result_top10RF,
             axes = c(1,2),
             geom.ind = c("point"), # Montre les points seulement (mais pas le "text")
             col.ind = V_class, # colorer by groups
             palette = c("#D3D600", "#00AFBB",  "#49FF00", "#FC4E07", "#FF00CD", "#26A97D"),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups",
             repel = F 
)

#### ACP FINAL RF ####
final_des = rownames(fit.des)[1:11]
finaltable = tableP[,final_des]

final_pca = (prcomp(finaltable))#Calcul d'ACP 2 sur Best Descr RF
fviz_pca_ind(final_pca,
             axes = c(1,2),
             geom.ind = c("point"), # Montre les points seulement (mais pas le "text")
             col.ind = V_class, # colorer by groups
             palette = c("#D3D600", "#00AFBB",  "#49FF00", "#FC4E07", "#FF00CD", "#26A97D"),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups",
             repel = F
)
##### Random Forest After Genetic Algo #####
table_after_GA_class= cbind(V_class, table_after_GA)
ntree.val_2 = 600
mtry.val_2 = sqrt(length(table_after_GA))  # Pour ajuster ntree on prend au debut racine carr?ee du nombre de var 
set.seed(2019)
fit.RFafterGA = randomForest(table_after_GA_class[,1] ~ . , data = table_after_GA, ntree = ntree.val_2, mtry = mtry.val_2)
plot(fit.RFafterGA$err.rate[, 1], type = "l", xlab = "Nombre d'arbres", ylab = "Erreur OOB", main="Erreur Out Of Bag (OOB) en fonction du \n nombre d'arbres")
fit.des_afterGA = as.matrix(sort(fit.RFafterGA$importance[,"MeanDecreaseGini"],decreasing = T))

barplot(fit.des_afterGA[1 :150,], las = 2)

varImpPlot(fit.RFafterGA) #Plot des descr les plus importants selon leur MeanDecrease Gini de manière croissante
## Plot mais cette fois de manière décroissante
plot(fit.des_afterGA, xlab="Rang du descripteur", ylab="MeanDecreaseGini", xaxp=c(0,300,6), ylim= c(0,0.5), type="l", main = "Importance des Descripteurs")
plot(fit.des_afterGA, xlab="Rang du descripteur", ylab="MeanDecreaseGini", xaxp=c(0,100,10), xlim =c(0,100), ylim= c(0,0.5), type="b", main = "Importance des Descripteurs")
##### ACP 2 sur Meilleur descr GA puis RF #####
top10desRF_GA = rownames(fit.des_afterGA)[1:10]
table_top10RF_GA = table_after_GA[,top10desRF_GA]

pca_result_top10RF_GA = (prcomp(table_top10RF_GA))#Calcul d'ACP 2 sur Best Descr RF(top10)

fviz_pca_ind(pca_result_top10RF_GA,
             axes = c(1,2),
             geom.ind = c("point"), # Montre les points seulement (mais pas le "text")
             col.ind = V_class, # colorer by groups
             palette = c("#D3D600", "#00AFBB",  "#49FF00", "#FC4E07", "#FF00CD", "#26A97D"),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups",
             repel = F 
)
##### Variance cumulées
Var_table=data.frame(a=1:length(fit.des_afterGA),b=1:length(fit.des_afterGA))
for(i in 1:length(fit.des_afterGA)) {
  topdesRFloop = rownames(fit.des_afterGA)[1:i]
  table_topRFloop = table_after_GA[,topdesRFloop]
  pca_result_topRFloop = (prcomp(table_topRFloop))
  varcumulloop = as.numeric(get_eigenvalue(pca_result_topRFloop)[2,3])
  Var_table[i,] = c(i, as.numeric(varcumulloop))
  
}
Var_table=transform(Var_table, a=as.numeric(a), b= (as.numeric(b)))
plot(Var_table$a,Var_table$b, ylab="Variance cumulée PC1 + PC2 (%)", xlab = "TOP n° ", main = "Variance cumulée en fonction des descripteurs choisis \n après Genetic Algorithm puis Random Forest", type="l", lab= c(40,10,0) )

##### Classement descripteurs selon top GA ####
varss = sort(table(unlist(rf_search$resampled_vars)), decreasing = TRUE)
smallVars = varss[1:10]
smallVars <- round(smallVars/length(rf_search$control$index)*100, 1)
varText <- paste0(names(smallVars), " (", smallVars, "%)")
varText <- paste(varText, collapse = ", ")
selectedGA_Vars= names(smallVars)

table_selectedGA_Vars = tableP[,selectedGA_Vars]

pca_result_selectedGA = (prcomp(table_selectedGA_Vars))#Calcul d'ACP 2 sur Best Descr RF(top10)

fviz_pca_ind(pca_result_selectedGA,
             axes = c(1,2),
             geom.ind = c("point"), # Montre les points seulement (mais pas le "text")
             col.ind = V_class, # colorer by groups
             palette = c("#D3D600", "#00AFBB",  "#49FF00", "#FC4E07", "#FF00CD", "#26A97D"),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups",
             repel = F 
)
##### Classement desc selon top GA ( fit$importance mean decrease Gini) #####
top_10_GA_fit = rownames(as.matrix(sort(rf_search$fit$importance[,"MeanDecreaseGini"],decreasing = T)))[1:10]
table_top_10_GA_fit = tableP[,top_10_GA_fit]
pca_result_top_10_GA_fit = (prcomp(table_top_10_GA_fit))#Calcul d'ACP 2 sur Best Descr GA via fit importance 
fviz_pca_ind(pca_result_top_10_GA_fit,
             axes = c(1,2), 
             geom.ind = c("point"), # Montre les points seulement (mais pas le "text")
             col.ind = V_class, # colorer by groups
             palette = c("#D3D600", "#00AFBB",  "#49FF00", "#FC4E07", "#FF00CD", "#26A97D"),
             addEllipses = TRUE, # Ellipses de concentration
             legend.title = "Groups",
             repel = F 
)
fviz_pca_ind()
