module Analysis exposing (..)


type alias Analysis =
    { control : PlotData
    , test : PlotData
    }


type alias LineData =
    { times : List Float
    , survival : List Float
    }


type alias ScatterData =
    LineData


type alias PlotData =
    { steps : LineData
    , censors : ScatterData
    }
