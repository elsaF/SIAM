%%%   %%%  %%%   %%%
%%%%%%%%%%%%%%%%%%%%
% PREDICATS DE JEU %
%%%%%%%%%%%%%%%%%%%%
%%%   %%%  %%%   %%%

% Ce fichier contient les prédicats de jeu, c'est à dire le menu, les boucles de jeu, les boucles d'affichage.
% Pour lancer le jeu, utiliser 'lancer_jeu.' dans votre console Prolog

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
%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAUVER ETAT DU PLATEAU COURANT %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
% Le prédicat plateau est dynamique				
:- dynamic(plateau/1).
% initie le plateau de départ, sera effacé par le premier set_plateau
plateau([ [ [0,n],[0,n],[0,n],[0,n],[0,n] ],[ [0,n],[0,n],[0,n],[0,n],[0,n] ],[33,32,34],'e']).
% plateau([ [ [51,n],[23,s],[0,n],[12,o],[0,n] ],[ [11,e],[0,n],[35,o],[36,s],[0,n] ],[33,55,34],'e']).

% Sauvegarde du plateau
set_plateau(P) :-
	retractall(plateau(_)), % avant d'ajouter une regle, on va retirer toutes les autres
	asserta(plateau(P)).% attention: il faut que P soit instanciee au prealable
%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%
% LANCER JEU %
%%%%%%%%%%%%%%
% Prédicat racine. Lance le jeu, propose une menu pour choisir entre les modes de jeu. A chaque fin de partie, ce menu est relancé.
%%%%%%%%%%%%%%
lancer_jeu :-
	repeat, 
	nl,write('----- ----- -----'),nl,write('Choisissez le type de partie :'),nl,
	write(' - 1 : Humain contre humain'),nl,
	write(' - 2 : Humain contre IA'),nl,
	write(' - 3 : IA contre IA'),nl,
	write(' - 4 : Humain contre IA (version avec recherche de profondeur 2)'),nl,
	write(' - 5 : IA contre IA (version avec recherche de profondeur 2)'),nl,
	write(' - 6 : Humain contre IA (version avec recherche de profondeur 3)'),nl,
	write(' - 7 : IA contre IA (version avec recherche de profondeur 3)'),nl,
	write(' - 8 : Quitter'),nl,
	read(Type),
	write('----- ----- -----'),nl,nl,nl,
	jeu(Type), !.
	
