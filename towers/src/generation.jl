# This file contains methods to generate a data set of instances 
include("io.jl")

cwd=pwd()
adresse="/Projet/RO203/towers"

"""
Generate a n*n grid
Argument
- n: size of the grid
"""
function generateGrid(n::Int64) #Generate a filled grid
    grid=Array{Int64, 2}(zeros(n, n)) #Generate an empty grid 
    filled=0
	while(filled<n*n) #If not all grid are filled
		i = Int64(floor(filled/n)+1)
		j = rem(filled,n)+1
		numTried = Array{Int64}(zeros(0))
		v = rand(1:n)
		push!(numTried,v)
		while !isValuable(grid,i,j,v) && size(numTried, 1) < n
			v = rand(1:n)
			if !(v in numTried)
				push!(numTried,v)
			end
		end
		grid[i,j]=v
		filled+=1
		if size(numTried, 1)>=n
			grid = Matrix{Int64}(zeros(n, n))
			filled=0
		end
	end
    return grid
end

function generateVectors(grid::Array{Int64, 2}) #Generate the four vectors of a filled grid
    n=size(grid,1)
	up=Vector{Int64}(zeros(n))
    down=Vector{Int64}(zeros(n))
    left=Vector{Int64}(zeros(n))
    right=Vector{Int64}(zeros(n))
	for c in 1:n #Calculate the visibility vector from up side
        max=0
        num=0
        for l in 1:n
            if grid[l,c]>max
                max=grid[l,c]
                num+=1
            end
        end
        up[c]=num
    end
    for c in 1:n #Calculate the visibility vector from down side
        max=0
        num=0
        for l in 0:n-1
            if grid[n-l,c]>max
                max=grid[n-l,c]
                num+=1
            end
        end
        down[c] = num
    end
    for l in 1:n #Calculate the visibility vector from left side
        max=0
        num=0
        for c in 1:n
            if grid[l,c]>max
                max=grid[l,c]
                num+=1
            end
        end
        left[l]=num
    end
    for l in 1:n #Calculate the visibility vector from right side
        max=0
        num=0
        for c in 0:n-1
            if grid[l,n-c]>max
                max=grid[l,n-c]
                num+=1
            end
        end
        right[l]=num
    end
    return up,down,left,right
end

function isValuable(grid::Array{Int64, 2}, i::Int64, j::Int64, v::Int64)
    n = size(grid,1)
    for l in 1:n
        if grid[l, j]==v
            return false
        end
    end
    for c in 1:n
        if grid[i, c]==v
            return false
        end
    end
    return true
end

function saveInstance(t::Matrix{Int64}, outputFile::String)
    n = size(t,1)
    # Open the output file
    writer = open(outputFile,"w")
    # For each cell (l, c) of the grid
    for l in 1:n
        for c in 1:n
            # Write its value
            if t[l,c]==0
                print(writer," ")
            else
                print(writer, t[l, c])
            end
            if c != n
                print(writer,",")
            else
                println(writer,"")
            end
        end
    end
    close(writer)
end

"""
Generate all the instances
Remark: a grid is generated only if the corresponding output file does not already exist
"""
function generateDataSet()
	cwd=pwd()
    # For each grid size considered
    for size in [5,6,7,8,12]
		# Generate 10 instances
		for i in 1:10
			fileName = cwd*adresse*"/data/instance_t"*string(size)*"_"*string(i)*".txt"
			if !isfile(fileName)
				println("-- Generating file "*fileName)
				up,down,left,right = generateVectors(generateGrid(size))
                A = Matrix{Int64}(zeros(size+2,size+2))
                for j in 2:size+1
                    A[1,j]=up[j-1]
                    A[size+2,j]=down[j-1]
                    A[j,1]=left[j-1]
                    A[j,size+2]=right[j-1]
                end
				saveInstance(A, fileName)
			end
		end
	end
end

generateDataSet()