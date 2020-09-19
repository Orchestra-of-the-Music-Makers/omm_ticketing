module Main exposing (..)

import Browser
import Browser.Navigation
import Html exposing (h1, text)
import Html.Attributes exposing (title)
import Url


type alias Model =
    {}


type Msg
    = Abc


type alias Flags =
    {}


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }


init : Flags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags urlUrl keyNavigationBrowser =
    ( {}, Cmd.none )


view : Model -> Browser.Document Msg
view model =
    Browser.Document "OMM Ticketing"
        [ h1 [] [ text "hello" ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( {}, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest urlRequestBrowser =
    Abc


onUrlChange : Url.Url -> Msg
onUrlChange urlUrl =
    Abc
