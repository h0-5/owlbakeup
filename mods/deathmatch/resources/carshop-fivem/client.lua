txd = engineLoadTXD ( "objeto/1.txd" ) --Coloque o nome do TXD
engineImportTXD ( txd, 4019 ) --Coloque o ID do objeto que você quer modificar
col = engineLoadCOL ( "objeto/1.col" ) --Coloque o nome do arquivo COL
engineReplaceCOL ( col, 4019 ) --Coloque o ID do objeto que você quer modificar
dff = engineLoadDFF ( "objeto/1.dff", 0 ) --Coloque o nome do DFF e não mexa nesse 0
engineReplaceModel ( dff, 4019 ) --Coloque o ID do objeto que você quer modificar
engineSetModelLODDistance(4019, 500) --ID do objeto e a distância que ele irá carregar - distancia está como 500

-------------------------------------------------------------------------------------------------------------------------

txd = engineLoadTXD ( "objeto/porta.txd" ) --Coloque o nome do TXD
engineImportTXD ( txd, 18553 ) --Coloque o ID do objeto que você quer modificar
col = engineLoadCOL ( "objeto/porta.col" ) --Coloque o nome do arquivo COL
engineReplaceCOL ( col, 18553 ) --Coloque o ID do objeto que você quer modificar
dff = engineLoadDFF ( "objeto/porta.dff", 0 ) --Coloque o nome do DFF e não mexa nesse 0
engineReplaceModel ( dff, 18553 ) --Coloque o ID do objeto que você quer modificar
engineSetModelLODDistance(18553, 500) --ID do objeto e a distância que ele irá carregar - distancia está como 500

-----------------------------------------------------------------------------------------------------------------------------

txd = engineLoadTXD ( "objeto/model.txd" ) --Coloque o nome do TXD
engineImportTXD ( txd, 4215 ) --Coloque o ID do objeto que você quer modificar
col = engineLoadCOL ( "objeto/model.col" ) --Coloque o nome do arquivo COL
engineReplaceCOL ( col, 4215 ) --Coloque o ID do objeto que você quer modificar
dff = engineLoadDFF ( "objeto/model.dff", 0 ) --Coloque o nome do DFF e não mexa nesse 0
engineReplaceModel ( dff, 4215 ) --Coloque o ID do objeto que você quer modificar
engineSetModelLODDistance(4215, 500) --ID do objeto e a distância que ele irá carregar - distancia está como 500

setOcclusionsEnabled( false )

----------------------------------------------------------
--- Discord : https://discord.gg/wdNPPm6s5
----------------------------------------------------------