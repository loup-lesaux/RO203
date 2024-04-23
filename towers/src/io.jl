# This file contains functions related to reading, writing and displaying a grid and experimental results
using JuMP
using Plots
import .GR

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""
function readInputFile(inputFile::String)
    datafile = open(inputFile) #Open the input file
    data = readlines(datafile)
    close(datafile)

    n=length(split(data[1],","))
	up=Array{Int64}(n-2)
	down=Array{Int64}(n-2)
	left=Array{Int64}(n-2)
	right=Array{Int64}(n-2)
    A=Matrix{Int64}(n-2,n-2)
    
    for line in 1:n
        lineSplit = split(data[line],",")
        if line == 1
            for col in 2:n-1
                up[col-1] = parse(Int64,lineSplit[col])
            end
        elseif line == n
            for col in 2:n-1
                down[col-1] = parse(Int64,lineSplit[col])
            end
        else
            left[line-1] = parse(Int64,lineSplit[1])
            for col in 2:n-1
                A[line-1,col-1] = parse(Int64,lineSplit[col])
            end
            right[line-1] = parse(Int64,lineSplit[n])
        end
    end
	return A, up, down, left, right
end

"""
Display an initial game represented by a 2-dimensional array and four visibility vectors.

Arguments:
    - t: array of size n*n with values in [| 0, n |] (0 if the cell is empty)
    - vL: vector of visibility left
    - vR: vector of visibility right
    - vU: vector of visbility upper
    - vD: vector of visibility down
"""
function displayGrid(t::Array{Int, 2}, vL::Array{Int, 1}, vR::Array{Int, 1}, vU::Array{Int, 1}, vD::Array{Int, 1})
    n = size(t, 1)
    blockSize = round.(Int, sqrt(n))
    print("    ")

    ## Display the upper visbility vector.
    for i in 1:n
        if vU[i] == 0
            print(" -")
        else
            if vU[i] < 10
                print(" ")
            end
            print(vU[i])
        end
        print(" ")
    end
    ## Display the upper border of the grid.
    println("\n    ", "-"^(3*n+blockSize-1)) 
    ## For each cell (l, c)
    for l in 1:n
        ## Display the left visbility vector.
        if vL[l] == 0
            print(" -")
        else
            if vL[l] < 10
                print(" ")
            end
            print(vL[l])
        end
        print(" |")
        ## Display the grid t.
        for c in 1:n
            if t[l, c] == 0
                print(" -")
            else
                if t[l, c] < 10
                    print(" ")
                end
                print(t[l, c])
            end
            print(" ")
        end
        print(" |")
        ## Display the right visbility vector.
        if vR[l] == 0
            println(" -")
        else
            if vR[l] < 10
                print(" ")
            end
            println(vR[l])
        end
    end
    ## Display the bottom border of the grid.
    print("    ", "-"^(3*n+blockSize-1),"\n    ")
    ## Display the down visbility vector.
    for i in 1:n
        if vD[i] == 0
            print(" -")
        else
            if vD[i] < 10
                print(" ")
            end
            
            print(vD[i])
        end
        print(" ")
    end
    println()
end

"""
Display an solution of game represented by a 2-dimensional array and four visibility vectors.

Arguments:
    - xk: array of size n*n*n (xk[i, j, k] = 1 if cell (i, j) has value k)
    - vL: vector of visibility left
    - vR: vector of visibility right
    - vU: vector of visbility upper
    - vD: vector of visibility down
"""
function displaySolution(xk::Array{VariableRef, 3}, vL::Array{Int, 1}, vR::Array{Int, 1}, vU::Array{Int, 1}, vD::Array{Int, 1})
    n = size(xk, 1)
    blockSize = round.(Int, sqrt(n))
    ## Display the upper visbility vector.
    print("    ")
    for i in 1:n
        if vU[i] == 0
            print(" -")
        else
            if vU[i] < 10
                print(" ")
            end
            print(vU[i])
        end
        print(" ")
    end

    ## Display the upper border of the grid.
    println("\n    ", "-"^(3*n+blockSize-1)) 
    
    ## For each cell (l, c)
    for l in 1:n

        ## Display the left visbility vector.
        if vL[l] == 0
            print(" -")
        else
            if vL[l] < 10
                print(" ")
            end
            print(vL[l])
        end
        print(" |")

        ## Display the solution x.
        for c in 1:n
            for k in 1:n
                if JuMP.value(xk[l, c, k]) > TOL
                    if k < 10
                        print(" ")
                    end
                    print(k)
                end
            end
            print(" ")
        end
        print(" |")

        ## Display the right visbility vector.
        if vR[l] == 0
            println(" -")
        else
            if vR[l] < 10
                print(" ")
            end
            println(vR[l])
        end
    end

    ## Display the bottom border of the grid.
    print("    ", "-"^(3*n+blockSize-1),"\n    ")

    ## Display the down visbility vector.
    for i in 1:n
        if vD[i] == 0
            print(" -")
        else
            if vD[i] < 10
                print(" ")
            end
            print(vD[i])
        end
        print(" ")
    end
    println()
end

