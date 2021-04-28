module Booklet exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, a, button, canvas, div, p, text)
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)
import Task
import Time


type alias Flags =
    {}


type alias Model =
    { zone : Time.Zone
    , time : Time.Posix
    , displaySurveyBanner : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { zone = Time.utc
      , time = Time.millisToPosix 0
      , displaySurveyBanner = False
      }
    , Task.perform AdjustTimeZone Time.here
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            let
                concertHasEnded =
                    not
                        ((Time.posixToMillis newTime < 1619859600000)
                            || (Time.posixToMillis newTime > 1619938800000 && Time.posixToMillis newTime < 1619946000000)
                            || (Time.posixToMillis newTime > 1619953200000 && Time.posixToMillis newTime < 1619960400000)
                        )
            in
            ( { model | time = newTime, displaySurveyBanner = concertHasEnded }
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )



-- PORT
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Time.every 1000 Tick
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        banner =
            if model.displaySurveyBanner then
                div [ class "sticky top-bar" ] [ a [ href "https://docs.google.com/forms/d/1rVGMwOJXjhxxdW2Z8ftcEQ3Xjn5S8rC23cpn5rB90po/edit" ] [ text "Take post-concert survey >>" ] ]

            else
                div [] []
    in
    div
        []
        [ banner
        , div [ id "pdf-viewer" ] []
        ]



---- PROGRAM ----


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
