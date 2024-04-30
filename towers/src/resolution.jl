# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")
include("io.jl")

cwd=pwd()
adresse="/RO203/towers"

TOL = 0.00001

"""
Solve an instance with CPLEX

Arguments:
- up, down, left, right: four visibility vectors
"""

function cplexSolve(up,down,left,right)

    #Acquérir la dimension du problème
    n = size(up, 1)
<<<<<<< HEAD
    #Create the model
    m = Model(CPLEX.Optimizer)
    #Start a chronometer
    start = time()

    #xk[i, j, k] = 1 if cell (i, j) has value k
    @variable(m, xk[1:n, 1:n, 1:n], Bin)

    #Visibility
    #left[i, j] = 1 if cell(i, j) is visible from left side
    @variable(m, l[1:n, 1:n], Bin)
    #right[i, j] = 1 if cell(i, j) is visible from right side
    @variable(m, r[1:n, 1:n], Bin)
    #up[i, j] = 1 if cell(i, j) is visible from up side
    @variable(m, u[1:n, 1:n], Bin)
    #down[i, j] = 1 if cell(i, j) is visible from down side
    @variable(m, d[1:n, 1:n], Bin)

    #Each cell (i, j) has one value k
    @constraint(m, [i in 1:n, j in 1:n], sum(xk[i, j, k] for k in 1:n) == 1)

    #Each line l has one cell with value k
    @constraint(m, [k in 1:n, l in 1:n], sum(xk[l, j, k] for j in 1:n) == 1)

    #Each column c has one cell with value k
    @constraint(m, [k in 1:n, c in 1:n], sum(xk[i, c, k] for i in 1:n) == 1)

    #Up visibility constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], u[i,j]<=1-sum(xk[l,j,kp] for l in 1:i-1 for kp in k:n)/n+1-xk[i,j,k])
    @constraint(m, [i in 1:n ,j in 1:n, k in 1:n], u[i,j]>=1-sum(xk[l,j,kp] for l in 1:i-1 for kp in k:n)-n*(1-xk[i,j,k]))
    for visibility in 1:n
        if up[visibility] != 0
            @constraint(m, sum(u[j, visibility] for j in 1:n) == up[visibility])
        end
    end
      
    #Down visibility constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], d[i,j]<=1-sum(xk[l,j,kp] for l in i+1:n for kp in k:n)/n+1-xk[i,j,k])
    @constraint(m, [i in 1:n ,j in 1:n, k in 1:n], d[i,j]>=1-sum(xk[l,j,kp] for l in i+1:n for kp in k:n)-n*(1-xk[i,j,k])) 
    for visibility in 1:n
        if down[visibility] != 0
            @constraint(m, sum(d[j, visibility] for j in 1:n) == down[visibility])
        end
    end
      
    #Left visible constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], l[i,j]<=1-sum(xk[i,c,kp] for c in 1:j-1 for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], l[i,j]>=1-sum(xk[i,c,kp] for c in 1:j-1 for kp in k:n)-n*(1-xk[i,j,k]))
	for visibility in 1:n
        if left[visibility] != 0
            @constraint(m, sum(l[visibility, j] for j in 1:n) == left[visibility])
        end
    end

    #Right visible constraint
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], r[i,j]<=1-sum(xk[i,c,kp] for c in j+1:n for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], r[i,j]>=1-sum(xk[i,c,kp] for c in j+1:n for kp in k:n)-n*(1-xk[i,j,k]))
    for visibility in 1:n
        if right[visibility] != 0
            @constraint(m, sum(r[visibility, j] for j in 1:n) == right[visibility])
        end
    end

    #Maximize the top-left cell (reduce the problem symmetry)
    @objective(m, Max, sum(xk[1, 1, k] for k in 1:n))
    #Solve the model
    optimize!(m)

    #Return:
    #1 - the value of xk
    #2 - true if an optimum is found
    #3 - the resolution time
