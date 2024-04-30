# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")
include("io.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""

function cplexSolve(G::Matrix{Int})

    leng=size(G,1)
    m = size(G, 1) + 4
    n = 0 # nombre de pions initiallement prévu
    #aussi le nombre d'étapes requises pour retirer tous les pions sauf le dernier

    for i in 1:leng
        for j in 1:leng
            if G[i, j] == 1
                n += 1
            end
        end
    end

    model = Model(CPLEX.Optimizer)

    #####################################################################################
    ######################## DEFINITION  VARIABLES ######################################
    #####################################################################################

    #Présence

    @variable(model, x[1:m, 1:m, 1:n], Bin)
    #1 si un pion est présent dans la case (i, j) à l’étape t
    #0 si la case (i, j) ne contient pas de pion à l’étape t


    @variable(model, y[1:m, 1:m, 1:n, 1:4], Bin)

    #Déplacement au nord y[i,j,t,1]

    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i − 2, j)
    #0 sinon

    #Déplacement au sud y[i,j,t,2]

    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i + 2, j)
    #0 sinon

    #Déplacement à l'ouest y[i,j,t,3]

    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i, j-2)
    #0 sinon

    #Déplacement à l'est y[i,j,t,4]

    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i,j + 2)
    #0 sinon

    #####################################################################################
    ######################## DEFINITION  OBJECTIF #######################################
    #####################################################################################

    #L’objectif est de minimiser le nombre de pions sur la grille à l’étape n :

    @objective(model, Min, sum(x[i,j,n] for i in 2:m-2 for j in 2:m-2)) 


    #####################################################################################
    ######################## CONTRAINTES DE BASES #######################################
    #####################################################################################

    # (1) S’il n’y a pas de pions dans une case, il n’y a pas de capacité de mouvement :

    @constraint(model, [i in 1:m, j in 1:m, t in 1:n-1, d in 1:4], y[i, j, t, d] <= x[i,j,t]) 

    # (2) Il y a capacité de mouvement vers le nord, lorsque la case d’au-dessus est occupée par
    #un pion et lorsque la case encore au-dessus est vide :

    @constraint(model, [i in 2:m, j in 1:m, t in 1:n-1], y[i, j, t, 1] <= x[i-1,j,t]) 
    @constraint(model, [i in 3:m, j in 1:m, t in 1:n-1], y[i, j, t, 1] <= 1-x[i-2,j,t]) 

    # (3) Il y a capacité de mouvement vers le sud, lorsque la case d’en-dessous est occupée par
    #un pion et lorsque la case encore en-dessous est vide :

    @constraint(model, [i in 1:m-1, j in 1:m, t in 1:n-1], y[i, j, t, 2] <= x[i+1,j,t]) 
    @constraint(model, [i in 1:m-2, j in 1:m, t in 1:n-1], y[i, j, t, 2] <= 1-x[i+2,j,t]) 

    # (4) Il y a capacité de mouvement vers l'ouest, lorsque la case adjacente à gauche est occupée par
    # un pion et lorsque la case à gauche de celle-ci est vide : 

    @constraint(model, [i in 1:m, j in 2:m, t in 1:n-1], y[i, j, t, 3] <= x[i,j-1,t]) 
    @constraint(model, [i in 1:m, j in 3:m, t in 1:n-1], y[i, j, t, 3] <= 1-x[i,j-2,t]) 

    # (5) Il y a capacité de mouvement vers l'est, lorsque la case adjacente à droite est occupée par
    #un pion et lorsque la case à droite de celle-ci est vide : 

    @constraint(model, [i in 1:m, j in 1:m-1, t in 1:n-1], y[i, j, t, 4] <= x[i,j+1,t]) 
    @constraint(model, [i in 1:m, j in 1:m-2, t in 1:n-1], y[i, j, t, 4] <= 1-x[i,j+2,t]) 

    #####################################################################################
    ######################## CONTRAINTES MOUVEMENT ######################################
    #####################################################################################

    # (6) Contraintes liées au mouvement des pions à chaque étape (cf rapport)

    @constraint(model, [i in 3:m-2, j in 3:m-2, t in 1:n-1], x[i,j,t] - x[i,j,t+1] == sum(y[i,j,t,d] for d in 1:4) + y[i+1,j,t,1] - y[i+2,j,t,1] + y[i-1,j,t,2] - y[i-2,j,t,2]+y[i,j+1,t,3] - y[i,j+2,t,3]+y[i,j-1,t,4] - y[i,j-2,t,4])

    # (7) De plus, il convient d’imposer un unique saut par étape de résolution. Cela se traduit de manière suivante :

    @constraint(model, [t in 1:(n-1)], sum(y[i,j,t,d] for i in 1:m, j in 1:m, d in 1:4) <= 1) 

    #####################################################################################
    ######################## CONTRAINTES SUR LES BORDS ##################################
    #####################################################################################

    # (8) les cases en dehors de la grille contiennent toujours des pions...

    @constraint(model, [i in 1:2, j in 1:m, t in 1:n], x[i, j, t] == 1)
    @constraint(model, [i in m-1:m, j in 1:m, t in 1:n], x[i, j, t] == 1)
    @constraint(model, [i in 1:m, j in 1:2, t in 1:n], x[i, j, t] == 1)
    @constraint(model, [i in 1:m, j in m-1:m, t in 1:n], x[i, j, t] == 1)

    # (9) ...qui ne peuvent se mouvoir

    @constraint(model, [i in 1:2, j in 1:m, t in 1:n, d in 1:4], y[i, j, t, d] == 0)
    @constraint(model, [i in m-1:m, j in 1:m, t in 1:n, d in 1:4], y[i, j, t, d] == 0)
    @constraint(model, [i in 1:m, j in 1:2, t in 1:n, d in 1:4], y[i, j, t, d] == 0)
    @constraint(model, [i in 1:m, j in m-1:m, t in 1:n, d in 1:4], y[i, j, t, d] == 0)

    #####################################################################################
    ######################## CONTRAINTES DEBUT DE PARTIE ################################
    #####################################################################################

    # (10) gi−2,j−2 = 0 i.e. la case (i, j) est vide mais peut-être occupée par un pion

    @constraint(model, [i in 3:(m-2), j in 3:(m-2); G[i-2, j-2] == 0], x[i, j, 1] == 0) 

    # (11) gi−2,j−2 = 1 i.e. la case (i, j) est occupée par un pion

    @constraint(model, [i in 3:(m-2), j in 3:(m-2); G[i-2, j-2] == 1], x[i, j, 1] == 1)
    
    # (12) gi−2,j−2 = 2 i.e. la case (i, j) est hors de la grille et ne peut-être jouée

    @constraint(model, [i in 3:(m-2), j in 3:(m-2), t in 1:n; G[i-2, j-2] == 2], x[i, j, t] == 1)
    @constraint(model, [i in 3:(m-2), j in 3:(m-2), t in 1:n, d in 1:4; G[i-2, j-2] == 2], y[i, j, t, d] == 0)

    #####################################################################################
    ################################ FIN DES CONTRAINTES ################################
    #####################################################################################

    set_optimizer_attribute(model, "CPXPARAM_TimeLimit", 300) # 5 minutes de time limit
    set_silent(model)
    start = time()
    optimize!(model)

    #Création d'une matrice res de dimensions n x (m - 4) x (m - 4) remplie initialement de 0.

    res = fill(0, m - 4, m - 4, n) 
    fin = fill(0,m-4,m-4)

    #Si le modèle a trouvé une solution admissible, le code retourne la matrice res arrondie en entiers,
    #la valeur de n et un booléen indiquant si le nombre de pions dans la dernière étape est égal à 1.
    #Sinon, s'il n'y a pas de solution réalisable, le code affiche un message indiquant qu'aucune solution
    #n'a été trouvée et retourne -1.


    if primal_status(model) == MOI.FEASIBLE_POINT
        for t in 1:n
            for i in 3:(m-2)
                for j in 3:(m-2)
                    if G[i-2, j-2] == 2
                        res[i-2, j-2, t] = 2
                    elseif value.(x[i,j,t]) == 0
                        res[i-2, j-2, t] = 0
                    elseif value.(x[i,j,t]) == 1
                        res[i-2, j-2, t] = 1
                        if t == n
                            ls += 1
                        end
                    end
                end
            end
        end
        for i in 3:m-2
            for j in 3:m-2
                fin[i-2,j-2]=res[i-2,j-2,n]
            end
        end
        return fin, primal_status(model) == MOI.FEASIBLE_POINT,time() - start
    else
        println("Aucune solution trouvée.")
        return -1
    end
end


######################### Fonction List_of_possible_move ############################

# Prend en entrée une grille et renvoit la liste des mouvements possibleValues
#sous la forme [i,j,d] avec (i,j) la case 
# où le pion va arriver et d la direction ("Nord", "Sud", "Ouest", "Est")

#####################################################################################


function List_of_possible_move(G::Matrix{Int})

    #Initialisation : taille de G (matrice carrée)

    leng=size(G,1)
    L=[]

    #Idée : on parcourt toute les cases de la grille et on identifie lorsqu'il y a une case vide
    #Les cases adjacentes à celles-ci (lorsque deux cases avec un pion sont adjacentes à celle-ci, un mouvement est possible)

    for i in 1:leng
        for j in 1:leng

            if G[i, j] == 0 #Case vide
                if i >= 3 && G[i-1, j] == 1 && G[i-2, j] == 1
                    push!(L, [i, j, "Nord"])
                end
                if i <= leng - 2 && G[i+1, j] == 1 && G[i+2, j] == 1
                    push!(L, [i, j, "Sud"])
                end
                if j >= 3 && G[i, j-1] == 1 && G[i, j-2] == 1
                    push!(L, [i, j, "Ouest"])
                end
                if j <= leng - 2 && G[i, j+1] == 1 && G[i, j+2] == 1
                    push!(L, [i, j, "Est"])
                end
            end
        end
    end

    return L

end


################################## Fonction Move ####################################

# Prend en entrée une grille et un mouvement possible [i,j,d] avec (i,j) la case 
# où le pion va arriver et d la direction ("Nord", "Sud", "Ouest", "Est")
# On renvoie en sortie la grille avec le mouvement effectué

#####################################################################################


function Move(G::Matrix{Int}, L::Any)
    i = L[1]
    j = L[2]
    d = L[3]
    H = copy(G)
    if d == "Nord" #dans ce cas au dessus de la grille on a du vide sur les deux cases
        H[i-2,j] = 0
        H[i-1,j] = 0
    elseif d == "Sud" #dans ce cas en-dessous de la grille on a du vide sur les deux cases
        H[i+2,j] = 0
        H[i+1,j] = 0
    elseif d == "Ouest" #dans ce cas à gauche de la grille on a du vide sur les deux cases
        H[i, j-2] = 0
        H[i, j-1] = 0
    elseif d == "Est" #dans ce cas à droite de la grille on a du vide sur les deux cases
        H[i, j+2] = 0
        H[i, j+1] = 0
    end
    H[i,j] = 1 #dans tous les cas le pion atterrit en (i,j)
    return H
end

################################## Fonction matrix_agglomeration ######################

# Prend en entrée une grille 
# On renvoie en sortie la matrice d'agglomération de cette grille 
# Qui contient en chaque élément 

#####################################################################################

function matrix_agglomeration(G::Matrix{Int})
    m = size(G, 1)
    G_extend = fill(0, m + 2, m + 2) #on ajoute une bordure pour l'effet de bord
    G_extend[2:m+1, 2:m+1] = replace(G, 0 => 0, 1 => 1, 2 => 0)#G_extend est une matrice avec un bord autour en plus pour pouvoir compter les 8 pions environnants  
    H = fill(0, m, m) #H est la grille qu'on renverra
    for i in 2:m+1
        for j in 2:m+1
            if G[i-1, j-1] <2 #case pouvant avoir un pion dessus, on 
                H[i-1, j-1] = G_extend[i+1, j] + G_extend[i+1, j+1] + G_extend[i, j+1] + G_extend[i-1, j] + G_extend[i-1, j-1] + G_extend[i, j-1] + G_extend[i+1, j-1] + G_extend[i-1, j+1]
            end
        end
    end
    return H
end

function matrix_agglomeration_wp(G::Matrix{Int})
    m = size(G, 1)
    G_extend = fill(0, m + 2, m + 2) #on ajoute une bordure pour l'effet de bord
    G_extend[2:m+1, 2:m+1] = replace(G, 0 => 0, 1 => 1, 2 => 0)#G_extend est une matrice avec un bord autour en plus pour pouvoir compter les 8 pions environnants  
    H = fill(0, m, m) #H est la grille qu'on renverra
    for i in 2:m+1
        for j in 2:m+1
            if G[i-1, j-1] <2 #case pouvant avoir un pion dessus, on 
                H[i-1, j-1] = G_extend[i+1, j] + G_extend[i+1, j+1] + G_extend[i, j+1] + G_extend[i-1, j] + G_extend[i-1, j-1] + G_extend[i, j-1] + G_extend[i+1, j-1] + G_extend[i-1, j+1]
                if G[i-1, j-1] == 0 #Si c'est une case vide, on pénalise H[i-1,j-1] dans le but de rassembler les pions
                    H[i-1, j-1] -= 6
                end
            end
        end
    end
    return H
end


####################### Fonction index_maximizing_agglomeration######################

# Prend en entrée une grille et la liste des mouvements possibles L
#Renvoie l'index de L tel que Move(G,L[index]) est le mouvement qui permet
# de maximiser le nombre de billes environnantes

#####################################################################################

function index_maximizing_agglomeration(G::Matrix{Int}, L::Any)
    max = 0
    index = 1
    lenL = length(L)
    for i in 1:lenL

        #Le fonctionnement est relativement simple, on va regarder 
        #La grille obtenue à partir de G suite au mouvement L[i]
        #pour tout i
        
        #La fonction matrix_agglomeration renvoit
        #La matrice d'agglomération correspondant à la matrice où chaque case (i,j) est le nombre 
        # des pions voisins présents autour de (i,j) [donc en (i,j-1),(i+1,j-1),(i-1,j-1),(i-1,j),(i+1,j),(i,j+1),(i-1,j+1),(i+1,j+1)]
        #avec comme convention qu'un bord, qu'une case non habitable ou qu'une case vide vaut 0
        #La somme de ses éléments est un indicateur d'agglomération des pions
        #que l'on cherche à maximiser selon les mouvements possibles.

        H = matrix_agglomeration(Move(G, L[i]))
        if sum(H) >= max
            max = sum(H)
            index = i
        end
    end
    return index
end

function index_maximizing_agglomeration_wp(G::Matrix{Int}, L::Any)
    max = 0
    index = 1
    lenL = length(L)
    for i in 1:lenL

        #Le fonctionnement est relativement simple, on va regarder 
        #La grille obtenue à partir de G suite au mouvement L[i]
        #pour tout i
        
        #La fonction matrix_agglomeration renvoit
        #La matrice d'agglomération correspondant à la matrice où chaque case (i,j) est le nombre 
        # des pions voisins présents autour de (i,j) [donc en (i,j-1),(i+1,j-1),(i-1,j-1),(i-1,j),(i+1,j),(i,j+1),(i-1,j+1),(i+1,j+1)]
        #avec comme convention qu'un bord, qu'une case non habitable ou qu'une case vide vaut 0
        #La somme de ses éléments est un indicateur d'agglomération des pions
        #que l'on cherche à maximiser selon les mouvements possibles.

        H = matrix_agglomeration_wp(Move(G, L[i]))
        if sum(H) >= max
            max = sum(H)
            index = i
        end
    end
    return index
