module Main exposing (..)

import API
import Browser
import Browser.Navigation
import Html exposing (a, button, div, form, h1, h2, h5, img, input, label, p, span, text)
import Html.Attributes exposing (alt, class, for, href, id, placeholder, src, style, target, title, type_)
import Html.Events exposing (onInput, onSubmit)
import Html.Lazy exposing (lazy)
import Http
import Iso8601
import QRCode exposing (QRCode)
import RemoteData
import Route
import Svg.Attributes
import Task
import Time
import Types exposing (..)
import Url
import Url.Parser


softAsHardLineBreak =
    True


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
            , zone = Time.utc
            , tncLink = flags.tncLink
            , bookletLink = flags.bookletLink
            , surveyLink = flags.surveyLink
            }

        ( newModel, cmd ) =
            updateWithURL urlUrl model
    in
    ( newModel
    , Cmd.batch
        [ Task.perform AdjustTimeZone Time.here
        , cmd
        ]
    )


view : Model -> Browser.Document Msg
view model =
    let
        page =
            case model.currentPage of
                Route.TicketStatus _ ->
                    ticketStatusPage model.bookletLink model.surveyLink model.tncLink model.currentTicket

                Route.UsherTicketStatus _ ->
                    usherTicketStatusPage model.zone model.currentTicket

                Route.NotFound ->
                    notFoundPage

                Route.AlbertTiuChopin ->
                    notFoundPage
    in
    Browser.Document "OMM Ticketing"
        [ page
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )


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

        Route.UsherTicketStatus s ->
            ( { newModel | currentTicket = RemoteData.Loading }, API.getTicketStatus newModel.lambdaUrl newModel.apiKey s )
        
        Route.AlbertTiuChopin ->
            ( newModel, Browser.Navigation.load "https://ticketing.orchestra.sg/booklet" )

        Route.NotFound ->
            ( newModel, Cmd.none )


ticketStatusPage : String -> String -> String -> RemoteData.WebData TicketStatus -> Html.Html Msg
ticketStatusPage bookletLink surveyLink tncLink remoteTicket =
    let
        card =
            case remoteTicket of
                RemoteData.Success ticket ->
                    let
                        ticketLink =
                            "https://ticketing.orchestra.sg/" ++ ticket.ticketID ++ "/status"

                        truncatedTicketID =
                            String.left 6 ticket.ticketID

                        qrCode message =
                            QRCode.fromStringWith QRCode.Quartile message
                                |> Result.map
                                    (QRCode.toSvg
                                        [ Svg.Attributes.width "100px"
                                        , Svg.Attributes.height "100px"
                                        , Svg.Attributes.class "img-rounded pr-3"
                                        ]
                                    )
                                |> Result.withDefault (text "Error while encoding to QRCode.")
                    in
                    div [ class "card omm-card" ]
                        [ div [ class "card-text" ]
                            [ div [ class "row ml-3" ]
                                [ div [ class "col-3 seat-no" ]
                                    [ div [ class "seat-content text-center" ]
                                        [ span [ class "clearfix" ] [ text "SEAT" ]
                                        , span [ class "clearfix", id "no" ] [ text ticket.seatID ]
                                        , span [ class "ticketid" ] [ text truncatedTicketID ]
                                        ]
                                    ]
                                , div [ class "col-9" ]
                                    [ div [ class "row" ]
                                        [ div [ class "col-12 text-right mt-4 mb-2" ] [ img [ src "/assets/OMM-White.png", class "p-3 omm-logo" ] [] ]
                                        ]
                                    , div [ class "row" ]
                                        [ div [ class "col-12" ] [ lazy qrCode ticketLink ] ]
                                    ]
                                ]
                            , div [ class "row pr-3" ]
                                [ div [ class "col-10 offset-2 text-right" ]
                                    [ p [ class "text-light grey mb-4 font-italic" ] [ text "Please show this to the usher to enter the hall." ]
                                    , h1 [ class "" ] [ text "OMM Restarts!" ]
                                    , p [ class "details" ] [ text ("11 Oct 2020, " ++ ticket.startTime) ]
                                    , p [ class "details mb-4" ] [ text "Singapore Conference Hall" ]
                                    , a [ href bookletLink, target "_blank" ] [ button [ class "btn btn-primary mb-2" ] [ text "PROGRAMME BOOKLET" ] ]
                                    , a [ href surveyLink, target "_blank" ] [ button [ class "btn btn-primary mb-4" ] [ text "POST-CONCERT SURVEY" ] ]
                                    , a [ href tncLink, target "_blank" ] [ p [ class "text-muted grey mb-4" ] [ text "Terms & Conditions" ] ]
                                    ]
                                ]
                            ]
                        ]

                RemoteData.Failure _ ->
                    failedFetchingPage

                _ ->
                    loadingPage
    in
    div [ class "container-fluid" ]
        [ div [ class "row" ]
            [ div [ class "min-vh-20" ] [] ]
        , card
        ]


