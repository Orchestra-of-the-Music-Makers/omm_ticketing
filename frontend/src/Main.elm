module Main exposing (..)

import API
import Browser
import Browser.Navigation
import Html exposing (button, div, form, h1, h5, input, label, p, text)
import Html.Attributes exposing (class, for, style, title, type_)
import Html.Events exposing (onInput, onSubmit)
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
            , password = ""
            }
    in
    updateWithURL urlUrl model


view : Model -> Browser.Document Msg
view model =
    let
        page =
            case model.currentPage of
                Route.TicketStatus string ->
                    ticketStatusPage (Maybe.withDefault emptyTicketStatus model.currentTicket)

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

        OnPasswordChanged s ->
            ( { model | password = s }, Cmd.none )

        OnMarkAsScannedSubmitted ticketID ->
            ( model, API.markTicketAsScanned model.lambdaUrl model.apiKey ticketID model.password )

        TicketMarkedAsScanned ticketID (Result.Ok result) ->
            case result.status of
                "success" ->
                    ( model, Browser.Navigation.pushUrl model.navKey (Route.toString (Route.TicketStatus ticketID)) )

                _ ->
                    ( model, Cmd.none )

        TicketMarkedAsScanned _ (Result.Err error) ->
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


ticketStatusPage : TicketStatus -> Html.Html Msg
ticketStatusPage ticket =
    let
        card =
            case ticket.scannedAt of
                Just posixTime ->
                    div [ class "card border-success mb-3" ]
                        [ div [ class "card-header" ] [ text "Ticket Status" ]
                        , div [ class "card-body" ]
                            [ h5 [ class "card-title text-success" ] [ text "Ticket has been scanned before" ]
                            , p [ class "card-text" ] [ text ("Seat number " ++ ticket.seatID) ]
                            , p [ class "card-text" ] [ text ("Ticket number " ++ ticket.ticketID) ]
                            , p [ class "card-text" ] [ text ("Was scanned at " ++ Iso8601.fromTime posixTime) ]
                            ]
                        ]

                Nothing ->
                    div [ class "card border-dark mb-3" ]
                        [ div [ class "card-header" ] [ text "Ticket Status" ]
                        , div [ class "card-body" ]
                            [ h5 [ class "card-title text-dark" ] [ text "Ticket not scanned yet" ]
                            , p [ class "card-text" ] [ text ("Seat number " ++ ticket.seatID) ]
                            , p [ class "card-text" ] [ text ("Ticket number " ++ ticket.ticketID) ]
                            , form [ onSubmit (OnMarkAsScannedSubmitted ticket.ticketID) ]
                                [ div [ class "form-group" ]
                                    [ label [ for "inputPassword" ] [ text "Password" ]
                                    , input [ type_ "password", class "form-control", onInput OnPasswordChanged ] []
                                    ]
                                , button [ class "btn btn-primary" ] [ text "Mark as scanned" ]
                                ]
                            ]
                        ]
    in
    div [ class "container" ]
        [ div [ class "row" ]
            [ div [ class "col-sm-12 text-center" ]
                [ card
                ]
            ]
        ]


notFoundPage : Html.Html Msg
notFoundPage =
    h1 [] [ text "404 Not Found" ]
