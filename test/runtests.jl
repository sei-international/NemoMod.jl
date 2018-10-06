#= Implements tests for NemoMod package. =#
using NemoMod
using Test, SQLite, DataFrames

dbfile = normpath(joinpath(dirname(pathof(NemoMod)),"../test/utopia.sqlite"))
dbfile2 = normpath(joinpath(dirname(pathof(NemoMod)),"../test/test.sqlite"))
cp(dbfile, dbfile2; force=true)

NemoMod.nemomain(dbfile2, "GLPK")

db = SQLite.DB(dbfile2)
testqry = SQLite.query(db, "select * from vtotaldiscountedcost")

@test testqry[1,:y] == "1990"
@test testqry[2,:y] == "1991"
@test testqry[3,:y] == "1992"
@test testqry[4,:y] == "1993"
@test testqry[5,:y] == "1994"
@test testqry[6,:y] == "1995"
@test testqry[7,:y] == "1996"
@test testqry[8,:y] == "1997"
@test testqry[9,:y] == "1998"
@test testqry[10,:y] == "1999"
@test testqry[11,:y] == "2000"
@test testqry[12,:y] == "2001"
@test testqry[13,:y] == "2002"
@test testqry[14,:y] == "2003"
@test testqry[15,:y] == "2004"
@test testqry[16,:y] == "2005"
@test testqry[17,:y] == "2006"
@test testqry[18,:y] == "2007"
@test testqry[19,:y] == "2008"
@test testqry[20,:y] == "2009"
@test testqry[21,:y] == "2010"

@test round(testqry[1,:val], 6) == 7078.726833
@test round(testqry[2,:val], 6) == 1376.094496
@test round(testqry[3,:val], 6) == 1424.622928
@test round(testqry[4,:val], 6) == 1299.845856
@test round(testqry[5,:val], 6) == 1341.383291
@test round(testqry[6,:val], 6) == 1214.807617
@test round(testqry[7,:val], 6) == 1196.944055
@test round(testqry[8,:val], 6) == 1207.676216
@test round(testqry[9,:val], 6) == 1098.252384
@test round(testqry[10,:val], 6) == 1117.595158
@test round(testqry[11,:val], 6) == 1047.769294
@test round(testqry[12,:val], 6) == 1125.578368
@test round(testqry[13,:val], 6) == 1047.590383
@test round(testqry[14,:val], 6) == 1023.135753
@test round(testqry[15,:val], 6) == 937.081597
@test round(testqry[16,:val], 6) == 2029.877355
@test round(testqry[17,:val], 6) == 885.294875
@test round(testqry[18,:val], 6) == 838.923596
@test round(testqry[19,:val], 6) == 777.346299
@test round(testqry[20,:val], 6) == 718.732469
@test round(testqry[21,:val], 6) == 659.805869

rm(dbfile2)
