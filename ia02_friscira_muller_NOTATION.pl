%%%  %%%    %%%  %%%
%%%%%%%%%%%%%%%%%%%%
% NOTATION PLATEAU %
%%%%%%%%%%%%%%%%%%%%
%%%  %%%    %%%  %%%


%%%%%%%%%%%%%%%%%%%%%%%%%
% Structures de données %
%%%%%%%%%%%%%%%%%%%%%%%%%
% Voici quelques structures de données utilisées sur ce fichier.
%
% Plateau = [E,R,M,J] le plateau de jeu avec E et R des listes de pions de la forme [Position,Orientation], M une liste de montagnes avec juste leur position, et J un caractère 'e' ou 'r'.
%
% Coup = [Origine,Destination,OrientationDArrivee]
%
% Impact : une liste de coups. Quand on effectue un coup, on calcule une liste des mouvements résultants (de taille 1 à 5) qui est la liste des pions à bouger. Exemple:
% [ [Origine,Destination,OrientationDArrivee], [Origine,Destination,OrientationDArrivee], [Origine,Destination,OrientationDArrivee]] est un impact qui implique de déplacer 3 pions, par exemple dans le cas ou deux pions poussent une montagne.
%
% ListePoussee : une liste qui contient les pions présents dans une ligne/colonne de poussée. Pour chaque pion on donne sa position, sa contribution à la poussée et son orientation (utile par la suite pour calculer la position ([Case,Orientation]) de chaque pion après la poussée effectuée. Par contribution, on entend un symbole pris dans l'ensemble '+', '-', ' ','M' qui permet de signifier respectivement qu'un pion contribue positivement, négativement, aucunement ou est une montagne.
% Exemple de liste : [ [52,'+','s'], [42,' ','e'], [32,'+','s'], [22,'-','n'], [52,'M','M'] ] NB : une montagne n'a pas d'orientation !
%
%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%
% NOTER PLATEAU %
%%%%%%%%%%%%%%%%%
% noter_plateau(P,Note)
%
% Prédicat qui permet d'associer une note à un plateau. Cette note reflète l'avantage que représente ce plateau pour le joueur. Si la note est mauvaise, ce plateau n'est pas intéressant. En revanche, meilleure est la note, meilleur est le coup qui a permis d'y arriver.
% La note est composée de plusieurs sous notes que l'on somme. Chaque note évalue une stratégie (nombre de pions sur le plateau, poussées possibles, ...).
% Voici les quatre parties de la note :
% - N1 est évaluée selon qu'un joueur a gagné ou perdu (N1 peut prendre -1000/0/1000
% - N2 est une fonction qui tente d'optimiser le nombre de pions de mon joueur sur le plateau. En avoir 0 ou 1 n'est pas très bien. En avoir 5 n'est pas bien non plus car je n'ai plus de pion en réserve pour bloquer l'adversaire. Enfin, avoir 2, 3 ou 4 pions est une bonne chose.
% - N3 permet de connaître le nombre de poussées pour mon camp et pour le camp de l'adversaire. Chacune de ces poussées incrémente ou décrémente la note selon le camp avantagé.
% - N4 fonctionne un peu comme N3 si ce n'est qu'il va attribuer à chaque poussée une note qui est fonction de la distance restante à parcourir pour la montagne que l'on pousse (si on en pousse une bien sur). La note est positive ou négative selon le camp considéré.
% La somme de ces notes nous donne une note générale assez fiable pour évaluer un plateau.
%
% Arguments :
% - P (in) : Plateau de jeu
% - Note (out) : La note du plateau
%%%%%%%%%%%%%%%%%
noter_plateau([E,R,M,J],Note) :-
	un_vainqueur([E,R,M,J],N1),				% Si on a un vainqueur, on va avoir une note +/- 1000 ou 0 sinon
	des_pions_sur_le_plateau([E,R,M,J],N2),	% En fonction du nombre de pions sur la plateau de mon équipe
	orientation_visavis_montagnes([E,R,M,J],N3),	% Est ce qu'un camp peut pousser ? Permet de trouver l'équilibre des forces, un status quo, ...
	montagnes_en_poussee_proche_bord([E,R,M,J],N4), % Est ce que l'ennemi ou moi même pousse une montagne qui est proche du bord ? Permet de caractériser l'urgence d'une situation
	Note is N1 + N2*0.3 + N3 + N4*1.5 .	% En multipliant N2 par 0.3,  on atténue l'impact de la règle qui permet d'optimiser le nombre de pions.
%%%%%%%%%%%%%%%%%

	
%%%%%%%%%%%%%%%%
% UN VAINQUEUR %
%%%%%%%%%%%%%%%%
% un_vainqueur(P,Note)
%
% Associe une note fonction de l'état du plateau : si le joueur J gagne, la note est +1000, s'il perd, -1000. Si personne ne gagne, la note est 0.
%
% Arguments :
% - P (in) : Plateau de jeu
% - Note (out) : La note du plateau concernant notre critère (de victoire)
%%%%%%%%%%%%%%%%
un_vainqueur([E,R,M,J],1000) :-
	vainqueur([E,R,M,_],J), !.
	
un_vainqueur([E,R,M,J],-1000) :-
	vainqueur([E,R,M,_],V),
	V \= J, !.
	
un_vainqueur([_,_,_,_],0).
%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%	
% VAINQUEUR %
%%%%%%%%%%%%%
% vainqueur(P,Camp).
%
% Vainqueur est vrai si le second argument est le vainqueur de la partie. Pour ce faire, il vérifie si une montagne est hors du plateau. Si oui, il cherche qu'il l'a poussée et trouve l'équipe du pion en question.
%
% Arguments :
% - P (in) : Plateau de jeu
% - Camp (out) : Le camp du vainqueur ('e' ou 'r').
%%%%%%%%%%%%%
vainqueur([E,R,M,_], Vainqueur) :-
	montagne_hors_limite(M,Mont),	% Si une montagne est hors limite
	orientation_derniere_poussee(Mont,OrientationPoussee),	% dans quel sens allait on pour la sortir ?
	chercher_pousseur(E,R,OrientationPoussee,Mont,Pousseur),% quel est le pion le plus proche dans le bon sens ?
	equipe(E,R,Pousseur,Vainqueur).	% Qui est le possesseur de ce pion ?
%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ORIENTATION DERNIERE POUSSEE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% orientation_derniere_poussee(Case,Ori).
%
% Prédicat qui récupère l'orientation (e,o,s,n) qui a conduit à la sortie d'une montagne hors du terrain en utilisatn sa position actuelle.
%
% Arguments :
% - Case (in) : Case hors du plateau pour laquelle on veut l'orientation qui l'a conduit là
% - Ori (out) : L'orientation ayant conduit à cette sortie du plateau
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
orientation_derniere_poussee(Case,'e') :- Col is Case mod 10, Col > 5 .
orientation_derniere_poussee(Case,'o') :- Col is Case mod 10, Col < 1 .
orientation_derniere_poussee(Case,'n') :- Lig is Case // 10, Lig > 5 .
orientation_derniere_poussee(Case,'s') :- Lig is Case // 10, Lig < 1 .
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%
% CHERCHER POUSSEUR %
%%%%%%%%%%%%%%%%%%%%%
% chercher_pousseur(E,R,Orientation,Case,Out).
%
% Prédicat qui récupère le pion le plus proche d'une montagne sortie du terrain. Il récupère la case précédente, cherche si un pion était à cette position et bien orienté, si oui, c'est le pousseur, sinon on continue sur la case encore précédente.
%
% Arguments :
% - E (in) : La liste des éléphants du plateau 
% - R (in) : La liste des rhinos du plateau 
% - Orientation (in) : L'orientation de la poussée
% - Case (in) : La case finale de la poussée
% - Out (out) : Le numéro de case ou se trouve le pion le plus proche du bout de la poussée.
%%%%%%%%%%%%%%%%%%%%%
chercher_pousseur(E,R,Ori,Case,Out) :-
	case_precedente(Case,Prec,Ori),	% Prec reçoit la case d'avant
	case_dans_limites(Prec),		% Si hors limite, on est foutus
	member2([Prec,Ori],E,R),		% Un pion est il là et bien orienté ?
	!,	% Si on trouve un E ou un R dans la même direction et bien il est vainqueur !
	Out = Prec.
	
chercher_pousseur(E,R,Ori,Case,Out) :-
	case_precedente(Case,Prec,Ori),	% Prec reçoit la case d'avant
	case_dans_limites(Prec),		% Si prec hors limite, on a finit
	chercher_pousseur(E,R,Ori,Prec,Out).
%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%
% CASE DANS LIMITES %
%%%%%%%%%%%%%%%%%%%%%
% case_dans_limites(Case).
%
% Vérifie si une case est sur le plateau ou non en testant sa ligne et sa colonne.
%
% Arguments :
% - Case (in) : la case pour laquelle on veut savoir si elle est dans le plateau
%%%%%%%%%%%%%%%%%%%%%
case_dans_limites(Case) :- Col is Case mod 10, Col < 6, Col > 0, Lig is Case // 10, Lig > 0, Lig < 6 .
case_dans_limites(_) :- !, fail.
%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DES PIONS SUR LE PLATEAU %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% des_pions_sur_le_plateau(P,Note).
%
% Permet d'associer une note au nombre de pions de mon joueur sur le plateau. On considère que le nombre de pion sur le plateau est un facteur important : ne pas en avoir ou trop en avoir est gênant (si on a 5 pions sur le plateau, on ne pourra pas en rentrer un pour bloquer un mouvement ennemi). Avoir de 1 à 4 pions donne une note de plus en plus élevée.
%
% Arguments :
% - P (in) : Le plateau de jeu à noter
% - Note (out) : La note relative au critère (nombre de pions).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
des_pions_sur_le_plateau([E,_,_,'e'],-30) :-	nombre_pion_joueur_sur_plateau(E,0).
des_pions_sur_le_plateau([E,_,_,'e'],-15) :-	nombre_pion_joueur_sur_plateau(E,1).
des_pions_sur_le_plateau([E,_,_,'e'], 0) :-		nombre_pion_joueur_sur_plateau(E,2).
des_pions_sur_le_plateau([E,_,_,'e'], 10) :-	nombre_pion_joueur_sur_plateau(E,3).
des_pions_sur_le_plateau([E,_,_,'e'], 20) :-	nombre_pion_joueur_sur_plateau(E,4).
des_pions_sur_le_plateau([E,_,_,'e'],-10) :-	nombre_pion_joueur_sur_plateau(E,5).
des_pions_sur_le_plateau([_,R,_,'r'],-30) :-	nombre_pion_joueur_sur_plateau(R,0).
des_pions_sur_le_plateau([_,R,_,'r'],-15) :-	nombre_pion_joueur_sur_plateau(R,1).
des_pions_sur_le_plateau([_,R,_,'r'], 0) :-		nombre_pion_joueur_sur_plateau(R,2).
des_pions_sur_le_plateau([_,R,_,'r'], 10) :-	nombre_pion_joueur_sur_plateau(R,3).
des_pions_sur_le_plateau([_,R,_,'r'], 20) :-	nombre_pion_joueur_sur_plateau(R,4).
des_pions_sur_le_plateau([_,R,_,'r'],-10) :-	nombre_pion_joueur_sur_plateau(R,5).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOMBRE PION JOUEUR SUR PLATEAU %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% nombre_pion_joueur_sur_plateau(ListePions,Nombre).
%
% Calcule le nombre de pions sur le plateau. Utilise une liste d'un joueur et incrémente un compteur pour chaque pion qui n'est pas en 0.
%
% Arguments :
% - ListePions (in) : La liste des pions d'un joueur
% - Nombre (out) : nombre de pions sur le plateau
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nombre_pion_joueur_sur_plateau([],0).

nombre_pion_joueur_sur_plateau([[0,_]|Q],Nbr) :-	% Pion en 0, on incrémente pas.
	!, nombre_pion_joueur_sur_plateau(Q,Nbr).	% On cut pour ne pas tester la clause 3
	
nombre_pion_joueur_sur_plateau([[_,_]|Q],Nbr) :-	% Pion sur plateau, on incrémente.
	nombre_pion_joueur_sur_plateau(Q,NTmp),
	Nbr is NTmp +1 .
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ORIENTATION VIS A VIS MONTAGNES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% orientation_visavis_montagnes(P,Note)
%
% Associe une note à un plateau. La note reflète les possibilités de poussées pour un joueur et son ennemi. Par exemple, pour chacune des poussées que je peux faire, j'ai une note positive en plus. Pour chaque poussée que mon adversaire peut faire, ma note décroit.
% IMPORTANT : on tient compte ici du fait que deux pions de mon camp poussant une même montagne ne représentent qu'une poussée.
% Le prédicat utilise "findall" afin de générer les poussées. Son utilisation ici implique un terme assez complexe que voici :
% findall(LPions,(
% 	member([Ori,Sens],E),
% 	construire_liste_pions([E,R,M,J],LPions,Ori,Sens),
% 	length(LPions,A),
% 	A>1,
% 	calculer_force(LPions,0,0),
% 	derniere_montagne(LPions,Limite),
% 	chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'e')
% ),ListeE).
%
% Que fait il ? Il récupère les pions (Ori,Sens) du joueur E. Il construit la liste de poussée de chacun (un pion seul aura une liste composée de lui seul). On filtre ces listes pour ne garder que les listes de poussées de plus d'un élément (un pion pousse une montagne, un pion pousse un pion, une poussée complexe, etc.). Ensuite, on vérifie que la poussée est possible (en termes de force). Enfin, on récupère la montagne qui est en train d'être poussée et on filtre à nouveau nos poussées pour ne garder que celles du joueur demandé.
% En utilisant cet appel deux fois, on connaît les poussées de mon joueur et les poussées de mon ennemi.
% La suite du prédicat consiste à nettoyer ces listes pour ne garder que celles qui poussent une montagne (pousser un ennemi sans montagnes n'est pas jugé très intéressant), chaque poussée reçoit une note.*
%
% Arguments :
% - P (in) : Plateau de jeu.
% - Note (out) : Note pour le plateau, relative au critère (nombre de poussées possibles pour chaque camp).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
orientation_visavis_montagnes([E,R,M,'e'],Note) :-
	% Trouver tous les listes de poussée de mon joueur.
	findall(LPions,(
		member([Ori,Sens],E),
		construire_liste_pions([E,R,M,J],LPions,Ori,Sens),
		length(LPions,A),
		A>1,
		calculer_force(LPions,0,0),
		derniere_montagne(LPions,Limite),
		chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'e')
	),ListeE),
	% Trouver toutes les listes de poussée de mon ennemi
	findall(LPions,(member([Ori,Sens],R),construire_liste_pions([E,R,M,J],LPions,Ori,Sens),length(LPions,A),A>1,calculer_force(LPions,0,0),derniere_montagne(LPions,Limite),chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'r')),ListeR),
	
	% Eliminer les poussées identiques (par exemple deux pions l'un derrière l'autre poussant une montagne. Ex: "> > M" et "> M".
	eliminer_poussees_identiques(ListeR,[],ListeRBis),
	eliminer_poussees_identiques(ListeE,[],ListeEBis),
	
	% Trouver les notes pour chaque poussée de chaque liste
	findall(N1,(member(Liste,ListeRBis),noter_poussee_ennemi(Liste,N1)),LN1),
	findall(N2,(member(Liste,ListeEBis),noter_poussee_ami(Liste,N2)),LN2),
	
	sommer_notes(LN1,Note1),
	sommer_notes(LN2,Note2),	% Sommer les notes et donner la note générale.
	Note is Note1 + Note2 .
	
% Prédicat identique au précédent mais considérant un joueur rhinocéros ce qui inverse les notions d'ami et d'ennemi.
orientation_visavis_montagnes([E,R,M,'r'],Note) :-
	findall(LPions,(member([Ori,Sens],E),construire_liste_pions([E,R,M,J],LPions,Ori,Sens),length(LPions,A),A>1,calculer_force(LPions,0,0),derniere_montagne(LPions,Limite),chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'e')),ListeE),
	findall(LPions,(member([Ori,Sens],R),construire_liste_pions([E,R,M,J],LPions,Ori,Sens),length(LPions,A),A>1,calculer_force(LPions,0,0),derniere_montagne(LPions,Limite),chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'r')),ListeR),
	eliminer_poussees_identiques(ListeE,[],ListeEBis),
	eliminer_poussees_identiques(ListeR,[],ListeRBis),
	findall(N1,(member(Liste,ListeRBis),noter_poussee_ami(Liste,N1)),LN1),
	findall(N2,(member(Liste,ListeEBis),noter_poussee_ennemi(Liste,N2)),LN2),
	sommer_notes(LN1,Note1),
	sommer_notes(LN2,Note2),
	Note is Note1 + Note2 .
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%
% DERNIERE MONTAGNE %
%%%%%%%%%%%%%%%%%%%%%
% derniere_montagne(Liste,Case).
% 
% Récupère la position de la dernière montagne d'une poussée (la plus proche de sortir donc).
% Renverse la liste et récupère la première montagne trouvable.
%
% Arguments :
% - Liste (in) : Liste de poussée à analyser.
% - Case (out) : La position de la montagne la plus au bout de la poussée.
%%%%%%%%%%%%%%%%%%%%%
derniere_montagne(Liste,Case) :-
	reverse(Liste,L2),
	member([Case,'M','M'],L2).
