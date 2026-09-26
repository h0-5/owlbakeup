addEventHandler('onClientResourceStart', resourceRoot, function () 

    txd = engineLoadTXD ( "1.txd", true )
    engineImportTXD ( txd, 10865 )
    col = engineLoadCOL ( "1.col" )
    engineReplaceCOL ( col, 10865 )
    dff = engineLoadDFF ( "1.dff", 0 )
    engineReplaceModel ( dff, 10865 , true)
    engineSetModelLODDistance(10865 , 500)

    txd = engineLoadTXD ( "2.txd", true )
    engineImportTXD ( txd, 10789 )
    col = engineLoadCOL ( "2.col" )
    engineReplaceCOL ( col, 10789 )
    dff = engineLoadDFF ( "2.dff", 0 )
    engineReplaceModel ( dff, 10789 , true)
    engineSetModelLODDistance(10789 , 500)

end)