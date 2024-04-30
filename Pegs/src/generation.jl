# This file contains methods to generate a data set of instances (i.e., sudoku grids)
#include("io.jl")

cwd=pwd()
adresse="/Projet/RO203/pegs"

"""
Generate an n*n grid with a given density

Argument
- n: size of the grid
- density: percentage in [0, 1] of initial values in the grid
"""

function generateInstance(n::Int64, type::String)
    grid=Array{Int64, 2}(zeros(n, n)) #Generate an empty grid 
    if type=="croix" #Crossed grid
        for i in 1:n
            for j in 1:n
                if ((i>=n+1-div(n,3))||(i<=div(n,3)))&&((j>=n+1-div(n,3))||(j<=div(n,3)))
                    grid[i,j]=2
                else
                    grid[i,j]=1
                end
            end
        end
        grid[div(n+1,2),div(n+1,2)]=0
    else #Wrong grid type
        println("Mauvais type de grille.")
        return -1
    end
    return grid 
end 

"""
Save an instance

Argument:
- grid: grid of the game
- outputFile: 
"""

function saveInstance(grid::Array{Int64, 2}, outputFile::String)
    n = size(grid,1)
    # Open the output file
    writer = open(outputFile,"w")
    # For each cell (l, c) of the grid
    for i in 1:n
        for j in 1:n
            # Write its value
            if grid[i,j]==0
                print(writer,"o")
            elseif grid[i,j]==1
                print(writer, "x")
            else
                print(writer, " ")
            end
            if j==n
                println(writer,"")
            end
        end
    end
    close(writer)
end

"""
Generate all the instances of the chosen types of grid

Argument:
- types: array of string containing the types of grid to generate

Remark: a grid is generated only if the corresponding output file does not already exist
"""

function generateDataSet(types::Array{String, 1})
    # For each grid size considered
    for type in types
         in [7,9]
		# Generate 10 instances
		for i in 1:10
			fileName = cwd*adresse*"/data/instance_t"*string(size)*"_"*string(i)*".txt"
			if !isfile(fileName)
				println("-- Generating file "*fileName)
				grid = generateInstance(size,"croix")
                if grid!=-1
                    saveInstance(grid, fileName)
                end
			end
		end
	end    
end

generateDataSet(["croix"])

