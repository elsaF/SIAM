%%%  %%%     %%%  %%%
%%%%%%%%%%%%%%%%%%%%%
% MECANISMES DE JEU %
%%%%%%%%%%%%%%%%%%%%%
%%%  %%%     %%%  %%%

% Dans ce fichier on retrouve les m�canismes qui v�rifient si un coup est valide (si le d�placement est bon, si les pouss�es sont faisables, etc.).

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

%%%%%%%%%%%%%%%%%
% COUP POSSIBLE %
%%%%%%%%%%%%%%%%%
% coup_possible(P,Coup,ListeMvmts).
%
% Coup_possible v�rifie si un coup de la forme [Origine,Destination,Orientation] marche, et retourne une liste contenant les mouvements � effectuer pour appliquer le coup (troisi�me argument).
% Le pr�dicat contient 4 clauses, outre les deux conditions d'arr�ts qui permettant d'une part l'arr�t du jeu et d'autre part de valider un coup trivial, les deux version commencent par verifier_coup (cad d�placement orthogonal, etc.) et pion_sur_plateau. Une fois ceci fait, dans le 1er, onv�rifie que la case de destination est libre, si tel est le cas, le coup est possible. Le second pr�dicat, lui, est donc appel� si la case de destination est occup�e. Il va donc v�rifier que la pouss�e est possible (d'un point de vue orientation), calculer la liste des pions sur la trajectoire, puis calculer la force de pouss�e. Si tout est bon, le pr�dicat termine valid� avec la liste des mouvements de la pouss�e.
% Dans le cas d'une pouss�e, le 3e argument contiendra donc la liste de chaque pion qui doit �tre d�plac�, sa case de d�part, d'arriv�e et son orientation (pr�serv�e par la pouss�e).
%
% Argument :
% - P (in) : Plateau de jeu
% - Coup (in) : le coup que l'on veut valider de la forme [Origine,Destination,Orientation]
% - ListeMvmts (out) : si le coup est possible, contient une liste de mouvements � appliquer au plateau. Sera de la forme [[Origine,Destination,Orientation],[Origine,Destination,Orientation]]
%%%%%%%%%%%%%%%%%

% G�re le cas o� le joueur veut quitter la partie (Coup == q).
coup_possible(_,q,_) :- nl,write('Vous avez choisi de quitter la partie! Bye bye!'),nl,nl.	

coup_possible(_,[0,0,_],_) :- !, fail.	% Un coup de 0 vers 0 est impossible. Le cut emp�che de tester les autres clauses.

% G�re le cas d'un mouvement statique (on tourne sur soi par exemple).
coup_possible([E,R,M,J],[Origine,Origine,Orientation],[[Origine,Origine,Orientation]]) :-
	!,
	% On a ici un coup en "sur place", on va juste v�rifier qu'il correspond � un de nos pions et que l'orientation change, sinon le coup est invalide. Le cut permet de ne pas tester les autres clauses. "Si ... alors ..."
	pion_joueur_sur_plateau([E,R,M,J],Origine),	% si le joueur a un pion en origine (et pas un pion de l'autre),
	member2([Origine,Ori],E,R),					% on r�cup�re l'orientation de ce pion
	Ori \= Orientation.							% Coup statique, il ne faut pas garder la m�me orientation qu'avant, si cette ligne �choue, le coup est impossible.
	

% Cas case libre
coup_possible([E,R,M,J],[Origine,Destination,Orientation],[[Origine,Destination,Orientation]]) :- % La liste retourn�e de contient qu'un mouvement
	verifier_coup(Origine,Destination),			% Si le coup est bon (orthogonal, etc).
	pion_joueur_sur_plateau([E,R,M,J],Origine),	% Si le pion est � ce joueur et sur le plateau
	case_non_occupee(R,Destination),			% On v�rifie que la case est libre
	case_non_occupee(E,Destination),			% idem
	case_montagne_non_occupee(M,Destination),	%idem
	!.	% On cut pour ne pas tester la clause 4, car on est dans le cas exclusif d'une case non occup�e et en aucun cas on n'a besoin de v�rifier les param�tres de pouss�e

% Cas pouss�e
coup_possible([E,R,M,J],[Origine,Destination,Orientation],Retour) :-
	verifier_coup(Origine,Destination),			% Si le coup est bon (orthogonal, etc).
	pion_joueur_sur_plateau([E,R,M,J],Origine),	% Si le pion est � ce joueur et sur le plateau
	
	poussee_possible([Origine,Destination,Orientation]),					% Si la pouss�e est possible (l'orientation correspond au sens de pouss�e n�cessaire)
	construire_liste_pions([E,R,M,'e'],ListePoussee,Origine,Orientation),	% Construction de la liste des pions sur le chemin
	calculer_force(ListePoussee,0,0),	% Calcul des rapports de force pour valider la pouss�e.
	construire_liste_deplacements(ListePoussee,Retour,Orientation).	% Construction des d�placements cons�quences dans la liste Retour	
%%%%%%%%%%%%%%%%


	
%%%%%%%%%%%%%%%%%
% VERIFIER COUP %
%%%%%%%%%%%%%%%%%
% verifier_coup(Origine, Destination)
%
% Pr�dicat pour v�rifier qu'un d�placement est possible, en utilisant les cas suivants :
% Cas 1 de deplacement de pion: Origine = 0 (l'animal rentre sur le plateau), alors Destination doit etre egal a une des 16 cases exterieures du plateau)
% Cas 2 de deplaccement de pion: Destination = 0 (l'animal sort du plateau), alors Origine doit etre egal a une des 16 cases exterieures du plateau), de plus, on doit verifier que le pion que l'on veut sortir du plateau est bien sur le plateau !
% Cas 3: le deplacement est ORTHOGONAL (pas diagonale), et deplacement d'une case maximum
%
% Arguments :
% - Origine (in) : La case d'origine
% - Destination (in) : La case de destination
%%%%%%%%%%%%%%%%%
% Animal rentre sur le plateau
verifier_coup(0,Destination) :- LigD is Destination // 10, LigD == 1, Destination >= 11, Destination =<15 .
verifier_coup(0,Destination) :- LigD is Destination // 10, LigD == 5, Destination >= 51, Destination =<55 .
verifier_coup(0,Destination) :- ColD is Destination mod 10, ColD ==  1, Destination >= 11, Destination =<51 .
verifier_coup(0,Destination) :- ColD is Destination mod 10, ColD ==  5,Destination >= 15, Destination =<55 .
verifier_coup(0,_) :- !, fail .	% Tout autre coup partant de 0 est mauvais

% Animal sort du plateau			
verifier_coup(Origine,0) :-  LigO is Origine // 10, LigO == 1 .
verifier_coup(Origine,0) :-  LigO is Origine // 10, LigO == 5 .
verifier_coup(Origine,0) :-  ColO is Origine mod 10, ColO ==  1 .
verifier_coup(Origine,0) :-  ColO is Origine mod 10, ColO ==  5 .
verifier_coup(_,0) :- !, fail.	% Tout autre coup arrivant en z�ro est mauvais

% Animal se d�place sur le plateau: une seule case et orthogonal (non diagonal)
% Cas o� le pion fait partie des 16 cases ext�rieures
% -> Cas o� le pion est sur une des quatre cases extr�mes
verifier_coup(11,Destination) :-  Destination == 12 .
verifier_coup(11,Destination) :-  Destination == 21 .
verifier_coup(15,Destination) :-  Destination == 14 .
verifier_coup(15,Destination) :-  Destination == 25 .
verifier_coup(51,Destination) :-  Destination == 41 .
verifier_coup(51,Destination) :-  Destination == 52 .
verifier_coup(55,Destination) :-  Destination == 45 .
verifier_coup(55,Destination) :-  Destination == 54 .

% -> Cas o� le pion est sur une ligne/colonne externe (mais pas sur un coin de plateau, cf ci dessus).
verifier_coup(Origine,Destination) :-  ColO is Origine mod 10, ColO ==  1, Or is Origine+10, Destination == Or .
verifier_coup(Origine,Destination) :-  ColO is Origine mod 10, ColO ==  1,  Or is Origine-10, Destination == Or .
verifier_coup(Origine,Destination) :-  ColO is Origine mod 10, ColO ==  1,  Or is Origine+1, Destination == Or .
verifier_coup(Origine,Destination) :-  ColO is Origine mod 10, ColO ==  5, Or is Origine+10,Destination == Or .
verifier_coup(Origine,Destination) :-  ColO is Origine mod 10, ColO ==  5, Or is Origine-10,Destination == Or .
verifier_coup(Origine,Destination) :-  ColO is Origine mod 10, ColO ==  5, Or is Origine-1,Destination == Or .
verifier_coup(Origine,Destination) :-  LigO is Origine // 10, LigO ==  1, Or is Origine+1,Destination == Or .
verifier_coup(Origine,Destination) :-  LigO is Origine // 10, LigO ==  1, Or is Origine-1,Destination == Or .
verifier_coup(Origine,Destination) :-  LigO is Origine // 10, LigO ==  1, Or is Origine+10,Destination == Or .
verifier_coup(Origine,Destination) :-  LigO is Origine // 10, LigO ==  5, Or is Origine+1,Destination == Or .
verifier_coup(Origine,Destination) :-  LigO is Origine // 10, LigO ==  5, Or is Origine-1,Destination == Or .
verifier_coup(Origine,Destination) :-  LigO is Origine // 10, LigO ==  5, Or is Origine-10,Destination == Or .

% Cas o� le pion ne fait pas partie des 16 cases ext�rieures
verifier_coup(Origine,Destination) :- Or is Origine+1,Destination == Or .
verifier_coup(Origine,Destination) :- Or is Origine-1,Destination == Or .
verifier_coup(Origine,Destination) :- Or is Origine+10,Destination == Or .
verifier_coup(Origine,Destination) :- Or is Origine-10,Destination == Or .
%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PION JOUEUR SUR PLATEAU %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% pion_joueur_sur_plateau(P,Case).
% 
% V�rifie que le joueur dispose bien d'un pion � la position demand�e.
% Par exemple, si le joueur veut deplacer son rhino de la case X � la case Y, on doit d'abord verifier a qu'il a bien un rhino en case X.
%
% Arguments :
% - P (in) : Le plateau de jeu
% - Case (in) : La case pour laquelle v�rifier le pr�dicat.
%%%%%%%%%%%%%%%%%%%%%%%%%%%
pion_joueur_sur_plateau([E,_,_,'e'],Origine) :-
	member([Origine,_],E).
	
pion_joueur_sur_plateau([_,R,_,'r'],Origine) :-
	member([Origine,_],R).
%%%%%%%%%%%%%%%%%%%%%%%%%%%	


%%%%%%%%%%%%%%%%%%%%
% CASE NON OCCUPEE %	
%%%%%%%%%%%%%%%%%%%%
% case_non_occupee(ListePions,Case).
% 
% V�rifie si une case est occup�e par un rhino ou un �l�phant en utilisant une liste de pions.
%
% Arguments :
% - ListePions (in) : Une liste de pions
% - Case (in) : La case qui doit �tre non occup�e par le joueur
%%%%%%%%%%%%%%%%%%%%
case_non_occupee([],_).

case_non_occupee([[_,_]|_],0) :- !.	% La case 0 n'est jamais occup�e, on cut pour ne pas tester les autres clauses

case_non_occupee([[Case,_]|_],Case) :- !, fail.	% Condition d'arr�t, case occup�e. On cut, on ne veut pas tester la clause 4, en aucun cas.

case_non_occupee([[_,_]|Q],Case) :-
	case_non_occupee(Q,Case).
%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CASE MONTAGNE NON OCCUPEE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% case_montagne_non_occupee(ListeM,Case)
% 
% Nous avons du faire un pr�dicat diff�rent pour les montagnes car la liste contenant les montagnes n'a pas la m�me structure que les listes contenant les rhino/elephant
% listeMontagne=[M1,M2,M3]. ==> chaque elt de la liste est une valeur
% listeRhino= [(pos1,or1),(pos2,or2)...]. ==> chaque elt de la liste est un couple de valeurs
%
% Arguments :
% - ListeM (in) : Une liste de montagnes
% - Case (in) : La case qui doit �tre non occup�e par une montagne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
case_montagne_non_occupee([],_).

case_montagne_non_occupee([_|_],0) :- !.	% La case 0 n'est pas occup�e.

case_montagne_non_occupee([T|_],T) :- !, fail.	% On cut, on ne veut pas tester la clause 4, en aucun cas.

case_montagne_non_occupee([T|Q],Case) :-
	T \= Case,
	case_montagne_non_occupee(Q,Case).
%%%%%%%%%%%%%%%%%	


%%%%%%%%%%%%%%%%%%%%	
% POUSSEE POSSIBLE %
%%%%%%%%%%%%%%%%%%%%	
% poussee_possible(Coup).
%
% Pr�dicat qui v�rifie que l'orientation de pouss�e est correcte, c'est � dire qu'on est orient� vers notre pouss�e.
%
% Arguments :
% - Coup (in) : Le coup que l'on veut v�rifier.
%%%%%%%%%%%%%%%%%%%%	
% Pour chaque pr�dicat on calcule la destination normale du pion et on compare � l'orientation
poussee_possible([Origine,Destination,Orientation]) :- Orig is Origine - 10, Destination == Orig,	!, Orientation == 's'.   % Le cut permet de s'assurer que les autres clauses ne seront pas test�es. SI Destination = Origine - 10 ALORS obligatoirement, Orientation doit �tre 's'.
poussee_possible([Origine,Destination,Orientation]) :- Orig is Origine + 10, Destination == Orig,	!, Orientation == 'n'.	
poussee_possible([Origine,Destination,Orientation]) :- Orig is Origine + 1, Destination == Orig, !, Orientation == 'e'.		
poussee_possible([Origine,Destination,Orientation]) :- Orig is Origine - 1, Destination == Orig, !, Orientation == 'o'.	
%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSTRUIRE LISTE PIONS %
%%%%%%%%%%%%%%%%%%%%%%%%%%
% construire_liste_pions(P,ListePoussee,Origine,Orientation).
%
% Construit une liste de pions dans une pouss�e. La sortie est une liste contenant des triplets du type : [Case,Apport,Orientation].
% L'apport est un symbole qui peut �tre +, -, ' ' ou M selon que le pion est dans le sens de la pouss�e, dans le sens contraire, perpendiculaire ou alors est une montagne.
% On a :
% - 4 conditions d'arr�t selon l'orientation de la ligne (N, S, E, O) pour ne pas calculer la liste jusqu'hors du plateau.
% - Sinon, Si la case est un E ou un R, alors, on a trois pr�dicats, un qui v�rifie si cette case est dans le sens de marche, le second dans le sens contraire.
% Selon la r�ponse, on ajoute dans notre liste de retour le num�ro de case suivi d'un + ou d'un - ou d'un espace(pion inutile) ainsi que l'orientation et appelle la suite de la boucle de r�cursion.
% - si la case est une montagne, on ajoute le num�ro de case suivi de deux M (l'un pour l'impact sur le calcul et l'autre pour faire "joli" puisqu'il faut un troisi�me argument).
% - enfin, si la case n'est ni E, ni R, ni M, on arr�te et on renvoi true gr�ce au fait final car on a atteind la fin de la ligne/colonne de pouss�e.
% Notons que :
% - Disposer du signe (+,-, ,M) permet de faire les calculs de force et que disposer des num�ros de case permet de connaitre la liste des pions � bouger si la pouss�e est valide.
%
% Arguments :
% - P (in) : le plateau de jeu
% - ListePoussee (out) : la liste de pouss�e d�crite dans la documentation ci dessus
% - Origine (in) : la case de d�part de la pouss�e
% - Orientation (in) : l'orientation de la pouss�e (n,s,e,o)
%%%%%%%%%%%%%%%%%%%%%%%%%%

% Si on a atteind la fin du plateau, on arr�te, on retourne bien une liste vide.
% Vers le nord, la limite est Case > 55
construire_liste_pions(_,[],Origine,'n') :-
	Origine > 55,! .	% Le cut nous emp�che de tenter de faire les clauses suivantes, qui vont r�ussir, mais qui n'auront aucun sens vu qu'on sera hors du plateau.
	
% Vers le sud, la case est < 11
construire_liste_pions(_,[],Origine,'s') :-
	Origine < 11,! .
	
% Vers l'est, la colonne d�passe 5
construire_liste_pions(_,[],Origine,'e') :-
	Colonne is Origine mod 10,
	Colonne > 5,! .
	
% Vers l'ouest, la colonne descend en dessous de 1
construire_liste_pions(_,[],Origine,'o') :-
	Colonne is Origine mod 10,
	Colonne < 1,! .

% Pion rencontr� dans le sens de la pouss�e, on va ajouter un '+'
construire_liste_pions([E,R,M,_],Out,Origine,Orientation) :-
	member2([Origine,Ori],E,R),	% Si le pion est un �l�phant OU un rhinoc�ros
	Ori == Orientation,			% S'il est dans le sens de la marche
	!,							% On n'ira pas tester les autres conditions
	case_suivante(Origine,Destination,Orientation),	% On r�cup�re la position suivante � �tudier
	construire_liste_pions([E,R,M,_],OutTemp,Destination,Orientation),	% Appel r�cursif
	Out = [[Origine,'+',Ori]|OutTemp].	% La sortie contient le triplet de pouss�e et la queue construire par r�cursion.
	
% Pion rencontr� dans le sens inverse de la pouss�e, on va ajouter un '-'
construire_liste_pions([E,R,M,_],Out,Origine,Orientation) :-
	member2([Origine,Ori],E,R),	% Si E ou R
	orientation_opposee(Orientation,Opposee),	% Seule diff�rence, on cherche si le pion est oppos� au mouvement.
	Ori == Opposee,				% Si g�ne le mouvement
	!,
	case_suivante(Origine,Destination,Orientation),
	construire_liste_pions([E,R,M,_],OutTemp,Destination,Orientation),
	Out = [[Origine,'-',Ori]|OutTemp].	% Element avec contribution n�gative

% Pion rencontr� dans un sens qui ne contribue pas (est ou ouest)
construire_liste_pions([E,R,M,_],Out,Origine,Orientation) :-
	member2([Origine,Ori],E,R),	% Si le pion courant est un rhino ou un �l�phant mais  ni dans le sens du mouvement, ni oppos� � celui ci.
	!,
	case_suivante(Origine,Destination,Orientation),
	construire_liste_pions([E,R,M,_],OutTemp,Destination,Orientation),
	Out = [[Origine,' ',Ori]|OutTemp].
	
% Montagne rencontr�e
construire_liste_pions([E,R,M,_],Out,Origine,Orientation) :-
	member(Origine,M),	% Si le pion courant est une montagne
	!,
	case_suivante(Origine,Destination,Orientation),
	construire_liste_pions([E,R,M,_],OutTemp,Destination,Orientation),	
	Out = [[Origine,'M','M']|OutTemp].
	
% Si on arrive ici, la case Origine ne correspond ni � une E, ni � un R, ni � une montagne, elle est vide.
construire_liste_pions(_,[],_,_).	% On arr�te notre r�cursion ici et on remonte l'arbre.
%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%
% CASE SUIVANTE %
%%%%%%%%%%%%%%%%%
% case_suivante(Origine,Destination,Orientation).
% 
% Le pr�dicat est vrai si Destination est la case de destination d'un pion plac� en Origine et se d�pla�ant selon l'orientation Orientation.
% Permet, dans la construction d'une liste de pouss�e, de connaitre la case suivante � �tudier.
%
% Arguments :
% - Origine (in) : la case de d�part
% - Destination (out) : la case d'arriv�e
% - Origine (in) : l'orientation du d�placement
%%%%%%%%%%%%%%%%%
case_suivante(Origine,Destination,'n') :-
	Destination is Origine + 10 .
	
case_suivante(Origine,Destination,'s') :-
	Destination is Origine - 10 .
	
case_suivante(Origine,Destination,'e') :-
	Destination is Origine + 1 .
	
case_suivante(Origine,Destination,'o') :-
	Destination is Origine - 1 .
%%%%%%%%%%%%%%%%%	


%%%%%%%%%%%%%%%%%%%
% CASE PRECEDENTE %	
%%%%%%%%%%%%%%%%%%%
% case_precedente(Case,Pr�c�dente,Orientation).
%
% Similaire � case_suivante mais pour avoir la case pr�c�dente.
%
% Arguments :
% - Origine (in) : la case de d'arriv�e
% - Pr�c�dente (out) : la case de d�part
% - Origine (in) : l'orientation du d�placement
%%%%%%%%%%%%%%%%%%%
case_precedente(Case,CasePrecedente,'n') :-
	CasePrecedente is Case - 10 .
	
case_precedente(Case,CasePrecedente,'s') :-
	CasePrecedente is Case + 10 .
	
case_precedente(Case,CasePrecedente,'e') :-
	CasePrecedente is Case - 1 .
	
case_precedente(Case,CasePrecedente,'o') :-
	CasePrecedente is Case + 1 .
%%%%%%%%%%%%%%%%%%%
	
	
%%%%%%%%%%%%%%%%%%%%%%%
% ORIENTATION OPPOSEE %
%%%%%%%%%%%%%%%%%%%%%%%
% orientation_opposee(O1,O2).
%
% Pr�dicat tr�s simple permettant de conna�tre l'orientation inverse de la courante, utile quand on veut savoir si un pion est dans le sens de la pouss�e, ou dans le sens contraire.
%
% Arguments :
% - O1 (in) : orientation de base
% - O2 (in) : orientation contraire
%%%%%%%%%%%%%%%%%%%%%%%
orientation_opposee('n','s').
orientation_opposee('s','n').
orientation_opposee('o','e').
orientation_opposee('e','o').
%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% construire_liste_deplacements %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% construire_liste_deplacements(ListePoussee,Sortie,Orientation).
%
% Utilise une liste de pouss�e en premier argument et ressort en second argument la liste des mouvements devant �tre appliqu�s. Ainsi on sait quel pion bouger, son origine, destination et orientation d'arriv�e (identique � celle de d�part). L'int�r�t est donc de pouvoir facilement connaitre la suite de mouvements r�sultants d'un coup pour l'appliquer � un plateau de jeu.
%
% Arguments :
% - ListePoussee (in) : liste de pouss�e � parser
% - Sortie (out) : la liste des mouvements de sortie
% - Orientation (in) : l'orientation g�n�rale de la pouss�e, utile pour naviguer de case en case.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Condition d'arr�t
construire_liste_deplacements([],[],_).

% Prend une liste de pouss�e [[Case,+/-/M,Orientation]|Q]  et �crit dans une seconde liste les d�placements en cons�quence [Origine,Destination,Orientation], l'origine �tant �gale � Case et l'orientation �tant identique � celle de base. Le troisi�me argument permet de connaitre le sens de pouss�e g�n�ral pour trouver les cases successives.
construire_liste_deplacements([[Case,_,Orientation]|Q1],[T2|Q2],Ori) :-
	case_suivante(Case,Destination,Ori),	% Case suivante
	T2 = [Case,Destination,Orientation],	% On cr�� un mouvement
	construire_liste_deplacements(Q1,Q2,Ori).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%
% CALCULER FORCE %
%%%%%%%%%%%%%%%%%%
% calculer_force(Liste,Force,Poids).
%
% Le pr�dicat est vrai si la pouss�e donn�e en 1er argument est faisable. Pour ce faire, il calcule la force r�sultante d'une pouss�e, en tenant compte des +, des -, et des Montagnes. Le pr�dicat prend une liste de pouss�e ainsi que deux compteurs initialis�s � z�ro qui vont respectivement mesurer la force et le poids d'une pouss�e. A chaque it�ration, la force doit suprasser le poids (>=) et en fin de pouss�e, la force totale doit �tre positive (strictement).
%
% Arguments :
% - Liste (in) : liste de pouss�e � parser
% - Force (in) : la force de la pouss�e (incr�ment�e par les +, d�cr�ment�e par les -)
% - Poids (in) : le poids de la pouss�e, incr�ment� par les montagnes
%%%%%%%%%%%%%%%%%%
% Condition d'arr�t, finale, la liste est vide, on v�rifie qu'on a toujous force >= poids montagnes et que la force totale est non nulle.
calculer_force([],F,M) :-	% Pas de cut car la liste vide n s'unifiera jamais avec les autres clauses
	F >= M,
	F > 0 .
	
% Cas d'un +, on augmente la force, on v�rifie toujours la condition permanente force >= montagne
calculer_force([[_,'+',_]|Q],Force,Masse) :-
	!,	% On cut car on ne veut pas unifier avec les autres clauses.
	ForceT is Force + 1,	% Si le pion est positif, on incr�mente la force
	MasseT is Masse,
	ForceT >= MasseT,
	calculer_force(Q,ForceT,MasseT).
	
% Cas d'un -, on diminue la force
calculer_force([[_,'-',_]|Q],Force,Masse) :-
	!,
	ForceT is Force - 1,
	MasseT is Masse,
	ForceT >= MasseT,
	calculer_force(Q,ForceT,MasseT).
	
% Cas d'une montagne, on augmente le poids
calculer_force([[_,'M',_]|Q],Force,Masse) :-
	!,
	ForceT is Force,
	MasseT is Masse + 1,
	ForceT >= MasseT,
	calculer_force(Q,ForceT,MasseT).
	
% Cas d'un pion inutile.
calculer_force([[_,' ',_]|Q],Force,Masse) :-
	calculer_force(Q,Force,Masse).
%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%
% Appliquer coup %
%%%%%%%%%%%%%%%%%%
% appliquer_coup(Pin,Mouvements,Pout)
%
% La fonction applique un coup, c'est � dire une s�rie de mouvements cons�quences d'un coup du joueur donn�s en param�tre 2.
% Coup doit �tre une liste de mouvements [origine, destination, orientation]
% Exemple : [ [0,11,'n'] [23,33,'e'] ]
%
% Arguments :
% - Pin (in) : le plateau de jeu de base
% - Mouvements (in) : la liste des mouvements devant �tre appliqu�s.
% - Pout (out) : le plateau r�sultant de l'application des mouvements.
%%%%%%%%%%%%%%%%%%
% Condition d'arr�t, appliquer un mouvement vide � un plateau P donne le plateau P
appliquer_coup(P,[],P).

% On va traiter les mouvements dans l'ordre inverse (pour �viter un chevauchement de deux pions si on en d�place l'un avant l'autre), donc on appelle r�cursivement le pr�dicat PUIS on utiliser deplacer_pion.
appliquer_coup(Pin, [[Origine,Destination,Orientation]|Q], Pout) :-
	appliquer_coup(Pin,Q,PoutTemp),
	deplacer_pion(PoutTemp, [Origine,Destination,Orientation], Pout).
%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%
% DEPLACER PION %
%%%%%%%%%%%%%%%%%
% deplacer_pion(P,Mouvement,Pout).
%
% Pr�dicat qui d�place un pion du plateau au moyen d'un triplet [Origine,Destination,Orientation]. Utilis� par appliquer_coup sur chaque mouvement.
%
% Arguments :
% - P (in) : le plateau de jeu de base
% - Mouvement (in) : le mouvement � appliquer de la forme [Origine,Destination,Orientation]% - Pout (out) : le plateau r�sultant de l'application du d�placement.
%%%%%%%%%%%%%%%%%%%
% On s'int�resse au joueur en cours pour bouger dans la bonne liste (tr�s utile si on bouge un pion depuis la case 0...
deplacer_pion([E,R,M,'e'],[0,Destination,Orientation], [EOut,R,M,'e']) :-
	remplacer_element_liste([0,_],[Destination,Orientation],E,EOut),! .
% Idem de l'autre c�t� de la savane
deplacer_pion([E,R,M,'r'],[0,Destination,Orientation], [E,ROut,M,'r']) :-
	remplacer_element_liste([0,_],[Destination,Orientation],R,ROut),! .
	
% Cas d'un �l�phant
deplacer_pion([E,R,M,J],[Origine,Destination,Orientation], [EOut,R,M,J]) :-
	member([Origine,_],E),!,	% On v�rifie que le pion est pr�sent pour ce joueur, et on cut pour ne pas tester avec les rhinos et les montagnes
	remplacer_element_liste([Origine,_],[Destination,Orientation],E,EOut).

% Cas d'un rhino
deplacer_pion([E,R,M,J],[Origine,Destination,Orientation], [E,ROut,M,J]) :-
	member([Origine,_],R),!,
	remplacer_element_liste([Origine,_],[Destination,Orientation],R,ROut).

% Cas d'une montagne
deplacer_pion([E,R,M,J],[Origine,Destination,_], [E,R,MOut,J]) :-
	member(Origine,M),!,
	remplacer_element_liste(Origine,Destination,M,MOut).
%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%
% AUTRE JOUEUR %
%%%%%%%%%%%%%%%%
% autre_joueur(A,B).
%
% Pr�dicat simplisite qui permet de conna�tre l'autre joueur que celui demand�. Utile en fin de tour pour passer la main au bon joueur.
%
% Arguments :
% - A : joueur 1
% - B : l'autre joueur 
%%%%%%%%%%%%%%%%
autre_joueur('e','r').
autre_joueur('r','e').
%%%%%%%%%%%%%%%%

	
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REMPLACER ELEMENT LISTE %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remplacer_element_liste(A, B, L1, L2).
%
% Ce pr�dicat remplace A par B dans la liste L1 et donne L2 en sortie, le tout UNE SEULE FOIS
% Principe : si on trouve A au d�but de L1, alors on place B au d�but de L2
% Si on trouve le premier �l�ment de L1 n'est pas A, alors on le recopie � l'identique dans L2
% Si on a atteind une liste vide, on stoppe.
%
% Arguments :
% - A (in) : �l�ment � chercher
% - B (in) : �l�ment � placer � la place de A
% - L1 (in) : liste dans laquelle remplacer
% - L2 (out) : liste de sortie
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Si la liste est vide, le remplacement aussi.
remplacer_element_liste(_, _, [], []).

% Si l'�l�ment � remplacer est en tete de L1, on place R � sa place au d�but de L2
remplacer_element_liste(O, R, [O|Q], [R|Q]) :- !. %On cut pour ne laisser qu'une solution au pr�dicat, en ne rempla�ant qu'UN �l�ment de la liste, on ne va pas tester la clause 3

% Si on a pas O en tete de liste L1, on place H, tete de L1 au d�but de L2 on on continue � descendre.
remplacer_element_liste(O, R, [H|Q], [H|Q2]) :- 
	remplacer_element_liste(O, R, Q, Q2).
%%%%%%%%%%%%%%%%%%%%%%%%%%%	
	


%%%%%%%%%%%
% MEMBER2 %
%%%%%%%%%%%
% member2(X,Y,Z).
%
% Pr�dicat qui permet de savoir si X est un membre de Y OU de Z
%
% Arguments :
% - X (in) : �l�ment � chercher
% - Y (in) : premi�re liste de recherche
% - Z (in) : seconde liste de recherche
%%%%%%%%%%%
member2(X,Y,_) :- member(X,Y).
member2(X,_,Z) :- member(X,Z).
%%%%%%%%%%%


%%%%%%%%%%%%
% VICTOIRE %
%%%%%%%%%%%%
% victoire(Plateau, Impact, DirectionPoussee, Vainqueur)
%
% Le pr�dicat victoire v�rifie si la partie est termin�e. Pour ce faire, il regarde si une montagne a �t� sortie du terrain. Si non, pas de victoire, si oui, il regarde alors qui �tait le plus proche pousseur de cette montagne en analysant la liste des derniers mouvements.
%
% Arguments :
% - Plateau (in) : le plateau de jeu
% - Impact (in) : la liste des derniers mouvements
% - DirectionPoussee (in) : la direction du coup gagnant, qui est donc celle de pouss�e
% - Vainqueur (out) : sortie du pr�dicat qui donne 'e' ou 'r'
%%%%%%%%%%%%
victoire([E,R,M,_],Impact, DirectionPoussee, Vainqueur) :-
	montagne_hors_limite(M,_),	% Si une montagne est hors limite
	write('Victoire d�tect�e !'),nl,
	reverse(Impact,ImpactBis),	% On inverse la liste des derniers mouvements
	% On cherche la nouvelle position de l'animal poussant le plus proche de la montagne sortie
	premier_animal_poussant(ImpactBis, DirectionPoussee, PositionVainqueur),
	% On r�cup�re l'�quipe � laquelle appartient le pion, il s'agit du vainqueur
	equipe(E,R,PositionVainqueur,Vainqueur),nl,
	write('/---------------------------------------------\\ '),nl,
	write('| Cest le joueur '),write(Vainqueur),write(' qui a gagn� cette partie ! |'),nl,
	write('\\---------------------------------------------/ '),nl.
%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%
% EQUIPE %
%%%%%%%%%%
% equipe(E,R,Case,Camp).
%
% Renvoi l'�quipe d'un pion en fonction de sa position
%
% Arguments :
% - E (in) : la liste des �l�phants
% - R (in) : la liste des rhinos
% - Case (in) : la case du pion dont on veut l'�quipe
% - Camp (out) : sortie du pr�dicat qui donne 'e' ou 'r'
%%%%%%%%%%
equipe(E,_,Case,'e') :-
	member([Case,_],E),! .
equipe(_,R,Case,'r') :-
	member([Case,_],R),! .
equipe(_,_,_,'aucune').
%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%	
% PREMIER ANIMAL POUSSANT %
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% premier_animal_poussant(Liste,Direction,Animal)
%
% Pr�dicat qui donne la position de l'animal pousseur, c'est � dire celui qui �tait le plus proche de la montagne qu'on a sortie. Il doit prendre la liste invers�e des derniers mouvements pour en extraire la position de l'animal qui a pouss� la montagne hors du terrain.
%
% Arguments :
% - Liste (in) : la liste des derniers mouvements, dans l'ordre INVERSE !!!
% - Direction (in) : le sens de la pouss�e
% - Animal (out): la position de l'animal le plus proche ayant pouss�
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Forc�ment une erreur si on a pas trouv� d'animal poussant alors qu'on a pouss�...
premier_animal_poussant([],_,_) :- !, fail.

% Si le mouvement en cours d'�tude �tait dans le bon sens, cest que la case en question contient l'animal qui a pouss� la montagne !
premier_animal_poussant([[_,Destination,Orientation]|_],Direction,Animal) :-
	Direction == Orientation,	% Si le pion est dans le sens de la pouss�e, il a gagn� (� condition que la liste soit parcourue dans l'ordre inverse).
	!,	% Si on est l�, on n'ira pas tester la clause 3 qui concerne un animal dans le mauvais sens.
	Animal = Destination.
	
% Si on arrive ici, l'animal courant n'est pas dans le bon sens, on effecute donc un appel r�cursif sur la queue de liste.
premier_animal_poussant([[_,_,_]|Q],Direction,Animal) :-	
	premier_animal_poussant(Q,Direction, Animal).
%%%%%%%%%%%%%%%	
	
	
	
%%%%%%%%%%%%%%%%%%%%%%%%
% MONTAGNE HORS LIMITE %
%%%%%%%%%%%%%%%%%%%%%%%%
% montagne_hors_limite(ListeM,M).
%
% V�rifie � partir de la liste des montagnes que l'un d'elles est hors limite et la donne dans le second argument.
%
% Arguments :
% - ListeM (in) : la liste des montagnes � analyser
% - M (out) : la montagne qui est hors du terrain.
%%%%%%%%%%%%%%%%%%%%%%%%
% Condition d'arr�t, aucune montagne hors limite
montagne_hors_limite([],_) :- !, fail.

montagne_hors_limite([T|_],T) :-
	Col is T mod 10,
	Col > 5, !.
	
montagne_hors_limite([T|_],T) :-
	Col is T mod 10,
	Col < 1, !.
	
montagne_hors_limite([T|_],T) :-
	Lig is T // 10,
	Lig > 5, !.
	
montagne_hors_limite([T|_],T) :-
	Col is T // 10,
	Col < 1, !.
	
montagne_hors_limite([_|Q],Mo) :-
	montagne_hors_limite(Q,Mo).
%%%%%%%%%%%%%%%%%%%%%%%%	


%%%%%%%%%%%%%%%%%%%%%%
% NORMALISER PLATEAU %
%%%%%%%%%%%%%%%%%%%%%%
% normaliser_plateau(Pin,Pout).
%
% Normaliser un plateau, c'est normaliser chaque de ses listes.
% La normalisation consiste � placer les �l�ments hors limites � z�ro, par exemple apr�s avoir pouss� un pion hors du plateau. 
%
% Arguments :
% - Pin (in) : le plateau � normaliser
% - Pout (out) : le plateau une fois normalis�
%%%%%%%%%%%%%%%%%%%%%%
normaliser_plateau([E,R,_,_],[Eout,Rout,_,_]) :-
	normaliser_liste(E,Eout),
	normaliser_liste(R,Rout).	% On ne normalise pas les montagnes car de toute fa�on la partie est termin�e si une montagne est sortie.
%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%
% NORMALISER LISTE %
%%%%%%%%%%%%%%%%%%%%
% normaliser_liste(Lin,Lout).
%
% Normaliser une liste, c'est normaliser chaque case de la liste.
%
% Arguments :
% - Lin (in) : la liste � normaliser
% - Lout (out) : la liste une fois normalis�e
%%%%%%%%%%%%%%%%%%%%
normaliser_liste([],[]).

normaliser_liste([[Case,O]|Q],[[CaseOut,O]|Qout]) :-
	normaliser_case(Case,CaseOut),
	normaliser_liste(Q,Qout).
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%
% NORMALISER LISTE COUPS %
%%%%%%%%%%%%%%%%%%%%%%%%%%
% normaliser_liste_coups(ListeIn,ListeOut).
%
% Le pr�dicat normalise non pas un plateau ou une liste de pions, mais une liste de coups, qui sont donc de la forme [Ori,Dest,Orientation].
%
% Arguments :
% - ListeIn (in) : la liste de coups � normaliser
% - ListeOut (out) : la liste de coups une fois normalis�e
%%%%%%%%%%%%%%%%%%%%%%%%%%
normaliser_liste_coups([],[]).

normaliser_liste_coups([[Ori,Dest,Orientation]|Q],[[Ori,DestOut,Orientation]|Qout]) :-
	normaliser_case(Dest,DestOut),
	normaliser_liste_coups(Q,Qout).
%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%
% NORMALISER CASE %
%%%%%%%%%%%%%%%%%%%
% normaliser_case(CaseIn,CaseOut).
%
% Le dernier niveau des normalisations. Ce pr�dicat normalise une case, c'est � dire que si elle ehors limite, on la place � z�ro.
%
% Arguments :
% - CaseIn (in) : la case � normaliser
% - CaseOut (out) : la case normalis�e
%%%%%%%%%%%%%%%%%%%
normaliser_case(Case,0) :-
	Col is Case mod 10,
	Col > 5,! .
normaliser_case(Case,0) :-
	Col is Case mod 10,
	Col < 1,! .
normaliser_case(Case,0) :-
	Lig is Case // 10,
	Lig > 5,! .
normaliser_case(Case,0) :-
	Lig is Case // 10,
	Lig < 1,! .
% Si on arrive ici, la case est bonne
normaliser_case(Case,Case).
%%%%%%%%%%%%%%%%%%%


