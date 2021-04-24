port module Booklet exposing (Model, Msg(..), init, main, update, view)

import Browser
import Html exposing (Html, br, button, canvas, div, p, header, text, a)
import Html.Attributes exposing (id, class, href)
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
    }

init : Flags -> ( Model, Cmd Msg )
init flags =
    ( Model flags.title flags.numPages flags.pageNum, Cmd.none )



-- UPDATE


type Msg
    = PrevPage
    | NextPage
    | Touchhh (List TouchEvent)


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
                pageNum =
                    if model.pageNum >= model.numPages then
                        model.numPages

                    else
                        model.pageNum + 1
            in
            ( { model | pageNum = pageNum }, paginate pageNum )

        Touchhh event ->
          let
              _ =
                Debug.log "event" event
          in

          (model, Cmd.none)



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


-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
  Sub.batch [
    touchStart Touchhh
    , touchMove Touchhh
    , touchEnd Touchhh
    , touchCancel Touchhh
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
