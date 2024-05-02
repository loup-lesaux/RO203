# This file contains functions related to reading, writing and displaying a grid and experimental results

using JuMP
#using Plots
import .GR
#using DataFrames, PlotlyJS

cwd=pwd()
adresse="/Projet/RO203/Pegs"

"""
Read an instance from an input file

- Argument:
inputFile: path of the input file
"""

function readInputFile(inputFile::String)
    # Open the input file
    datafile = open(inputFile)    
    data = readlines(datafile)
    close(datafile)
    n=length(split(data[1],","))-1
    print(n)
    grid=Matrix{Int64}(zeros(n, n))
    # For each line of the input file
    for line in 1:n
        lineSplit = split(data[line],",")
        for col in 1:n
            if lineSplit[col]==" "
            grid[line,col] = 2
            elseif lineSplit[col]=="x"
                grid[line,col] = 1
            else
                grid[line,col] = 0
            end
        end
    end
    return grid
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
##################################CETTE FONCTION EST MAUDITE, REPARTIR DE ZERO.
# function performanceDiagram(outputFile::String)
#     resultFolder = cwd*adresse*"/res/"
#     maxSize=4 #Maximal number of files in a subfolder
#     subfolderCount=0 #Number of subfolders
#     folderName = Vector{String}()
#     for file in readdir(resultFolder) #For each file in the result folder
#         path = resultFolder * file
#         if isdir(path) #If it is a subfolder
#             folderName = vcat(folderName, file)
#             subfolderCount += 1
#             folderSize = size(readdir(path), 1)
#             if maxSize < folderSize
#                 maxSize = folderSize
#             end
#         end
#     end
#     #Array that will contain the resolution times (one line for each subfolder)
#     results = Array{Float64,2}(undef, 1, subfolderCount*maxSize)
#     for i in 1:subfolderCount
#         for j in 1:maxSize
#             results[1, (i-1)*maxSize+j] = Inf
#         end
#     end
#     folderCount = 0
#     maxSolveTime = 0
#     #For each subfolder
#     for file in readdir(resultFolder)
#         path = resultFolder * file
#         if isdir(path)
#             folderCount += 1
#             fileCount = 0
#             #For each text file in the subfolder
#             for resultFile in filter(x->occursin(".txt", x), readdir(path))
#                 fileCount += 1
#                 readlines(path * "/" * resultFile)
#                 solveTime=readlines(path * "/" * resultFile)[1][13:18]
#                 #solveTime=replace(solveTime, "." => ",")
#                 solveTime = parse(Float64, solveTime)
#                 isOptimal = readlines(path * "/" * resultFile)[2][13:16]
#                 results[1, (folderCount-1)*maxSize+fileCount] = solveTime
#             end
#         end
#     end
#     #Sort each row increasingly
#     # println("Max solve time: ", maxSolveTime)
#     # x = Array{Float64, 1}()
#     # y = Array{Float64, 1}()
#     # #x coordinate of the previous inflexion point
#     # previousX = 0
#     # previousY = 0
#     # append!(x, previousX)
#     # append!(y, previousY)
#     # #Current position in the line
#     # currentId = 1
#     # #While the end of the line is not reached 
#     # while currentId != size(results, 2) && results[1, currentId] != Inf
#     #     #Number of elements which have the value previousX
#     #     identicalValues = 1
#     #     #While the value is the same
#     #     while results[1, currentId] == previousX && currentId <= size(results, 2)
#     #         currentId += 1
#     #         identicalValues += 1
#     #     end
#     #     #Add the proper points
#     #     append!(x, previousX)
#     #     append!(y, currentId - 1)
#     #     if results[1, currentId] != Inf
#     #         append!(x, results[1, currentId])
#     #         append!(y, currentId - 1)
#     #     end
#     #     previousX = results[1, currentId]
#     #     previousY = currentId - 1
#     # end
#     # append!(x, maxSolveTime)
#     # append!(y, currentId - 1)
#     # println(size(x))
#     solver=["test","test","test","test","test"]
#     x1=[results[1,1],results[1,6],results[1,11],results[1,16]]
#     x2=[results[1,2],results[1,7],results[1,12],results[1,17]]
#     x3=[results[1,3],results[1,8],results[1,13],results[1,18]]
#     x4=[results[1,4],results[1,9],results[1,14],results[1,19]]
#     x5=[results[1,5],results[1,10],results[1,15],results[1,20]]
#     df=DataFrame()
#     df.A = x1
#     df[:, :B]=x2
#     df[:, :C]=x3
#     df[:, :D]=x4
#     df[:, :E]=x5
#     #df=DataFrame(x1,x2,x3,x4,x5)
#     #plot(x,kind="bar", label = folderName[dim], legend = :bottomright, xaxis = "Time (s)", yaxis = "Solved instances",linewidth=3)
#     plt=plot(bar(df, x=:"test1", y =:"cc"))
#     # plot(bar(x1[1],label="cross 5"))
#     # plot(bar(x1[2]),label="cross 7")
#     # plot(bar(x1[3]),label="europe 5")
#     # plot(bar(x1[4]),label="europe 7")
#     # plot(bar(x2[1]),label="cross 5")
#     # plot(bar(x2[2]),label="cross 7")
#     # plot(bar(x2[3]),label="europe 5")
#     # plot(bar(x2[4]),label="europe 7")
#     # plot(bar(x3[1]),label="cross 5")
#     # plot(bar(x3[2]),label="cross 7")
#     # plot(bar(x3[3]),label="europe 5")
#     # plot(bar(x3[4]),label="europe 7")
#     # plot(bar(x4[1]),label="cross 5")
#     # plot(bar(x4[2]),label="cross 7")
#     # plot(bar(x4[3]),label="europe 5")
#     # plot(bar(x4[4]),label="europe 7")
#     # plot(bar(x5[1]),label="cross 5")
#     # plot(bar(x5[2]),label="cross 7")
#     # plot(bar(x5[3]),label="europe 5")
#     # plot(bar(x5[4]),label="europe 7")
#     #plot(groupedbar(["cross 5","cross 7","europe 5","europe 7"],[x1,x2,x3,x4,x5], group=["cplex","heuristique_agglo","heuristique_agglo_wp","heuristique_random","heuristique_closer_to_center"],title="Temps de résolution", label="Type de solveur", color=:blue))
#     savefig(plt,outputFile)
# end

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

