port module Booklet exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, a, br, button, canvas, div, header, p, text)
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)


type alias Flags =
    { title : String
    , numPages : Int
    , pageNum : Int
    }


type alias Model =
    { title : String
    , numPages : Int
    , pageNum : Int
    , startEvent : Maybe TouchEvent
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model flags.title flags.numPages flags.pageNum Nothing, Cmd.none )



-- UPDATE


type Msg
    = PrevPage
    | NextPage
    | TouchOther (List TouchEvent)
    | TouchStart (List TouchEvent)
    | TouchEnd (List TouchEvent)


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
            ( { model | startEvent = List.head event }, Cmd.none )

        TouchEnd event ->
            let
                swipeDirection =
                    case ( model.startEvent, List.head event ) of
                        ( Just startEvent, Just endEvent ) ->
                            if startEvent.pageX - endEvent.pageX > 30 then
                                Just Left

                            else if startEvent.pageX - endEvent.pageX < -30 then
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
            ( model, Cmd.none )



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
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div
        []
        [ div [ class "sticky top-bar" ] [ a [ href "https://docs.google.com/forms/d/1rVGMwOJXjhxxdW2Z8ftcEQ3Xjn5S8rC23cpn5rB90po/edit" ] [ text "Take post-concert survey >>" ] ]
        , br [] []
        , canvas [ id "canvas" ] []
        , div [ class "fixed-bottom" ]
            [ p [ class "white" ] [ text ("Page: " ++ String.fromInt model.pageNum ++ " of " ++ String.fromInt model.numPages) ]
            , button [ onClick PrevPage ] [ text "< Prev Page" ]
            , button [ onClick NextPage ] [ text "Next Page >" ]
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
