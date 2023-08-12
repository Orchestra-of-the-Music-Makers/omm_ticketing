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
                Route.TicketData _ ->
                    ticketDataPage model.tncLink model.currentTicket

                Route.NotFound ->
                    notFoundPage

                Route.MusicUnmasked ->
                    notFoundPage
                
                Route.MusicUnmaskedDocs ->
                    notFoundPage

                Route.SymphonicFantasies ->
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

        GotTicketData (Result.Ok result) ->
            ( { model | currentTicket = RemoteData.Success result }, Cmd.none )

        GotTicketData (Result.Err error) ->
            ( { model | currentTicket = RemoteData.Failure error }, Cmd.none )

        OnPasswordChanged s ->
            ( { model | password = s }, Cmd.none )

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
        Route.TicketData s ->
            ( { newModel | currentTicket = RemoteData.Loading }, API.getTicketData newModel.lambdaUrl newModel.apiKey s )
        
        Route.MusicUnmasked ->
            ( newModel, Browser.Navigation.load "https://drive.google.com/file/d/1IX6bjJVDjAnC0WL-G9lRTZg6vpueAENx/view?usp=drivesdk" )
        
        Route.MusicUnmaskedDocs ->
            ( newModel, Browser.Navigation.load "https://drive.google.com/file/d/1IX6bjJVDjAnC0WL-G9lRTZg6vpueAENx/view?usp=drivesdk" )

        Route.SymphonicFantasies ->
            ( newModel, Browser.Navigation.load "https://drive.google.com/file/d/1hWI9EhvMDeTLVbE0EccgXr7P8SkuuHzg/view?usp=drivesdk" )

        Route.NotFound ->
            ( newModel, Cmd.none )

ticketDataPage : String -> RemoteData.WebData TicketData -> Html.Html Msg
ticketDataPage tncLink remoteEvent =
    let
        card =
            case remoteEvent of
                RemoteData.Success ticket ->
                    let
                        truncatedTicketID =
                            String.left 6 ticket.ticketID

                        seatCard =
                            case ticket.seatID of
                                Nothing ->
                                    div [ class "col-3" ] []
                                _ ->
                                    div [ class "col-3 seat-no" ] [ div [ class "seat-content text-center" ]
                                        [ span [ class "clearfix" ] [ text "SEAT" ]
                                        , span [ class "clearfix", id "no" ] [ text "ticket.seatID" ]
                                        , span [ class "ticketid" ] [ text truncatedTicketID ]
                                        ]]

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
                                [ seatCard
                                , div [ class "col-9" ]
                                    [ div [ class "row" ]
                                        [ div [ class "col-12 text-right mt-4 mb-2" ] [ img [ src "/assets/OMM-White.png", class "p-3 omm-logo" ] [] ]
                                        ]
                                    , div [ class "row" ]
                                        [ div [ class "col-12" ] [ lazy qrCode ticket.ticketID ] ]
                                    ]
                                ]
                            , div [ class "row pr-3" ]
                                [ div [ class "col-10 offset-2 text-right" ]
                                    [ p [ class "text-light grey mb-4 font-italic" ] [ text "Please show this to the usher to enter the hall." ]
                                    , h1 [ class "" ] [ text ticket.title ]
                                    , p [ class "details" ] [ text ticket.date ]
                                    , p [ class "details mb-4" ] [ text ticket.venue ]
                                    , a [ href ticket.bookletLink, target "_blank" ] [ button [ class "btn btn-primary mb-2" ] [ text "PROGRAMME BOOKLET" ] ]
                                    , a [ href ticket.surveyLink, target "_blank" ] [ button [ class "btn btn-primary mb-4" ] [ text "POST-CONCERT SURVEY" ] ]
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
    h1 [] [ text "Redirecting..." ]
