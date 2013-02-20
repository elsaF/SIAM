%%%   %%%  %%%   %%%
%%%%%%%%%%%%%%%%%%%%
% PREDICATS DE JEU %
%%%%%%%%%%%%%%%%%%%%
%%%   %%%  %%%   %%%

% Ce fichier contient les pr�dicats de jeu, c'est � dire le menu, les boucles de jeu, les boucles d'affichage.
% Pour lancer le jeu, utiliser 'lancer_jeu.' dans votre console Prolog

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
%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAUVER ETAT DU PLATEAU COURANT %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%		
% Le pr�dicat plateau est dynamique				
:- dynamic(plateau/1).
% initie le plateau de d�part, sera effac� par le premier set_plateau
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
% Pr�dicat racine. Lance le jeu, propose une menu pour choisir entre les modes de jeu. A chaque fin de partie, ce menu est relanc�.
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
% Pr�dicat de d�part du jeu. Repr�sente l'ex�cution d'un tour de jeu dans le cas d'une partie humain contre humain.
% Le pr�dicat charge le plateau, annonce le tour courant, affiche le plateau et demande un coup.
% Il v�rifie la validit� du coup (en boucle), d�s que le coup est valide, il l'applique, sauvegarde le plateau et donne la main � l'autre joueur.
%%%%%%%%%
jouer :-
	plateau([E,R,M,J]),	% Chargement plateau
	write('Cest au joueur '),write(J),write(' de jouer maintenant !'),nl,
	afficher_plateau([E,R,M,J]),
	
	% R�cup�ration du coup et v�rification de celui ci
	repeat, 
	write('Joueur '),write(J),write(', entrez le coup � jouer :  [Origine,Destination,Orientation]. ou q. pour quitter :'),nl,
	read(Coup), 
	coup_possible([E,R,M,J],Coup,Impact),
	!,
	quitter_partie(Coup),
	
	% Application du coup, v�rification de victoire et changement de joueur.
	nl, write('Coup possible ! '),nl,write('----- ----- -----'),nl,nl,
	appliquer_coup([E,R,M,J],Impact,[Xout,Yout,Zout,J]),	% Applique coup
	
	% Ici, v�rifier si un joueur � gagn� (montagne hors limite, analyse dans Impact qui est le plus proche dans le bon sens.
	Coup = [_,_,DirectionPoussee],	% On r�cup�re le sens de pouss�e
	\+victoire([Xout,Yout,Zout,J],Impact,DirectionPoussee,_),	% Si non victoire, on continue, si victoire, la ligne est fausse, le jeu s'arr�te !
	autre_joueur(J,JBis),	% On change le joueur courant, on sauvegarde, on coupe le backtrack.
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont �t� sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer.
	
	
% Quitter Partie est un pr�dicat simpliste pour finir une partie si le joueur entre 'q.' comme coup.
quitter_partie(q):- !, fail.
quitter_partie(_).


%%%%%%%%%%%%%%%
% JOUER HU IA %
%%%%%%%%%%%%%%%
% jouer_hu_ia(Prof).
%
% Boucle de jeu dans le cadre Humain contre IA. La diff�rence se situe sur le fait qu'on deux clauses. La premi�re est celle qui fait jouer l'ordinateur en recherchant un coup optimal, la seconde clause est celle qui permet au joueur humain de jouer.
%
% Arguments :
% - Prof : la profondeur de l'arbre qui cherche le meilleur coup � jouer. ATTENTION, fonctionne rapidement pour Prof entre 1 et 2. A partir de 3, le temps de calcul est cons�quent.
%%%%%%%%%%%%%%%
jouer_hu_ia(Profondeur) :-
	plateau([E,R,M,J]),
	J == 'e',
	write('Cest au PC de jouer en tant que '),write(J),write(' !'),nl,nl,
	afficher_plateau([E,R,M,J]),
	
	% On cherche le coup � jouer en fonction de la profondeur de recherche max que l'on s'autorise.
	trouver_coup([E,R,M,J],Coup,_,Profondeur),
	coup_possible([E,R,M,J],Coup,Impact),	% On sait que le coup est possible, mais on veut r�cup�rer son impact

	write('Le PC a choisit de jouer le coup : '),write(Coup),write(' !'),nl,write('Pour continuer, entrez n\'importe quoi de la forme s. (pas de MAJ !) ou alors q. pour quitter'),nl,
	read(In),!,
	quitter_partie(In),
	
	% On applique le coup, on v�rifie si qqn gagne et on pr�pare la prochaine it�ration de boucle de jeu.
	appliquer_coup([E,R,M,J],Impact,[Xout,Yout,Zout,J]),
	Coup = [_,_,DirectionPoussee],	% R�cup�ration de la direction du coup
	\+victoire([Xout,Yout,Zout,J],Impact,DirectionPoussee,_),
	autre_joueur(J,JBis),	% On change le joueur courant, on sauvegarde, on coupe le backtrack.
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont �t� sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer_hu_ia(Profondeur).
	
	
jouer_hu_ia(Profondeur) :-
	plateau([E,R,M,J]),
	J == 'r',
	write('Cest au joueur humain de jouer.'),nl,
	afficher_plateau([E,R,M,J]),
	
	repeat, 
	write('Joueur '),write(J),write(', entrez le coup � jouer :  [Origine,Destination,Orientation]. ou q. pour quitter :'),nl,
	read(Coup), 
	coup_possible([E,R,M,J],Coup,Impact),
	!,
	quitter_partie(Coup),
	
	nl, write('Coup possible ! '),nl,write('----- ----- -----'),nl,nl,
	appliquer_coup([E,R,M,J],Impact,[Xout,Yout,Zout,J]),	% Applique coup
	% Ici, v�rifier si un joueur � gagn� (montagne hors limite, analyse dans Impact qui est le plus proche dans le bon sens.
	Coup = [_,_,DirectionPoussee],	% On r�cup�re le sens de pouss�e
	\+victoire([Xout,Yout,Zout,J],Impact,DirectionPoussee,_),	% Si non victoire, on continue, si victoire, la ligne est fausse, le jeu s'arr�te !
	autre_joueur(J,JBis),	% On change le joueur courant, on sauvegarde, on coupe le backtrack.
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont �t� sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer_hu_ia(Profondeur).
%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%
% JOUER IA IA %
%%%%%%%%%%%%%%%
% jouer_ia_ia(Prof).
%
% Boucle de jeu en mode IA contre IA. Fonctionne de la m�me fa�on que la premi�re des clauses du pr�dicat jouer_hu_ia.
%
% Arguments :
% - Prof : la profondeur de l'arbre qui cherche le meilleur coup � jouer. ATTENTION, fonctionne rapidement pour Prof entre 1 et 2. A partir de 3, le temps de calcul est cons�quent.
%%%%%%%%%%%%%%%
jouer_ia_ia(Profondeur) :-	% Identique � jouer_ia1/0 clause 1 (celle de l'IA justement).
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
	normaliser_plateau([Xout,Yout,_,_],[XoutBis,YoutBis,_,_]),	% On replace les pions qui ont �t� sortis du plateau en position 0
	set_plateau([XoutBis,YoutBis,Zout,JBis]),
	!,
	jouer_ia_ia(Profondeur).
%%%%%%%%%%%%%%%

	
%%%%%%%%%%%%%%%%%%%%
% Membre al�atoire %
%%%%%%%%%%%%%%%%%%%%
% membre_alea(Liste,Membre).
% 
% Permet de choisir un �l�ment au hasard dans une liste, utile pour choisir de fa�on non d�terministre entre deux solutions semblant identiques d'un point de vue �volution du jeu.
% G�n�re un nombre al�atoire et l'utilise comme indice dans la liste.
%
% Arguments :
% - Liste (in) : la liste dans laquelle piocher au hasard
% - Membre (out) : un �l�ment choisit au hasard
%%%%%%%%%%%%%%%%%%%%
membre_alea([], _) :- fail.	% Si la liste est vide, le pr�dicat est invalide

membre_alea(L, E) :-
	length(L, Len),	% On prend la taille de la liste, on g�n�re un nombre al�atoire entre 1 et le nombre d'�l�ments +1, on renvoi l'�l�ment � cette index.
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
% Pr�dicat qui affiche un plateau. NB : La version � un argument sert juste d'alias pour appeller le vrai pr�dicat avec Case = 51, notre case de d�part.
% Le pr�dicat afficher_plateau/2 pend en param�tre le plateau de jeu et un num�ro de case courante.
% Il d�compose le num�ro de case en ligne/colonne, si on est sur la premi�re colonne(d'une ligne), on trace le trait au dessus, et ensutie chaque case s'affiche. 
% Une fois la derni�re colonne affich�e, on "va � la ligne" en d�cr�mentant le num�ro de case de 14.
% Dans le cas ou on a atteind 1 comme num�ro de case, on a termin�.
%
% Arguments :
% - P1 (in) : le plateau de jeu � afficher
% - P2 (in) : le plateau de jeu � afficher
% - Case (in) : le num�ro de case que l'on affiche en ce moment
%%%%%%%%%%%%%%%%%%%%
% Appel avec un seul argument, permet de simplifier l'interface.
afficher_plateau(Plateau) :- afficher_plateau(Plateau,51).

% Derni�re case, on affiche les lignes de fin et les pions hors plateau
afficher_plateau([E,R,_,_],Case) :-
	Case == 1,
	!,
	write('    ------ ------ ------ ------ ------ '),
	nl,nl,
	write('    ------ ------ ------ ------ ------ '),nl,
	findall(Pion,member([0,_],E),L1),
	findall(Pion,member([0,_],R),L2),
	length(L1,NbE),length(L2,NbR),
	write('   | Pions �l�phants restants :  '),write(NbE),write('    |'),
	nl,
	write('   | Pions rhinoc�ros restants : '),write(NbR),write('    |'),nl,
	write('    ------ ------ ------ ------ ------ '),nl,
	nl, !.
	
% Case de d�but de ligne (colonne = 1), on trace le chapeau d'une ligne et la premi�re case
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
	
% Case du plateau dans les 3 colonnes interm�diaires
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
	
% Case extr�mit� d'une ligne (colonne = 5)
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
% Afficher case prend deux arguments : le plateau de jeu, qu'il d�compose en 4 sous-listes, et le num�ro de case � afficher.
% Il y a un pr�dicat pour l'affichage des �l�phants, un pour les rhinoc�ros, un pour les montagnes.
% SI le num�ro de case est dans la sous-liste analys�e, on affiche l'animal.
% Important : si aucun pion n'est sur la case en cours d'analyse, il faut quand m�me que le pr�dicat renvoie vrai pour ne pas interrompre l'affichage du plateau,
% donc le dernier pr�dicat permet de renvoyer vrai et d'affiche un espace.
%
% Arguments :
% - P (in) : le plateau de jeu
% - Case (in) : le num�ro de case que l'on affiche
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
% Le pr�dicat teste l'orientation pass�e en param�tre et affiche le symbole correspondant.
%
% Arguments :
% - O (in) : l'orientation � afficher.
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