"""
Create a pdf file which contains a performance diagram associated to the results of the ../res folder
Display one curve for each subfolder of the ../res folder.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function performanceDiagram(outputFile::String)
    resultFolder = "../res/"
    maxSize=0 #Maximal number of files in a subfolder
    subfolderCount=0 #Number of subfolders
    folderName=Array{String, 1}()
    for file in readdir(resultFolder) #For each file in the result folder
        path = resultFolder * file
        if isdir(path) #If it is a subfolder
            folderName = vcat(folderName, file)
            subfolderCount += 1
            folderSize = size(readdir(path), 1)
            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end
    #Array that will contain the resolution times (one line for each subfolder)
    results = Array{Float64}(undef, subfolderCount, maxSize)
    for i in 1:subfolderCount
        for j in 1:maxSize
            results[i, j] = Inf
        end
    end
    folderCount = 0
    maxSolveTime = 0
    # For each subfolder
    for file in readdir(resultFolder)
        path = resultFolder * file
        if isdir(path)
            folderCount += 1
            fileCount = 0
            # For each text file in the subfolder
            for resultFile in filter(x->occursin(".txt", x), readdir(path))
                fileCount += 1
                include(path * "/" * resultFile)
                if isOptimal
                    results[folderCount, fileCount] = solveTime
                    if solveTime > maxSolveTime
                        maxSolveTime = solveTime
                    end 
                end 
            end 
        end
    end 
    #Sort each row increasingly
    results = sort(results, dims=2)
    println("Max solve time: ", maxSolveTime)
    n=size(results,1)
    #For each line to plot
    for dim in 1:n
        x = Array{Float64, 1}()
        y = Array{Float64, 1}()
        #x coordinate of the previous inflexion point
        previousX = 0
        previousY = 0
        append!(x, previousX)
        append!(y, previousY)
        #Current position in the line
        currentId = 1
        #While the end of the line is not reached 
        while currentId != size(results, 2) && results[dim, currentId] != Inf
            #Number of elements which have the value previousX
            identicalValues = 1
             #While the value is the same
            while results[dim, currentId] == previousX && currentId <= size(results, 2)
                currentId += 1
                identicalValues += 1
            end
            #Add the proper points
            append!(x, previousX)
            append!(y, currentId - 1)
            if results[dim, currentId] != Inf
                append!(x, results[dim, currentId])
                append!(y, currentId - 1)
            end
            previousX = results[dim, currentId]
            previousY = currentId - 1
        end
        append!(x, maxSolveTime)
        append!(y, currentId - 1)
        #If it is the first subfolder
        if dim == 1
            # Draw a new plot
            plot(x, y, label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)
        #Otherwise 
        else
            #Add the new curve to the created plot
            savefig(plot!(x, y, label = folderName[dim], linewidth=3), outputFile)
        end 
    end
end 

"""
Create a latex file which contains an array with the results of the ../res folder.
Each subfolder of the ../res folder contains the results of a resolution method.

Arguments
- outputFile: path of the output file

Prerequisites:
- Each subfolder must contain text files
- Each text file correspond to the resolution of one instance
- Each text file contains a variable "solveTime" and a variable "isOptimal"
"""
function resultsArray(outputFile::String)
    resultFolder = "../res/"
    dataFolder = "../data/"
    # Maximal number of files in a subfolder
    maxSize = 0
    # Number of subfolders
    subfolderCount = 0
    # Open the latex output file
    fout = open(outputFile, "w")
    # Print the latex file output
    println(fout, raw"""\documentclass{article}
\usepackage[french]{babel}
\usepackage [utf8] {inputenc} % utf-8 / latin1 
\usepackage{multicol}

\setlength{\hoffset}{-18pt}
\setlength{\oddsidemargin}{0pt} % Marge gauche sur pages impaires
\setlength{\evensidemargin}{9pt} % Marge gauche sur pages paires
\setlength{\marginparwidth}{54pt} % Largeur de note dans la marge
\setlength{\textwidth}{481pt} % Largeur de la zone de texte (17cm)
\setlength{\voffset}{-18pt} % Bon pour DOS
\setlength{\marginparsep}{7pt} % Séparation de la marge
\setlength{\topmargin}{0pt} % Pas de marge en haut
\setlength{\headheight}{13pt} % Haut de page
\setlength{\headsep}{10pt} % Entre le haut de page et le texte
\setlength{\footskip}{27pt} % Bas de page + séparation
\setlength{\textheight}{668pt} % Hauteur de la zone de texte (25cm)

\begin{document}""")

    header = raw"""
\begin{center}
\renewcommand{\arraystretch}{1.4} 
 \begin{tabular}{l"""
    # Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()
    # List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()
    # For each file in the result folder
    for file in readdir(resultFolder)
        path = resultFolder * file
        # If it is a subfolder
        if isdir(path)
            # Add its name to the folder list
            folderName = vcat(folderName, file)
            subfolderCount += 1
            folderSize = size(readdir(path), 1)
            # Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end
            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end
    # Only keep one string for each instance solved
    unique(solvedInstances)
    # For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end
    header *= "}\n\t\\hline\n"
    # Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end
    header *= "\\\\\n\\textbf{Instance} "
    # Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end
    header *= "\\\\\\hline\n"
    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)
    # On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1
    # For each solved files
    for solvedInstance in solvedInstances
        # If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 
        # Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))
        # For each resolution method
        for method in folderName
            path = resultFolder * method * "/" * solvedInstance
            # If the instance has been solved by this method
            if isfile(path)
                include(path)
                println(fout, " & ", round(solveTime, digits=2), " & ")
                if isOptimal
                    println(fout, "\$\\times\$")
                end
            # If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end
        println(fout, "\\\\")
        id += 1
    end
    # Print the end of the latex file
    println(fout, footer)
    println(fout, "\\end{document}")
    close(fout)  
end