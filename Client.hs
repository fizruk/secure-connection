module Main where

import Network.Socket hiding (send, sendTo, recv, recvFrom)

import System.Environment (getArgs)

import OpenSSL (withOpenSSL)
import qualified OpenSSL.Session as SSL

import Common

main :: IO ()
main = withSocketsDo $ do
    [host, portStr] <- getArgs
    addrInfo <- getAddrInfo Nothing (Just host) (Just portStr)
    let serverAddr = head addrInfo
    sock <- socket (addrFamily serverAddr) Stream defaultProtocol
    connect sock $ addrAddress serverAddr

    withOpenSSL $ do
        -- set up SSL context
        ctx  <- SSL.context
        SSL.contextSetCiphers ctx "MEDIUM"

        -- make SSL connection
        conn <- SSL.connection ctx sock
        SSL.connect conn

        -- lazily recieve all messages
        input <- SSL.lazyRead conn
        msgs  <- readMsgs input

        -- display all recieved messages
        mapM_ (putStrLn . prettyMsg) msgs

        -- close connection
        SSL.shutdown conn SSL.Unidirectional