% Les options du menu et leur action.
jeu(1) :- write('C\'est parti !'),nl,set_plateau([ [ [0,0],[0,0],[0,0],[0,0],[0,0] ],[ [0,0],[0,0],[0,0],[0,0],[0,0] ],[33,32,34],'e']),jouer.
jeu(2) :- write('C\'est parti !'),nl,set_plateau([ [ [0,0],[0,0],[0,0],[0,0],[0,0] ],[ [0,0],[0,0],[0,0],[0,0],[0,0] ],[33,32,34],'e']),jouer_hu_ia(1).
jeu(3) :- write('C\'est parti !'),nl,set_plateau([ [ [0,0],[0,0],[0,0],[0,0],[0,0] ],[ [0,0],[0,0],[0,0],[0,0],[0,0] ],[33,32,34],'e']),jouer_ia_ia(1).
jeu(4) :- write('C\'est parti !'),nl,set_plateau([ [ [0,0],[0,0],[0,0],[0,0],[0,0] ],[ [0,0],[0,0],[0,0],[0,0],[0,0] ],[33,32,34],'e']),jouer_hu_ia(2).
jeu(5) :- write('C\'est parti !'),nl,set_plateau([ [ [0,0],[0,0],[0,0],[0,0],[0,0] ],[ [0,0],[0,0],[0,0],[0,0],[0,0] ],[33,32,34],'e']),jouer_ia_ia(2).
jeu(6) :- write('C\'est parti !'),nl,set_plateau([ [ [0,0],[0,0],[0,0],[0,0],[0,0] ],[ [0,0],[0,0],[0,0],[0,0],[0,0] ],[33,32,34],'e']),jouer_hu_ia(3).
jeu(7) :- write('C\'est parti !'),nl,set_plateau([ [ [0,0],[0,0],[0,0],[0,0],[0,0] ],[ [0,0],[0,0],[0,0],[0,0],[0,0] ],[33,32,34],'e']),jouer_ia_ia(3).
jeu(8).
%%%%%%%%%%%%%%

 
%%%%%%%%%
% JOUER %
%%%%%%%%%
% jouer.
%
% Prédicat de départ du jeu. Représente l'exécution d'un tour de jeu dans le cas d'une partie humain contre humain.
% Le prédicat charge le plateau, annonce le tour courant, affiche le plateau et demande un coup.
% Il vérifie la validité du coup (en boucle), dès que le coup est valide, il l'applique, sauvegarde le plateau et donne la main à l'autre joueur.
%%%%%%%%%
jouer :-
	plateau([E,R,M,J]),	% Chargement plateau
	write('Cest au joueur '),write(J),write(' de jouer maintenant !'),nl,
	afficher_plateau([E,R,M,J]),
	
	% Récupération du coup et vérification de celui ci
	repeat, 
	write('Joueur '),write(J),write(', entrez le coup à jouer :  [Origine,Destination,Orientation]. ou q. pour quitter :'),nl,
	read(Coup), 
	coup_possible([E,R,M,J],Coup,Impact),
	!,
	quitter_partie(Coup),
	
	% Application du coup, vérification de victoire et changement de joueur.
	nl, write('Coup possible ! '),nl,write('----- ----- -----'),nl,nl,
	appliquer_coup([E,R,M,J],Impact,[Xout,Yout,Zout,J]),	% Applique coup
	
	% Ici, vérifier si un joueur à gagné (montagne hors limite, analyse dans Impact qui est le plus proche dans le bon sens.
	Coup = [_,_,DirectionPoussee],	% On récupère le sens de poussée
	\+victoire([Xout,Yout,Zout,J],Impact,DirectionPoussee,_),	% Si non victoire, on continue, si victoire, la ligne est fausse, le jeu s'arrête !
	autre_joueur(J,JBis),	% On change le joueur courant, on sauvegarde, on coupe le backtrack.
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont été sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer.
	
	
% Quitter Partie est un prédicat simpliste pour finir une partie si le joueur entre 'q.' comme coup.
quitter_partie(q):- !, fail.
quitter_partie(_).


%%%%%%%%%%%%%%%
% JOUER HU IA %
%%%%%%%%%%%%%%%
% jouer_hu_ia(Prof).
%
% Boucle de jeu dans le cadre Humain contre IA. La différence se situe sur le fait qu'on deux clauses. La première est celle qui fait jouer l'ordinateur en recherchant un coup optimal, la seconde clause est celle qui permet au joueur humain de jouer.
%
% Arguments :
% - Prof : la profondeur de l'arbre qui cherche le meilleur coup à jouer. ATTENTION, fonctionne rapidement pour Prof entre 1 et 2. A partir de 3, le temps de calcul est conséquent.
%%%%%%%%%%%%%%%
jouer_hu_ia(Profondeur) :-
	plateau([E,R,M,J]),
	J == 'e',
	write('Cest au PC de jouer en tant que '),write(J),write(' !'),nl,nl,
	afficher_plateau([E,R,M,J]),
	
	% On cherche le coup à jouer en fonction de la profondeur de recherche max que l'on s'autorise.
	trouver_coup([E,R,M,J],Coup,_,Profondeur),
	coup_possible([E,R,M,J],Coup,Impact),	% On sait que le coup est possible, mais on veut récupérer son impact

	write('Le PC a choisit de jouer le coup : '),write(Coup),write(' !'),nl,write('Pour continuer, entrez n\'importe quoi de la forme s. (pas de MAJ !) ou alors q. pour quitter'),nl,
	read(In),!,
	quitter_partie(In),
	
	% On applique le coup, on vérifie si qqn gagne et on prépare la prochaine itération de boucle de jeu.
	appliquer_coup([E,R,M,J],Impact,[Xout,Yout,Zout,J]),
	Coup = [_,_,DirectionPoussee],	% Récupération de la direction du coup
	\+victoire([Xout,Yout,Zout,J],Impact,DirectionPoussee,_),
	autre_joueur(J,JBis),	% On change le joueur courant, on sauvegarde, on coupe le backtrack.
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont été sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer_hu_ia(Profondeur).
	
	
jouer_hu_ia(Profondeur) :-
	plateau([E,R,M,J]),
	J == 'r',
	write('Cest au joueur humain de jouer.'),nl,
	afficher_plateau([E,R,M,J]),
	
	repeat, 
	write('Joueur '),write(J),write(', entrez le coup à jouer :  [Origine,Destination,Orientation]. ou q. pour quitter :'),nl,
	read(Coup), 
	coup_possible([E,R,M,J],Coup,Impact),
	!,
	quitter_partie(Coup),
	
	nl, write('Coup possible ! '),nl,write('----- ----- -----'),nl,nl,
	appliquer_coup([E,R,M,J],Impact,[Xout,Yout,Zout,J]),	% Applique coup
	% Ici, vérifier si un joueur à gagné (montagne hors limite, analyse dans Impact qui est le plus proche dans le bon sens.
	Coup = [_,_,DirectionPoussee],	% On récupère le sens de poussée
	\+victoire([Xout,Yout,Zout,J],Impact,DirectionPoussee,_),	% Si non victoire, on continue, si victoire, la ligne est fausse, le jeu s'arrête !
	autre_joueur(J,JBis),	% On change le joueur courant, on sauvegarde, on coupe le backtrack.
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont été sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer_hu_ia(Profondeur).
%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%
% JOUER IA IA %
%%%%%%%%%%%%%%%
% jouer_ia_ia(Prof).
%
% Boucle de jeu en mode IA contre IA. Fonctionne de la même façon que la première des clauses du prédicat jouer_hu_ia.
%
% Arguments :
% - Prof : la profondeur de l'arbre qui cherche le meilleur coup à jouer. ATTENTION, fonctionne rapidement pour Prof entre 1 et 2. A partir de 3, le temps de calcul est conséquent.
%%%%%%%%%%%%%%%
jouer_ia_ia(Profondeur) :-	% Identique à jouer_ia1/0 clause 1 (celle de l'IA justement).
	plateau([E,R,M,J]),
	write('Cest au PC de jouer en tant que '),write(J),write(' !'),nl,nl,
	afficher_plateau([E,R,M,J]),
	
	trouver_coup([E,R,M,J],Coup,_,Profondeur),
	coup_possible([E,R,M,J],Coup,Impact),

	write('Le PC a choisit de jouer le coup : '),write(Coup),write(' !'),nl,write('Pour continuer, entrez n\'importe quoi de la forme s. (pas de MAJ !) ou alors q. pour quitter'),nl,
	read(In),!,
	quitter_partie(In),
	
	appliquer_coup([E,R,M,J],Impact,[Xout,Yout,Zout,J]),
	Coup = [_,_,DirectionPoussee],
	\+victoire([Xout,Yout,Zout,J],Impact,DirectionPoussee,_),
	autre_joueur(J,JBis),	% On change le joueur courant, on sauvegarde, on coupe le backtrack.
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont été sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer_ia_ia(Profondeur).
%%%%%%%%%%%%%%%

	
%%%%%%%%%%%%%%%%%%%%
% Membre aléatoire %
%%%%%%%%%%%%%%%%%%%%
% membre_alea(Liste,Membre).
% 
% Permet de choisir un élément au hasard dans une liste, utile pour choisir de façon non déterministre entre deux solutions semblant identiques d'un point de vue évolution du jeu.
% Génère un nombre aléatoire et l'utilise comme indice dans la liste.
%
% Arguments :
% - Liste (in) : la liste dans laquelle piocher au hasard
% - Membre (out) : un élément choisit au hasard
%%%%%%%%%%%%%%%%%%%%
membre_alea([], _) :- fail.	% Si la liste est vide, le prédicat est invalide

membre_alea(L, E) :-
	length(L, Len),	% On prend la taille de la liste, on génère un nombre aléatoire entre 1 et le nombre d'éléments +1, on renvoi l'élément à cette index.
	Len2 is Len +1,
	random(1, Len2, Idx),
	nth(Idx, L, E).
%%%%%%%%%%%%%%%%%%%%


	
%%%%%%%%%%%%%%%%%%%%
% AFFICHER PLATEAU %
%%%%%%%%%%%%%%%%%%%%
% afficher_plateau(P1).
% afficher_plateau(P2,Case).
%
% Prédicat qui affiche un plateau. NB : La version à un argument sert juste d'alias pour appeller le vrai prédicat avec Case = 51, notre case de départ.
% Le prédicat afficher_plateau/2 pend en paramètre le plateau de jeu et un numéro de case courante.
% Il décompose le numéro de case en ligne/colonne, si on est sur la première colonne(d'une ligne), on trace le trait au dessus, et ensutie chaque case s'affiche. 
% Une fois la dernière colonne affichée, on "va à la ligne" en décrémentant le numéro de case de 14.
% Dans le cas ou on a atteind 1 comme numéro de case, on a terminé.
%
% Arguments :
% - P1 (in) : le plateau de jeu à afficher
% - P2 (in) : le plateau de jeu à afficher
% - Case (in) : le numéro de case que l'on affiche en ce moment
%%%%%%%%%%%%%%%%%%%%
% Appel avec un seul argument, permet de simplifier l'interface.
afficher_plateau(Plateau) :- afficher_plateau(Plateau,51).

% Dernière case, on affiche les lignes de fin et les pions hors plateau
afficher_plateau([E,R,_,_],Case) :-
	Case == 1,
	!,
	write('    ------ ------ ------ ------ ------ '),
	nl,nl,
	write('    ------ ------ ------ ------ ------ '),nl,
	findall(Pion,member([0,_],E),L1),
	findall(Pion,member([0,_],R),L2),
	length(L1,NbE),length(L2,NbR),
	write('   | Pions éléphants restants :  '),write(NbE),write('    |'),
	nl,
	write('   | Pions rhinocéros restants : '),write(NbR),write('    |'),nl,
	write('    ------ ------ ------ ------ ------ '),nl,
	nl, !.
	
% Case de début de ligne (colonne = 1), on trace le chapeau d'une ligne et la première case
afficher_plateau(Plateau,Case) :-
	Col is Case mod 10,
	Col == 1,
	write('    ------ ------ ------ ------ ------ '),
	nl,
	write('   |      |      |      |      |      |'),
	nl,
	write('   |  '),
	afficher_case(Plateau,Case),
	write('  '),
	C is Case+1,
	afficher_plateau(Plateau,C),
	!.
	
% Case du plateau dans les 3 colonnes intermédiaires
afficher_plateau(Plateau,Case) :-
	Col is Case mod 10,
	Col >= 2,
	Col =< 4,
	write('|  '),
	afficher_case(Plateau,Case),
	write('  '),
	C is Case+1,
	afficher_plateau(Plateau,C),
	!.
	
% Case extrémité d'une ligne (colonne = 5)
afficher_plateau(Plateau,Case) :-
	Col is Case mod 10,
	Col == 5,
	write('|  '),
	afficher_case(Plateau,Case),
	write('  |'),
	nl,
	write('   |      |      |      |      |      |'),
	nl,
	C is Case - 14,
	afficher_plateau(Plateau,C),
	!.
%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%
% AFFICHER CASE %
%%%%%%%%%%%%%%%%%
% afficher_case(P,Case).
%
% Afficher case prend deux arguments : le plateau de jeu, qu'il décompose en 4 sous-listes, et le numéro de case à afficher.
% Il y a un prédicat pour l'affichage des éléphants, un pour les rhinocéros, un pour les montagnes.
% SI le numéro de case est dans la sous-liste analysée, on affiche l'animal.
% Important : si aucun pion n'est sur la case en cours d'analyse, il faut quand même que le prédicat renvoie vrai pour ne pas interrompre l'affichage du plateau,
% donc le dernier prédicat permet de renvoyer vrai et d'affiche un espace.
%
% Arguments :
% - P (in) : le plateau de jeu
% - Case (in) : le numéro de case que l'on affiche
%%%%%%%%%%%%%%%%%
afficher_case([X,_,_,_], Case) :-
	member([Case,O],X),!,	% On cut pour ne pas tenter d'unifier avec les autres clauses, notamment la 4e.
	write('E'),
	afficher_orientation(O).
	
afficher_case([_,Y,_,_], Case) :-
	member([Case,O],Y),!,
	write('R'),
	afficher_orientation(O).		

afficher_case([_,_,Z,_], Case) :- 
	member(Case,Z),!,
	write('M ').
	
afficher_case(_,_) :-
	write('  ').
%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%
% AFFICHER ORIENTATION %
%%%%%%%%%%%%%%%%%%%%%%%%
% afficher_orientation(O).
%
% Le prédicat teste l'orientation passée en paramètre et affiche le symbole correspondant.
%
% Arguments :
% - O (in) : l'orientation à afficher.
%%%%%%%%%%%%%%%%%%%%%%%%
afficher_orientation(O) :-
	O = 'e',
	write('>').
afficher_orientation(O) :-
	O = 'n',
	write('^').
afficher_orientation(O) :-
	O = 's',
	write('v').
afficher_orientation(O) :-
	O = 'o',
	write('<').
%%%%%%%%%%%%%%%%%%%%%%%%



