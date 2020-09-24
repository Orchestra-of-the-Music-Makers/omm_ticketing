module Main exposing (..)

import API
import Browser
import Browser.Navigation
import Html exposing (button, div, form, h1, h5, img, input, label, p, span, text)
import Html.Attributes exposing (alt, class, for, id, src, style, title, type_)
import Html.Events exposing (onInput, onSubmit)
import Http
import Iso8601
import RemoteData
import Route
import Types exposing (..)
import Url
import Url.Parser

softAsHardLineBreak = True


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
            , currentTicket = RemoteData.NotAsked
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
                    ticketStatusPage model.currentTicket

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
            ( { model | currentTicket = RemoteData.Success result }, Cmd.none )

        GotTicketStatus (Result.Err error) ->
            ( { model | currentTicket = RemoteData.Failure error }, Cmd.none )

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
            ( { newModel | currentTicket = RemoteData.Loading }, API.getTicketStatus newModel.lambdaUrl newModel.apiKey s )

        Route.NotFound ->
            ( newModel, Cmd.none )


ticketStatusPage : RemoteData.WebData TicketStatus -> Html.Html Msg
ticketStatusPage remoteTicket =
    let
        card =
            case remoteTicket of
                RemoteData.Success ticket ->
                    case ticket.scannedAt of
                        Just posixTime ->
                            let
                                qrCodeSrc =
                                    "https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl=https%3A%2F%2Fticketing.orchestra.sg%2F" ++ ticket.ticketID ++ "%0A&choe=UTF-8"
                            in
                            div [ class "card" ]
                                [div [ class "card-text" ]
                                    [ div [ class "row ml-3" ]
                                        [ div [ class "col-3 seat-no" ]
                                                [ div [ class "seat-content text-center"]
                                                [ span [ class "clearfix" ] [ text "SEAT" ]
                                                , span [ class "clearfix", id "no" ] [ text ticket.seatID ]
                                                , span [ class "ticketid" ] [ text ticket.ticketID ]
                                                ]
                                            ]
                                        , div [ class "col-9" ]
                                            [ div [ class "row" ]
                                                [ div [ class "col-12 text-right mt-4 mb-2" ] [ img [ src "/assets/OMM-White.png", class "p-3 omm-logo" ] [] ]
                                                ]
                                            , div [ class "row" ]
                                                [ div [ class "col-12" ]
                                                    [ img [ src qrCodeSrc, alt "QR Code", class "img-rounded pr-3"] []
                                                    ]
                                                ]
                                            ]
                                        ]
                                    , div [ class "row pr-3" ]
                                        [ div [ class "col-10 offset-2 text-right" ]
                                            [ p [ class "text-light grey mb-4 font-italic" ] [ text "Present to usher upon entrance." ]
                                            , h1 [ class "" ] [ text "OMM Restarts!" ]
                                            , p [ class "details" ] [ text "11 Oct 2020, 7.30PM"]
                                            , p [ class "details mb-4" ] [ text "Singapore Conference Hall" ]
                                            , button [ class "btn btn-primary mb-2" ] [ text "PROGRAMME BOOKLET" ]
                                            , button [ class "btn btn-primary mb-4" ] [ text "POST-CONCERT SURVEY" ]
                                            , p [ class "text-muted grey mb-4" ] [ text "Terms & Conditions" ]
                                            ]
                                        ]
                                
                                
                                
                                ]

                                -- , div [ class "card-body" ]
                                --     [ h5 [ class "card-title text-success" ] [ text "Ticket has been scanned before" ]
                                --     , p [ class "card-text" ] [ text ("Seat number " ++ ticket.seatID) ]
                                --     , p [ class "card-text" ] [ text ("Ticket number " ++ ticket.ticketID) ]
                                --     , p [ class "card-text" ] [ text ("Was scanned at " ++ Iso8601.fromTime posixTime) ]
                                --     ]
                                ]

                        Nothing ->
                            div [ class "card border-dark mt-3 mb-3" ]
                                [ div [ class "card-header" ] [ text "Ticket Status" ]
                                , div [ class "card-body" ]
                                    [ img [ src "/assets/OMM-White.png", class "w-50 p-3" ] []
                                    , h5 [ class "card-title text-dark" ] [ text "Ticket not scanned yet" ]
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

                RemoteData.Failure _ ->
                    div [ class "card border-danger mt-3 mb-3" ]
                        [ div [ class "card-header" ] [ text "Ticket Status" ]
                        , div [ class "card-body" ]
                            [ h5 [ class "card-title" ] [ text "Failed fetching ticket status" ] ]
                        ]

                _ ->
                    div [ class "card border-dark mt-3 mb-3" ]
                        [ div [ class "card-header" ] [ text "Ticket Status" ]
                        , div [ class "card-body" ]
                            [ div [ class "spinner-border" ] [ span [ class "sr-only" ] [ text "Loading..." ] ] ]
                        ]
    in
    div [ class "container-fluid" ]
        [ div [ class "row" ]
            [ div [ class "min-vh-20" ] [] ]
        , card
        ]


notFoundPage : Html.Html Msg
notFoundPage =
    h1 [] [ text "404 Not Found" ]