end

function random_index_choice(L::Any)
    return Int(floor(rand() * length(L))) + 1
end



function index_maximizing_distance_to_center(G::Matrix{Int}, L::Any)
    max = 0
    index = 1
    k=1
    center = Int(size(G,1) ÷ 2 + 1)
    for x in L
        i=x[1]
        j=x[2]
        d = abs(i - center) + abs(j - center)
        if(d>=max)
            max=d
            index=k
        end
        k+=1    
    end
    return index
end

function index_minimizing_distance_to_center(G::Matrix{Int}, L::Any)
    min = 0
    index = 1
    k=1
    center = Int(size(G,1) ÷ 2 + 1)
    for x in L
        i=x[1]
        j=x[2]
        d = abs(i - center) + abs(j - center)
        if(d<=min)
            min=d
            index=k
        end
        k+=1    
    end
    return index
end

function index_closer_to_center(G::Matrix{Int}, L::Any)

    A=[] #top left corner
    B=[] #top right corner
    C=[] #bottom left corner
    D=[] #bottom right corner

    c = Int(size(G,1) ÷ 2 + 1)

    #création de la liste des mouvement intéressants selon le découpage en quatre zones
    #c'est-à-dire que les mouvements qui rapprochent du centre

    for x in L
        i=x[1]
        j=x[2]
        d=x[3]
        if(i<=c && j<=c &&(d=="Est"||d=="Sud"))
            push!(A,x)
        elseif(i<=c && j>c &&(d=="Ouest"||d=="Sud"))
            push!(B,x)
        elseif(i>c && j<=c &&(d=="Est"||d=="Nord"))
            push!(C,x)
        elseif(i>c && j>c &&(d=="Ouest"||d=="Nord"))
            push!(D,x)
        end
    end

    #On concatène

    List_of_interest=cat(A,B,C,D,dims=1)

    #On n'a plus qu'à choisir ceux minimisant la distance au centre 

    return(index_minimizing_distance_to_center(G,List_of_interest))
    
end

################################## Fonction heuristicSolve ##########################

# Prend en entrée une grille à résoudre
# Retourne en sortie une grille résolue en choisissant parmis les coups possibles ceux qui
# maximisent l'agglomération des pions sur la grille

#####################################################################################


function heuristicSolve(G::Matrix{Int})

    leng = size(G, 1) #On récupère la taille de la grille initiale

    H=copy(G)

    n=0 #nombre 'étapes dans la partie
    
    for i in 1:leng
        for j in 1:leng
            if G[i, j] == 1
                n += 1
            end
        end
    end

    t=0 #compteur de boucle pour empêcher de boucler à l'infini

    while t < n
        L= List_of_possible_move(H)
        #Si pas de mouvements possibles à réaliser, on stop la boucle
        if length(L) == 0
            break
        else
            k = index_maximizing_agglomeration(H,L) #indice maximisant l'agglomération des pions
            H=Move(H,L[k])
        end
        t += 1
    end

    return H

end




function heuristicSolve_wp(G::Matrix{Int})

    leng = size(G, 1) #On récupère la taille de la grille initiale

    H=copy(G)

    n=0 #nombre 'étapes dans la partie
    
    for i in 1:leng
        for j in 1:leng
            if G[i, j] == 1
                n += 1
            end
        end
    end

    t=0 #compteur de boucle pour empêcher de boucler à l'infini

    while t < n
        L= List_of_possible_move(H)
        #Si pas de mouvements possibles à réaliser, on stop la boucle
        if length(L) == 0
            break
        else
            k = index_maximizing_agglomeration_wp(H,L) #indice maximisant l'agglomération des pions
            H=Move(H,L[k])
        end
        t += 1
    end

    return H

end



