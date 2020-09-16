module Subscriptions exposing (subscriptions)

import Model exposing (Model)
import Msg exposing (Msg(..))
import RemoteData exposing (RemoteData(..))
import Time


subscriptions : Model -> Sub Msg
subscriptions model =
    -- tick the timer if inputGeneRemote is not asked and the prefix length is more than 1
    case model.inputGeneRemote of
        NotAsked ->
            if String.length model.inputGeneString > 1 then
                Time.every 500 (\_ -> Tick model.inputGeneString)

            else
                Sub.none

        _ ->
            Sub.none