usherTicketStatusPage : Time.Zone -> RemoteData.WebData TicketStatus -> Html.Html Msg
usherTicketStatusPage zone remoteTicket =
    let
        card =
            case remoteTicket of
                RemoteData.Success ticket ->
                    case ticket.scannedAt of
                        Just posixTime ->
                            let
                                ( date, month, year ) =
                                    ( String.fromInt (Time.toDay zone posixTime)
                                    , Types.toMonthStr (Time.toMonth zone posixTime)
                                    , String.fromInt (Time.toYear zone posixTime)
                                    )

                                ( hour, minute, second ) =
                                    ( String.padLeft 2 '0' (String.fromInt (Time.toHour zone posixTime))
                                    , String.padLeft 2 '0' (String.fromInt (Time.toMinute zone posixTime))
                                    , String.padLeft 2 '0' (String.fromInt (Time.toSecond zone posixTime))
                                    )
                            in
                            div [ class "card omm-card usher-card" ]
                                [ div [ class "card-text" ]
                                    [ div [ class "row ml-3" ]
                                        [ div [ class "col-3 seat-no" ]
                                            [ div [ class "seat-content text-center" ]
                                                [ span [ class "clearfix" ] [ text "SEAT" ]
                                                , span [ class "clearfix", id "no" ] [ text ticket.seatID ]
                                                , span [ class "ticketid" ] [ text ticket.ticketID ]
                                                ]
                                            ]
                                        , div [ class "col-9" ]
                                            [ div [ class "row" ]
                                                [ div [ class "col-12 text-right mt-4 mb-2" ] [ img [ src "/assets/OMM-White.png", class "p-3 omm-logo" ] [] ]
                                                ]
                                            ]
                                        ]
                                    , div [ class "row pr-3" ]
                                        [ div [ class "col-10 offset-2 text-right" ]
                                            [ h1 [ class "" ] [ text "Ticket was scanned at" ]
                                            , p [ class "details mb-4" ] [ text (date ++ "-" ++ month ++ "-" ++ year ++ ", " ++ hour ++ ":" ++ minute ++ ":" ++ second) ]
                                            ]
                                        ]
                                    ]
                                ]

                        Nothing ->
                            div [ class "card omm-card usher-card" ]
                                [ div [ class "card-text" ]
                                    [ div [ class "row ml-3" ]
                                        [ div [ class "col-3 seat-no" ]
                                            [ div [ class "seat-content text-center" ]
                                                [ span [ class "clearfix" ] [ text "SEAT" ]
                                                , span [ class "clearfix", id "no" ] [ text ticket.seatID ]
                                                , span [ class "ticketid" ] [ text ticket.ticketID ]
                                                ]
                                            ]
                                        , div [ class "col-9" ]
                                            [ div [ class "row" ]
                                                [ div [ class "col-12 text-right mt-4 mb-2" ] [ img [ src "/assets/OMM-White.png", class "p-3 omm-logo" ] [] ]
                                                ]
                                            ]
                                        ]
                                    , div [ class "row pr-3" ]
                                        [ div [ class "col-10 offset-2 text-right" ]
                                            [ h1 [ class "" ] [ text "Ticket not scanned yet" ]
                                            , form [ onSubmit (OnMarkAsScannedSubmitted ticket.ticketID) ]
                                                [ div [ class "form-group" ]
                                                    [ input [ type_ "password", class "form-control", onInput OnPasswordChanged, placeholder "password" ] []
                                                    ]
                                                , button [ class "btn btn-primary" ] [ text "Mark as scanned" ]
                                                ]
                                            ]
                                        ]
                                    ]
                                ]

                RemoteData.Failure _ ->
                    failedFetchingPage

                _ ->
                    loadingPage
    in
    div [ class "container-fluid" ]
        [ card
        ]


failedFetchingPage : Html.Html Msg
failedFetchingPage =
    div [ class "m-3 text-center" ]
        [ h1 [] [ text "Failed fetching ticket status" ] ]


loadingPage : Html.Html Msg
loadingPage =
    div [ class "m-3 text-center" ]
        [ div [ class "spinner-border text-light" ] [ span [ class "sr-only" ] [ text "Loading..." ] ] ]


notFoundPage : Html.Html Msg
notFoundPage =
    h1 [] [ text "404 Not Found" ]
