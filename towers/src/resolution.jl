# This file contains methods to solve an instance (heuristically or with CPLEX)
using CPLEX

include("generation.jl")
include("io.jl")

TOL = 0.00001

"""
Solve an instance with CPLEX
"""
function cplexSolve(up::Vector{Int64},down::Vector{Int64},left::Vector{Int64},right::Vector{Int64})
    n=size(up,1)
    # Create the model
    m = Model(CPLEX.Optimizer)
    # Define the variable
    @variable(m,x[1:n, 1:n, 1:n],Bin) # 1 si k se trouve en (i,j), 0 sinon
	@variable(m,yu[1:n,1:n],Bin)	# 1 si (i,j) visible depuis up, 0 sinon
	@variable(m,yd[1:n,1:n],Bin)	# 1 si (i,j) visible depuis down, 0 sinon
	@variable(m,yl[1:n,1:n],Bin)	# 1 si (i,j) visible depuis left, 0 sinon
	@variable(m,yr[1:n,1:n],Bin)	# 1 si (i,j) visible depuis right, 0 sinon
    # Objective function
    @objective(m,Max,sum(x[1, 1, k] for k in 1:n))
    # Basis constraints
    @constraint(m, [i in 1:n, j in 1:n], sum(x[i,j,k] for k in 1:n) == 1) # Une seule tour par case
	@constraint(m, [i in 1:n, k in 1:n], sum(x[i,j,k] for j in 1:n) == 1) # Pas de doublons sur une colonne
	@constraint(m, [j in 1:n, k in 1:n], sum(x[i,j,k] for i in 1:n) == 1) # Pas de doublons sur une ligne
    # Constraints
    #Up
	@constraint(m, [j in 1:n], sum(yu[i,j] for i in 1:n)==up[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yu[i,j]<=1-sum(x[l,j,h] for l in 1:i-1 for h in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yu[i,j]>=1-sum(x[l,j,h] for l in 1:i-1 for h in k:n)-n*(1-x[i,j,k]))

	#Down
	@constraint(m, [j in 1:n], sum(yd[i,j] for i in 1:n)==down[j])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yd[i,j]<=1-sum(x[l,j,h] for l in i+1:n for h in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yd[i,j]>=1-sum(x[l,j,h] for l in i+1:n for h in k:n)-n*(1-x[i,j,k]))
	#Left
	@constraint(m, [i in 1:n], sum(yl[i,j] for j in 1:n)==left[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yl[i,j]<=1-sum(x[i,l,h] for l in j+1:n for h in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yl[i,j]>=1-sum(x[i,l,h] for l in j+1:n for h in k:n)-n*(1-x[i,j,k]))	
	#Right
	@constraint(m, [i in 1:n], sum(yr[i,j] for j in 1:n)==right[i])
	@constraint(m, [i in 1:n, j in 1:n, k in 1:n], yr[i,j]<=1-sum(x[i,l,h] for l in 1:j-1 for h in k:n)/n+1-x[i,j,k])
	@constraint(m, [i in 1:n ,j in 1:n, k in 1:n], yr[i,j]>=1-sum(x[i,l,h] for l in 1:j-1 for h in k:n)-n*(1-x[i,j,k]))
    # Start a chronometer
    start = time()
    # Solve the model
    optimize!(m)
    # Return:
    # 1 - true if an optimum is found
    # 2 - the resolution time
    return JuMP.primal_status(m) == JuMP.MOI.FEASIBLE_POINT, time() - start
end


"""
Solve all the instances contained in "../data" through CPLEX and heuristics

The results are written in "../res/cplex" and "../res/heuristic"

Remark: If an instance has previously been solved (either by cplex or the heuristic) it will not be solved again
"""
function solveDataSet()
    cwd=pwd()
    dataFolder = cwd*"/RO203/towers/data/"
    resFolder = cwd*"/RO203/towers/res/"

    # Array which contains the name of the resolution methods
    resolutionMethod = ["cplex"]
    #resolutionMethod = ["cplex", "heuristique"]

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
        up,down,left,right= readInputFile(dataFolder * file)

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
                    isOptimal, resolutionTime = cplexSolve(up,down,left,right)
                    
                    # If a solution is found, write it
                    if isOptimal
                        println("is optimal")                  
                        writeSolution(fout,x)
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
            include(outputFile)
            println(resolutionMethod[methodId], " optimal: ", isOptimal)
            println(resolutionMethod[methodId], " time: " * string(round(solveTime, sigdigits=2)) * "s\n")
        end         
    end 
end

#solveDataSet()

#Test 

cwd=pwd()
up,down,left,right=readInputFile(cwd*"/RO203/towers/data/instance_t5_1.txt")
println(up)
up=[2, 2, 2, 3, 1]
down=[3,2,1,2,3]
left=[3,2,1,2,3]
right=[1,3,2,2,3 ]

resolutionTime=-1
isOptimal=false
x, isOptimal, resolutionTime=cplexSolve(up,down,left,right)
println(x)
println(isOptimal)
displayGrid(x,up,down,left,right)
displaySolution(x,up,down,left,right)
