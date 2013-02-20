%%%%   %%%   %%%   %%%   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INTELLIGENCE ARTIFICIELLE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   %%%   %%%   %%%   %%%%

% Ce fichier contient les pr�dicats permettant de construire les coups possibles pour l'IA.
% Le principe g�n�ral est de g�n�rer une liste de coups potentiels, puis d'�laguer cette liste.

%%%%%%%%%%%%%%%%%%%%%%%%%
% Structures de donn�es %
%%%%%%%%%%%%%%%%%%%%%%%%%
% Voici quelques structures de donn�es utilis�es sur ce fichier.
%
% Plateau = [E,R,M,J] le plateau de jeu avec E et R des listes de pions de la forme [Position,Orientation], M une liste de montagnes avec juste leur position, et J un caract�re 'e' ou 'r'.
%
% Coup = [Origine,Destination,OrientationDArrivee]
%
% Impact : une liste de coups. Quand on effectue un coup, on calcule une liste des mouvements r�sultants (de taille 1 � 5) qui est la liste des pions � bouger. Exemple:
% [ [Origine,Destination,OrientationDArrivee], [Origine,Destination,OrientationDArrivee], [Origine,Destination,OrientationDArrivee]] est un impact qui implique de d�placer 3 pions, par exemple dans le cas ou deux pions poussent une montagne.
%
% ListePoussee : une liste qui contient les pions pr�sents dans une ligne/colonne de pouss�e. Pour chaque pion on donne sa position, sa contribution � la pouss�e et son orientation (utile par la suite pour calculer la position ([Case,Orientation]) de chaque pion apr�s la pouss�e effectu�e. Par contribution, on entend un symbole pris dans l'ensemble '+', '-', ' ','M' qui permet de signifier respectivement qu'un pion contribue positivement, n�gativement, aucunement ou est une montagne.
% Exemple de liste : [ [52,'+','s'], [42,' ','e'], [32,'+','s'], [22,'-','n'], [52,'M','M'] ] NB : une montagne n'a pas d'orientation !
%
%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%
% COUPS POSSIBLES %%%
%%%%%%%%%%%%%%%%%%%%%
% coups_possible(P,ListeCoups,ListePlateaux)
% 
% Pr�dicat qui liste tous les coups possibles jouables et les plateaux r�sultants de l'application de ces coups.
% Plus en d�tails : le pr�dicat liste les coups potentiels (d�placement de chaque pion dans chaque (direction,orientation), entr�e ou sortie du plateau. Il supprime ensuite les coups inutiles dans cet ensemble (orientations inutiles, etc.) puis filtre le tout pour n'obtenir que les coups possibles (pouss�e possible, etc.).
% Enfin, il calcule les plateaux r�sultants de chaque coup.
%
% Arguments :
% - P (in) : le plateau de jeu
% - ListeCoups (out) : une liste de couples (A,B) ou A est un coup � jouer de la forme [Origine,Destination,Orientation] et B un impact c'est � dire une suite de mouvements � appliquer pour jouer le coup de la forme [[Ori1,Dest1,Sens1],[Ori2,Dest2,Sens2],[Ori3,Dest3,Sens3]].
% - ListePlateaux (out) : Une liste des plateaux r�sultants de l'application de chacun des coups possibles pr�c�demment calcul�s.
%%%%%%%%%%%%%%%%%%%%%
coups_possible([E,R,M,'e'],L,L2) :-
	coups_potentiels_joueur(E,Liste),				% tous les coups potentiels
	reduire_coups_possibles([E,R,M,'e'],Liste,ListeOptimisee),	% r�duction pour ne garder que ceux utiles
	findall((Coups,Impacts),(member(Coups,ListeOptimisee),coup_possible([E,R,M,'e'],Coups,Impacts)),L),	% filtrage pour garder ceux qui sont possibles
	extraire_impacts(L,Imp),						% On se fait une liste avec juste les impacts pour traitement suivant
	findall(Plateau,(member(I,Imp),appliquer_coup([E,R,M,'e'],I,Plateau)),L2).	% r�cup�ration de tous les plateaux gr�ce aux impacts extraits pr�c�demment
	
coups_possible([E,R,M,'r'],L,L2) :-		% Version pour les rhino, change uniquement le passage de param�tres � coups_potentiels.				
	coups_potentiels_joueur(R,Liste),
	reduire_coups_possibles([E,R,M,'r'],Liste,ListeOptimisee),
	findall((Coups,Impacts),(member(Coups,ListeOptimisee),coup_possible([E,R,M,'r'],Coups,Impacts)),L),
	extraire_impacts(L,Imp),
	findall(Plateau,(member(I,Imp),appliquer_coup([E,R,M,'r'],I,Plateau)),L2).
%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%
% EXTRAIRE IMPACTS %
%%%%%%%%%%%%%%%%%%%%
% extraire_impacts(Lin,Lout).
%
% Simple fonction qui permet d'extraire d'une liste (Coup,Impact) uniquement les impacts.
% Permet au pr�dicat coups_possible de se construire une liste des impacts contenus dans les doublons (A,B).
%
% Arguments :
% - Lin (in) : la liste d'entr�e de la forme (A,B) par exemple avec A un Coup et B un impact
% - Lout (out) : la liste de sortie qui contient tous les B de la liste Lin
%%%%%%%%%%%%%%%%%%%%
extraire_impacts([],[]).
extraire_impacts([(_,I)|Q],[I|Q2]) :-
	extraire_impacts(Q,Q2).
%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REDUIRE COUPS POSSIBLES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reduire_coups_possibles(P,Lin,Lout).
%
% Fonction d'�lagage, utilis�e pour analyser une liste de coups potentiels et n'en conserver que ceux utiles. Si on arrive � �laguer nos coups, on diminue le nombre de plateaux � tester par la suite !
% On peut par exemple supprimer des pseudo-doublons : si je vais de A en B, j'ai 4 coups possibles selon l'orientation d'arriv�e. Si ma case d'arriv�e n'est entour�e d'aucun pion, alors j'ignore trois des quatre orentations possibles.
% Je supprime �galement les rotations sur moi m�me qui ne seraient pas utiles (car elles n'affectent d'aucune mani�re le jeu) si personne ne m'entoure.
%
% Arguments :
% - P (in) : Plateau de jeu
% - Lin (in) : Liste de coups potentiels
% - Lout (out) : Liste de coups �lagu�e pour ne conserver que les coups int�ressants.
%%%%%%%%%%%%%%%%%%%%%%%%%%%
reduire_coups_possibles(P,ListeIn,ListeOut) :-
	sans_doublon(ListeIn,L1),		% Enlever les doublons de la liste (doublons dus aux pions entrant sur le plateau du type [0,_,_])
	sortie_plateau_doublons(L1,L2), % Quand on sort du plateau, on ne laisse qu'un coup possible: [Case,0,_], on sen fiche de lorientation de sortie.
	supprimer_rotations_inutiles(P,L2,L3),	% On supprime parmi les rotations sur place celles qui sont jug�es inutiles
	supprimer_orientations_inutiles(P,L3,L4),	% On supprime des mouvements identiques aux orientations inutiles (entr�e sur le plateau en d�but de partie).
	sans_doublon(L4,ListeOut).	% On retire encore des doublons g�n�r�s "volontairement" � la suppression des orientations inutiles.
%%%%%%%%%%%%%%%%%%%%%%		


%%%%%%%%%%%%%%%%
% SANS DOUBLON %
%%%%%%%%%%%%%%%%
% sans_doublon(Lin,Lout)
%
% Fonction de suppression des doublons dans la liste des coups envisag�s. Des doublons sont produits sur les sorties de plateau notamment.
%
% Arguments :
% - Lin (in) : Liste d'entr�e de coups de la forme [Ori,Dest,Sens]
% - Lout (out) : Liste vid�e des mouvements identiques
%%%%%%%%%%%%%%%%
sans_doublon([],[]).
sans_doublon([X|L],R):- member(X,L),sans_doublon(L,R).
sans_doublon([X|L],[X|R]):- \+member(X,L),sans_doublon(L,R).
%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SORTIE PLATEAU DOUBLONS %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% sortie_plateau_doublons(Lin,Lout).
%
% Fonction qui va g�rer le cas d'un pion qui sort du plateau, dans ce cas, on enl�ve tous les pions avec la m�me origine et la destination 0 sauf un car quand on sort du plateau, on s'en fiche de donner une orientation au pion.
% Ainsi, la liste [11,0,n],[11,0,e],[11,0,o],[11,0,s] doit donner: [11,0,s] 
%
% Arguments :
% - Lin (in) : Liste de coups � nettoyer
% - Lout (out) : Liste de coups nettoy�e
%
% Test 1 : sortie_plateau_doublons([[11,0,n],[11,0,e],[11,0,o],[11,0,s]],L).
% Test 2 : sortie_plateau_doublons([[11,11,o],[11,11,s],[11,21,n],[11,21,e],[11,21,o],[11,21,s],[11,0,n],[11,0,e],[11,0,o],[11,0,s],[11,0,n],[11,0,e],[11,0,o],[11,0,s],[11,12,n],[11,12,e]],L).
%%%%%%%%%%%%%%%%%%%%%%%%%%%
sortie_plateau_doublons([],[]).	% Condition d'arr�t, si la liste � nettoyer est vide, la sortie aussi...

sortie_plateau_doublons([[Origine,0,_]|L],R) :-	% Si le coup est d�j� membre de la sortie, on fait juste un appel r�cursif
			member([Origine,0,_],L),
			sortie_plateau_doublons(L,R), !.
			
sortie_plateau_doublons([[Origine,0,_]|L],[[Origine,0,_]|R]) :- % Sinon, si on a pas encore un coup de cette forme, on l'ajoute dans la sortie.
			\+member([Origine,0,_],L),
			sortie_plateau_doublons(L,R), !.

sortie_plateau_doublons([[Origine,D,O]|L],[[Origine,D,O]|R]) :- % Autre cas, si on arrive l�, on ajoute le coup
			sortie_plateau_doublons(L,R). 
%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUPPRIMER ROTATIONS INUTILES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% supprimer_rotations_inutiles(P,Lin,Lout).
%
% On va ici supprimer les cas ou un pion tourne sur lui m�me alors qu'il n'y a personne autour.
% Si on a un pion avec ses 4 cases autour vides (-1;+1;-10;+10) alors on supprime les coups o� il tourne sur lui meme donc les coups du type : [Origine, Origine ,_].
% Si P = [[ [11,'e'],[23,'e'],[42,'n'],[44,'n'],[0,0] ],[[24,s],[52,n],[13,n],[44,n],[0,0]],[31,33,25],e],
% Alors les coups possibles a partir de la case 44 seront : Liste = [[44,44,n],[44,44,e],[44,44,o],[44,44,s]].
% Or, on ne veut avoir aucun coup possible en sortie car on veut garder l'orientation de depart du pion
% Test 1 : plateau(P), afficher_plateau(P), coups_potentiels_joueur([[11,'e'],[23,'e'],[42,'n'],[44,'n'],[0,0]],Liste), supprimer_rotations_inutiles(P,Liste,ListeOut).
% R�sultat du test : on voit que en 11 par exemple, les 4 cases autour sont vides donc on va bien enlever les coups [11,11,n],[11,11,e],[11,11,o],[11,11,s] de la liste de coups potentiels. Il en va de m�me pour la case en 44.
%
% IMPORTANT : pour tester il faut bien appeler coups_potentiels_joueur avec la liste E ou la liste R puis appeler supprimer_rotations_inutiles avec le plateau entier !
%
% Arguments :
% - P (in) : Le plateau courant
% - Lin (in) : liste de coups � �laguer
% - Lout (out) : Liste de coups en sortie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
supprimer_rotations_inutiles(_,[],[]) :- !.

supprimer_rotations_inutiles(P,[[Origine,Origine,_]|L],R) :- % Si le coup est un coup o� je ne bouge pas de case, je le supprime de la liste
	quatre_cases_autour_pion_vides(P,Origine),
	supprimer_rotations_inutiles(P,L,R), !.
	
supprimer_rotations_inutiles(P,[[Origine,D,O]|L],[[Origine,D,O]|R]) :- % Si c'est un coup o� je me d�place d'une case � l'autre, je ne le supprime pas de la liste.
	supprimer_rotations_inutiles(P,L,R). 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUPPRIMER ORIENTATIONS INUTILES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% supprimer_orientations_inutiles(P,Lin,Lout).
%
% Si je vais en A, s'il n'y  a personne autour de A, alors je garde une seule des solutions.
% Exemple : je suis en (44,n), dans mes possibilit�s, j'ai la case 43, donc (43,n) (43,e) (43,o) (43,s). 
% S'il n'y a rien autour de cette case 43 (les 3 cases du contour) alors je ne garde que(43,n) par exemple.
% Sinon je garde bien les quatre possibilit�s.
%
% Test 1 : plateau(P), afficher_plateau(P),coups_potentiels_joueur([[11,'e'],[23,'e'],[42,'n'],[44,'n'],[0,0]],Liste), supprimer_orientations_inutiles(P,Liste, ListeOut,e).
% En sortie, on a : E = [[11,e],[23,e],[42,n],[44,n],[0,0]].
%
% Arguments :
% - P (in) : Le plateau courant
% - Lin (in) : liste de coups � �laguer
% - Lout (out) : Liste de coups en sortie
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
supprimer_orientations_inutiles(_,[],[]).	% Condition d'arr�t.

% Si le pion vient de z�ro, alors (cut), s'il a en tourage libre, on ajoute syst�matiquement la m�me orientation, ce qui nous permettra (en filtrant les doublons) de ne garder qu'un seul coup d'entr�e.
supprimer_orientations_inutiles([E,R,M,_],[[0,Destination,_]|L],Lout) :-	
	trois_cases_autour_pion_vides([E,R,M,_],0,Destination),
	!, % On reste ici puisqu'on a un pion en 0 sans voisins et qu'on ne veut pas tester les autres clauses
	Lout= [[0,Destination,'n']|Q],
	supprimer_orientations_inutiles([E,R,M,_],L,Q).

% Si je me d�place vers une case vide (et non entour�e), mais que le coup ne correspond pas � la position courante d'un pion, je fait juste un appel r�cursif, car je ne garde pas ce coup.
supprimer_orientations_inutiles([E,R,M,_],[[Origine,Destination,Orientation]|L],Lout) :-
	trois_cases_autour_pion_vides([E,R,M,_],Origine,Destination),
	\+member2([Origine,Orientation],E,R),
	supprimer_orientations_inutiles([E,R,M,_],L,Lout),
	!.

% Sinon, si j'ai toujours ma destination non entour�e mais qu'en plus je conserve mon orientation pr�c�dente, alors j'ajoute ce coup � la sortie. Cela permet de garder un coup sur les quatre possibles.
supprimer_orientations_inutiles([E,R,M,_],[[Origine,Destination,Orientation]|L],Lout) :- 
	trois_cases_autour_pion_vides([E,R,M,_],Origine,Destination),
	member2([Origine,Orientation],E,R),
	Lout = [[Origine,Destination,Orientation]|Q],
	supprimer_orientations_inutiles([E,R,M,_],L,Q).
	
% Si on a pas trois cases vides autour du pion, on conserve le coup dans la sortie car l'orientation va tout changer.	
supprimer_orientations_inutiles([E,R,M,_],[[Origine,Destination,Orientation]|L],Lout) :- 
	\+trois_cases_autour_pion_vides([E,R,M,_],Origine,Destination),
	Lout = [[Origine,Destination,Orientation]|Q],
	supprimer_orientations_inutiles([E,R,M,_],L,Q).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%
% CASES VIDES %
%%%%%%%%%%%%%%%
% cases_vides(P,Lin).
%
% On v�rifie si les cases pass�es en 2nd argument (liste) sont vides ou non gr�ce au plateau.
%
% Arguments :
% - P (in) : le plateau de jeu
% - Lin (in) : liste de case � v�rifier
%%%%%%%%%%%%%%%
cases_vides([_,_,_,_],[]).

cases_vides([E,R,M,_],[T|Q]) :- 
	\+member([T,_],E),
	\+member([T,_],R),		
	\+member(T,M),
	cases_vides([E,R,M,_],Q).
%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% QUATRE CASES AUTOUR PION VIDES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% quatre_cases_autour_pion_vides(P,Case).
%
% Predicat qui est vrai si les 4 cases autour d'une case "Origine" sur un plateau sont vides.
% 
% Arguments :
% - P (in) : le plateau de jeu
% - Case (in) : la case pour laquelle le pr�dicat doit �tre vrai.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
quatre_cases_autour_pion_vides([E,R,M,_],Origine) :- 
	Dest1 is Origine+10,
	Dest2 is Origine-10,
	Dest3 is Origine+1,
	Dest4 is Origine-1,
	cases_vides([E,R,M,_],[Dest1,Dest2,Dest3,Dest4]).	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TROIS CASES AUTOUR PION VIDES %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trois_cases_autour_pion_vides(P,Origine,Destination).
%
% Predicat qui est vrai si les 3 cases autour dune case "Origine" sur un plateau sont vides.
% Pourquoi 3? Car si le coup que l'on teste est le deplacement POTENTIEL d'une case � l'autre alors dans la case de depart on aura toujours ce pion
%
% Arguments :
% - P (in) : le plateau de jeu
% - Origine (in) : la case pour laquelle le pr�dicat doit �tre vrai.
% - Destination (in) : la case d'arriv�e potentielle.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Si le pion vient de 0, on va v�rifier les cases que l'on peut.
trois_cases_autour_pion_vides([E,R,M,_],0,Destination) :- 
	!,	% On cut pour ne pas tester les autres clauses "SI ... ALORS ... "
	Dest1 is Destination+10,
	Dest2 is Destination-10,
	Dest3 is Destination-1,
	Dest4 is Destination+1,
	cases_vides([E,R,M,_],[Dest1,Dest2,Dest3,Dest4]).


% Si l'orientation du coup �tait ouest alors la case de droite de ma case (Destination+1) de destination est toujours remplie (la case ou se trouve mon pion avant son d�placement).
trois_cases_autour_pion_vides([E,R,M,_],Origine,Destination) :- 
	Or is Origine-1,
	Destination == Or, % Ca veut dire que le coup etait orient� a l'ouest
	!,
	Dest1 is Destination+10,
	Dest2 is Destination-10,
	Dest3 is Destination-1,
	cases_vides([E,R,M,_],[Dest1,Dest2,Dest3]).	
		
% Si l'orientation du coup etait "est" alors la case de gauche de ma case (Destination-1) de destination est toujours remplie
trois_cases_autour_pion_vides([E,R,M,_],Origine,Destination) :- 
	Or is Origine+1,
	Destination == Or, %ca veut dire que le coup etait orient� a lest
	!,
	Dest1 is Destination+10,
	Dest2 is Destination-10,
	Dest3 is Destination+1,
	cases_vides([E,R,M,_],[Dest1,Dest2,Dest3]).
		
% Si l'orientation du coup etait sud alors la case du desssus de ma case (Destination+10) de destination est toujours remplie
trois_cases_autour_pion_vides([E,R,M,_],Origine,Destination) :- 
	Or is Origine-10,
	Destination == Or, %ca veut dire que le coup etait orient� au sud
	!,
	Dest1 is Destination+1,
	Dest2 is Destination-10,
	Dest3 is Destination-1,
	cases_vides([E,R,M,_],[Dest1,Dest2,Dest3]).	
		
% Si l'orientation du coup etait nord alors la case du dessous de ma case (Destination_10) de destination est toujours remplie
trois_cases_autour_pion_vides([E,R,M,_],Origine,Destination) :-
	Or is Origine+10,
	Destination == Or, %ca veut dire que le coup etait orient� au nord
	!,
	Dest1 is Destination+10,
	Dest2 is Destination-1,
	Dest3 is Destination+1,
	cases_vides([E,R,M,_],[Dest1,Dest2,Dest3]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUPS POTENTIELS JOUEUR %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% coups_potentiels_joueur(LPions,Lout).
%
% Ce pr�dicat renvoi tous les coups potentiels a partir des pions dont le joueur dispose.
%
% Arguments :
% - LPions (in): Liste des pions du joueur
% - Lout (out): Liste des coups potentiels en sortie
%%%%%%%%%%%%%%%%%%%%%%%%%%%
coups_potentiels_joueur([],[]).	% Pas de pions, pas de coup potentiel...

coups_potentiels_joueur([[0,_]|Q],Sortie) :- 
	!,	% Si le pion est en 0, on ne fait que cette clause
	coups_potentiels_hors_plateau(Sortie1),	% alors les coups potentiels sont ceux en provenance de l'ext�rieur
	coups_potentiels_joueur(Q,Sortie2),		% appel sur les autres pions non �tudi�s.
	append(Sortie1,Sortie2,Sortie).

coups_potentiels_joueur([[Case,_]|Q],Sortie) :-	% Si on arrive ici, le pion est forc�ment sur le plateau (car on cut si Case = 0)
	coups_potentiels_pion_sur_plateau(Case,Sortie1),	% On cherche donc les coups potentiels du pion sur le plateau.
	coups_potentiels_joueur(Q,Sortie2),
	append(Sortie1,Sortie2,Sortie).
%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUPS POTENTIELS HORS PLATEAU %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% coups_potentiels_hors_plateau(Lout).
%
% Pr�dicat qui permet de construire tous les d�placements possibles pour un pion hors plateau, c'est � dire chaque d�placement de 0 vers une case du contour et selon les quatre orientations possibles.
%
% Arguments :
% - Lout (out) : la liste des coups pour un pion hors du plateau
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
coups_potentiels_hors_plateau([ [0,11,'e'],[0,11,'s'],[0,11,'n'],[0,11,'o'],
[0,12,'e'],[0,12,'s'],[0,12,'n'],[0,12,'o'],
[0,13,'e'],[0,13,'s'],[0,13,'n'],[0,13,'o'],
[0,14,'e'],[0,14,'s'],[0,14,'n'],[0,14,'o'],
[0,15,'e'],[0,15,'s'],[0,15,'n'],[0,15,'o'],
[0,21,'e'],[0,21,'s'],[0,21,'n'],[0,21,'o'],
[0,31,'e'],[0,31,'s'],[0,31,'n'],[0,31,'o'],
[0,41,'e'],[0,41,'s'],[0,41,'n'],[0,41,'o'],
[0,51,'e'],[0,51,'s'],[0,51,'n'],[0,51,'o'],
[0,52,'e'],[0,52,'s'],[0,52,'n'],[0,52,'o'],
[0,53,'e'],[0,53,'s'],[0,53,'n'],[0,53,'o'],
[0,54,'e'],[0,54,'s'],[0,54,'n'],[0,54,'o'],
[0,55,'e'],[0,55,'s'],[0,55,'n'],[0,55,'o'],
[0,45,'e'],[0,45,'s'],[0,45,'n'],[0,45,'o'],
[0,35,'e'],[0,35,'s'],[0,35,'n'],[0,35,'o'],
[0,25,'e'],[0,25,'s'],[0,25,'n'],[0,25,'o']	]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COUPS POTENTIELS PION SUR PLATEAU %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% coups_potentiels_pion_sur_plateau(Case,Coups).
% 
% Permet de lister tous les coups potentiels pour un pion, c'est � dire un d�placement dans chacune des directions.
%
% Arguments :
% - Case (in) : Position du pion pour lequel on veut les coups
% - Coups (out) : Liste des coups pour ce pion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
coups_potentiels_pion_sur_plateau(Case,CoupsN) :-
	D1 is Case + 10,
	D2 is Case - 10,
	D3 is Case - 1,
	D4 is Case + 1,
	O1 = 'n',
	O2 = 'e',
	O3 = 'o',
	O4 = 's',
	Coups = [ [Case,Case,O1],[Case,Case,O2],[Case,Case,O3],[Case,Case,O4],
[Case,D1,O1],[Case,D1,O2],[Case,D1,O3],[Case,D1,O4],
[Case,D2,O1],[Case,D2,O2],[Case,D2,O3],[Case,D2,O4],
[Case,D3,O1],[Case,D3,O2],[Case,D3,O3],[Case,D3,O4],
[Case,D4,O1],[Case,D4,O2],[Case,D4,O3],[Case,D4,O4] ],
	normaliser_liste_coups(Coups,CoupsN).	% On remplace les d�placements hors plateaux par une sortie (destination = 0).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%
% TROUVER COUP %
%%%%%%%%%%%%%%%%
% trouver_coup(P,Coup,Note,Niveau).
%
% Pr�dicat central de l'IA, qui permet de trouver un coup � jouer en tentant de pr�voir � n niveaux. La combinatoire du jeu de SIAM limite cependant cette profondeur � 3 au maximum sur des plateformes actuelles.
% Fonctionnement g�n�ral : pour le plateau pass� en argument, on va chercher tous les coups possibles et les plateaux r�sultants, et on va rappeller notre pr�dicat r�cursivement sur chaque plateau.
% Une fois le bas de l'arbre atteint (Niveau = 1), on note chaque plateau et on retient le coup qui a g�n�r� le meilleur plateau, onfait remonter sa note au niveau de r�cursion sup�rieur.
% On utilise ensuite un fonctionnement minimax : � chaque niveau, le pr�dicat va soit retenir la note maximale, soit la note minimale (avec le coup qui l'a g�n�r�e et la note en question). En alternant minimisation et maximisation, on simule le fait que quand A pr�voit son coup, il tente de maximiser ses coups et part du principe que B va maximiser lui aussi ses propres coups, ce qui revient � minimiser le coup du point de vue de A. Avec un simple test de parit� sur Niveau, on sait donc si on doit faire le min ou le max.
% Une fois revenu au niveau le plus haut de la recherche, on retient donc le Coup de base qui a conduit � la solution (feuille de l'arbre) la plus int�ressante.
%
% Arguments :
% - P (in) : plateau de jeu
% - Coup (out) : le meilleur coup � jouer
% - Note (out) : la note du meilleur coup � jouer
% - Niveau (in) : la profondeur actuelle de la recherche de solution (commence >= 1 et d�croit jusque 1)
%%%%%%%%%%%%%%%%

% Si le plateau est victorieux, on s'arr�te pour cette branche.
trouver_coup([E,R,M,J],_,1000,_) :-
	vainqueur([E,R,M,J],J), !.	% On cut pour simuler le SI ... ALORS ... on ne veut pas redescendre dans l'arbre.

% Idem	
trouver_coup([E,R,M,J],_,-1000,_) :-
	autre_joueur(J,JBis),
	vainqueur([E,R,M,J],JBis), !.

% Niveau de profondeur le plus bas, on cherche le meilleur coup (pour le joueur courant).
trouver_coup(P,Coup,Note,1) :-
	!,	% On cut, pour arr�ter la descente de l'arbre
	coups_possible(P,CoupsEtImpacts,PlateauxRetours),	% Listing des coups possibles pour le joueur
	findall(NoteT,										% On note chaque plateau
		(member(PT,PlateauxRetours),
		noter_plateau(PT,NoteT)),
	Liste),
	max_liste(Liste,Max),		% On cherche la meilleure note
	findall(Num,nth(Num,Liste,Max),Liste2),	% Trouver les indices ou le score vaut max
	membre_alea(Liste2,Idx),!,	% Si plusieurs coups sont maximaux, on va en prendre un au hasard
	nth(Idx,CoupsEtImpacts,(Coup,_)),	% On retourne le coup
	nth(Idx,Liste,Note).				% On retourne la note
	
% Pr�dicat utilis� sur les niveaux sup�rieurs de l'arbre.
trouver_coup([E,R,M,J],Coup,Note,Niveau) :-
	NT is Niveau mod 2,	
	NT == 1,	% Si le niveau est impair, on maximise la solution
	
	% On cherche les coups possibles
	coups_possible([E,R,M,J],CoupsEtImpacts,Pouts),
	autre_joueur(J,JBis),	% On r�cup�re l'autre joueur
	NT2 is Niveau - 1,		% Calcul du prochain niveau
	
	% On g�n�re le niveau inf�rieur de l'arbre, avec JBis l'autre joueur et on r�cup�re les notes des noeuds g�n�r�s dans L
	findall(NoteT,(member([EB,RB,MB,_],Pouts),	
		trouver_coup([EB,RB,MB,JBis],_,NoteT,NT2)),
	L),

	% On cherche le max
	max_liste(L,Max),
	findall(Num,nth(Num,L,Max),Liste2),	% Trouver les indices ou le score vaut max
	membre_alea(Liste2,Idx),
	!,	% On cut pour ne pas qu'un backtrack g�n�re un autre nombre al�atoire !
	nth(Idx,CoupsEtImpacts,(Coup,_)),
	nth(Idx,L,Note).
		
trouver_coup([E,R,M,J],Coup,Note,Niveau) :-
	NT is Niveau mod 2,
	NT == 0,	% Si niveau pair, on minimise
	
	% Idem pr�dicat pr�c�dent
	coups_possible([E,R,M,J],CoupsEtImpacts,Pouts),
	autre_joueur(J,JBis),
	NT2 is Niveau - 1,
	write('.'),
	findall(NoteT,
		(member([EB,RB,MB,_],Pouts),
		trouver_coup([EB,RB,MB,JBis],_,NoteT,NT2)),	% Pbm : cherche toutes solutions, faudrait je sais pas quoi...
	L),
	
	% On minimise
	min_liste(L,Min),
	findall(Num,nth(Num,L,Min),Liste2),	% trouver les indices ou le score vaut max (parfois plusieurs non ?)
	membre_alea(Liste2,Idx),
	!,	% On cut pour ne pas qu'un backtrack g�n�re un autre nombre al�atoire !
	nth(Idx,CoupsEtImpacts,(Coup,_)),
	nth(Idx,L,Note).
%%%%%%%%%%%%%%%%