%%%%%%%%%%%%%%%%%%%%%
	
	
%%%%%%%%%%%%%%%%%
% NOTER POUSSEE %
%%%%%%%%%%%%%%%%%
% noter_poussee_ami(Liste,Note).
% noter_poussee_ennemi(Liste,Note).
%
% Deux prédicats pour noter une poussée amie ou ennemie. On parcours la liste des poussées, et pour chaque poussée, si elle contient une montagne, on associe une note positive aux amies et une négative aux ennemies.
%
% Arguments :
% - Liste (in) : Liste de poussée à analyser.
% - Note (out) : Note pour la poussée (tient compte de la présence d'une montagne)
%%%%%%%%%%%%%%%%%
noter_poussee_ami(Liste,20) :-
	member([_,'M','M'],Liste), !.
noter_poussee_ami(_,0).

noter_poussee_ennemi(Liste,-20) :-
	member([_,'M','M'],Liste), !.
noter_poussee_ennemi(_,0).
%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%
% SOMMER NOTES %
%%%%%%%%%%%%%%%%
% sommer_notes(Notes,Somme).
%
% Permet de faire la somme des éléments d'une liste.
%
% Arguments :
% - Notes (in) : Liste de notes à sommer
% - Somme (out) : La somme des notes de la liste
%%%%%%%%%%%%%%%%
sommer_notes([],0).

sommer_notes([T|Q],Note) :-
	sommer_notes(Q,NT),
	Note is T+NT.
%%%%%%%%%%%%%%%%
	
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ELIMINER POUSSEES IDENTIQUES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% eliminer_poussees_identiques(Poussees, Destinations, Sortie).
%
% Permet de filtrer les poussées pour éviter d'avoir deux poussées différentes quand un joueur humain n'en considdèrerait qu'une seule.
% Ex : [[22,+,n],[32,'M','M']] et [[12,+,n],[22,+,n],[32,'M','M']] ne sont qu'une seule et même poussée.
% Test possible :
% L = [[[22,+,n],[32,'M','M']],[[12,+,n],[22,+,n],[32,'M','M']]], eliminer_poussees_identiques(L,[],L2).
%
% Arguments :
% - Poussees (in) : la liste des poussées à élaguer
% - Destinations (in) : doit valoir [] au premier appel, permet de stocker des résultats intermédiaires que sont la destination de chaque poussée afin de savoir quelles poussées élaguer.
% - Sortie (out) : la liste des poussées nettoyée de ses poussées similaires.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eliminer_poussees_identiques([],_,[]).	% Condition d'arrêt.

eliminer_poussees_identiques([T|Q],Destinations,Out) :-
	reverse(T,[Dest|_]),			% On inverse la liste de poussée pour connaitre sa destinatio
	member(Dest,Destinations), !,	% On vérifie que cette destination n'est pas déjà atteinte par une poussée jumelle, si oui, on cut pour ne pas aller tester la clause suivante.
	eliminer_poussees_identiques(Q,Destinations,Out).
	
eliminer_poussees_identiques([T|Q],Destinations,Out) :-
	reverse(T,[Dest|_]),			% Idem que clause 2
	DTmp = [Dest|Destinations],		% On construit une liste de destinations avec la précédente qui n'a pas encore été atteinte (cf la clause 2)
	eliminer_poussees_identiques(Q,DTmp,OTmp),
	Out = [T|OTmp].
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHERCHER CAMP POUSSEUR %
%%%%%%%%%%%%%%%%%%%%%%%%%%
% chercher_camp_pousseur(E,R,M,Origine,Orientation,Limite,Camp).
%
% Prédicat qui renvoit le camp qui serait gagnant dans une poussée. Il utilise un prédicat pour construire la liste de poussée et cherche le de camp du dernier pion bien orienté dans cette liste. 
%
% Arguments :
% - E (in) : la liste des pions de l'éléphant
% - R (in) : la liste des pions du rhino
% - M (in) : la liste des montagnes
% - Origine (in) : la position de départ de la poussée
% - Orientation (in) : l'orientation de la poussée (n,s,e,o).
% - Limite (in) : la case finale de la poussée
% - Camp (out) : le camp (e,r) du pion qui pousse réellement la montagne (le pion le plus au bout).
%%%%%%%%%%%%%%%%%%%%%%%%%%
chercher_camp_pousseur(E,R,M,Origine,Orientation,Limite,Camp) :-
	construire_liste_pousseurs(E,R,M,Origine,Orientation,Limite,L),
	reverse(L,[T2|_]),
	equipe(E,R,T2,Camp).
%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRUIRE LISTE POUSSEURS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% construire_liste_pousseurs(E,R,M,Origine,Orientation,Limite,Liste).
%
% Permet de consruire une liste contenant les positions de tous les pions bien orientés dans une poussée. Le prédicat connait le plateau, et la position d'arrivée, il revient en arrière pour analyser chaque pion sur la ligne/la colonne et ajoute à la liste de sortie les pions bien orientés, quelque soit leur camp.
%
% Arguments :
% - E (in) : la liste des pions de l'éléphant
% - R (in) : la liste des pions du rhino
% - M (in) : la liste des montagnes
% - Origine (in) : la position de départ de la poussée
% - Orientation (in) : l'orientation de la poussée (n,s,e,o).
% - Limite (in) : la case finale de la poussée
% - Liste (out) : la liste des pions sur la poussée et bien orientés (uniquement leur case)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
construire_liste_pousseurs(_,_,_,Limite,_,Limite,[]).	% Si on atteint la limite, on s'arrête.

construire_liste_pousseurs(E,R,M,Origine,_,_,[]) :-
	\+case_occupee([E,R,M,_],Origine), !.	% Si la case est non occupée, on arrête de parcourir la ligne/la colonne
	
construire_liste_pousseurs(_,_,_,Origine,_,_,[]) :-
	\+case_dans_limites(Origine), !.		% Si la case est hors limites, on a atteint la fin de la poussée qui débutait à l'autre bord du plateau.

construire_liste_pousseurs(E,R,M,Origine,Ori,Limite,Liste) :-
	case_suivante(Origine,Dest,Ori),		% On récupère la prochaine case
	construire_liste_pousseurs(E,R,M,Dest,Ori,Limite,LT),	% On construit la liste à partir de cette nouvelle case
	member2([Origine,Ori],E,R), !,			% Si le pion courant est bien orienté, on cut pour ne pas tester la clause 5 et on ajoute le pion à la liste
	Liste = [Origine|LT].
	
construire_liste_pousseurs(E,R,M,Origine,Ori,Limite,Liste) :-
	case_suivante(Origine,Dest,Ori),		% Sinon on est ici et on fait juste l'appel récursif.
	construire_liste_pousseurs(E,R,M,Dest,Ori,Limite,Liste).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	


%%%%%%%%%%%%%%%%
% CASE OCCUPEE %
%%%%%%%%%%%%%%%% 
% case_occupee(P,Case).
%
% Vérifie si une case est occupée sur le plateau. 
%
% Arguments :
% - P (in) : le plateau de jeu
% - Case (in) : la case pour laquelle on veut vérifier le prédicat.
%%%%%%%%%%%%%%%%
case_occupee([E,R,_,_],Case) :-	% Si la case est un éléphant ou un rhinocéros
	member2([Case,_],E,R), !.	% On cut pour ne pas tester les autres clauses
	
case_occupee([_,_,M,_],Case) :-	% Si la case est une montagne.
	member(Case,M), !.			% Idem
	
case_occupee([_,_,_,_],_) :- fail.	% Sinon, la case est libre, on renvoi faux.
%%%%%%%%%%%%%%%%





%%%%%%%%%%%%%%%%%%%
% DISTANCE REELLE %
%%%%%%%%%%%%%%%%%%%
% distance_pions(A,B,Distance).
%
% Donne la distance euclidienne entre deux cases.
%
% Arguments :
% - A (in) : la case A
% - B (in) : la case B
% - Distance (out) : la distance entre A et B
%%%%%%%%%%%%%%%%%%%
distance_pions(A,B,Dist) :-
	CA is A mod 10,
	LA is A // 10,
	CB is B mod 10,
	LB is B // 10,
	Dist is sqrt((CA-CB)*(CA-CB) + (LA-LB)*(LA-LB)).
%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%
% MIN LISTE %
%%%%%%%%%%%%%
% min_liste(Liste,Min).
% min_liste(Liste,Min0,Min).
%
% Permet de connaitre le minimum d'une liste. Utilise le prédicat natif min pour la comparaison.
%
% Arguments :
% - Liste (in) : la liste de laquelle on veut le maximum
% - Min (out) : le minimum retourné
% - Min0 (out) : le minimum temporaire, qui est utilisé à chaque descente d'un cran dans la récursion : on passe le minimum de la liste jusqu'à l'élément courant.
%%%%%%%%%%%%%
min_liste([T|Q], Min) :-
    min_liste(Q, T, Min).

min_liste([], Min, Min).

min_liste([T|Q], Min0, Min) :-
    Min1 is min(T, Min0),
    min_liste(Q, Min1, Min).
%%%%%%%%%%%%%


%%%%%%%%%%%%%
% MAX LISTE %
%%%%%%%%%%%%%
% max_liste(Liste,Max).
% max_liste(Liste,Max0,Max).
%
% Comme min_liste mais pour connaitre le maximum
%
% Arguments :
% - Liste (in) : la liste de laquelle on veut le maximum
% - Max (out) : le maximum retourné
% - Max0 (out) : le maximum temporaire, qui est utilisé à chaque descente d'un cran dans la récursion : on passe le maximum de la liste jusqu'à l'élément courant.
%%%%%%%%%%%%%
max_liste([T|Q], Max) :-
    max_liste(Q, T, Max).

max_liste([], Max, Max).

max_liste([T|Q], Max0, Max) :-
    Max1 is max(T, Max0),
    max_liste(Q, Max1, Max).
%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DISTANCE BORD SELON ORIENTATION %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% distance_bord_selon_orientation(Case,Orientation,Distance).
%
% Permet de connaitre le nombre de cases restante entre un pion et le bord vers lequel il est orienté. Permet par exemple de savoir dans combien de mouvements une motagne sera au bord du plateau telle qu'on la pousse maintenant.
%
% Arguments :
% - Case (in) : la position de la case pour laquelle on veut la distance au bord
% - Orientation (in) : la direction dans laquelle on va
% - Distance (out) : la distance de la case au bord selon l'orientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
distance_bord_selon_orientation(Case,Orientation,Dist) :-
	case_dans_limites(Case), !,
	case_suivante(Case,Destination,Orientation),
	distance_bord_selon_orientation(Destination,Orientation,DTemp),
	Dist is DTemp + 1 .
	
distance_bord_selon_orientation(_,_,-1).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MONTAGNES EN POUSSEE PROCHE BORD %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% montagnes_en_poussee_proche_bord(P,Note).
%
% Derrière ce prédicat au nom étrange se trouve un mécanisme fort utile ! Le but général est d'associer une note à un plateau en tenant compte de la distance restante à chaque montagne en train d'être poussée pour atteindre le bord. Le prédicat utilise des mécanismes semblables à orientation_visavis_montagnes() si ce n'est qu'il diffère sur la façon de comptabiliser. Une fois les poussées trouvées, chacune reçoit une note qui est fonction de la distance restante à parcourir.
% Ainsi, un ennemi poussant une montagne presqu'au bord du plateau va baisser note note considérablement. Un pion ami poussant une montagne loin du bord n'augmentera que peu notre note.
%
% Arguments :
% - P (in) : le plateau de jeu
% - Note (out) : la note associée selon le critère (proximité des montagnes en cours de poussée du bord)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
montagnes_en_poussee_proche_bord([E,R,M,'e'],Note) :-	% Clause pour les éléphants
	% On récupère les distances restantes pour chaque poussée de mon camp.
	findall(Out,(member([Ori,Sens],E),
		construire_liste_pions([E,R,M,J],LPions,Ori,Sens),
		length(LPions,A),
		A>1,
		calculer_force(LPions,0,0),
		derniere_montagne(LPions,Limite),
		chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'e'),
		member([Case,'M','M'],LPions),
		distance_bord_selon_orientation(Case,Sens,Out)),ListeE),% ListeE de la forme [1,2], on cherche une note qui valorise le fait d'avoir des courtes distances (genre 1 ou 2)
	% On note chaque poussée et on met le tout dans une note
	ponderer_notes_poussee_montagne(ListeE,NoteE),
	
	% On récupère les distances restantes pour chaque poussée de l'autre camp.
	findall(Out,(member([Ori,Sens],R),
		construire_liste_pions([E,R,M,J],LPions,Ori,Sens),
		length(LPions,A),
		A>1,
		calculer_force(LPions,0,0),derniere_montagne(LPions,Limite),
		chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'r'),
		member([Case,'M','M'],LPions),
		distance_bord_selon_orientation(Case,Sens,Out)),ListeR),
			
	% On note le tout
	ponderer_notes_poussee_montagne(ListeR,NoteR),
	
	% On fait la différence des notes.
	Note is NoteE - NoteR.
	
