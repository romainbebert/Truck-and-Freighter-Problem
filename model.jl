
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#
# Lecture des données
#
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

using JuMP
using Cbc
#using GLPKMathProgInterface
using DelimitedFiles

# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Type et structure
# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Type d'instance pour le truck and freighter routing problem
mutable struct t_instance
  nbJ         ::Int64                # number of customers
  nbJs        ::Int64
  nbP         ::Int64
  nbV         ::Int64
  custNo      ::Array{Int64, 1}
  lat         ::Array{Float64, 1}
  long        ::Array{Float64, 1}
  J           ::Array{Int64, 1}
  Js          ::Array{Int64, 1}
  P           ::Array{Int64, 1}
  V           ::Array{Int64, 1}
  q           ::Array{Int64, 1}
  Q           ::Int64
  t           ::Array{Float64, 2}
  alpha       ::Int64
  s           ::Int64
  a           ::Array{Int64, 1}
  b           ::Array{Int64, 1}
  T           ::Int64
end

# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Affichage d'uen instance
# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
function displayData(data::t_instance)
  println()
  println("¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤ INSTANCE ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤")
  println("$(data.nbJ) customers whose $(data.nbJs) small truck only, and 1 depot and $(data.nbP) parkings")
 
  println(" ($(data.custNo[1])) D : [$(data.a[1]), $(data.b[1])]")
  for i in data.P
    println(" ($(data.custNo[i])) P : [$(data.a[i]), $(data.b[i])]")
  end
  for i in data.Js
     println(" ($(data.custNo[i])) S : q = $(data.q[i]), s = $(data.s), [$(data.a[i]), $(data.b[i])]") 
  end
  for i in setdiff(data.J,data.Js)
     println(" ($(data.custNo[i])) LS : q = $(data.q[i]), s = $(data.s), [$(data.a[i]), $(data.b[i])]") 
  end
  println("t = ")
  for i = 1:data.nbV
    println(" ", data.t[i,:])
  end
  println("¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤")
  println()
end

# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Collect the un-hidden filenames available in a given directory
# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
function getfname(target::String)
  # target : string := chemin + nom du repertoire ou se trouve les instances

  rep_courant = pwd()
    
  # positionne le currentdirectory dans le repertoire cible
  cd(joinpath(rep_courant, target)) 

  # retourne le repertoire courant
  println("pwd = ", pwd())

  # recupere tous les fichiers se trouvant dans le repertoire data
  allfiles = readdir()

  # vecteur booleen qui marque les noms de fichiers valides
  flag = trues(size(allfiles))

  k=1  
  for f in allfiles
    # traite chaque fichier du repertoire
    if f[1] != '.'
      # pas un fichier cache => conserver
      println("fname = ", f) 
    else
      # fichier cache => supprimer
      flag[k] = false
    end
    k = k+1
  end

  # extrait les noms valides et retourne le vecteur correspondant
  finstances = allfiles[flag]

  for i = 1:length(finstances)
    finstances[i] = string(target, "/" ,finstances[i])
  end

  # replace le currentdirectory dans le répertoire courant
  cd(rep_courant)

  return finstances
end

# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Lecture  des parametres dans le fichier parametres.txt
# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
function readParameters()
  f = open("instances2018/parameters.txt", "r")
  readline(f)
  params =  parse.(Int64, split(readline(f)))
  close(f)
  return params
end

# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Lecture  des données dans un fichier T-N-P.txt
# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
function readData(params, nom_fichier)  
  # on récupère les valeurs de T N et P dans le nom de l'instance
  # (T-N-P.txt : T - distribution geographique des points, N - nombre de clients, P - nombre de parking)
  name = split(nom_fichier[15:end-4], "-")

  # initilisation
  nbJ = parse.(Int64, name[3])
  nbP = parse.(Int64, name[2])
  nbV = nbJ + nbP + 2
  custNo = zeros(Int64, nbV)
  lat = zeros(Float64, nbV)
  long = zeros(Float64, nbV)
  J = Int64[]
  Js = Int64[]
  P = zeros(Int64, nbP)
  V = collect(1:nbV)
  q = zeros(Int64, nbV)
  Q = params[1]
  t = zeros(Float64, nbV, nbV)
  alpha = params[2]
  s = params[5]
  a = zeros(Int64, nbV)
  b = zeros(Int64, nbV)
  T = params[3]

  f = open(nom_fichier, "r")

  readline(f)

  j = 1
  for i = 1:nbV-1
    line = split(readline(f))
    
    custNo[i] = parse.(Int64, line[1])
    lat[i] = parse.(Float64, line[4])
    long[i] = parse.(Float64, line[5])

    if line[3] == "S" || line[3] == "LS"
      push!(J, i)
      if line[3] == "S"
        push!(Js, i)
      end
    elseif line[3] == "P"
      P[j] = i
      j += 1
    end

    q[i] = parse.(Int64, line[2])
    a[i] = parse.(Int64, line[6])
    if line[3] == "D" || line[3] == "P"
      b[i] = a[i] + params[3]
    else
      b[i] = a[i] + params[4]
    end
  end
  # on double le dépôt
  custNo[nbV] = custNo[1]
  lat[nbV] = lat[1]
  long[nbV] = long[1]
  q[nbV] = q[1]
  a[nbV] = a[1]
  b[nbV] = b[1]

  nbJs = length(Js)

  close(f)
  
  # Récupération des t[i,j] dans distancematrix98.txt
  f = open("instances2018/distancematrix98.txt", "r")
  for i = 1:nbV
    for j = 1:nbV
      for k = 1:custNo[i]-1
        readline(f)
      end
      line = split(readline(f))
      t[i,j] = parse.(Float64, line[custNo[j]])
      seekstart(f) # replace le pointeur au début du fichier
    end
  end
  close(f)

  data = t_instance(nbJ, nbJs, nbP, nbV, custNo, lat, long, J, Js, P, V, q, Q, t, alpha, s, a, b, T)

  return data
end

# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
# Modélisation du problème
# ¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤
function modeliseTFRP(solverSelected, data::t_instance)

  # declaring a optimization model
  m = Model(solver=solverSelected)

  M = zeros(Float64, 2, data.nbV, data.nbV)
  for i = 1:data.nbV
    for j = 1:data.nbV
      M[1,i,j] = max(data.b[i]+data.s+data.t[i,j]-data.a[j], 0)
      M[2,i,j] = max(data.b[i]+data.s+data.alpha*data.t[i,j]-data.a[j], 0)
    end
  end
  #=
  println("M[1,:,:] = ")
  for i = 1:data.nbV
    println(" ", M[1,i,:])
  end
  println("M[2,:,:] = ")
  for i = 1:data.nbV
    println(" ", M[2,i,:])
  end
  =#

  Vdiff1 = setdiff(data.V, 1)
  VdiffnbV = setdiff(data.V, data.nbV)

  # Variables
  @variable(m, x[1:3, VdiffnbV, Vdiff1], Bin)
  @variable(m, u[data.V] >= 0, Int)
  @variable(m, w[1:2, data.V] >= 0)

  # Declaring the objective
  @objective(m, Min, sum(data.t[i,j] * x[1, i, j] 
                          + data.alpha * data.t[i,j] * x[2, i, j] 
                          - data.alpha * data.t[i,j] * x[3, i, j] for i in VdiffnbV, j in Vdiff1))

  # Declaring the constraints
  
  # Correspondance entre x[1,i,j], x[2,i,j] et x[3,i,j]
  @constraint(m, ctr11[k=1:2, i in VdiffnbV, j in Vdiff1], x[k,i,j] >= x[3,i,j])
  
  # Conservation des flots
  @constraint(m, ctr21[k=1:2, i in union(data.J, data.P)], sum(x[k,j,i] for j in setdiff(VdiffnbV, i))
                                                            == sum(x[k,i,j] for j in setdiff(Vdiff1, i)))

  @constraint(m, ctr22, sum(x[1,1,j] for j in Vdiff1) == 1)          # Départ dépôt
  @constraint(m, ctr23[j in Vdiff1], x[1,1,j] == x[2,1,j])           # Quand ils partent du dépôt, c'est en même temps
  @constraint(m, ctr24, sum(x[1,i,data.nbV] for i in VdiffnbV) == 1)        # Retour dépôt
  @constraint(m, ctr25[i in VdiffnbV], x[1,i,data.nbV] == x[2,i,data.nbV])  # Quand ils retournent au dépôt, c'est en même temps
  
  @constraint(m, ctr26[k=1:2], x[k,1,data.nbV] == 0) # Pas de trajet entre 1 et n+1
  @constraint(m, ctr28[i in data.J, j in VdiffnbV], x[1,j,i] + sum(x[2,l,i] for l in setdiff(VdiffnbV, j)) <= 1) # Interdit l'arrivée de 2 points différents si pas parking
  @constraint(m, ctr29[i in data.J, j in VdiffnbV], x[2,j,i] + sum(x[1,l,i] for l in setdiff(VdiffnbV, j)) <= 1)
  @constraint(m, ctr210[i in data.J, j in Vdiff1], x[1,i,j] + sum(x[2,i,l] for l in setdiff(Vdiff1, j)) <= 1) # Interdit de partir à 2 points différents si pas parking
  @constraint(m, ctr211[i in data.J, j in Vdiff1], x[2,i,j] + sum(x[1,i,l] for l in setdiff(Vdiff1, j)) <= 1)

  # Satisfaction de la demande
  @constraint(m, ctr31[i in data.J], sum(x[k,i,j] for k=1:2, j in setdiff(Vdiff1, i)) >= 1)   # Tous les J sont visités par au moins 1 véhicule
  @constraint(m, ctr32[i in data.Js], sum(x[1,i,j] for j in setdiff(Vdiff1, i)) == 0)         # Pas de gros véhicule sur les Js
 
  # Capacité
  @constraint(m, ctr41[i in data.J, j in Vdiff1], u[j] <= u[i] - data.q[i] + (1-x[2,i,j]) * data.Q)
  @constraint(m, ctr42[i in data.P, j in Vdiff1], u[j] <= data.Q + (1-x[2,i,j]) * data.q[j])
  
  # Temps
  @constraint(m, ctr51[k=1:2, i in data.V], data.a[i] <= w[k,i])
  @constraint(m, ctr52[k=1:2, i in data.V], w[k,i] <= data.b[i])
  @constraint(m, ctr53[i in VdiffnbV, j in setdiff(Vdiff1,i)], w[1,i] + data.s + data.t[i,j] - w[1,j] <= (1-x[1,i,j])*M[1,i,j])
  @constraint(m, ctr54[i in VdiffnbV, j in setdiff(Vdiff1,i)], w[2,i] + data.s + data.alpha*data.t[i,j] - w[2,j] <= (1-x[2,i,j])*M[2,i,j])
  @constraint(m, ctr55[i in union(data.P, 1, data.nbV)], w[1,i] == w[2,i])

  return m, x, u, w