###############FONCTION NON IMPLEMENTEE

function resultsArray(outputFile::String)
    resultFolder = cwd*adresse*"/res/"
    dataFolder = cwd*adresse*"/data/"
    #Maximal number of files in a subfolder
    maxSize = 42
    # Number of subfolders
    subfolderCount = 1
    #Open the latex output file
    fout = open(outputFile, "w")
    #Print the latex file output
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
    #Name of the subfolder of the result folder (i.e, the resolution methods used)
    folderName = Array{String, 1}()
    #List of all the instances solved by at least one resolution method
    solvedInstances = Array{String, 1}()
    #For each file in the result folder
    for file in readdir(resultFolder)
        path = resultFolder * file
        #If it is a subfolder
        if isdir(path)
            #Add its name to the folder list
            folderName = vcat(folderName, file)
            subfolderCount += 1
            folderSize = size(readdir(path), 1)
            #Add all its files in the solvedInstances array
            for file2 in filter(x->occursin(".txt", x), readdir(path))
                solvedInstances = vcat(solvedInstances, file2)
            end
            if maxSize < folderSize
                maxSize = folderSize
            end
        end
    end
    #Only keep one string for each instance solved
    unique(solvedInstances)
    #For each resolution method, add two columns in the array
    for folder in folderName
        header *= "rr"
    end
    header *= "}\n\t\\hline\n"
    #Create the header line which contains the methods name
    for folder in folderName
        header *= " & \\multicolumn{2}{c}{\\textbf{" * folder * "}}"
    end
    header *= "\\\\\n\\textbf{Instance} "
    #Create the second header line with the content of the result columns
    for folder in folderName
        header *= " & \\textbf{Temps (s)} & \\textbf{Optimal ?} "
    end
    header *= "\\\\\\hline\n"
    footer = raw"""\hline\end{tabular}
\end{center}

"""
    println(fout, header)
    #On each page an array will contain at most maxInstancePerPage lines with results
    maxInstancePerPage = 30
    id = 1
    # For each solved files
    for solvedInstance in solvedInstances
        #If we do not start a new array on a new page
        if rem(id, maxInstancePerPage) == 0
            println(fout, footer, "\\newpage")
            println(fout, header)
        end 
        #Replace the potential underscores '_' in file names
        print(fout, replace(solvedInstance, "_" => "\\_"))
        #For each resolution method
        for method in folderName
            path = resultFolder * method * "/" * solvedInstance
            #If the instance has been solved by this method
            if isfile(path)
                readlines(path)
                solveTime=readlines(path)[end-1][13:18]
                #solveTime=replace(solveTime, "." => ",")
                solveTime = parse(Float64, solveTime)
                isOptimal=readlines(path)[end][13:16]
                println(fout, " & ", round(solveTime, digits=2), " & ")
                if isOptimal=="true"
                    println(fout, "\$\\times\$")
                end
            #If the instance has not been solved by this method
            else
                println(fout, " & - & - ")
            end
        end
        println(fout, "\\\\")
        id += 1
    end
    #Print the end of the latex file
    println(fout, footer)
    println(fout, "\\end{document}")
    close(fout)
end 

#performanceDiagram(cwd*adresse*"/res/graphe.png")
#resultsArray(cwd*adresse*"/LaTeX/array.tex")