% Même prédicat pour l'autre camp, change uniquement la façon dont chaque note est pondérée.
montagnes_en_poussee_proche_bord([E,R,M,'r'],Note) :-
	findall(Out,(member([Ori,Sens],R),
			construire_liste_pions([E,R,M,J],LPions,Ori,Sens),
			length(LPions,A),
			A>1,
			calculer_force(LPions,0,0),
			derniere_montagne(LPions,Limite),
			chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'r'),
			member([Case,'M','M'],LPions),
			distance_bord_selon_orientation(Case,Sens,Out)),ListeR),% ListeE de la forme [1,2], on cherche une note qui valorise le fait d'avoir des courtes distances (genre 1 ou 2)
	ponderer_notes_poussee_montagne(ListeR,NoteR),
	findall(Out,(member([Ori,Sens],E),
			construire_liste_pions([E,R,M,J],LPions,Ori,Sens),
			length(LPions,A),
			A>1,
			calculer_force(LPions,0,0),
			derniere_montagne(LPions,Limite),
			chercher_camp_pousseur(E,R,M,Ori,Sens,Limite,'e'),
			member([Case,'M','M'],LPions),
			distance_bord_selon_orientation(Case,Sens,Out)),ListeE),
	ponderer_notes_poussee_montagne(ListeE,NoteE),
	Note is NoteR - NoteE.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PONDERER NOTES POUSSEE MONTAGNE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ponderer_notes_poussee_montagne(ListeD,Note).
%
% Permet d'associer une note à une liste de poussée. Pour ce faire, on utilise en entrée une liste contenant la distance restante pour chaque poussée.
% Si la distance est nulle, la note est 15 pour cette poussée. Sinon, la note est de 1/D²*20 avec D la distance. Le prédicat renvoi la somme de ces notes.
%
% Arguments :
% - ListeD (in) : la liste des distances à noter
% - Note (out) : la note associée.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ponderer_notes_poussee_montagne([],0).

ponderer_notes_poussee_montagne([0|_],20) :- !.

ponderer_notes_poussee_montagne([T|Q],Note) :-
	ponderer_notes_poussee_montagne(Q,NTemp),
	NCurr is 1 / T / T * 15,
	Note is NTemp + NCurr.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

