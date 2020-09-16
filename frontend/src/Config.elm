module Config exposing (..)

import ConfigGene exposing (ConfigGene)
import ControlType exposing (ControlType)
import Dict exposing (Dict)
import Gene exposing (Gene)
import Json.Encode as Encode exposing (Value)
import Profile exposing (Profile)
import Side exposing (Side)
import Study exposing (Study)



-- Creating a configuration


{-| Configuration that is in the process of being created.

Genes are stored as a dictionary keyed by the HUGO ID.

-}
type alias InProgress =
    { study : Maybe Study
    , profile : Maybe Profile
    , genes : Dict String ConfigGene
    }


default : InProgress
default =
    { study = Nothing
    , profile = Nothing
    , genes = Dict.empty
    }



-- Configuration creator helpers


setStudy : Study -> InProgress -> InProgress
setStudy study data =
    { data | study = Just study }


setProfile : Profile -> InProgress -> InProgress
setProfile profile data =
    { data | profile = Just profile }


addGene : Gene -> InProgress -> InProgress
addGene gene data =
    { data | genes = Dict.insert gene.hugo (ConfigGene.fromGene gene) data.genes }


removeGene : Gene -> InProgress -> InProgress
removeGene gene data =
    { data | genes = Dict.remove gene.hugo data.genes }


getGeneList : InProgress -> List ConfigGene
getGeneList data =
    Dict.values data.genes


updateGeneSide : Gene -> Side -> InProgress -> InProgress
updateGeneSide gene side data =
    { data | genes = Dict.update gene.hugo (\m -> Maybe.map (ConfigGene.setSide side) m) data.genes }


updateGeneControlType : Gene -> ControlType -> InProgress -> InProgress
updateGeneControlType gene controlType data =
    { data | genes = Dict.update gene.hugo (\m -> Maybe.map (ConfigGene.setControlType controlType) m) data.genes }


updateGeneThreshold : Gene -> Side -> Int -> InProgress -> InProgress
updateGeneThreshold gene side threshold data =
    if (threshold < 0) || (threshold > 100) then
        data

    else
        { data | genes = Dict.update gene.hugo (\m -> Maybe.map (ConfigGene.setThreshold threshold) m) data.genes }



-- check if valid


validate : InProgress -> Maybe Config
validate config =
    let
        withUnmaybe study profile =
            { study = study
            , profile = profile
            , genes = getGeneList config
            }
    in
    if Dict.size config.genes > 0 then
        Maybe.map2 withUnmaybe config.study config.profile

    else
        Nothing



-- A full configuration


type alias Config =
    { study : Study
    , profile : Profile
    , genes : List ConfigGene
    }


encode : Config -> Value
encode config =
    Encode.object
        [ ( "study_id", Encode.string config.study.id )
        , ( "molecular_profile_id", Encode.string config.profile.id )
        , ( "genes", Encode.list ConfigGene.encode config.genes )
        ]
