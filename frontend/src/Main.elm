module Main exposing (..)

import Browser
import Model exposing (Model)
import Msg exposing (Msg(..))
import Subscriptions exposing (subscriptions)
import Update exposing (init, update)
import View exposing (view)



---- MODEL ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }
