module Booklet exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, a, button, canvas, div, img, p, span, text)
import Html.Attributes exposing (class, height, href, id, src, width)
import Html.Events exposing (onClick)
import Task
import Time


type alias Flags =
    { displaySurveyBanner : Bool }


type alias Model =
    { zone : Time.Zone
    , time : Time.Posix
    , displaySurveyBanner : Bool
    , forceDisplayBanner : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { zone = Time.utc
      , time = Time.millisToPosix 0
      , displaySurveyBanner = False
      , forceDisplayBanner = flags.displaySurveyBanner
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
                    model.forceDisplayBanner
                        || not
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
                div [ class "sticky top-bar" ]
                    [ span []
                        [ text "Help us improve your experience! "
                        , span []
                            [ a
                                [ href "https://docs.google.com/forms/d/1rVGMwOJXjhxxdW2Z8ftcEQ3Xjn5S8rC23cpn5rB90po/edit" ]
                                [ span [] [ span [ class "link-text" ] [ text "Take survey" ] ]
                                , img [ src "assets/arrow-right.svg", width 12, height 12 ] []
                                ]
                            ]
                        ]
                    ]

            else
                div [] []
    in
    div
        []
        [ banner
        , div [ id "pdf-viewer" ]
            [ div [ id "viewer", class "pdfViewer" ] []
            ]
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