=======

    #Créer le modèle et lancer le chronomètre
    m = Model(CPLEX.Optimizer)
    start = time()

    #####################################################################################
    ######################## DEFINITION  VARIABLES ######################################
    #####################################################################################

    #Présence

    #xk[i, j, k] = 1 si la tour de hauteur k est dans la case (i, j)
    #            = 0 sinon

    @variable(m, xk[1:n, 1:n, 1:n], Bin)

    #Visibilité

    #UP

    #yu[i, j]    = 1 si la tour contenue dans la case (i, j) est visible depuis up
    #            = 0 sinon
    @variable(m, yu[1:n, 1:n], Bin)

    #LEFT

    #yl[i, j]    = 1 si la tour contenue dans la case (i, j) est visible depuis left
    #            = 0 sinon
    @variable(m, yl[1:n, 1:n], Bin)

    #RIGHT

    #yr[i, j]    = 1 si la tour contenue dans la case (i, j) est visible depuis right
    #            = 0 sinon
    @variable(m, yr[1:n, 1:n], Bin)

    #DOWN

    #yd[i, j]    = 1 si la tour contenue dans la case (i, j) est visible depuis down
    #            = 0 sinon
    @variable(m, yd[1:n, 1:n], Bin)

    #####################################################################################
    ######################## CONTRAINTES DE BASES #######################################
    #####################################################################################

    # Sur une colonne les tours sont toutes de hauteurs différentes :
    @constraint(m, [k in 1:n, l in 1:n], sum(xk[l, j, k] for j in 1:n) == 1)

    # Sur une ligne les tours sont toutes de hauteurs différentes :
    @constraint(m, [k in 1:n, c in 1:n], sum(xk[i, c, k] for i in 1:n) == 1)

    # Chaque case doit contenir une tour :
    @constraint(m, [i in 1:n, j in 1:n], sum(xk[i, j, k] for k in 1:n) == 1)

    #####################################################################################
    ######################## CONTRAINTES VISIBILITE #####################################
    #####################################################################################


    # UP
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], yu[i,j]<=1-sum(xk[l,j,kp] for l in 1:i-1 for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yu[i,j]>=1-sum(xk[l,j,kp] for l in 1:i-1 for kp in k:n)-n*(1-xk[i,j,k]))
    @constraint(m, [j in 1:n],sum(yu[i, j] for i in 1:n) == up[j])

    # LEFT
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], yl[i,j]<=1-sum(xk[i,c,kp] for c in 1:j-1 for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yl[i,j]>=1-sum(xk[i,c,kp] for c in 1:j-1 for kp in k:n)-n*(1-xk[i,j,k]))
	@constraint(m, [i in 1:n],sum(yl[i, j] for j in 1:n) == left[i])

    # DOWN
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], yd[i,j]<=1-sum(xk[l,j,kp] for l in i+1:n for kp in k:n)/n+1-xk[i,j,k])
    @constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yd[i,j]>=1-sum(xk[l,j,kp] for l in i+1:n for kp in k:n)-n*(1-xk[i,j,k]))
    @constraint(m, [j in 1:n],sum(yd[i, j] for i in 1:n) == down[j])

    # RIGHT
    @constraint(m, [i in 1:n, j in 1:n, k in 1:n], yr[i,j]<=1-sum(xk[i,c,kp] for c in j+1:n for kp in k:n)/n+1-xk[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yr[i,j]>=1-sum(xk[i,c,kp] for c in j+1:n for kp in k:n)-n*(1-xk[i,j,k]))
    @constraint(m, [i in 1:n],sum(yr[i, j] for j in 1:n) == right[i])


    #####################################################################################
    ######################## DEFINITION  OBJECTIF #######################################
    #####################################################################################

    @objective(m, Max, sum(xk[1, 1, k] for k in 1:n))

    # Résoudre le model
    optimize!(m)

    # On renvoit la valeur de xk, un booléen indiquant si l'optimum est atteint, le temps de résolution
>>>>>>> cf070f12b137f35b910b288521edb84018f821a8
    return xk, JuMP.primal_status(m) == JuMP.MOI.FEASIBLE_POINT, time() - start
end


"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()
    cwd=pwd()
    dataFolder = cwd*adresse*"/data/"
    resFolder = cwd*adresse*"/res/"
    #Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]
    #Array which contains the result folder of each resolution method
    resolutionFolder = resFolder .* resolutionMethod
    #Create each result folder if it does not exist
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
        up,down,left,right= readInputFile(dataFolder * file)
        #For each resolution method
        for methodId in 1:size(resolutionMethod, 1)
            outputFile = resolutionFolder[methodId] * "/" * file
            #If the instance has not already been solved by this method
            if !isfile(outputFile)
                fout = open(outputFile, "w")  
                resolutionTime = -1
                isOptimal = false
                #If the method is cplex
                if resolutionMethod[methodId] == "cplex"
                    println("resolutionMethod[methodId] == cplex")
                    #Solve it and get the results
                    x,isOptimal, resolutionTime = cplexSolve(up,down,left,right)
                    #If a solution is found, write it
                    if isOptimal
                        writeSolution(fout,x,up,down,left,right)
                    end
                else
                    println("Erreur")
                end
                println(fout, "solveTime = ", resolutionTime) 
                println(fout, "isOptimal = ", isOptimal)
                close(fout)
            end
            #Display the results obtained with the method on the current instance
            #include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end

#solveDataSet()


########################################################################################################################
#####Tests 
########################################################################################################################

# cwd=pwd()
# up,down,left,right=readInputFile(cwd*"/RO203/towers/data/instance_t5_1.txt")
# println(up)
# up=[2, 2, 2, 3, 1]
# down=[3,2,1,2,3]
# left=[3,2,1,2,3]
# right=[1,3,2,2,3 ]

# up,down,left,right=readInputFile("/Projet/RO203/data/instance_t5_1.txt")
# displayGrid(A,up,down,left,right)
# resolutionTime=-1
# isOptimal=false
# x, isOptimal, resolutionTime=cplexSolve(up,down,left,right)
# if isOptimal
#     #x=Array{Int64}(x)
#     displayGrid(up,down,left,right)
#     displaySolution(up,down,left,right)
#     fout = open("222.txt","w")
#     writeSolution(fout, x)
#     close(fout)
# end

up,down,left,right=readInputFile(cwd*adresse*"/data/instance_t5_1.txt")
x,a,b=cplexSolve(up,down,left,right)
outputFile=cwd*"/RO203/towers/res/test.txt"

fout = open(outputFile, "w") 
writeSolution(fout,x,up,down,left,right)

