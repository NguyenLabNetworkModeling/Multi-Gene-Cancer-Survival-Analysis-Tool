module ConfigGene exposing (..)

{-| Functions relating to the configuration of a single gene for analysis
-}

import ControlType exposing (ControlType)
import Enum
import Gene exposing (Gene)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Side exposing (Side)


type alias ConfigGene =
    { gene : Gene
    , side : Side
    , threshold : Int
    , controlType : ControlType
    }


{-| Creates config from a gene with an above 0.5 threshold default
-}
fromGene : Gene -> ConfigGene
fromGene gene =
    { gene = gene
    , side = Side.Above
    , threshold = 50
    , controlType = ControlType.Complement
    }


encode : ConfigGene -> Value
encode gene =
    Encode.object
        [ ( "hugo", Encode.string gene.gene.hugo )
        , ( "entrez", Encode.string gene.gene.entrez )
        , ( "side", Enum.encode Side.enum gene.side )
        , ( "threshold", Encode.int gene.threshold )
        , ( "control_type", Enum.encode ControlType.enum gene.controlType )
        ]



-- Setters


setSide : Side -> ConfigGene -> ConfigGene
setSide side config =
    -- update the threshold when updating the config to prevent invalid thresholds
    { config | side = side, threshold = 100 - config.threshold }


setThreshold : Int -> ConfigGene -> ConfigGene
setThreshold threshold config =
    -- update the side when updating the config to prevent invalid sides
    let
        side =
            if threshold == 50 then
                config.side

            else if threshold > 50 then
                Side.Above

            else
                Side.Below
    in
    { config | threshold = threshold, side = side }


setControlType : ControlType -> ConfigGene -> ConfigGene
setControlType controlType config =
    { config | controlType = controlType }
