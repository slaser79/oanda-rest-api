-- | Defines the endpoints listed in the
-- <http://developer.oanda.com/rest-live-v20/instrument-ep/ Instrument> section of the
-- API.

module OANDA.Instrument
  ( CandlestickGranularity (..)
  , granularityToDiffTime
  , WeeklyAlignment (..)
  , PriceValue (..)
  , Candlestick (..)
  , CandlestickData (..)
  , CandlestickArgs (..)
  , candlestickArgsInstrument
  , candlestickArgsPrice
  , candlestickArgsGranularity
  , candlestickArgsCount
  , candlestickArgsFrom
  , candlestickArgsTo
  , candlestickArgsSmooth
  , candlestickArgsIncludeFirst
  , candlestickArgsDailyAlignment
  , candlestickArgsAlignmentTimezone
  , candlestickArgsWeeklyAlignment
  , candlestickArgs
  , oandaCandles
  , CandlestickResponse (..)
  ) where

import OANDA.Internal

data CandlestickGranularity
  = S5
  | S10
  | S15
  | S30
  | M1
  | M2
  | M4
  | M5
  | M10
  | M15
  | M30
  | H1
  | H2
  | H3
  | H4
  | H6
  | H8
  | H12
  | D
  | W
  | M
  deriving (Show)

deriveJSON defaultOptions ''CandlestickGranularity

-- | Utility function to convert Granularity to NominalDiffTime. __NOTE__: The
-- conversion from month to NominalDiffTime is not correct in general; we just
-- assume 31 days in a month, which is obviously false for 5 months of the
-- year.
granularityToDiffTime :: CandlestickGranularity -> NominalDiffTime
granularityToDiffTime S5 = fromSeconds' 5
granularityToDiffTime S10 = fromSeconds' 10
granularityToDiffTime S15 = fromSeconds' 15
granularityToDiffTime S30 = fromSeconds' 30
granularityToDiffTime M1 = fromSeconds' $ 1 * 60
granularityToDiffTime M2 = fromSeconds' $ 2 * 60
granularityToDiffTime M4 = fromSeconds' $ 4 * 60
granularityToDiffTime M5 = fromSeconds' $ 5 * 60
granularityToDiffTime M10 = fromSeconds' $ 10 * 60
granularityToDiffTime M15 = fromSeconds' $ 15 * 60
granularityToDiffTime M30 = fromSeconds' $ 30 * 60
granularityToDiffTime H1 = fromSeconds' $ 1 * 60 * 60
granularityToDiffTime H2 = fromSeconds' $ 2 * 60 * 60
granularityToDiffTime H3 = fromSeconds' $ 3 * 60 * 60
granularityToDiffTime H4 = fromSeconds' $ 4 * 60 * 60
granularityToDiffTime H6 = fromSeconds' $ 6 * 60 * 60
granularityToDiffTime H8 = fromSeconds' $ 8 * 60 * 60
granularityToDiffTime H12 = fromSeconds' $ 12 * 60 * 60
granularityToDiffTime D = fromSeconds' $ 1 * 60 * 60 * 24
granularityToDiffTime W = fromSeconds' $ 7 * 60 * 60 * 24
granularityToDiffTime M = fromSeconds' $ 31 * 60 * 60 * 24

data WeeklyAlignment
  = Monday
  | Tuesday
  | Wednesday
  | Thursday
  | Friday
  | Saturday
  | Sunday
  deriving (Show)

newtype PriceValue = PriceValue { unPriceValue :: Text }
  deriving (Show, ToJSON, FromJSON)

data CandlestickData
  = CandlestickData
  { candlestickDataO :: PriceValue
  , candlestickDataH :: PriceValue
  , candlestickDataL :: PriceValue
  , candlestickDataC :: PriceValue
  } deriving (Show)

deriveJSON (unPrefix "candlestickData") ''CandlestickData

data Candlestick
  = Candlestick
  { candlestickTime :: ZonedTime
  , candlestickBid :: Maybe CandlestickData
  , candlestickAsk :: Maybe CandlestickData
  , candlestickMid :: Maybe CandlestickData
  , candlestickVolume :: Integer
  , candlestickComplete :: Bool
  } deriving (Show)

deriveJSON (unPrefix "candlestick") ''Candlestick

data CandlestickArgs
  = CandlestickArgs
  { _candlestickArgsInstrument :: InstrumentName
  , _candlestickArgsPrice :: Maybe Text
  , _candlestickArgsGranularity :: CandlestickGranularity
  , _candlestickArgsCount :: Maybe Int
  , _candlestickArgsFrom :: Maybe ZonedTime
  , _candlestickArgsTo :: Maybe ZonedTime
  , _candlestickArgsSmooth :: Maybe Bool
  , _candlestickArgsIncludeFirst :: Maybe Bool
  , _candlestickArgsDailyAlignment :: Maybe Int
  , _candlestickArgsAlignmentTimezone :: Maybe String
  , _candlestickArgsWeeklyAlignment :: Maybe WeeklyAlignment
  }

candlestickArgs :: InstrumentName -> CandlestickGranularity -> CandlestickArgs
candlestickArgs instrument granularity =
  CandlestickArgs
  { _candlestickArgsInstrument = instrument
  , _candlestickArgsPrice = Nothing
  , _candlestickArgsGranularity = granularity
  , _candlestickArgsCount = Nothing
  , _candlestickArgsFrom = Nothing
  , _candlestickArgsTo = Nothing
  , _candlestickArgsSmooth = Nothing
  , _candlestickArgsIncludeFirst = Nothing
  , _candlestickArgsDailyAlignment = Nothing
  , _candlestickArgsAlignmentTimezone = Nothing
  , _candlestickArgsWeeklyAlignment = Nothing
  }

makeLenses ''CandlestickArgs

oandaCandles :: OandaEnv -> CandlestickArgs -> OANDARequest CandlestickResponse
oandaCandles env CandlestickArgs{..} = OANDARequest request
  where
    instrumentText = unpack $ unInstrumentName _candlestickArgsInstrument
    request =
      baseApiRequest env "GET" ("/v3/instruments/" ++ instrumentText ++ "/candles")
      & setRequestQueryString params
    params =
      catMaybes
      [ ("price",) . Just . encodeUtf8 <$> _candlestickArgsPrice
      , Just ("granularity", Just . fromString $ show _candlestickArgsGranularity)
      , ("count",) . Just . fromString . show <$> _candlestickArgsCount
      , ("from",) . Just . fromString . formatTimeRFC3339 <$> _candlestickArgsFrom
      , ("to",) . Just . fromString . formatTimeRFC3339 <$> _candlestickArgsTo
      , ("smooth",) . Just . fromString . show <$> _candlestickArgsSmooth
      , ("includeFirst",) . Just . fromString . show <$> _candlestickArgsIncludeFirst
      , ("dailyAlignment",) . Just . fromString . show <$> _candlestickArgsDailyAlignment
      , ("alignmentTimezone",) . Just . fromString . show <$> _candlestickArgsAlignmentTimezone
      , ("weeklyAlignment",) . Just . fromString . show <$> _candlestickArgsWeeklyAlignment
      ]

data CandlestickResponse
  = CandlestickResponse
  { candlestickResponseInstrument :: InstrumentName
  , candlestickResponseGranularity :: CandlestickGranularity
  , candlestickResponseCandles :: [Candlestick]
  } deriving (Show)

deriveJSON (unPrefix "candlestickResponse") ''CandlestickResponse