function heuristicSolve_random(G::Matrix{Int})

    leng = size(G, 1) #On récupère la taille de la grille initiale

    H=copy(G)

    n=0 #nombre 'étapes dans la partie
    
    for i in 1:leng
        for j in 1:leng
            if G[i, j] == 1
                n += 1
            end
        end
    end

    t=0 #compteur de boucle pour empêcher de boucler à l'infini

    while t < n
        L= List_of_possible_move(H)
        #Si pas de mouvements possibles à réaliser, on stop la boucle
        if length(L) == 0
            break
        else
            k = random_index_choice(L) #indice random
            H=Move(H,L[k])
        end
        t += 1
    end

    return H, t

end





function heuristicSolve_distance_max(G::Matrix{Int})

    leng = size(G, 1) #On récupère la taille de la grille initiale

    H=copy(G)

    n=0 #nombre 'étapes dans la partie
    
    for i in 1:leng
        for j in 1:leng
            if G[i, j] == 1
                n += 1
            end
        end
    end

    t=0 #compteur de boucle pour empêcher de boucler à l'infini

    while t < n
        L= List_of_possible_move(H)
        #Si pas de mouvements possibles à réaliser, on stop la boucle
        if length(L) == 0
            break
        else
            k = index_maximizing_distance_to_center(H,L) #indice maximisant l'agglomération des pions
            H=Move(H,L[k])
        end
        t += 1
    end

    return H, t

end


function heuristicSolve_distance_min(G::Matrix{Int})

    leng = size(G, 1) #On récupère la taille de la grille initiale

    H=copy(G)

    n=0 #nombre 'étapes dans la partie
    
    for i in 1:leng
        for j in 1:leng
            if G[i, j] == 1
                n += 1
            end
        end
    end

    t=0 #compteur de boucle pour empêcher de boucler à l'infini

    while t < n
        L= List_of_possible_move(H)
        #Si pas de mouvements possibles à réaliser, on stop la boucle
        if length(L) == 0
            break
        else
            k = index_minimizing_distance_to_center(H,L) #indice maximisant l'agglomération des pions
            H=Move(H,L[k])
        end
        t += 1
    end

    return H, t

end


function heuristicSolve_closer_to_center(G::Matrix{Int})

    leng = size(G, 1) #On récupère la taille de la grille initiale

    H=copy(G)

    n=0 #nombre 'étapes dans la partie
    
    for i in 1:leng
        for j in 1:leng
            if G[i, j] == 1
                n += 1
            end
        end
    end

    t=0 #compteur de boucle pour empêcher de boucler à l'infini

    while t < n
        L= List_of_possible_move(H)
        #Si pas de mouvements possibles à réaliser, on stop la boucle
        if length(L) == 0
            break
        else
            k = index_closer_to_center(H,L) #indice maximisant l'agglomération des pions
            H=Move(H,L[k])
        end
        t += 1
    end

    return H, t

end

####################### Fonction solveDataSet #################################

# Prend en entrée une grille et la liste des mouvements possibles L
#Renvoie l'index de L tel que Move(G,L[index]) est le mouvement qui permet
# de maximiser le nombre de billes environnantes

###############################################################################



