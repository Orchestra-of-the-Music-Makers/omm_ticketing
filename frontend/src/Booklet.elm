port module Booklet exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, a, br, button, canvas, div, header, p, text)
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)
import Task
import Time


type alias Flags =
    { title : String
    , numPages : Int
    , pageNum : Int
    , concertSlot : String
    }


type alias Model =
    { title : String
    , numPages : Int
    , pageNum : Int
    , startEvent : Maybe TouchEvent
    , concertSlot : ConcertSlot
    , zone : Time.Zone
    , time : Time.Posix
    , displaySurveyBanner : Bool
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        concertSlot =
            case flags.concertSlot of
                "may1" ->
                    May1

                "may24" ->
                    May24

                "may28" ->
                    May28

                _ ->
                    Unknown
    in
    ( { title = flags.title
      , numPages = flags.numPages
      , pageNum = flags.pageNum
      , startEvent = Nothing
      , concertSlot = concertSlot
      , zone = Time.utc
      , time = Time.millisToPosix 0
      , displaySurveyBanner = False
      }
    , Task.perform AdjustTimeZone Time.here
    )



-- UPDATE


type Msg
    = PrevPage
    | NextPage
    | TouchOther (List TouchEvent)
    | TouchStart (List TouchEvent)
    | TouchEnd (List TouchEvent)
    | Tick Time.Posix
    | AdjustTimeZone Time.Zone


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PrevPage ->
            let
                pageNum =
                    if model.pageNum <= 1 then
                        1

                    else
                        model.pageNum - 1
            in
            ( { model | pageNum = pageNum }, paginate pageNum )

        NextPage ->
            let
                ( pageNum, cmd ) =
                    if model.pageNum >= model.numPages then
                        ( model.numPages, Cmd.none )

                    else
                        ( model.pageNum + 1, paginate (model.pageNum + 1) )
            in
            ( { model | pageNum = pageNum }, cmd )

        TouchStart event ->
            let
                startEvent =
                    if List.length event > 1 then
                        Nothing

                    else
                        List.head event
            in
            ( { model | startEvent = startEvent }, Cmd.none )

        TouchEnd event ->
            let
                swipeDirection =
                    case ( model.startEvent, List.head event ) of
                        ( Just startEvent, Just endEvent ) ->
                            if startEvent.pageX - endEvent.pageX > 75 then
                                Just Left

                            else if startEvent.pageX - endEvent.pageX < -75 then
                                Just Right

                            else
                                Nothing

                        ( Nothing, _ ) ->
                            Nothing

                        ( _, Nothing ) ->
                            Nothing

                ( newPageNum, cmd ) =
                    case swipeDirection of
                        Just Right ->
                            let
                                pageNum =
                                    if model.pageNum <= 1 then
                                        1

                                    else
                                        model.pageNum - 1
                            in
                            ( pageNum, paginate pageNum )

                        Just Left ->
                            let
                                pageNum =
                                    if model.pageNum >= model.numPages then
                                        model.numPages

                                    else
                                        model.pageNum + 1
                            in
                            ( pageNum, paginate pageNum )

                        Nothing ->
                            ( model.pageNum, Cmd.none )
            in
            ( { model | startEvent = Nothing, pageNum = newPageNum }, cmd )

        TouchOther event ->
            let
                startEvent =
                    if List.length event > 1 then
                        Nothing

                    else
                        model.startEvent
            in
            ( { model | startEvent = startEvent }, Cmd.none )

        Tick newTime ->
            let
                concertHasEnded =
                    case model.concertSlot of
                        Unknown ->
                            True

                        May1 ->
                            Time.posixToMillis newTime > 1619340120000

                        May24 ->
                            Time.posixToMillis newTime > 1619340120000

                        May28 ->
                            Time.posixToMillis newTime > 1619340120000
            in
            ( { model | time = newTime, displaySurveyBanner = concertHasEnded }
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )



-- PORT


port paginate : Int -> Cmd msg


port touchStart : (List TouchEvent -> msg) -> Sub msg


port touchMove : (List TouchEvent -> msg) -> Sub msg


port touchEnd : (List TouchEvent -> msg) -> Sub msg


port touchCancel : (List TouchEvent -> msg) -> Sub msg


type alias TouchEvent =
    { identifier : Int
    , pageX : Float
    , pageY : Float
    }


type SwipeDirection
    = Left
    | Right



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ touchStart TouchStart
        , touchMove TouchOther
        , touchEnd TouchEnd
        , touchCancel TouchOther
        , Time.every 1000 Tick
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
        , canvas [ id "canvas" ] []
        , div [ class "fixed-bottom page-navigation" ]
            [ button [ onClick PrevPage ] [ text "< Prev" ]
            , p [] [ text (String.fromInt model.pageNum ++ " / " ++ String.fromInt model.numPages) ]
            , button [ onClick NextPage ] [ text "Next >" ]
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



---- DATA ----


type ConcertSlot
    = May1
    | May24
    | May28
    | Unknown
