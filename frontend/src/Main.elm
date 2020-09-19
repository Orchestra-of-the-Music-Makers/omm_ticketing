module Main exposing (..)

import API
import Browser
import Browser.Navigation
import Html exposing (div, h1, p, text)
import Html.Attributes exposing (title)
import Http
import Iso8601
import Route
import Types exposing (..)
import Url
import Url.Parser


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = OnUrlRequest
        , onUrlChange = OnUrlChange
        }


init : Flags -> Url.Url -> Browser.Navigation.Key -> ( Model, Cmd Msg )
init flags urlUrl navKey =
    let
        model =
            { apiKey = flags.apiKey
            , lambdaUrl = flags.lambdaUrl
            , currentPage = Route.NotFound
            , navKey = navKey
            , currentTicket = Nothing
            }
    in
    updateWithURL urlUrl model


view : Model -> Browser.Document Msg
view model =
    let
        page =
            case model.currentPage of
                Route.TicketStatus string ->
                    ticketStatusPage (Maybe.withDefault emptyGetTicketStatusResponse model.currentTicket)

                Route.NotFound ->
                    notFoundPage
    in
    Browser.Document "OMM Ticketing"
        [ page
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case Debug.log "update" msg of
        -- [url] decide what to do
        OnUrlRequest (Browser.Internal url) ->
            ( model, Browser.Navigation.pushUrl model.navKey (Url.toString url) )

        OnUrlRequest (Browser.External "") ->
            -- when we have `a` with `onClick` but without `href`
            -- we'll get this event; should ignore
            ( model, Cmd.none )

        OnUrlRequest (Browser.External urlString) ->
            ( model, Browser.Navigation.load urlString )

        -- [url] given that we _are at this url_ how should our model change?
        OnUrlChange url ->
            updateWithURL url model

        GotTicketStatus (Result.Ok result) ->
            ( { model | currentTicket = Just result }, Cmd.none )

        GotTicketStatus (Result.Err error) ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


updateWithURL : Url.Url -> Model -> ( Model, Cmd Msg )
updateWithURL url model =
    let
        currentPage =
            url
                |> Url.Parser.parse Route.route
                |> Maybe.withDefault Route.NotFound

        newModel =
            { model | currentPage = currentPage }
    in
    case currentPage of
        Route.TicketStatus s ->
            ( newModel, API.getTicketStatus newModel.lambdaUrl newModel.apiKey s )

        Route.NotFound ->
            ( newModel, Cmd.none )


ticketStatusPage : GetTicketStatusResponse -> Html.Html Msg
ticketStatusPage ticket =
    let
        scannedAt =
            case ticket.scannedAt of
                Just posixTime ->
                    Iso8601.fromTime posixTime

                Nothing ->
                    "Ticket hasn't been scanned"
    in
    div []
        [ h1 [] [ text "Ticket Status" ]
        , p [] [ text ("seatID: " ++ ticket.seatID) ]
        , p [] [ text ("ticketID: " ++ ticket.ticketID) ]
        , p [] [ text ("scannedAt: " ++ scannedAt) ]
        ]


notFoundPage : Html.Html Msg
notFoundPage =
    h1 [] [ text "404 Not Found" ]