end

# Set the solver to use
#solverSelected = GLPKSolverMIP() #tm_lim=30000) # solve the MILP with GLPK
solverSelected = CbcSolver() # solve the MILP with Cbc

allfinstance  = getfname("instances2018")
nbInstances   = length(allfinstance)
instance      = 11

println(allfinstance[instance])
params = readParameters()
data = readData(params, allfinstance[instance])
displayData(data)

#sol = t_solution(zeros(Int64, data.nb_var), 0)
lp, lp_x, lp_u, lp_w = modeliseTFRP(solverSelected, data)
println("   Temps de résolution : ")
# Solve the problem with the selected solver
status = @time solve(lp)

# Displaying the results
if status == :Optimal

  x = getvalue(lp_x)
  u = getvalue(lp_u)
  w = getvalue(lp_w)
  z = getobjectivevalue(lp)

  println("   Résolu à l'optimalité")
  #=
  println("   x = ", x)
  println("   u = ", u)
  println("   w = ", w)
  =#
  println("   Fonction objectif z = ", z) # optimal value of objective function

# Génération des fichiers de résultats pour la représentation graphique en python
  bigTruck = zeros(Int64,data.nbV, data.nbV)
  smallTruck = zeros(Int64,data.nbV, data.nbV)

  for i = 1:data.nbV-1 
    for j = 2:data.nbV
      bigTruck[i,j] = round(x[1,i,j])
      smallTruck[i,j] = round(x[2,i,j])
    end
  end
  println("Instance used : ", allfinstance[instance])
  writedlm("smallTruck.res", smallTruck)
  writedlm("bigTruck.res", bigTruck)

elseif status == :Unbounded

  println(" LP is unbounded")

elseif status == :Infeasible

  println(" LP is infeasible")

elseif status == :UserLimit

  println(" Iteration limit or timeout")

elseif status == :Error

  println(" Solver exited with an error")

elseif status == :NotSolved

  println(" Model built in memory but not optimized")

end
