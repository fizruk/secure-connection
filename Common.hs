{-# LANGUAGE TemplateHaskell, DeriveDataTypeable #-}
module Common where

import Data.Data

import Data.Binary.Get
import Data.Binary.Put

import Data.Bson (Document)
import Data.Bson.Binary
import Data.Bson.Mapping

import Codec.Compression.Snappy

import Data.ByteString.Lazy (ByteString, toChunks, fromChunks)

data Message = Message
    { msgId   :: Int
    , msgText :: String
    } deriving (Show, Read, Eq, Ord, Data, Typeable)
$(deriveBson ''Message)

-- | Make message.
mkMsg :: Int -> String -> Message
mkMsg = Message

-- | Read messages from compressed ByteString.
readMsgs :: (Monad m) => ByteString -> m [Message]
readMsgs = manyFromBs . decompressLazyBs

-- | Write message to compressed ByteString.
writeMsg :: Message -> ByteString
writeMsg = compressLazyBs . toBs

-- | Compress each chunck of lazy ByteString separately.
compressLazyBs :: ByteString -> ByteString
compressLazyBs = fromChunks . map compress . toChunks

-- | Decompress each chunck of lazy ByteString separately.
decompressLazyBs :: ByteString -> ByteString
decompressLazyBs = fromChunks . map decompress . toChunks

-- | Pretty print message.
prettyMsg :: Message -> String
prettyMsg (Message n s) = show n ++ ") " ++ s

-- | Convert data to ByteString.
toBs :: (Bson a) => a -> ByteString
toBs = bsonToBs . toBson

-- | Read data from ByteString.
fromBs :: (Bson a, Monad m) => ByteString -> m a
fromBs = fromBson . bsToBson

-- | Read sequence of data from ByteString.
manyFromBs :: (Bson a, Monad m) => ByteString -> m [a]
manyFromBs = mapM fromBson . bsToBsons

-- helpers
bsonToBs :: Document -> ByteString
bsonToBs = runPut . putDocument

bsToBson :: ByteString -> Document
bsToBson = runGet getDocument

getDocuments :: Get [Document]
getDocuments = do
    doc <- getDocument
    emt <- isEmpty
    if emt
        then return [doc]
        else do
            docs <- getDocuments
            return $ doc : docs

bsToBsons :: ByteString -> [Document]
bsToBsons = runGet getDocuments