function solveDataSet()
    cwd=pwd()
    dataFolder = cwd*"/RO203/Pegs/data/"
    resFolder = cwd*"/RO203/Pegs/res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex","heuristique_agglo","heuristique_agglo_wp","heuristique_random","heuristique_closer_to_center"]

    # Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod

    # Create each result folder if it does not exist
    for folder in resolutionFolder
        if !isdir(folder)
            mkdir(folder)
        end
    end
            
    global isOptimal = false
    global solveTime = -1


    # For each instance
    # (for each file in folder dataFolder which ends by ".txt")
    for file in filter(x->occursin(".txt", x), readdir(dataFolder)) 
        println("-- Resolution of ", file)

        G= readInputFile(dataFolder * file)

        # For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            
            outputFile = resolutionFolder[methodId] * "/" * file

            # If the instance has not already been solved by this method
            if !isfile(outputFile)
                
                fout = open(outputFile, "w")  

                resolutionTime = -1
                isOptimal = false
                
                # If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    println("resolutionMethod[methodId] == cplex")                  
                    
                    # Solve it and get the results
                    fin, isOptimal, resolutionTime = cplexSolve(G)
                    # If a solution is found, write it
                    if isOptimal
                        writeSolution(fin)
                    end
                
                # If the method is the heuristic agglo
                elseif resolutionMethod[methodId] == "heuristique_agglo"
                    isSolved = false

                    # Start a chronometer 
                    resolutionTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100

                        # Solve it and get the results
                        H = heuristicSolve(G)

                        

                        # Stop the chronometer
                        resolutionTime = time() - resolutionTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 

                # If the method is one of the heuristics
                else
                    
                    isSolved = false

                    # Start a chronometer 
                    startingTime = time()
                    
                    # While the grid is not solved and less than 100 seconds are elapsed
                    while !isOptimal && resolutionTime < 100
                        
                        # TODO 
                        println("In file resolution.jl, in method solveDataSet(), TODO: fix heuristicSolve() arguments and returned values")
                        
                        # Solve it and get the results
                        isOptimal, resolutionTime = heuristicSolve()

                        # Stop the chronometer
                        resolutionTime = time() - startingTime
                        
                    end

                    # Write the solution (if any)
                    if isOptimal

                        # TODO
                        println("In file resolution.jl, in method solveDataSet(), TODO: write the heuristic solution in fout")
                        
                    end 
                end
                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end
            # Display the results obtained with the method on the current instance
            # include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end







####################      Test unitaires des fonctions      ###################

# Afin de garantir une approche qui ne fonce pas droit dans le mur sans vérif

###############################################################################



function create_basic_board()
    size=7
    G = zeros(Int, size, size)
    # Placement des obstacles
    obstacles = [(1, 1), (1, 2), (2, 1), (2, 2), (6, 1), (6, 2), (7, 1), (7, 2), (1, 6), (1, 7), (2, 6), (2, 7),(6, 6), (7, 6), (6, 7), (7, 7)]
    for (i, j) in obstacles
        G[i, j] = 2
    end
    # Placement des pions en dehors des obstacles
    for i in 1:size
        for j in 1:size
            if (i, j) ∉ obstacles
                G[i, j] = 1
            end
        end
    end
    G[4, 4]=0 #le trou au milieu tu as capté
    return G
end

function print_basic_board(G::Matrix{Int})
    n = size(G, 1)
    for i in 1:n
        for j in 1:n
            if(G[i,j]==0)
                print("o")
            end
            if(G[i,j]==1)
                print("x")
            end
            if(G[i,j]==2)
                print(" ")
            end
            print(" ")
        end
        println()  # Aller à la ligne pour la prochaine rangée
    end
    println()
end


function print_list_elements(L)
    for entry in L
        println(entry[1], " ", entry[2], " ", entry[3])
        println()
    end
end


# Création de la matrice G représentant le plateau anglais
#println("Plateau de base :")
G = create_basic_board()

# Affichage du plateau
#print_basic_board(G)


# Liste des mouvements possibles
#print_list_elements(List_of_possible_move(G))

# Test heuristicsolve

#H, u=heuristicSolve(G)
#A, u=heuristicSolve_wp(G)
#M, u=heuristicSolve_random(G)
#B, u=heuristicSolve_distance_max(G)
#C, u=heuristicSolve_distance_min(G)
#D, u=heuristicSolve_closer_to_center(G)

# println("résolution heuristique sans pénalisation des trous :")
# print_basic_board(H)

# println("résolution heuristique avec pénalisation des trous :")
# print_basic_board(A)

# println("résolution heuristique avec choix random :")
# print_basic_board(M)

# println("résolution heuristique avec maximisation des distances au centre :")
# print_basic_board(B)

# println("résolution heuristique avec minimisant des distances au centre :")
# print_basic_board(C)

# println("résolution heuristique avec closer to center :")
# print_basic_board(D)
#println(G)

B,t,d,a=cplexSolve(G);
solveDataSet()
