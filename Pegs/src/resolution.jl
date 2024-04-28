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

    println("Nombre d'étapes requises pour retirer tous les pions sauf le dernier : ", n)

    model = Model(CPLEX.Optimizer)

    #####################################################################################
    ######################## DEFINITION  VARIABLES ######################################
    #####################################################################################

    #Présence

    @variable(model, x[1:m, 1:m, 1:n], Bin)
    #1 si un pion est présent dans la case (i, j) à l’étape t
    #0 si la case (i, j) ne contient pas de pion à l’étape t

    #Déplacement au nord

    @variable(model, y[1:m, 1:m, 1:n, 1], Bin)
    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i − 2, j)
    #0 sinon

    #Déplacement au sud

    @variable(model, y[1:m, 1:m, 1:n, 2], Bin)
    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i + 2, j)
    #0 sinon

    #Déplacement à l'ouest

    @variable(model, y[1:m, 1:m, 1:n, 3], Bin)
    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i, j-2)
    #0 sinon

    #Déplacement à l'est

    @variable(model, y[1:m, 1:m, 1:n, 4], Bin)
    #1 si le pion présent en (i, j) peut entamer un déplacement vers la case (i,j + 2)
    #0 sinon

    #####################################################################################
    ######################## DEFINITION  OBJECTIF #######################################
    #####################################################################################

    #L’objectif est de minimiser le nombre de pions sur la grille à l’étape n :

    @objective(model, Min, sum(x[i,j,n] for i in 1:m for j in 1:m)) 


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
    optimize!(model)

    #Création d'une matrice res de dimensions n x (m - 4) x (m - 4) remplie initialement de 0.

    res = fill(0, m - 4, m - 4, n) 

    #Cette variable sera utilisée pour compter le nombre de pions dans la dernière étape du processus de résolution

    ls = 0

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
        return round.(Int, res), n, ls == 1
    else
        println("Aucune solution trouvée.")
        return -1
    end

end

function solveDataSet(path::String)

    for i in (length(readdir(path))+1):(length(readdir("res/cplex")))
        file = "res/cplex/cplex_$i.txt"
        rm(file)
    end

    for i in 1:size(readdir(path), 1) # enumerate ne fonctionne pas car ça lit les fichiers dans un ordre aléatoire

        G = readInputFile(joinpath(path, "instance_$i.txt"))
        out = @timed cplexSolve(G)
        x = out.value[1]
        nb_steps = out.value[2]
        isOptimal = out.value[3]

        n = size(x, 1)
        l = size(x, 2)
        c = size(x, 3)

        text = ""

        if x != -1
            for s in 1:n
                text = string(text, "Etape ", string(s), " : \n")
                for i in 1:l
                    for j in 1:c
                        if x[s, i, j] == 1
                            text = string(text, "  ")
                        elseif x[s, i, j] == 2
                            text = string(text, " □")
                        else
                            text = string(text, " ■")
                        end
                    end
                    if i != l
                        text = string(text, "\n")
                    end
                end
                text = string(text, "\n\n")
            end
        end

        file = open("res/cplex/cplex_$i.txt", "w")
        write(file, "taille instance = ", string(l), " x ", string(c), "\n")
        write(file, "solveTime = ", string(out.time), " s\n")
        write(file, "nombre d'étpes nécessaires à la resolution = ", string(nb_steps), "\n")
        if x != -1 && isOptimal
            write(file, "isOptimal = true\n\n")
        else
            write(file, "isOptimal = false\n\n")
        end
        write(file, text)
        close(file)
    end
    return 1
end

function heuristicSolve(G::Matrix{Int})

    #####################################################################################
    ################################ Initialisation #####################################
    #####################################################################################

    leng = size(G, 1) #On récupère la taille de la grille initiale

    println("initial Grid") #on l'affiche
    displayGrid(G)

    listSteps = Matrix[]
    push!(listSteps, G)
    listOfPossibilities = []
    t = 0

    while t < 100
        t += 1
        listOfPossibilities = []
        #Pour chaque trou, si on a deux pions alignés à côté, on marque la possibilité dans listOfPossibilities
        for i in 1:leng
            for j in 1:leng
                if G[i, j] == 2 #trou sur la map
                    if i >= 3 && G[i-1, j] == 3 && G[i-2, j] == 3
                        push!(listOfPossibilities, [i, j, "up"])
                    end
                    if i <= l - 2 && G[i+1, j] == 3 && G[i+2, j] == 3
                        push!(listOfPossibilities, [i, j, "down"])
                    end
                    if j >= 3 && G[i, j-1] == 3 && G[i, j-2] == 3
                        push!(listOfPossibilities, [i, j, "left"])
                    end
                    if j <= c - 2 && G[i, j+1] == 3 && G[i, j+2] == 3
                        push!(listOfPossibilities, [i, j, "right"])
                    end
                end
            end
        end

        #println(listOfPossibilities)

        if length(listOfPossibilities) == 0
            break
        else
            #k =  Int(ceil(rand() * length(listOfPossibilities)))
            k = heuristicChoice(G, listOfPossibilities)

            G = doMove(G, listOfPossibilities[k])
            A = copy(G)
            push!(listSteps, A)
        end
    end

    return listSteps, t

end

function doMove(G::Matrix{Int}, Possibilitie::Any)
    i_hole = Possibilitie[1]
    j_hole = Possibilitie[2]
    action = Possibilitie[3]
    A = copy(G)

    if action == "up"
        A[i_hole-2, j_hole] = 2
        A[i_hole-1, j_hole] = 2
    elseif action == "down"
        A[i_hole+2, j_hole] = 2
        A[i_hole+1, j_hole] = 2
    elseif action == "left"
        A[i_hole, j_hole-2] = 2
        A[i_hole, j_hole-1] = 2
    elseif action == "right"
        A[i_hole, j_hole+2] = 2
        A[i_hole, j_hole+1] = 2
    end
    A[i_hole, j_hole] = 3
    return A
end

function heuristic_function(G::Matrix{Int})
    l = size(G, 1)
    c = size(G, 2)
    INTER = fill(0, l + 2, c + 2)
    INTER[2:l+1, 2:c+1] = replace(G, 1 => 0, 2 => 0, 3 => 1)
    func = fill(0, l, c)
    for i in 2:l+1
        for j in 2:c+1
            if G[i-1, j-1] > 1 #case valide
                func[i-1, j-1] = INTER[i+1, j] + INTER[i+1, j+1] + INTER[i, j+1] + INTER[i-1, j] + INTER[i-1, j-1] + INTER[i, j-1] + INTER[i+1, j-1] + INTER[i-1, j+1]
                if G[i-1, j-1] == 2
                    func[i-1, j-1] -= 6
                end
            end
        end
    end
    return func
end

function heuristicChoice(G::Matrix{Int}, listOfPossibilities::Any)
    max = 0
    index = 1
    K = length(listOfPossibilities)
    for i in 1:K
        INTER = heuristic_function(doMove(G, listOfPossibilities[i]))
        if sum(INTER) >= max
            max = sum(INTER)
            index = i
        end
    end
    #println("max = ",max," index = ",index,"listOfPossibilities[index] = ",listOfPossibilities[index])
    return index
end