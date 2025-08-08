module Main where

import Prelude
import Data.Maybe (Maybe(..))
import Data.Either (Either(..))
import Data.Void (Void, absurd)
import Data.Functor (void)
import Data.HTTP.Method (Method(..))
import Data.String (joinWith)
import Effect.Class (liftEffect)
import Effect.Aff (Aff)
import Effect.Aff.Class (liftAff)
import Halogen.Aff (awaitBody, runHalogenAff, selectElement)
import Web.DOM.ParentNode (QuerySelector(..))
import Effect (Effect)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Events as HE
import Halogen.HTML.Properties as HP
import Halogen.VDom.Driver (runUI)
import Affjax.Web as AX
import Affjax.ResponseFormat as ResponseFormat
import Data.Argonaut.Core (Json)
import Data.Argonaut.Decode (decodeJson, (.:))
import Data.Argonaut.Decode.Class (class DecodeJson)

-- The app state now includes loading state
type State = 
  { quote :: String
  , isLoading :: Boolean
  , error :: Maybe String
  }

-- Actions the user can do
data Action = GetQuote | GetAllQuotes

-- Query type (we don't use queries, so this is just a placeholder)
data Query a = Query Void a

-- JSON response type for a single quote
newtype QuoteResponse = QuoteResponse { quote :: String }

instance decodeQuoteResponse :: DecodeJson QuoteResponse where
  decodeJson json = do
    obj <- decodeJson json
    quote <- obj .: "quote"
    pure $ QuoteResponse { quote }

-- JSON response type for all quotes
newtype QuotesResponse = QuotesResponse { quotes :: Array String }

instance decodeQuotesResponse :: DecodeJson QuotesResponse where
  decodeJson json = do
    obj <- decodeJson json
    quotes <- obj .: "quotes"
    pure $ QuotesResponse { quotes }

-- The UI component
component :: H.Component Query Unit Void Aff
component = H.mkComponent
  { initialState: const { quote: "Click the button to get a quote from the server!", isLoading: false, error: Nothing }
  , render
  , eval: H.mkEval $ H.defaultEval { handleAction = handleAction }
  }

-- What the app looks like
render :: State -> H.ComponentHTML Action () Aff
render state =
  HH.div_
    [ HH.h2_ [ HH.text "💬 Quote Explorer " ]
    , HH.p 
        [ HP.style $ if state.isLoading then "opacity: 0.7; font-style: italic;" else "" ] 
        [ HH.text $ if state.isLoading then "Loading..." else state.quote ]
    , case state.error of
        Just err -> HH.p 
          [ HP.style "color: red; font-size: 0.9rem;" ] 
          [ HH.text $ "Error: " <> err ]
        Nothing -> HH.text ""
    , HH.div_
        [ HH.button 
            [ HE.onClick \_ -> GetQuote
            , HP.disabled state.isLoading
            ] 
            [ HH.text "✨ Get Random Quote" ]
        , HH.text " "
        , HH.button 
            [ HE.onClick \_ -> GetAllQuotes
            , HP.disabled state.isLoading
            , HP.style "background-color: #4CAF50; margin-left: 10px;"
            ] 
            [ HH.text "📚 Show All Quotes" ]
        ]
    ]

-- API base URL
apiBaseUrl :: String
apiBaseUrl = "http://localhost:3001"

-- Fetch a random quote from the backend
fetchRandomQuote :: Aff (Either String String)
fetchRandomQuote = do
  result <- AX.get ResponseFormat.json (apiBaseUrl <> "/api/quote")
  case result of
    Left err -> pure $ Left $ "Network error: " <> AX.printError err
    Right response -> 
      case decodeJson response.body of
        Left decodeErr -> pure $ Left $ "JSON decode error: " <> show decodeErr
        Right (QuoteResponse { quote }) -> pure $ Right quote

-- Fetch all quotes from the backend
fetchAllQuotes :: Aff (Either String (Array String))
fetchAllQuotes = do
  result <- AX.get ResponseFormat.json (apiBaseUrl <> "/api/quotes")
  case result of
    Left err -> pure $ Left $ "Network error: " <> AX.printError err
    Right response -> 
      case decodeJson response.body of
        Left decodeErr -> pure $ Left $ "JSON decode error: " <> show decodeErr
        Right (QuotesResponse { quotes }) -> pure $ Right quotes

-- What happens when user clicks
handleAction :: Action -> H.HalogenM State Action () Void Aff Unit
handleAction GetQuote = do
  H.modify_ \st -> st { isLoading = true, error = Nothing }
  result <- liftAff fetchRandomQuote
  case result of
    Left err -> H.modify_ \st -> st { isLoading = false, error = Just err }
    Right quote -> H.modify_ \st -> st { quote = quote, isLoading = false, error = Nothing }

handleAction GetAllQuotes = do
  H.modify_ \st -> st { isLoading = true, error = Nothing }
  result <- liftAff fetchAllQuotes
  case result of
    Left err -> H.modify_ \st -> st { isLoading = false, error = Just err }
    Right quotes -> 
      let allQuotesText = "All available quotes:\n\n" <> (quotes # map (\q -> "• " <> q) # joinWith "\n")
      in H.modify_ \st -> st { quote = allQuotesText, isLoading = false, error = Nothing }

-- Start app
main :: Effect Unit
main = runHalogenAff do
  _ <- awaitBody
  app <- selectElement (QuerySelector "#app")
  case app of
    Just element -> void $ runUI component unit element
    Nothing -> pure unit