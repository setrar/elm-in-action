module PhotoGroove exposing (main)

import Browser
import Html exposing (Html, div, h1, h3, img, text, button, input, label)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Random
import Http

urlPrefix : String
urlPrefix =
   "http://elm-in-action.com/"

viewLoaded : List Photo -> String -> ThumbnailSize -> List (Html Msg)
viewLoaded photos selectedUrl chosenSize =
        [ h1 [] [ text "Photo Groove" ]
        , button
            [ onClick ClickedSurpriseMe ]
            [ text "Surprise Me!" ]
        , h3 [] [ text "Thumbnail Size:" ]
        , div [ id "choose-size" ]
            (List.map viewSizeChooser [ Small, Medium, Large ])
        , div [ id "thumbnails", class (sizeToString chosenSize) ]
            (List.map (viewThumbnail selectedUrl) photos)
        , img
            [ class "large"
            , src (urlPrefix ++ "large/" ++ selectedUrl)
            ]
            []
        ]

type Msg 
    = ClickedPhoto String
    | ClickedSize ThumbnailSize
    | ClickedSurpriseMe
    | GotRandomPhoto Photo
    | GotPhotos (Result Http.Error String)

view : Model -> Html Msg
view model =
    div [ class "content" ] <|
        case model.status of
            Loaded photos selectedUrl ->
                viewLoaded photos selectedUrl model.chosenSize
            Loading ->
                []
            Errored errorMessage ->
                [ text ("Error: " ++ errorMessage) ]

viewThumbnail : String -> Photo -> Html Msg
viewThumbnail selectedUrl thumb =
    img
        [ src (urlPrefix ++ thumb.url)
        , classList [ ( "selected", selectedUrl == thumb.url ) ]
        , onClick <| ClickedPhoto thumb.url
        ]
        []

viewSizeChooser : ThumbnailSize -> Html Msg
viewSizeChooser size =
    label []
        [ input [ type_ "radio", name "size", onClick (ClickedSize size) ] []
        , text (sizeToString size)
        ]

sizeToString : ThumbnailSize -> String
sizeToString size =
    case size of
        Small ->
            "small"

        Medium ->
            "med"

        Large ->
            "large"

type ThumbnailSize
    = Small
    | Medium
    | Large

type alias Photo =
    { url : String }

type Status
    = Loading
    | Loaded (List Photo) String
    | Errored String

type alias Model =
    { status : Status
    , chosenSize : ThumbnailSize
    }

initialModel : Model
initialModel =
    { status = Loading
    , chosenSize = Medium
    }

initialCmd : Cmd Msg
initialCmd =
    Http.get
        { url = urlPrefix ++ "/photos/list"
        , expect = Http.expectString GotPhotos
        }

selectUrl : String -> Status -> Status
selectUrl url status =
    case status of
        Loaded photos _ ->
            Loaded photos url

        Loading ->
            status

        Errored errorMessage ->
            status

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotRandomPhoto photo ->
            ( { model | status = selectUrl photo.url model.status}, Cmd.none )

        ClickedPhoto url -> 
            ( { model | status = selectUrl url model.status}, Cmd.none )

        ClickedSize size ->
            ( { model | chosenSize = size }, Cmd.none )

        ClickedSurpriseMe ->
            case model.status of
                Loaded (x :: xs) _ ->
                    Random.uniform x xs
                    |> Random.generate GotRandomPhoto
                    |> Tuple.pair model

                Loaded [] _ ->
                    ( model, Cmd.none)

                Loading ->
                    ( model, Cmd.none )

                Errored errorMessage ->
                    ( model, Cmd.none )

        GotPhotos (Ok responseStr) ->
            case String.split "," responseStr of
                x :: _ as urls ->
                    let
                        photos =List.map Photo urls
                    in
                        ( { model | status = Loaded photos x }, Cmd.none )
                [] ->
                    ( { model | status = Errored "0 photos found" }, Cmd.none )

        GotPhotos (Err _) ->
            ( model, Cmd.none )

main : Program () Model Msg
main = 
    Browser.element
        { init = \_ -> ( initialModel, initialCmd )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
