module Analysis exposing (..)

import Array exposing (Array)
import Config
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)


type alias Analysis =
    { km : GroupData
    , cox : Statistics
    , eventType : String
    , eventTimeUnit : String
    , numAvailable : Int
    , numControl : Int
    , numTest : Int

    -- not bothering to decode returned config, should be the same as saved state on client
    --, config : Config
    }


decoder : Decoder Analysis
decoder =
    Decode.succeed Analysis
        |> required "km" decoderGroupData
        |> required "cox" decoderStatistics
        |> required "event_type" (Decode.string |> Decode.map String.toLower)
        |> required "event_time_unit" (Decode.string |> Decode.map String.toLower)
        |> required "num_available" Decode.int
        |> required "num_control" Decode.int
        |> required "num_test" Decode.int


type alias GroupData =
    { control : BothPlotData
    , test : BothPlotData
    }


decoderGroupData : Decoder GroupData
decoderGroupData =
    Decode.map2 GroupData
        (Decode.field "control" decoderBothPlotData)
        (Decode.field "test" decoderBothPlotData)


type alias Statistics =
    { pValue : Float
    , estimate : Float
    , hazardRatio : Float
    }


decoderStatistics : Decoder Statistics
decoderStatistics =
    Decode.map3 Statistics
        (Decode.field "p_value" Decode.float)
        (Decode.field "estimate" Decode.float)
        (Decode.field "hr" Decode.float)


type alias PlotData =
    { times : Array Float
    , survival : Array Float
    }


decoderPlotData : Decoder PlotData
decoderPlotData =
    Decode.map2 PlotData
        (Decode.field "times" (Decode.array Decode.float))
        (Decode.field "survival" (Decode.array Decode.float))


type alias BothPlotData =
    { steps : PlotData
    , censors : PlotData
    }


decoderBothPlotData : Decoder BothPlotData
decoderBothPlotData =
    Decode.map2 BothPlotData
        (Decode.field "steps" decoderPlotData)
        (Decode.field "censors" decoderPlotData)
